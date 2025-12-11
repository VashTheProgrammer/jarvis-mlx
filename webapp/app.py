#!/usr/bin/env python3
"""
Flask Web App per Chat con modelli MLX fine-tuned
Supporta selezione dinamica tra più modelli/adapter
"""

import os
import json
import time
from pathlib import Path
from functools import wraps
from flask import Flask, render_template, request, jsonify, Response, stream_with_context, session, redirect, url_for
from mlx_lm import load, generate
import mlx.core as mx
from dotenv import load_dotenv

# Carica variabili d'ambiente
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'change-this-secret-key-in-production')
app.config['APP_PASSWORD'] = os.getenv('APP_PASSWORD', 'admin123')
app.config['SECRET_PATH'] = os.getenv('SECRET_PATH', '')
app.config['REQUIRE_AUTH_LOCAL'] = os.getenv('REQUIRE_AUTH_LOCAL', 'false').lower() == 'true'

# Percorsi
BASE_DIR = Path(__file__).parent.parent
MODELS_DIR = BASE_DIR / "models"
CONFIG_FILE = MODELS_DIR / "models_config.json"

# Cache dei modelli caricati
loaded_models = {}
current_model_id = None


def is_local_request():
    """Verifica se la richiesta proviene da localhost"""
    remote_addr = request.remote_addr
    # Considera locale: 127.0.0.1, ::1 (IPv6 localhost), e 0.0.0.0
    return remote_addr in ['127.0.0.1', 'localhost', '::1', '0.0.0.0']


