# Guida Rapida Jarvis MLX

Operazioni quotidiane per gestire gli esperti AI.

---

## 1. Modificare un Dataset

```bash
# Modifica il file JSON
nano data/cooking_expert/my_data.json

# Converti in JSONL
python3 scripts/convert_to_jsonl.py data/cooking_expert/my_data.json
```

**Consigli dataset:**
- 20-30 esempi = ottimale
- Aggiungi domande generiche (es: "Cosa sai fare?", "Sei un esperto?")
- Varia le formulazioni della stessa domanda

---

## 2. Ri-trainare un Esperto

```bash
# Metodo 1: Script automatico
./scripts/update_expert.sh cooking

# Metodo 2: Manuale
cd /Users/adrianocostanzo/ml-projects/fine-tuning
python3 -m mlx_lm.lora --config models/cooking_expert/adapter_config.json

# Monitorare il progresso (in altra finestra terminale)
./scripts/monitor_training.sh cooking
```

**Tempo:** ~20-30 minuti per 300 iterazioni

---

## 3. Testare un Esperto

```bash
# Test singolo esperto (veloce)
./scripts/test_expert.sh cooking

# Test tutti gli esperti (lento ~10 min)
python3 scripts/test_all_experts.py
```

**Cosa verificare:**
- Risposte corrette sulle domande del dataset
- Risposte sensate su domande generiche
- Nessun loop infinito o errori

---

## 4. Avviare la Webapp

```bash
cd webapp
./jarvis_server.sh start   # Avvia
./jarvis_server.sh stop    # Ferma
./jarvis_server.sh status  # Controlla stato
```

**URL:** http://localhost:8080

**Login:** Solo se accedi da remoto (da localhost NO password)

---

## 5. Creare un Nuovo Esperto

```bash
./scripts/create_expert.sh music

# Poi modifica:
# - data/music_expert/my_data.json (aggiungi esempi)
# - models/models_config.json (abilita l'esperto)
```

---

## 6. Workflow Completo (esempio: migliorare cooking)

```bash
# 1. Modifica dataset
nano data/cooking_expert/my_data.json

# 2. Converti
python3 scripts/convert_to_jsonl.py data/cooking_expert/my_data.json

# 3. Re-training (in background)
./scripts/update_expert.sh cooking &

# 4. Monitora (opzionale)
./scripts/monitor_training.sh cooking

# 5. Test
./scripts/test_expert.sh cooking

# 6. Se OK, riavvia webapp
cd webapp
./jarvis_server.sh restart
```

---

## Parametri Training Ottimali

File: `models/EXPERT_expert/adapter_config.json`

```json
{
  "batch_size": 1,
  "iters": 300,
  "max_seq_length": 1536,
  "grad_accumulation_steps": 2,
  "lora_parameters": {
    "rank": 8,
    "dropout": 0.05,
    "scale": 20.0
  },
  "learning_rate": 0.0001,
  "seed": 42
}
```

**Modificare solo se:**
- Dataset molto grande (>50 esempi) → `iters: 500`
- OOM error → `max_seq_length: 1024`

---

## Troubleshooting

### OOM durante training
```bash
# Riduci max_seq_length in adapter_config.json
"max_seq_length": 1024  # invece di 1536
```

### Modello risponde male
- Dataset troppo piccolo → aggiungi più esempi
- Dataset troppo specifico → aggiungi domande generiche
- Troppi training → riduci `iters` a 150

### Webapp non si avvia
```bash
# Controlla errori
cd webapp
tail -f jarvis.log

# Ferma tutto e riavvia
./jarvis_server.sh stop
sleep 5
./jarvis_server.sh start
```

---

## File Importanti

```
fine-tuning/
├── data/EXPERT_expert/
│   ├── my_data.json        ← Modifica questo
│   ├── train.jsonl         ← Generato automaticamente
│   └── valid.jsonl         ← Generato automaticamente
│
├── models/EXPERT_expert/
│   ├── adapter_config.json ← Parametri training
│   └── adapters.safetensors ← Modello trainato
│
├── scripts/
│   ├── update_expert.sh    ← Re-training veloce
│   ├── test_expert.sh      ← Test singolo
│   └── monitor_training.sh ← Monitor progresso
│
└── webapp/
    └── jarvis_server.sh    ← Start/stop webapp
```

---

**Fatto!** Queste sono le operazioni che userai il 90% delle volte.
