# Setup GitHub per Jarvis MLX

## 📋 Prerequisiti

Git non è ancora installato sul tuo Mac. Segui questi passi:

### 1. Installa Git (Command Line Tools)

```bash
xcode-select --install
```

Clicca "Install" nella finestra popup e attendi (~5-10 minuti).

Verifica installazione:
```bash
git --version
```

### 2. Configura Git (prima volta)

```bash
git config --global user.name "Tuo Nome"
git config --global user.email "tua@email.com"
```

## 🚀 Push su GitHub

### 3. Inizializza Repository

```bash
cd /Users/adrianocostanzo/ml-projects/fine-tuning

git init
git add .
git commit -m "Initial commit: Jarvis MLX - LLM fine-tuning su Apple Silicon

✨ Features:
- Sistema semplicissimo per fine-tuning LLM
- Supporto modelli da 0.5B a 14B+
- Dataset formato JSON ultra-semplice
- Script di conversione automatica
- Testato su Qwen 0.5B, 1.5B, 7B
- Ottimizzato per Apple Silicon (MLX)

🧪 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 4. Crea Repository su GitHub

1. Vai su https://github.com/new
2. Nome repository: **jarvis-mlx**
3. Descrizione: *Fine-tuning semplicissimo di LLM su Apple Silicon*
4. Public/Private: a tua scelta
5. **NON** aggiungere README, .gitignore o LICENSE (già presenti)
6. Clicca "Create repository"

### 5. Push

GitHub ti mostrerà i comandi. Usa questi:

```bash
git remote add origin https://github.com/TUO_USERNAME/jarvis-mlx.git
git branch -M main
git push -u origin main
```

Oppure con SSH (se configurato):
```bash
git remote add origin git@github.com:TUO_USERNAME/jarvis-mlx.git
git branch -M main
git push -u origin main
```

## ✅ Verifiche

File che verranno pushati:
```
✅ README.md (guida completa con badges)
✅ LICENSE (MIT)
✅ .gitignore (configurato)
✅ data/my_data.json (template)
✅ scripts/*.py (3 script essenziali)
✅ scripts/requirements.txt
❌ models/ (ignorato, file troppo grandi)
❌ data/*.jsonl (ignorato, generati automaticamente)
```

## 🎯 Comandi Futuri

Dopo modifiche:
```bash
git add .
git commit -m "Descrizione modifiche"
git push
```

## 📝 Note

- I modelli fine-tuned (adapter) NON vengono pushati (troppo grandi, ~11MB+)
- Ogni utente genera i propri adapter localmente
- Solo il codice e il template dataset vanno su GitHub

Tutto pronto per il push! 🚀
