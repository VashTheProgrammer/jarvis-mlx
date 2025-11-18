#!/usr/bin/env python3
"""
Test completo di tutti i modelli esperti con domande appropriate
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from mlx_lm import load, generate
import json

# Percorsi
BASE_DIR = Path(__file__).parent.parent
MODELS_DIR = BASE_DIR / "models"
CONFIG_FILE = MODELS_DIR / "models_config.json"

# Domande di test per ogni esperto
TEST_QUESTIONS = {
    "astrology": [
        "Quali sono le caratteristiche del segno dell'Ariete?",
        "Cosa significa avere Venere in Toro?",
    ],
    "biology": [
        "Cos'è la fotosintesi?",
        "Come funziona il DNA?",
    ],
    "cooking": [
        "Come si fa la carbonara?",
        "Dammi una ricetta veloce per la cena",
    ],
    "history": [
        "Chi era Giulio Cesare?",
        "Quando è iniziata la Seconda Guerra Mondiale?",
    ],
    "programming": [
        "Come si crea una funzione in Python?",
        "Cos'è un ciclo for?",
    ],
    "base": [
        "Ciao, come stai?",
        "Raccontami una breve storia",
    ]
}

def format_prompt(message):
    """Formatta il prompt in formato chat"""
    return f"<|im_start|>user\n{message}<|im_end|>\n<|im_start|>assistant\n"


def test_expert(expert_id, base_model, adapter_path, questions):
    """Testa un esperto con domande specifiche"""
    print(f"\n{'='*70}")
    print(f"🧪 TEST: {expert_id}")
    print(f"{'='*70}\n")

    try:
        # Carica il modello
        print(f"📦 Caricamento modello...")
        print(f"   Base: {base_model}")
        print(f"   Adapter: {adapter_path if adapter_path else 'None (modello base)'}")

        if adapter_path:
            model, tokenizer = load(base_model, adapter_path=str(adapter_path))
        else:
            model, tokenizer = load(base_model)

        print(f"✅ Modello caricato!\n")

        # Testa ogni domanda
        for i, question in enumerate(questions, 1):
            print(f"❓ Domanda {i}: {question}")
            print(f"{'─'*70}")

            # Formatta prompt
            prompt = format_prompt(question)

            # Genera risposta con parametri controllati
            response = generate(
                model,
                tokenizer,
                prompt=prompt,
                max_tokens=300,  # Limitato per test veloce
                verbose=False
            )

            # Pulisci risposta
            response = response.replace("<|im_end|>", "").strip()

            print(f"🤖 Risposta:\n{response}")
            print(f"{'─'*70}\n")

        print(f"✅ Test completato per {expert_id}\n")
        return True

    except Exception as e:
        print(f"❌ ERRORE durante test di {expert_id}: {e}\n")
        return False


def main():
    print("="*70)
    print("🧪 TEST COMPLETO DI TUTTI GLI ESPERTI")
    print("="*70)

    # Carica configurazione
    if not CONFIG_FILE.exists():
        print(f"❌ File di configurazione non trovato: {CONFIG_FILE}")
        return

    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        config = json.load(f)

    base_model = config['base_model']
    models = config['models']

    print(f"\n📋 Modello base: {base_model}")
    print(f"📋 Esperti da testare: {len(models)}\n")

    results = {}

    # Testa ogni modello
    for model_info in models:
        model_id = model_info['id']

        # Skip se disabilitato
        if not model_info.get('enabled', True):
            print(f"⏭️  Saltato {model_id} (disabilitato)\n")
            continue

        # Verifica che l'adapter esista (se non è None)
        adapter_path_str = model_info.get('adapter_path')

        if adapter_path_str is None:
            # Modello base senza adapter
            adapter_path = None
        else:
            adapter_path = MODELS_DIR / adapter_path_str
            if not adapter_path.exists():
                print(f"⚠️  Adapter non trovato per {model_id}: {adapter_path}\n")
                results[model_id] = False
                continue

        # Ottieni domande di test
        questions = TEST_QUESTIONS.get(model_id, ["Test generico"])

        # Esegui test
        success = test_expert(model_id, base_model, adapter_path, questions)
        results[model_id] = success

    # Riepilogo
    print("\n" + "="*70)
    print("📊 RIEPILOGO TEST")
    print("="*70 + "\n")

    for model_id, success in results.items():
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} - {model_id}")

    total = len(results)
    passed = sum(1 for s in results.values() if s)

    print(f"\n📈 Risultato: {passed}/{total} test passati")

    if passed == total:
        print("🎉 Tutti i test sono passati!")
    else:
        print("⚠️  Alcuni test sono falliti, controlla i log sopra")


if __name__ == "__main__":
    main()
