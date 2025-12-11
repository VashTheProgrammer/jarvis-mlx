# Jarvis MLX 🤖

Fine-tuning di modelli esperti AI su Apple Silicon

Sistema per creare e gestire modelli AI specializzati usando **MLX** su Mac (M1/M2/M3/M4).

## Guida Rapida

Leggi **[GUIDA_RAPIDA.md](GUIDA_RAPIDA.md)** per workflow quotidiano (modificare dataset, re-training, test, webapp).

---

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

```bash
python -m mlx_lm lora \
  --model mlx-community/Qwen2.5-7B-Instruct-4bit \
  --train \
  --data ../data \
  --adapter-path ../models/my_model \
  --iters 1000 \
  --batch-size 2 \
  --learning-rate 1e-4
```

**Nota:** Il modello 7B richiede almeno 16GB di RAM.

## 🧪 Testa il Modello

**Singola domanda:**
```bash
python -m mlx_lm generate \
  --model mlx-community/Qwen2.5-7B-Instruct-4bit \
  --adapter-path ../models/my_model \
  --prompt "La tua domanda"
```

**Chat interattiva:**
```bash
python -m mlx_lm chat \
  --model mlx-community/Qwen2.5-7B-Instruct-4bit \
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

## 🎯 Modello Utilizzato

```
mlx-community/Qwen2.5-7B-Instruct-4bit
```
- RAM richiesta: ~6-8GB
- Velocità: ~0.7 iterazioni/sec
- Qualità: Eccellente per la maggior parte dei task
- Ideale per: Conversazione, Q&A, coding, traduzioni

## 💡 Tips

1. **Inizia piccolo**: 10-20 esempi bastano per testare
2. **Qualità > Quantità**: Meglio 50 esempi buoni che 500 mediocri
3. **Monitora il loss**: Deve scendere (es. da 3.0 a < 0.1)
4. **Tempo di training**: ~10-15 minuti per 100 iterazioni con il modello 7B

## 🚀 Workflow Completo

```bash
# 1. Attiva ambiente
conda activate ml-tuning
cd scripts

# 2. Modifica dataset
nano ../data/my_data.json  # o usa VS Code, qualsiasi editor

# 3. Converti
python convert_dataset.py ../data/my_data.json

# 4. Allena
python -m mlx_lm lora \
  --model mlx-community/Qwen2.5-7B-Instruct-4bit \
  --train \
  --data ../data \
  --adapter-path ../models/my_model \
  --iters 1000 \
  --batch-size 2

# 5. Testa
python -m mlx_lm chat \
  --model mlx-community/Qwen2.5-7B-Instruct-4bit \
  --adapter-path ../models/my_model
```

## ❓ FAQ

**Q: Quanti esempi servono?**
A: Minimo 10-20, ideale 50-200.

**Q: Quanto tempo ci vuole?**
A: 1000 iterazioni con il 7B = ~2-3 ore (dipende dal Mac).

**Q: Out of memory?**
A: Usa `--batch-size 1` o riduci il numero di iterazioni processate simultaneamente.

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

## 🌐 Web Chat Interface

Chatta con i tuoi modelli tramite interfaccia web!

```bash
cd webapp
./start_server.sh
```

Poi apri il browser su `http://localhost:5000`

### Caratteristiche
- ✅ Interfaccia moderna stile ChatGPT
- ✅ Selezione tra più modelli esperti
- ✅ Accessibile da rete locale (smartphone, tablet, ecc.)
- ✅ Cronologia conversazione
- ✅ Dark mode

Vedi [webapp/README.md](webapp/README.md) per dettagli.

## 🎓 Creare Modelli Esperti

Crea modelli specializzati in diversi argomenti!

```bash
cd scripts
./create_expert.sh programming_expert 1000
```

Lo script:
1. Crea template dataset
2. (Tu modifichi il dataset con le tue Q&A)
3. Converte e fa training automaticamente
4. Testa il modello

Poi abilita il modello in `models/models_config.json` e sarà disponibile nella webapp!

**Esempi di esperti disponibili:**
- 💻 **Programmazione**: Python, coding, best practices
- ⭐ **Astrologia**: Oroscopi, segni zodiacali, carta natale
- 🧬 **Biologia**: Anatomia, scienze naturali
- 📚 **Storia**: Eventi storici, personaggi famosi
- 👨‍🍳 **Cucina**: Ricette italiane, tecniche culinarie
- 📖 **Physophia**: Esperto del mondo fantasy (esempio di training da libro)
- 💼 **Il tuo esperto personalizzato!**

### Training da Libro/Documento

Per trainare su un libro o documento lungo (come Physophia), usa il training incrementale:

```bash
# 1. Crea dataset con chunk piccoli (200 parole max)
python3 scripts/create_small_chunks_dataset.py

# 2. Training automatico in batch
scripts/train_all_batches.sh
```

**Nota**: Il fine-tuning su testi narrativi lunghi ha limiti. Per migliori risultati, considera **RAG (Retrieval-Augmented Generation)** invece del fine-tuning diretto.

---

**Tutto qui!** Semplice, no? 🚀
