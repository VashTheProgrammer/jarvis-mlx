#!/bin/bash
# Script per trainare tutti i modelli esperti in sequenza

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

MODEL="mlx-community/Qwen2.5-7B-Instruct-4bit"
ITERS=150

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🎓 TRAINING TUTTI I MODELLI ESPERTI${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Modello base: ${MODEL}${NC}"
echo -e "${YELLOW}Iterazioni: ${ITERS}${NC}"
echo ""

START_TOTAL=$(date +%s)

# Array di esperti
EXPERTS=("programming" "astrology" "biology" "history" "cooking")
NAMES=("💻 Programmazione" "⭐ Astrologia" "🧬 Biologia" "📚 Storia" "👨‍🍳 Cucina")

for i in "${!EXPERTS[@]}"; do
    EXPERT="${EXPERTS[$i]}_expert"
    NAME="${NAMES[$i]}"

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$(($i + 1))/5 - ${NAME}${NC}"
    echo -e "${BLUE}========================================${NC}"

    START=$(date +%s)

    # Converti dataset
    echo -e "${GREEN}🔄 Conversione dataset...${NC}"
    python convert_dataset.py "../data/${EXPERT}/my_data.json" --output-dir "../data/${EXPERT}"

    # Training
    echo -e "${GREEN}🚀 Training in corso...${NC}"
    python -m mlx_lm.lora \
      --model "$MODEL" \
      --train \
      --data "../data/${EXPERT}" \
      --adapter-path "../models/${EXPERT}" \
      --iters "$ITERS" \
      --batch-size 2 \
      --learning-rate 1e-4 \
      --save-every 50

    END=$(date +%s)
    DURATION=$((END - START))
    MIN=$((DURATION / 60))
    SEC=$((DURATION % 60))

    echo ""
    echo -e "${GREEN}✅ ${NAME} completato in ${MIN}m ${SEC}s${NC}"
    echo ""
done

END_TOTAL=$(date +%s)
DURATION_TOTAL=$((END_TOTAL - START_TOTAL))
MIN_TOTAL=$((DURATION_TOTAL / 60))
SEC_TOTAL=$((DURATION_TOTAL % 60))

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🎉 TUTTI I MODELLI COMPLETATI!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}⏱️  Tempo totale: ${MIN_TOTAL}m ${SEC_TOTAL}s${NC}"
echo ""
echo -e "${YELLOW}📁 Modelli salvati in: ../models/${NC}"
echo ""
echo -e "${YELLOW}💡 Prossimo passo: Abilita i modelli in models/models_config.json${NC}"
echo ""
