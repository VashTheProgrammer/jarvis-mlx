#!/bin/bash
# Test rapido di un singolo esperto

EXPERT=$1

if [ -z "$EXPERT" ]; then
    echo "Uso: ./scripts/test_expert.sh <expert_name>"
    echo "Esempi: ./scripts/test_expert.sh cooking"
    echo "        ./scripts/test_expert.sh astrology"
    exit 1
fi

cd /Users/adrianocostanzo/ml-projects/fine-tuning

python3 << EOF
from mlx_lm import load, generate
from pathlib import Path

expert = "$EXPERT"
base_model = "mlx-community/Qwen2.5-7B-Instruct-4bit"
adapter_path = f"models/{expert}_expert"

# Domande di test per esperto
test_questions = {
    "cooking": [
        "Come si fa la carbonara?",
        "Dammi una ricetta veloce"
    ],
    "astrology": [
        "Caratteristiche dell'Ariete?",
        "Cosa significa Venere in Toro?"
    ],
    "history": [
        "Chi era Giulio Cesare?",
        "Quando iniziò la WWII?"
    ],
    "biology": [
        "Cos'è la fotosintesi?",
        "Come funziona il DNA?"
    ],
    "programming": [
        "Come si crea una funzione Python?",
        "Cos'è un ciclo for?"
    ]
}

print(f"🧪 TEST: {expert}")
print("=" * 60)
print()

if expert not in test_questions:
    print(f"⚠️  Nessuna domanda test per {expert}")
    print("Aggiungi domande nello script!")
    exit(1)

# Carica modello
print("📦 Caricamento modello...")
model, tokenizer = load(base_model, adapter_path=adapter_path)
print("✅ Modello caricato!")
print()

# Test domande
for i, question in enumerate(test_questions[expert], 1):
    print(f"❓ Domanda {i}: {question}")
    print("-" * 60)

    prompt = f"<|im_start|>user\\n{question}<|im_end|>\\n<|im_start|>assistant\\n"
    response = generate(model, tokenizer, prompt=prompt, max_tokens=300, verbose=False)

    print(f"🤖 Risposta:\\n{response}")
    print("-" * 60)
    print()

print("✅ Test completato!")
EOF
