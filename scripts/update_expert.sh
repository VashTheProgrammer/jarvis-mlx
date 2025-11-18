#!/bin/bash
# Script per aggiornare/ri-trainare un singolo esperto

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}❌ Errore: specifica quale esperto aggiornare${NC}"
    echo ""
    echo -e "${YELLOW}Uso: ./update_expert.sh <nome_esperto> [iterazioni]${NC}"
    echo ""
    echo "Esperti disponibili:"
    echo "  - programming_expert"
    echo "  - astrology_expert"
    echo "  - biology_expert"
    echo "  - history_expert"
    echo "  - cooking_expert"
    echo ""
    echo "Esempio:"
    echo "  ./update_expert.sh programming_expert 500"
    echo ""
    exit 1
fi

EXPERT=$1
ITERS=${2:-150}
MODEL="mlx-community/Qwen2.5-7B-Instruct-4bit"

EXPERT_DATA="../data/${EXPERT}"
EXPERT_MODEL="../models/${EXPERT}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔄 AGGIORNAMENTO ESPERTO${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}📋 Configurazione:${NC}"
echo -e "   Esperto:       ${EXPERT}"
echo -e "   Iterazioni:    ${ITERS}"
echo -e "   Dataset:       ${EXPERT_DATA}/my_data.json"
echo -e "   Modello:       ${EXPERT_MODEL}"
echo ""

# Verifica dataset esiste
if [ ! -f "${EXPERT_DATA}/my_data.json" ]; then
    echo -e "${RED}❌ Dataset non trovato: ${EXPERT_DATA}/my_data.json${NC}"
    exit 1
fi

echo -e "${YELLOW}📝 Hai modificato il dataset ${EXPERT_DATA}/my_data.json?${NC}"
echo -e "${YELLOW}Premi INVIO per continuare o CTRL+C per annullare...${NC}"
read

START=$(date +%s)

# Backup del modello esistente (se esiste)
if [ -d "$EXPERT_MODEL" ]; then
    BACKUP="${EXPERT_MODEL}_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}💾 Backup modello esistente → ${BACKUP}${NC}"
    mv "$EXPERT_MODEL" "$BACKUP"
fi

# Conversione dataset
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔄 Conversione Dataset${NC}"
echo -e "${BLUE}========================================${NC}"
python convert_dataset.py "${EXPERT_DATA}/my_data.json" --output-dir "$EXPERT_DATA"

# Training
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Training Modello${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}⏱️  Questo richiederà circa $(($ITERS / 25)) minuti...${NC}"
echo ""

python -m mlx_lm.lora \
  --model "$MODEL" \
  --train \
  --data "$EXPERT_DATA" \
  --adapter-path "$EXPERT_MODEL" \
  --iters "$ITERS" \
  --batch-size 2 \
  --learning-rate 1e-4 \
  --save-every 50

END=$(date +%s)
DURATION=$((END - START))
MIN=$((DURATION / 60))
SEC=$((DURATION % 60))

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}✅ AGGIORNAMENTO COMPLETATO!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}⏱️  Tempo: ${MIN}m ${SEC}s${NC}"
echo ""
echo -e "${GREEN}📁 Modello aggiornato: ${EXPERT_MODEL}${NC}"
echo ""
echo -e "${YELLOW}💡 Il modello aggiornato sarà automaticamente disponibile nella webapp!${NC}"
echo -e "${YELLOW}   Riavvia il server webapp se era già in esecuzione.${NC}"
echo ""

# Test rapido
echo -e "${YELLOW}🧪 Vuoi testare il modello? (y/n)${NC}"
read -r RESPONSE
if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Inserisci una domanda di test:${NC}"
    read TEST_QUESTION

    if [ ! -z "$TEST_QUESTION" ]; then
        echo ""
        echo -e "${GREEN}Risposta del modello:${NC}"
        python -m mlx_lm.generate \
          --model "$MODEL" \
          --adapter-path "$EXPERT_MODEL" \
          --prompt "$TEST_QUESTION" \
          --max-tokens 200 \
          --temp 0.7
    fi
fi

echo ""
echo -e "${GREEN}✅ Fatto!${NC}"
echo ""
