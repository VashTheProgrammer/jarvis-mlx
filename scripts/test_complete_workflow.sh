#!/bin/bash
# Script di test completo del workflow di fine-tuning
# Esegue tutte le fasi e misura i tempi

set -e  # Esce in caso di errore

# Colori per output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configurazione
MODEL="mlx-community/Qwen2.5-7B-Instruct-4bit"
TEST_DATA_DIR="../data/test"
TEST_MODEL_DIR="../models/test_model"
ITERS=100  # Poche iterazioni per test veloce

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🧪 TEST COMPLETO WORKFLOW FINE-TUNING${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Modello: ${MODEL}${NC}"
echo -e "${YELLOW}Iterazioni: ${ITERS}${NC}"
echo ""

# Cleanup precedente
echo -e "${GREEN}🧹 Pulizia file precedenti...${NC}"
rm -rf "$TEST_DATA_DIR"
rm -rf "$TEST_MODEL_DIR"
mkdir -p "$TEST_DATA_DIR"
echo ""

# FASE 1: Creazione dataset di test
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📝 FASE 1: Creazione dataset di test${NC}"
echo -e "${BLUE}========================================${NC}"
START_DATASET=$(date +%s)

cat > "$TEST_DATA_DIR/test_data.json" << 'EOF'
[
  {
    "domanda": "Qual è la capitale dell'Italia?",
    "risposta": "La capitale dell'Italia è Roma, una città ricca di storia e cultura."
  },
  {
    "domanda": "Chi ha inventato il telefono?",
    "risposta": "Il telefono è stato inventato da Alexander Graham Bell nel 1876."
  },
  {
    "domanda": "Quanto fa 7 x 8?",
    "risposta": "7 x 8 fa 56."
  },
  {
    "domanda": "Qual è il pianeta più grande del sistema solare?",
    "risposta": "Il pianeta più grande del sistema solare è Giove."
  },
  {
    "domanda": "Come si dice 'ciao' in inglese?",
    "risposta": "In inglese 'ciao' si dice 'hello' o 'hi'."
  },
  {
    "domanda": "Qual è la formula dell'acqua?",
    "risposta": "La formula dell'acqua è H2O, composta da due atomi di idrogeno e uno di ossigeno."
  },
  {
    "domanda": "Chi ha scritto la Divina Commedia?",
    "risposta": "La Divina Commedia è stata scritta da Dante Alighieri."
  },
  {
    "domanda": "Quanti continenti ci sono?",
    "risposta": "Ci sono 7 continenti: Africa, Antartide, Asia, Europa, Nord America, Oceania e Sud America."
  }
]
EOF

END_DATASET=$(date +%s)
TIME_DATASET=$((END_DATASET - START_DATASET))
echo -e "${GREEN}✅ Dataset creato in ${TIME_DATASET}s${NC}"
echo -e "   File: $TEST_DATA_DIR/test_data.json"
echo -e "   Esempi: 8"
echo ""

# FASE 2: Conversione dataset
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔄 FASE 2: Conversione dataset${NC}"
echo -e "${BLUE}========================================${NC}"
START_CONVERT=$(date +%s)

python convert_dataset.py "$TEST_DATA_DIR/test_data.json" --output-dir "$TEST_DATA_DIR"

END_CONVERT=$(date +%s)
TIME_CONVERT=$((END_CONVERT - START_CONVERT))
echo -e "${GREEN}✅ Conversione completata in ${TIME_CONVERT}s${NC}"
echo ""

# FASE 3: Training
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 FASE 3: Training del modello${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}⏱️  Questa fase richiederà alcuni minuti...${NC}"
START_TRAIN=$(date +%s)

python -m mlx_lm.lora \
  --model "$MODEL" \
  --train \
  --data "$TEST_DATA_DIR" \
  --adapter-path "$TEST_MODEL_DIR" \
  --iters "$ITERS" \
  --batch-size 2 \
  --learning-rate 1e-4 \
  --save-every 50

END_TRAIN=$(date +%s)
TIME_TRAIN=$((END_TRAIN - START_TRAIN))
TIME_TRAIN_MIN=$((TIME_TRAIN / 60))
TIME_TRAIN_SEC=$((TIME_TRAIN % 60))
echo ""
echo -e "${GREEN}✅ Training completato in ${TIME_TRAIN_MIN}m ${TIME_TRAIN_SEC}s${NC}"
echo ""

# FASE 4: Test del modello
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🧪 FASE 4: Test del modello trainato${NC}"
echo -e "${BLUE}========================================${NC}"
START_TEST=$(date +%s)

# Test domanda 1
echo -e "${YELLOW}Domanda 1: Qual è la capitale dell'Italia?${NC}"
python -m mlx_lm.generate \
  --model "$MODEL" \
  --adapter-path "$TEST_MODEL_DIR" \
  --prompt "Qual è la capitale dell'Italia?" \
  --max-tokens 100 \
  --temp 0.1

echo ""
echo -e "${YELLOW}Domanda 2: Chi ha inventato il telefono?${NC}"
python -m mlx_lm.generate \
  --model "$MODEL" \
  --adapter-path "$TEST_MODEL_DIR" \
  --prompt "Chi ha inventato il telefono?" \
  --max-tokens 100 \
  --temp 0.1

END_TEST=$(date +%s)
TIME_TEST=$((END_TEST - START_TEST))
echo ""
echo -e "${GREEN}✅ Test completato in ${TIME_TEST}s${NC}"
echo ""

# RIEPILOGO FINALE
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📊 RIEPILOGO TEMPI${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "📝 Creazione dataset:    ${TIME_DATASET}s"
echo -e "🔄 Conversione:          ${TIME_CONVERT}s"
echo -e "🚀 Training ($ITERS iter): ${TIME_TRAIN_MIN}m ${TIME_TRAIN_SEC}s"
echo -e "🧪 Test modello:         ${TIME_TEST}s"
echo ""
TOTAL_TIME=$((TIME_DATASET + TIME_CONVERT + TIME_TRAIN + TIME_TEST))
TOTAL_MIN=$((TOTAL_TIME / 60))
TOTAL_SEC=$((TOTAL_TIME % 60))
echo -e "${GREEN}⏱️  TEMPO TOTALE: ${TOTAL_MIN}m ${TOTAL_SEC}s${NC}"
echo ""

# Info sui file generati
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📁 FILE GENERATI${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Dataset:"
echo -e "  - $TEST_DATA_DIR/test_data.json"
echo -e "  - $TEST_DATA_DIR/train.jsonl"
echo -e "  - $TEST_DATA_DIR/valid.jsonl"
echo ""
echo -e "Modello:"
ls -lh "$TEST_MODEL_DIR/" | awk '{if(NR>1) print "  - " $9 " (" $5 ")"}'
echo ""

echo -e "${GREEN}✅ Test workflow completato con successo!${NC}"
echo ""
echo -e "${YELLOW}💡 Per fare una chat interattiva:${NC}"
echo -e "   python -m mlx_lm.chat --model $MODEL --adapter-path $TEST_MODEL_DIR"
echo ""
