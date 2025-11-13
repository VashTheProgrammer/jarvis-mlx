# Jarvis MLX 🤖

Fine-tuning semplicissimo di LLM su Apple Silicon (M1/M2/M3/M4)

[![MLX](https://img.shields.io/badge/MLX-Apple%20Silicon-orange)](https://github.com/ml-explore/mlx)
[![Python](https://img.shields.io/badge/Python-3.9+-blue)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

Sistema ultra-semplificato per fare fine-tuning di Large Language Models usando **MLX** su Mac con Apple Silicon.

## 🔧 Setup Iniziale (Prima Volta)

```bash
# Attiva ambiente conda
conda activate ml-tuning

# Verifica installazione
cd scripts
python test_setup.py
```

Se mancano dipendenze:
```bash
pip install -r scripts/requirements.txt
```

## 🎯 3 Passi per il Fine-Tuning

### 1️⃣ Crea il Dataset (SUPER SEMPLICE)

Apri `data/my_data.json` e scrivi domande e risposte:

```json
[
  {
    "domanda": "La tua domanda qui",
    "risposta": "La risposta che vuoi insegnare al modello"
  },
  {
    "domanda": "Un'altra domanda",
    "risposta": "Un'altra risposta"
  }
]
```

**È TUTTO QUI!** Non serve altro formato complicato.

### 2️⃣ Converti il Dataset

```bash
conda activate ml-tuning
cd scripts
python convert_dataset.py ../data/my_data.json
```

Questo crea automaticamente `train.jsonl` e `valid.jsonl` nel formato corretto.

### 3️⃣ Avvia il Training

**Modello PICCOLO (veloce, test):**
```bash
python -m mlx_lm lora \
  --model mlx-community/Qwen2.5-0.5B-Instruct-4bit \
  --train \
  --data ../data \
  --adapter-path ../models/my_model \
  --iters 500 \
  --batch-size 2 \
  --learning-rate 1e-4
```

**Modello MEDIO (più potente):**
```bash
python -m mlx_lm lora \
  --model mlx-community/Qwen2.5-1.5B-Instruct-4bit \
  --train \
  --data ../data \
  --adapter-path ../models/my_model \
  --iters 1000 \
  --batch-size 2 \
  --learning-rate 1e-4
```

**Modello GRANDE (massima qualità, richiede 16GB RAM):**
```bash
python -m mlx_lm lora \
  --model mlx-community/Qwen2.5-3B-Instruct-4bit \
  --train \
  --data ../data \
  --adapter-path ../models/my_model \
  --iters 1000 \
  --batch-size 2 \
  --learning-rate 1e-4
```

## 🧪 Testa il Modello

**Singola domanda:**
```bash
python -m mlx_lm generate \
  --model mlx-community/Qwen2.5-0.5B-Instruct-4bit \
  --adapter-path ../models/my_model \
  --prompt "La tua domanda"
```

**Chat interattiva:**
```bash
python -m mlx_lm chat \
  --model mlx-community/Qwen2.5-0.5B-Instruct-4bit \
  --adapter-path ../models/my_model
```

## 📝 Template Dataset

Ecco alcuni template pronti da copiare:

### Q&A Semplice
```json
[
  {"domanda": "Cos'è X?", "risposta": "X è..."},
  {"domanda": "Come si fa Y?", "risposta": "Per fare Y..."}
]
```

### Programmazione
```json
[
  {
    "domanda": "Come creare una funzione?",
    "risposta": "def my_function():\n    return 'Hello'"
  }
]
```

### Traduzioni
```json
[
  {"domanda": "Traduci: Ciao", "risposta": "Hello"},
  {"domanda": "Traduci: Grazie", "risposta": "Thank you"}
]
```

### Istruzioni
```json
[
  {
    "domanda": "Scrivi una email formale per richiedere informazioni",
    "risposta": "Gentile [Nome],\n\nLe scrivo per richiedere..."
  }
]
```

## ⚙️ Parametri Importanti

| Parametro | Cosa fa | Consigliato |
|-----------|---------|-------------|
| `--iters` | Quanto allena | 500-1000 |
| `--batch-size` | Velocità vs RAM | 1-2 |
| `--learning-rate` | Velocità apprendimento | 1e-4 |
| `--model` | Modello da usare | Vedi sotto |

## 🎯 Modelli Consigliati

### Per iniziare (8GB RAM)
```
mlx-community/Qwen2.5-0.5B-Instruct-4bit
```
- RAM: ~1GB, velocissimo (~6 it/sec)

### Uso generale (8-16GB RAM)
```
mlx-community/Qwen2.5-1.5B-Instruct-4bit  # Raccomandato
```
- RAM: ~2GB, bilanciato (~1.6 it/sec)

### Qualità superiore (16GB RAM)
```
mlx-community/Qwen2.5-3B-Instruct-4bit
```
- RAM: ~4GB, molto potente (~0.8 it/sec)

### Massima qualità (16GB RAM)
```
mlx-community/Qwen2.5-7B-Instruct-4bit
```
- RAM: ~6GB, top-tier (~0.7 it/sec)

### Modelli avanzati (32GB+ RAM)

**Ancora più potenti:**
```bash
# 14B - Massima qualità per 32GB
mlx-community/Qwen2.5-14B-Instruct-4bit

# Llama alternative
mlx-community/Llama-3.1-8B-Instruct-4bit
```

**Specializzati:**
```bash
# Codice (programmazione)
mlx-community/DeepSeek-Coder-7B-Instruct-4bit
mlx-community/CodeLlama-13B-Instruct-4bit

# Multilingue (italiano++)
mlx-community/aya-23-8B-4bit
```

**Trovane altri:** https://huggingface.co/mlx-community

## 💡 Tips

1. **Inizia piccolo**: 10-20 esempi bastano per testare
2. **Qualità > Quantità**: Meglio 50 esempi buoni che 500 mediocri
3. **Monitora il loss**: Deve scendere (es. da 3.0 a < 0.1)
4. **Tempo di training**:
   - 0.5B: ~1-2 minuti per 100 iter
   - 1.5B: ~2-4 minuti per 100 iter
   - 3B: ~5-10 minuti per 100 iter

## 🚀 Workflow Completo

```bash
# 1. Attiva ambiente
conda activate ml-tuning
cd scripts

# 2. Modifica dataset
nano ../data/my_data.json  # o usa VS Code, qualsiasi editor

# 3. Converti
python convert_dataset.py ../data/my_data.json

# 4. Allena (modello 1.5B consigliato)
python -m mlx_lm lora \
  --model mlx-community/Qwen2.5-1.5B-Instruct-4bit \
  --train \
  --data ../data \
  --adapter-path ../models/my_model \
  --iters 1000 \
  --batch-size 2

# 5. Testa
python -m mlx_lm chat \
  --model mlx-community/Qwen2.5-1.5B-Instruct-4bit \
  --adapter-path ../models/my_model
```

## ❓ FAQ

**Q: Quanti esempi servono?**
A: Minimo 10-20, ideale 50-200.

**Q: Quanto tempo ci vuole?**
A: 1000 iterazioni su 1.5B = ~20-30 minuti.

**Q: Out of memory?**
A: Usa `--batch-size 1` o modello più piccolo.

**Q: Il modello non impara?**
A: Aumenta `--iters` a 1500-2000 o `--learning-rate` a 5e-4.

**Q: Posso usare formato inglese?**
A: Sì! Usa `"question"` e `"answer"` invece di `"domanda"` e `"risposta"`.

## 📁 Struttura Progetto

```
fine-tuning/
├── README.md                    # Questa guida
├── data/
│   ├── my_data.json            # Il tuo dataset (modifica questo!)
│   ├── train.jsonl             # Generato automaticamente
│   └── valid.jsonl             # Generato automaticamente
├── models/                      # Adapter LoRA salvati qui
│   └── my_model/
│       └── adapters.safetensors
└── scripts/
    ├── requirements.txt         # Dipendenze
    ├── test_setup.py           # Test installazione
    └── convert_dataset.py      # Conversione dataset
```

---

**Tutto qui!** Semplice, no? 🚀
