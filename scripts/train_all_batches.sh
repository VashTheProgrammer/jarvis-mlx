#!/bin/bash

# Script per trainare tutti i batch automaticamente
# Ogni batch ha 30 esempi, training incrementale sul batch precedente

set -e

DATASET_FILE="data/physophia_expert/my_data_small.json"
BATCH_SIZE=30
CONFIG_FILE="models/physophia_expert/adapter_config.json"
ADAPTER_FILE="models/physophia_expert/adapters.safetensors"
LOG_DIR="models/physophia_expert"

# Calcola il numero totale di batch
TOTAL_EXAMPLES=$(python3 -c "import json; print(len(json.load(open('$DATASET_FILE'))))")
TOTAL_BATCHES=$((($TOTAL_EXAMPLES + $BATCH_SIZE - 1) / $BATCH_SIZE))

echo "📦 Dataset: $TOTAL_EXAMPLES esempi"
echo "🔢 Batch size: $BATCH_SIZE"
echo "📊 Total batches: $TOTAL_BATCHES"
echo ""

# Partendo dal batch 3 (già fatti batch 1 e 2)
START_BATCH=3

for ((batch=$START_BATCH; batch<=$TOTAL_BATCHES; batch++)); do
    echo "========================================"
    echo "🚀 BATCH $batch/$TOTAL_BATCHES"
    echo "========================================"

    # Calcola gli indici
    start_idx=$(( ($batch - 1) * $BATCH_SIZE ))

    # Crea il batch corrente
    echo "📝 Creando batch $batch (esempi $start_idx-$(($start_idx + $BATCH_SIZE - 1)))..."
    python3 << EOF
import json
from pathlib import Path

# Carica dataset
with open("$DATASET_FILE", 'r', encoding='utf-8') as f:
    data = json.load(f)

# Estrai batch corrente
start = $start_idx
batch_data = data[start:start + $BATCH_SIZE]

print(f"   Batch $batch: {len(batch_data)} esempi")

# Split train/valid (90/10)
split_idx = int(len(batch_data) * 0.9)
train_data = batch_data[:split_idx]
valid_data = batch_data[split_idx:]

print(f"   Train: {len(train_data)}, Valid: {len(valid_data)}")

# Salva in JSONL
output_dir = Path("data/physophia_expert")

with open(output_dir / "train.jsonl", 'w', encoding='utf-8') as f:
    for ex in train_data:
        entry = {
            "messages": [
                {"role": "user", "content": ex["user"]},
                {"role": "assistant", "content": ex["assistant"]}
            ]
        }
        f.write(json.dumps(entry, ensure_ascii=False) + '\n')

with open(output_dir / "valid.jsonl", 'w', encoding='utf-8') as f:
    for ex in valid_data:
        entry = {
            "messages": [
                {"role": "user", "content": ex["user"]},
                {"role": "assistant", "content": ex["assistant"]}
            ]
        }
        f.write(json.dumps(entry, ensure_ascii=False) + '\n')
EOF

    # Training
    echo "🔄 Training batch $batch..."
    python3 -m mlx_lm.lora \
        --config "$CONFIG_FILE" \
        --resume-adapter-file "$ADAPTER_FILE" \
        2>&1 | tee "$LOG_DIR/batch${batch}_training.log"

    # Verifica successo
    if [ $? -eq 0 ]; then
        echo "✅ Batch $batch completato!"
        echo "   Progress: $batch/$TOTAL_BATCHES ($(( $batch * 100 / $TOTAL_BATCHES ))%)"
    else
        echo "❌ Errore nel batch $batch!"
        exit 1
    fi

    echo ""
done

echo "========================================"
echo "🎉 TRAINING COMPLETATO!"
echo "========================================"
echo "Tutti i $TOTAL_BATCHES batch sono stati trainati con successo!"
echo "Adapter finale salvato in: $ADAPTER_FILE"
