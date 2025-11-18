#!/bin/bash
# Monitor training di qualsiasi esperto

EXPERT=$1

if [ -z "$EXPERT" ]; then
    echo "Uso: ./scripts/monitor_training.sh <expert_name>"
    echo "Esempi: ./scripts/monitor_training.sh cooking"
    echo "        ./scripts/monitor_training.sh astrology"
    exit 1
fi

LOG_FILE="models/${EXPERT}_expert/training.log"

echo "📊 Monitoraggio Training: $EXPERT"
echo "================================"
echo ""

while true; do
    if ps aux | grep -q "[m]lx_lm.lora.*${EXPERT}_expert"; then
        clear
        echo "📊 Monitoraggio Training: $EXPERT"
        echo "================================"
        echo ""
        echo "✅ Training in corso..."
        echo ""

        if [ -f "$LOG_FILE" ]; then
            tail -10 "$LOG_FILE" | grep "Iter"
        fi

        echo ""
        echo "⏱️  Aggiornamento ogni 10 secondi..."
        echo "🛑 Premi CTRL+C per uscire"

        sleep 10
    else
        clear
        echo "📊 Monitoraggio Training: $EXPERT"
        echo "================================"
        echo ""
        echo "✅ Training COMPLETATO!"
        echo ""
        echo "Test con: ./scripts/test_expert.sh $EXPERT"
        break
    fi
done
