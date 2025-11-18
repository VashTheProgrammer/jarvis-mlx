#!/bin/bash
# Script per gestire il server Jarvis MLX Web Chat
# Uso: ./jarvis_server.sh start|stop|restart|status

set -e

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Directory di lavoro (sempre la directory dove si trova questo script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.server.pid"
LOG_FILE="$SCRIPT_DIR/server.log"
APP_FILE="$SCRIPT_DIR/app.py"

# Funzione per verificare se il server è in esecuzione
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0  # In esecuzione
        else
            # PID file esiste ma processo no, pulisci
            rm -f "$PID_FILE"
            return 1  # Non in esecuzione
        fi
    fi
    return 1  # Non in esecuzione
}

# Funzione per avviare il server
start_server() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🚀 Jarvis MLX - Web Chat Server${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Verifica se già in esecuzione
    if is_running; then
        echo -e "${YELLOW}⚠️  Il server è già in esecuzione (PID: $(cat $PID_FILE))${NC}"
        echo -e "${YELLOW}💡 Usa './jarvis_server.sh stop' per fermarlo${NC}"
        exit 1
    fi

    # Verifica file app.py
    if [ ! -f "$APP_FILE" ]; then
        echo -e "${RED}❌ Errore: file app.py non trovato in $SCRIPT_DIR${NC}"
        exit 1
    fi

    # Verifica dipendenze
    echo -e "${YELLOW}📦 Verifica dipendenze...${NC}"

    if ! python3 -c "import flask" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Flask non installato. Installazione in corso...${NC}"
        pip install -r "$SCRIPT_DIR/requirements.txt"
        echo -e "${GREEN}✅ Flask installato!${NC}"
    else
        echo -e "${GREEN}✅ Dipendenze OK${NC}"
    fi

    echo ""

    # Ottieni l'IP locale
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🌐 Server Info${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "📱 ${GREEN}Accedi da:${NC}"
    echo -e "   Locale:       ${YELLOW}http://localhost:8080${NC}"
    echo -e "   Rete locale:  ${YELLOW}http://${LOCAL_IP}:8080${NC}"
    echo ""
    echo -e "💡 ${GREEN}Da altri dispositivi sulla stessa rete WiFi:${NC}"
    echo -e "   Apri il browser e vai su: ${YELLOW}http://${LOCAL_IP}:8080${NC}"
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Avvia il server in background
    echo -e "${GREEN}🚀 Avvio server in background...${NC}"

    cd "$SCRIPT_DIR"
    nohup python3 app.py > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!

    # Salva il PID
    echo $SERVER_PID > "$PID_FILE"

    # Aspetta un momento per verificare che sia partito
    sleep 2

    if is_running; then
        echo -e "${GREEN}✅ Server avviato con successo! (PID: $SERVER_PID)${NC}"
        echo ""
        echo -e "${YELLOW}📝 Log in tempo reale:${NC}"
        echo -e "   tail -f $LOG_FILE"
        echo ""
        echo -e "${YELLOW}🛑 Per fermare il server:${NC}"
        echo -e "   ./jarvis_server.sh stop"
        echo ""
    else
        echo -e "${RED}❌ Errore durante l'avvio del server${NC}"
        echo -e "${YELLOW}📝 Controlla i log:${NC}"
        tail -20 "$LOG_FILE"
        exit 1
    fi
}

# Funzione per fermare il server
stop_server() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🛑 Arresto Jarvis MLX Server${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    if ! is_running; then
        echo -e "${YELLOW}⚠️  Il server non è in esecuzione${NC}"

        # Cerca eventuali processi orfani
        ORPHAN_PIDS=$(ps aux | grep "[p]ython.*app\.py" | awk '{print $2}')
        if [ -n "$ORPHAN_PIDS" ]; then
            echo -e "${YELLOW}🔍 Trovati processi orfani, li termino...${NC}"
            echo "$ORPHAN_PIDS" | xargs kill -9 2>/dev/null || true
            echo -e "${GREEN}✅ Processi orfani terminati${NC}"
        fi

        exit 0
    fi

    PID=$(cat "$PID_FILE")
    echo -e "${YELLOW}🔄 Terminazione processo $PID...${NC}"

    # Prova prima con SIGTERM (gentile)
    kill "$PID" 2>/dev/null || true

    # Aspetta un po'
    sleep 2

    # Se ancora in esecuzione, usa SIGKILL (forzato)
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Terminazione forzata...${NC}"
        kill -9 "$PID" 2>/dev/null || true
    fi

    # Pulisci il PID file
    rm -f "$PID_FILE"

    # Cerca e termina eventuali processi figli
    CHILD_PIDS=$(ps aux | grep "[p]ython.*app\.py" | awk '{print $2}')
    if [ -n "$CHILD_PIDS" ]; then
        echo -e "${YELLOW}🔄 Terminazione processi figli...${NC}"
        echo "$CHILD_PIDS" | xargs kill -9 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ Server arrestato con successo!${NC}"
    echo ""
}

# Funzione per mostrare lo status
show_status() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}📊 Status Jarvis MLX Server${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    if is_running; then
        PID=$(cat "$PID_FILE")
        echo -e "${GREEN}✅ Server in esecuzione${NC}"
        echo -e "   PID: $PID"
        echo ""
        echo -e "${YELLOW}📊 Informazioni processo:${NC}"
        ps -p "$PID" -o pid,ppid,%cpu,%mem,etime,command 2>/dev/null || echo "Impossibile ottenere info processo"
        echo ""
        echo -e "${YELLOW}📝 Ultimi log (ultimi 10 righe):${NC}"
        if [ -f "$LOG_FILE" ]; then
            tail -10 "$LOG_FILE"
        else
            echo "   Nessun log disponibile"
        fi
    else
        echo -e "${YELLOW}⚠️  Server non in esecuzione${NC}"

        # Controlla processi orfani
        ORPHAN_PIDS=$(ps aux | grep "[p]ython.*app\.py" | awk '{print $2}')
        if [ -n "$ORPHAN_PIDS" ]; then
            echo ""
            echo -e "${RED}⚠️  Attenzione: trovati processi Python potenzialmente orfani:${NC}"
            echo "$ORPHAN_PIDS"
            echo ""
            echo -e "${YELLOW}💡 Usa './jarvis_server.sh stop' per terminarli${NC}"
        fi
    fi
    echo ""
}

# Funzione per restart
restart_server() {
    echo -e "${BLUE}🔄 Riavvio server...${NC}"
    echo ""
    stop_server
    sleep 2
    start_server
}

# Gestione comandi
case "${1:-}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        show_status
        ;;
    *)
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Jarvis MLX Server Manager${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo ""
        echo "Uso: $0 {start|stop|restart|status}"
        echo ""
        echo "Comandi:"
        echo "  start    - Avvia il server in background"
        echo "  stop     - Ferma il server"
        echo "  restart  - Riavvia il server"
        echo "  status   - Mostra lo stato del server"
        echo ""
        exit 1
        ;;
esac