def login_required(f):
    """Decorator per proteggere le route con password"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Se la richiesta è locale e non è richiesta l'autenticazione locale, skip
        if is_local_request() and not app.config['REQUIRE_AUTH_LOCAL']:
            return f(*args, **kwargs)

        # Altrimenti richiede autenticazione
        if not session.get('authenticated'):
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function


def load_models_config():
    """Carica la configurazione dei modelli disponibili"""
    if not CONFIG_FILE.exists():
        return {"base_model": "mlx-community/Qwen2.5-7B-Instruct-4bit", "models": []}

    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def get_available_models():
    """Restituisce lista dei modelli disponibili (enabled)"""
    config = load_models_config()
    available = []

    for model in config['models']:
        # Controlla se il modello è abilitato
        if not model.get('enabled', True):
            continue

        # Se ha un adapter, verifica che esista
        if model['adapter_path']:
            adapter_path = MODELS_DIR / model['adapter_path']
            if not adapter_path.exists():
                continue

        available.append(model)

    return available


def load_model(model_id):
    """Carica un modello specifico (con cache)"""
    global loaded_models, current_model_id

    # Se è già caricato, ritorna subito
    if model_id in loaded_models and current_model_id == model_id:
        return loaded_models[model_id]

    # IMPORTANTE: Libera memoria dei modelli vecchi per evitare OOM
    # Mantieni solo il modello corrente in cache
    if current_model_id and current_model_id != model_id:
        if current_model_id in loaded_models:
            print(f"🗑️  Rimozione modello vecchio dalla cache: {current_model_id}")
            del loaded_models[current_model_id]
            import gc
            gc.collect()  # Forza garbage collection

    config = load_models_config()
    base_model = config['base_model']

    # Trova il modello richiesto
    model_info = None
    for m in config['models']:
        if m['id'] == model_id:
            model_info = m
            break

    if not model_info:
        raise ValueError(f"Modello '{model_id}' non trovato")

    print(f"🔄 Caricamento modello: {model_info['name']}")

    # Carica il modello base + adapter (se presente)
    if model_info['adapter_path']:
        adapter_path = str(MODELS_DIR / model_info['adapter_path'])
        print(f"   📦 Adapter: {adapter_path}")
        model, tokenizer = load(base_model, adapter_path=adapter_path)
    else:
        print(f"   📦 Modello base (no adapter)")
        model, tokenizer = load(base_model)

    # Salva in cache
    loaded_models[model_id] = {
        'model': model,
        'tokenizer': tokenizer,
        'info': model_info
    }
    current_model_id = model_id

    print(f"✅ Modello caricato: {model_info['name']}")
    return loaded_models[model_id]


def format_prompt(message, conversation_history=None, system_prompt=None):
    """Formatta il prompt in formato chat con system prompt opzionale"""
    messages = []

    # Aggiungi system prompt se presente
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})

    # Aggiungi lo storico della conversazione se presente
    if conversation_history:
        for entry in conversation_history:
            messages.append({"role": "user", "content": entry['user']})
            messages.append({"role": "assistant", "content": entry['assistant']})

    # Aggiungi il messaggio corrente
    messages.append({"role": "user", "content": message})

    # Formatta in stile chat (Qwen format)
    formatted = ""
    for msg in messages:
        if msg['role'] == 'system':
            formatted += f"<|im_start|>system\n{msg['content']}<|im_end|>\n"
        elif msg['role'] == 'user':
            formatted += f"<|im_start|>user\n{msg['content']}<|im_end|>\n"
        else:
            formatted += f"<|im_start|>assistant\n{msg['content']}<|im_end|>\n"

    formatted += "<|im_start|>assistant\n"
    return formatted


@app.route('/')
@login_required
def index():
    """Pagina principale"""
    return render_template('index.html')


@app.route('/login', methods=['GET', 'POST'])
def login():
    """Pagina di login"""
    if request.method == 'POST':
        password = request.form.get('password', '')
        if password == app.config['APP_PASSWORD']:
            session['authenticated'] = True
            return redirect(url_for('index'))
        else:
            return render_template('login.html', error='Password errata')
    return render_template('login.html')


@app.route('/logout')
def logout():
    """Logout"""
    session.clear()
    return redirect(url_for('login'))


@app.route('/api/models', methods=['GET'])
@login_required
def api_models():
    """Restituisce la lista dei modelli disponibili"""
    models = get_available_models()
    return jsonify({
        'models': models,
        'current': current_model_id
    })


@app.route('/api/model/select', methods=['POST'])
@login_required
def api_select_model():
    """Seleziona un modello"""
    data = request.json
    model_id = data.get('model_id')

    if not model_id:
        return jsonify({'error': 'model_id mancante'}), 400

    try:
        model_data = load_model(model_id)
        return jsonify({
            'success': True,
            'model': model_data['info']
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/chat', methods=['POST'])
@login_required
def api_chat():
    """Endpoint per chat (con streaming)"""
    data = request.json
    message = data.get('message', '')
    model_id = data.get('model_id', 'base')
    history = data.get('history', [])
    max_tokens = data.get('max_tokens', 500)
    temperature = data.get('temperature', 0.7)

    if not message:
        return jsonify({'error': 'Messaggio vuoto'}), 400

    try:
        # Carica il modello
        model_data = load_model(model_id)
        model = model_data['model']
        tokenizer = model_data['tokenizer']

        # Ottieni il system prompt se presente nella configurazione
        system_prompt = model_data['info'].get('system_prompt', None)

        # Formatta il prompt
        prompt = format_prompt(message, history, system_prompt=system_prompt)

        # Genera la risposta
        response = generate(
            model,
            tokenizer,
            prompt=prompt,
            max_tokens=max_tokens,
            verbose=False
        )

        # Pulisci la risposta (rimuovi tag speciali)
        response = response.replace("<|im_end|>", "").strip()

        return jsonify({
            'response': response,
            'model': model_data['info']['name']
        })

    except Exception as e:
        print(f"❌ Errore: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/chat/stream', methods=['POST'])
@login_required
def api_chat_stream():
    """Endpoint per chat con streaming (risposta in tempo reale)"""
    data = request.json
    message = data.get('message', '')
    model_id = data.get('model_id', 'base')
    history = data.get('history', [])
    max_tokens = data.get('max_tokens', 500)
    temperature = data.get('temperature', 0.7)

    if not message:
        return jsonify({'error': 'Messaggio vuoto'}), 400

    def generate_stream():
        try:
            # Carica il modello
            model_data = load_model(model_id)
            model = model_data['model']
            tokenizer = model_data['tokenizer']

            # Ottieni il system prompt se presente nella configurazione
            system_prompt = model_data['info'].get('system_prompt', None)

            # Formatta il prompt
            prompt = format_prompt(message, history, system_prompt=system_prompt)

            # Tokenizza il prompt
            prompt_tokens = mx.array(tokenizer.encode(prompt))

            # Genera token per token
            generated_tokens = []
            for token, _ in zip(
                generate(model, tokenizer, prompt=prompt, max_tokens=max_tokens),
                range(max_tokens)
            ):
                # Decodifica il token
                text = tokenizer.decode([token])

                # Stop se troviamo il token di fine
                if "<|im_end|>" in text or token == tokenizer.eos_token_id:
                    break

                # Invia il token al client
                yield f"data: {json.dumps({'token': text})}\n\n"

            yield f"data: {json.dumps({'done': True})}\n\n"

        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"

    return Response(
        stream_with_context(generate_stream()),
        mimetype='text/event-stream',
        headers={
            'Cache-Control': 'no-cache',
            'X-Accel-Buffering': 'no'
        }
    )


@app.route('/api/health', methods=['GET'])
def health():
    """Health check"""
    return jsonify({
        'status': 'ok',
        'loaded_models': list(loaded_models.keys()),
        'current_model': current_model_id
    })


if __name__ == '__main__':
    print("=" * 70)
    print("🚀 Jarvis MLX Web Chat")
    print("=" * 70)
    print()
    print("📡 Server in avvio...")
    print()

    # Carica il primo modello disponibile
    available = get_available_models()
    if available:
        first_model = available[0]['id']
        print(f"🔄 Pre-caricamento modello: {available[0]['name']}")
        try:
            load_model(first_model)
            print(f"✅ Modello pronto!")
        except Exception as e:
            print(f"⚠️  Errore caricamento: {e}")

    print()
    print("=" * 70)
    print("🌐 Server avviato!")
    print("=" * 70)
    print()
    print("📱 Accedi da:")
    print("   - Locale:      http://localhost:8080")
    print("   - Rete locale: http://<tuo-ip>:8080")
    print()
    print("💡 Premi CTRL+C per fermare il server")
    print("=" * 70)
    print()

    # Avvia il server (accessibile da rete locale)
    app.run(
        host='0.0.0.0',  # Accessibile da tutta la rete locale
        port=8080,  # Porta 8080 (5000 spesso occupata da AirPlay su macOS)
        debug=True,
        threaded=True
    )
