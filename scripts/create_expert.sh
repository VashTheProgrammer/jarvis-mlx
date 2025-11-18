#!/bin/bash
# Script per creare un nuovo modello esperto

set -e

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🎓 Creazione Nuovo Modello Esperto${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Input parametri
if [ -z "$1" ]; then
    echo -e "${YELLOW}Uso: ./create_expert.sh <nome_esperto> <iterazioni>${NC}"
    echo ""
    echo "Esempi:"
    echo "  ./create_expert.sh programming_expert 1000"
    echo "  ./create_expert.sh astrology_expert 1000"
    echo "  ./create_expert.sh biology_expert 1000"
    echo ""
    exit 1
fi

EXPERT_ID=$1
ITERS=${2:-1000}

EXPERT_DATA="../data/${EXPERT_ID}"
EXPERT_MODEL="../models/${EXPERT_ID}"
MODEL="mlx-community/Qwen2.5-7B-Instruct-4bit"

echo -e "${GREEN}📋 Configurazione:${NC}"
echo -e "   ID Esperto:    ${EXPERT_ID}"
echo -e "   Iterazioni:    ${ITERS}"
echo -e "   Dataset:       ${EXPERT_DATA}"
echo -e "   Modello:       ${EXPERT_MODEL}"
echo ""

# Verifica se esiste già
if [ -d "$EXPERT_DATA" ]; then
    echo -e "${YELLOW}⚠️  La directory del dataset esiste già: ${EXPERT_DATA}${NC}"
    echo -e "${YELLOW}   Controlla il file my_data.json e modificalo se necessario${NC}"
else
    echo -e "${GREEN}📁 Creazione directory dataset...${NC}"
    mkdir -p "$EXPERT_DATA"

    # Crea template dataset
    cat > "$EXPERT_DATA/my_data.json" << 'EOF'
[
  {
    "domanda": "Inserisci qui la prima domanda",
    "risposta": "Inserisci qui la risposta esperta"
  },
  {
    "domanda": "Inserisci qui la seconda domanda",
    "risposta": "Inserisci qui la seconda risposta esperta"
  }
]
EOF
    echo -e "${GREEN}✅ Template dataset creato: ${EXPERT_DATA}/my_data.json${NC}"
    echo ""
    echo -e "${YELLOW}📝 IMPORTANTE: Modifica il file ${EXPERT_DATA}/my_data.json con i tuoi dati!${NC}"
    echo ""
    echo -e "${YELLOW}Premi INVIO quando hai finito di modificare il dataset...${NC}"
    read
fi

# Converti dataset
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔄 Conversione Dataset${NC}"
echo -e "${BLUE}========================================${NC}"
python convert_dataset.py "$EXPERT_DATA/my_data.json" --output-dir "$EXPERT_DATA"
echo ""

# Training
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Training Modello Esperto${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}⏱️  Questo richiederà circa $(($ITERS / 25)) minuti...${NC}"
echo ""

START_TIME=$(date +%s)

python -m mlx_lm.lora \
  --model "$MODEL" \
  --train \
  --data "$EXPERT_DATA" \
  --adapter-path "$EXPERT_MODEL" \
  --iters "$ITERS" \
  --batch-size 2 \
  --learning-rate 1e-4 \
  --save-every 200

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo -e "${GREEN}✅ Training completato in ${MINUTES}m ${SECONDS}s!${NC}"
echo ""

# Test rapido
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🧪 Test Rapido${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Inserisci una domanda di test (lascia vuoto per saltare):${NC}"
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

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}✅ Modello Esperto Creato!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}📁 File generati:${NC}"
echo -e "   Dataset: ${EXPERT_DATA}/"
echo -e "   Modello: ${EXPERT_MODEL}/"
echo ""
echo -e "${YELLOW}💡 Prossimi passi:${NC}"
echo ""
echo -e "1. ${GREEN}Abilita il modello nella webapp:${NC}"
echo -e "   Modifica: ../models/models_config.json"
echo -e "   Cerca il modello '${EXPERT_ID}' e imposta 'enabled: true'"
echo ""
echo -e "2. ${GREEN}Avvia la webapp:${NC}"
echo -e "   cd ../webapp"
echo -e "   ./start_server.sh"
echo ""
echo -e "3. ${GREEN}Test via chat:${NC}"
echo -e "   python -m mlx_lm.chat --model $MODEL --adapter-path $EXPERT_MODEL"
echo ""
