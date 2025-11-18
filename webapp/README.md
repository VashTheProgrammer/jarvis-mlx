# 🌐 Jarvis MLX - Web Chat Interface

Interfaccia web moderna per chattare con i tuoi modelli MLX fine-tuned!

## 🎯 Caratteristiche

- ✅ **Interfaccia stile ChatGPT** - UI moderna e responsive
- ✅ **Multi-modello** - Seleziona tra diversi esperti (programmazione, astrologia, biologia, ecc.)
- ✅ **Rete locale** - Accessibile da qualsiasi dispositivo su WiFi
- ✅ **Cronologia conversazione** - Mantiene il contesto della chat
- ✅ **Dark mode** - Design moderno e professionale
- ✅ **Auto-detection modelli** - Carica automaticamente i modelli disponibili

## 🚀 Avvio Rapido

### 1. Installa dipendenze (prima volta)

```bash
cd webapp
pip install -r requirements.txt
```

### 2. Avvia il server

```bash
./start_server.sh
```

Il server si avvierà su `http://localhost:5000`

### 3. Accedi dalla rete locale

Da qualsiasi dispositivo sulla stessa rete WiFi:
```
http://<ip-del-mac>:5000
```

L'IP viene mostrato all'avvio del server.

## 📱 Come Usare

1. **Seleziona un modello** dalla barra laterale
2. **Scrivi un messaggio** nella chat
3. **Premi Invio** o clicca "Invia"
4. Il modello risponderà in tempo reale!

### Scorciatoie
- `Enter` - Invia messaggio
- `Shift+Enter` - Nuova riga

## 🎓 Gestione Modelli

### Configurazione Modelli

I modelli sono configurati in `models/models_config.json`:

```json
{
  "base_model": "mlx-community/Qwen2.5-7B-Instruct-4bit",
  "models": [
    {
      "id": "programming",
      "name": "Esperto Programmazione",
      "description": "Specializzato in coding",
      "icon": "💻",
      "adapter_path": "programming_expert",
      "enabled": true
    }
  ]
}
```

### Creare un Nuovo Esperto

Usa lo script helper:

```bash
cd scripts
./create_expert.sh programming_expert 1000
```

Questo:
1. Crea la directory del dataset
2. Genera un template JSON
3. (Tu modifichi il dataset)
4. Converte il dataset
5. Fa il training
6. Testa il modello

### Abilitare un Modello

1. Apri `models/models_config.json`
2. Trova il tuo modello
3. Imposta `"enabled": true`
4. Riavvia il server

## 🏗️ Struttura

```
webapp/
├── app.py                 # Backend Flask
├── start_server.sh        # Script di avvio
├── requirements.txt       # Dipendenze Python
├── templates/
│   └── index.html        # Frontend HTML/CSS/JS
└── static/               # File statici (vuota per ora)

models/
├── models_config.json    # Configurazione modelli
├── test_model/           # Modello di test
├── qwen_7b_tuned/       # Modello principale
└── [altri esperti]/     # I tuoi modelli custom
```

## 🔧 API Endpoints

Il backend espone diverse API REST:

### GET /api/models
Restituisce tutti i modelli disponibili

**Risposta:**
```json
{
  "models": [...],
  "current": "model_id"
}
```

### POST /api/model/select
Seleziona un modello

**Body:**
```json
{
  "model_id": "programming"
}
```

### POST /api/chat
Invia un messaggio e ricevi risposta

**Body:**
```json
{
  "message": "Come si fa un loop in Python?",
  "model_id": "programming",
  "history": [],
  "max_tokens": 500,
  "temperature": 0.7
}
```

**Risposta:**
```json
{
  "response": "In Python puoi usare...",
  "model": "Esperto Programmazione"
}
```

### GET /api/health
Health check del server

## 🎨 Personalizzazione

### Cambiare Porta

Modifica `app.py`, linea finale:
```python
app.run(host='0.0.0.0', port=5000)  # Cambia 5000
```

### Modificare UI

Il frontend è in `templates/index.html` - tutto in un file!
- CSS: Nel tag `<style>`
- JS: Nel tag `<script>`
- HTML: Nel `<body>`

### Aggiungere Funzionalità

Il backend Flask è facilmente estendibile:
- Aggiungi endpoint in `app.py`
- Modifica la logica di generazione
- Aggiungi filtri o post-processing

## 💡 Tips

### Performance
- Il primo caricamento del modello è lento (~10-30s)
- I modelli successivi sono in cache
- Ogni modello usa ~6GB RAM

### Multi-utente
- Il server supporta più utenti contemporaneamente
- Ogni utente ha la sua sessione indipendente
- La memoria del modello è condivisa

### Debugging
- Controlla la console del server per log
- Il browser mostra errori nella console (F12)
- Usa `debug=True` in `app.run()` per development

## 🐛 Troubleshooting

### Port già in uso
```bash
# Trova il processo
lsof -i :5000
# Killalo
kill -9 <PID>
```

### Modello non si carica
- Verifica che `adapter_path` esista in `models/`
- Controlla che `enabled: true` in config
- Guarda i log del server per errori

### Errore 500
- Controlla che mlx-lm sia installato
- Verifica che il modello base sia disponibile
- Controlla la RAM disponibile (serve 6GB+)

## 📊 Esempi di Utilizzo

### Chat Programmazione
```
User: Come si fa una funzione ricorsiva?
AI: Una funzione ricorsiva è una funzione che chiama se stessa...
```

### Chat Astrologia
```
User: Dimmi l'oroscopo del Leone
AI: Il Leone è un segno di fuoco, governato dal Sole...
```

### Chat Biologia
```
User: Spiega la fotosintesi
AI: La fotosintesi è il processo attraverso cui le piante...
```

## 🚀 Deploy in Produzione

### Usa Gunicorn (più stabile)
```bash
pip install gunicorn
gunicorn -w 2 -b 0.0.0.0:5000 app:app
```

### Con HTTPS (opzionale)
```bash
# Genera certificato self-signed
openssl req -x509 -newkey rsa:4096 -nodes \
  -out cert.pem -keyout key.pem -days 365

# Avvia con SSL
gunicorn -w 2 -b 0.0.0.0:5000 \
  --certfile=cert.pem --keyfile=key.pem \
  app:app
```

## 📝 TODO Future Features

- [ ] Streaming delle risposte (token-by-token)
- [ ] Salvataggio conversazioni
- [ ] Export chat in PDF/MD
- [ ] Autenticazione utenti
- [ ] Statistiche utilizzo modelli
- [ ] Upload dataset via web
- [ ] Training via web interface

---

**Fatto con ❤️ usando Flask + MLX**
