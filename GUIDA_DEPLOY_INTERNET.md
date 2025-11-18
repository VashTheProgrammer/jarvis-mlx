# Guida per Esporre Fluotech AI su Internet

## Opzione 1: Cloudflare Tunnel (CONSIGLIATA) ✅

**Vantaggi:**
- ✅ Gratuito
- ✅ HTTPS automatico
- ✅ Non serve aprire porte sul router
- ✅ Protezione DDoS inclusa
- ✅ IP del Mac nascosto

### Passo 1: Installa Cloudflare Tunnel

```bash
brew install cloudflare/cloudflare/cloudflared
```

### Passo 2: Login a Cloudflare

```bash
cloudflared tunnel login
```

Questo aprirà il browser per autenticarti con il tuo account Cloudflare (crea un account gratuito se non ce l'hai).

### Passo 3: Aggiungi il dominio a Cloudflare

1. Vai su [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Clicca "Add a Site"
3. Inserisci `fluotech.co.uk`
4. Scegli il piano Free
5. Segui le istruzioni per cambiare i nameserver su GoDaddy:
   - Vai su GoDaddy → Domini → fluotech.co.uk → Gestisci DNS
   - Cambia i nameserver con quelli forniti da Cloudflare

### Passo 4: Crea il Tunnel

```bash
# Crea il tunnel
cloudflared tunnel create fluotech-ai

# Vedrai un ID, salvalo!
# Esempio output: Created tunnel fluotech-ai with id abc123def456
```

### Passo 5: Configura il Tunnel

Crea il file di configurazione:

```bash
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

Inserisci questo contenuto (sostituisci TUNNEL-ID con l'ID del tunnel):

```yaml
tunnel: TUNNEL-ID
credentials-file: /Users/adrianocostanzo/.cloudflared/TUNNEL-ID.json

ingress:
  - hostname: ai.fluotech.co.uk
    service: http://localhost:8501
  - service: http_status:404
```

### Passo 6: Crea il Record DNS

```bash
cloudflared tunnel route dns fluotech-ai ai.fluotech.co.uk
```

### Passo 7: Avvia Tutto

**Terminale 1 - Avvia la webapp:**
```bash
cd /Users/adrianocostanzo/ml-projects/fine-tuning/webapp
python app.py
```

**Terminale 2 - Avvia il tunnel:**
```bash
cloudflared tunnel run fluotech-ai
```

### Passo 8: Accedi da Internet!

Vai su: **https://ai.fluotech.co.uk**

- Password di default: `Fluotech2024!` (cambiala nel file `.env`)

---

## Opzione 2: Cloudflare Access (Autenticazione Avanzata)

Se vuoi aggiungere autenticazione OAuth (Google, GitHub, etc.):

1. Vai su Cloudflare Dashboard → Zero Trust → Access
2. Crea un'applicazione per `ai.fluotech.co.uk`
3. Configura le regole di accesso (es: solo email specifiche)

---

## Opzione 3: ngrok (Temporaneo, per test)

**Vantaggi:**
- ⚡ Velocissimo da configurare
- 🔄 Perfetto per test temporanei

**Svantaggi:**
- ⚠️ URL cambia ogni volta
- ⚠️ Limite di ore gratuite

```bash
# Installa ngrok
brew install ngrok

# Registrati su ngrok.com e ottieni il token
ngrok config add-authtoken TUO_TOKEN

# Avvia il tunnel
ngrok http 8501
```

L'URL sarà tipo: `https://abc123.ngrok.io`

---

## Rendere il Tunnel Persistente (MacOS)

Per far partire automaticamente il tunnel all'avvio del Mac:

### 1. Crea uno script di avvio

```bash
nano ~/fluotech-ai-start.sh
```

Contenuto:
```bash
#!/bin/bash
cd /Users/adrianocostanzo/ml-projects/fine-tuning/webapp
source venv/bin/activate  # se usi virtual env
python app.py &
cloudflared tunnel run fluotech-ai
```

Rendi eseguibile:
```bash
chmod +x ~/fluotech-ai-start.sh
```

### 2. Crea un LaunchAgent

```bash
nano ~/Library/LaunchAgents/com.fluotech.ai.plist
```

Contenuto:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.fluotech.ai</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/adrianocostanzo/fluotech-ai-start.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/adrianocostanzo/fluotech-ai.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/adrianocostanzo/fluotech-ai-error.log</string>
</dict>
</plist>
```

Carica il servizio:
```bash
launchctl load ~/Library/LaunchAgents/com.fluotech.ai.plist
```

---

## Sicurezza

### Cambia la Password

Modifica `/Users/adrianocostanzo/ml-projects/fine-tuning/webapp/.env`:

```env
APP_PASSWORD=TuaNuovaPasswordSicurissima!
SECRET_KEY=cambia-anche-questo-con-qualcosa-di-random
```

### Firewall Cloudflare

Cloudflare offre gratuitamente:
- Protezione DDoS
- WAF (Web Application Firewall)
- Rate limiting
- IP blocking per paese

Configura tutto dal dashboard di Cloudflare.

---

## Monitoraggio

### Visualizza i log in tempo reale:

```bash
tail -f ~/fluotech-ai.log
tail -f ~/fluotech-ai-error.log
```

### Controlla se il servizio è attivo:

```bash
launchctl list | grep fluotech
```

---

## Troubleshooting

### Il tunnel non si connette?

```bash
# Controlla lo stato
cloudflared tunnel info fluotech-ai

# Testa il tunnel manualmente
cloudflared tunnel run fluotech-ai --loglevel debug
```

### La webapp non risponde?

```bash
# Verifica che sia in ascolto
lsof -i :8501

# Riavvia manualmente
cd /Users/adrianocostanzo/ml-projects/fine-tuning/webapp
python app.py
```

### Password non accettata?

Controlla il file `.env` e riavvia la webapp.

---

## Costi

- **Cloudflare Tunnel**: Gratuito ✅
- **Dominio GoDaddy**: ~£10-15/anno (già ce l'hai)
- **Totale**: £0/mese + dominio annuale

---

## URL Finale

**https://ai.fluotech.co.uk**

Password: quella che hai impostato in `.env` (default: `Fluotech2024!`)

---

**Domande? Contattami o consulta:**
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Cloudflare Access Docs](https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/)
