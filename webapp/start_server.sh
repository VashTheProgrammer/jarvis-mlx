#!/bin/bash
# Script per avviare il server web Flask

set -e

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Jarvis MLX - Web Chat Server${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verifica dipendenze
echo -e "${YELLOW}📦 Verifica dipendenze...${NC}"

if ! python3 -c "import flask" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Flask non installato. Installazione in corso...${NC}"
    pip install -r requirements.txt
    echo -e "${GREEN}✅ Flask installato!${NC}"
else
    echo -e "${GREEN}✅ Flask già installato${NC}"
fi

echo ""

# Ottieni l'IP locale
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🌐 Server Info${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "📱 ${GREEN}Accedi da:${NC}"
echo -e "   Locale:       ${YELLOW}http://localhost:5000${NC}"
echo -e "   Rete locale:  ${YELLOW}http://${LOCAL_IP}:5000${NC}"
echo ""
echo -e "💡 ${GREEN}Da altri dispositivi sulla stessa rete WiFi:${NC}"
echo -e "   Apri il browser e vai su: ${YELLOW}http://${LOCAL_IP}:5000${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
echo ""

# Avvia il server
echo -e "${GREEN}🚀 Avvio server...${NC}"
echo ""

python3 app.py
