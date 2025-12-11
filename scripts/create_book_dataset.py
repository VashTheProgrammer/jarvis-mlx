#!/usr/bin/env python3
"""
Script per creare dataset di training da un libro completo in Markdown.
Divide il libro in chunks e crea esempi Q&A per training.
"""

import re
import json
import argparse
from pathlib import Path
from typing import List, Dict

def read_markdown(file_path: str) -> str:
    """Legge il file markdown"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return f.read()

def split_by_headers(text: str) -> List[Dict[str, str]]:
    """Divide il testo per headers markdown (# Titolo)"""
    sections = []

    # Split by headers
    pattern = r'^(#{1,3})\s+(.+)$'
    parts = re.split(pattern, text, flags=re.MULTILINE)

    current_section = {"title": "Introduzione", "content": ""}

    for i in range(0, len(parts)):
        if i == 0 and parts[i].strip():
            # Primo pezzo senza header
            current_section["content"] = parts[i].strip()
        elif i > 0 and parts[i].startswith('#'):
            # Salva sezione precedente se ha contenuto
            if current_section["content"].strip():
                sections.append(current_section)

            # Nuova sezione
            level = parts[i]
            title = parts[i+1] if i+1 < len(parts) else ""
            content = parts[i+2] if i+2 < len(parts) else ""

            current_section = {
                "title": title.strip(),
                "content": content.strip()
            }

    # Aggiungi ultima sezione
    if current_section["content"].strip():
        sections.append(current_section)

    return sections

def split_into_chunks(text: str, chunk_size: int = 800) -> List[str]:
    """Divide il testo in chunks di parole"""
    words = text.split()
    chunks = []

    for i in range(0, len(words), chunk_size):
        chunk = ' '.join(words[i:i + chunk_size])
        if chunk.strip():
            chunks.append(chunk.strip())

    return chunks

def create_training_examples(sections: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """Crea esempi di training dal libro"""
    examples = []

    for section in sections:
        title = section["title"]
        content = section["content"]

        if not content:
            continue

        # Se la sezione è lunga, dividila in chunks
        if len(content.split()) > 1000:
            chunks = split_into_chunks(content, chunk_size=800)

            for i, chunk in enumerate(chunks):
                # Vari tipi di prompt
                prompts = [
                    f"Parlami di {title}",
                    f"Continua la storia di {title}",
                    f"Descrivi la scena di {title}",
                    f"Cosa succede in {title}?",
                ]

                prompt = prompts[i % len(prompts)]

                examples.append({
                    "user": prompt,
                    "assistant": chunk
                })
        else:
            # Sezione breve, usa intera
            examples.append({
                "user": f"Parlami di {title}",
                "assistant": content
            })

            examples.append({
                "user": f"Descrivi {title}",
                "assistant": content
            })

    return examples

def add_general_questions(examples: List[Dict[str, str]], book_content: str) -> List[Dict[str, str]]:
    """Aggiunge domande generali sul libro"""

    # Estrai personaggi principali (nomi propri all'inizio frase)
    characters = re.findall(r'\b([A-Z][a-z]+)\b', book_content)
    char_counts = {}
    for char in characters:
        if len(char) > 3:  # Ignora parole troppo corte
            char_counts[char] = char_counts.get(char, 0) + 1

    # Top 10 personaggi più menzionati
    top_chars = sorted(char_counts.items(), key=lambda x: x[1], reverse=True)[:10]

    # Domande generali
    general = [
        {
            "user": "Qual è l'ambientazione di questa storia?",
            "assistant": "La storia è ambientata a Physophia, un regno dove la natura non è semplicemente una cornice, ma l'essenza stessa della vita. Qui esiste la NI (Intelligenza Naturale) con cui tutti gli esseri vivono in armonia. La città principale è Alethopolis, la polis della Verità, dove conoscenza e natura si fondono."
        },
        {
            "user": "Chi sono gli Eterni?",
            "assistant": "Gli Eterni sono quattro figure straordinarie con sembianze umane ma più vicine a divinità. Sono Franky (spavaldo e analitico), Pathos (sentimentale e sognatore), Kalè (misteriosa e coraggiosa), e Aster (intelligente e appassionata di scienza). Hanno connessione assoluta con la NI e nessuno sa quando sono nati."
        },
        {
            "user": "Cos'è la NI?",
            "assistant": "La NI (Intelligenza Naturale) è l'intelligenza della natura stessa, considerata più evoluta e divina rispetto agli umani. Gli abitanti di Physophia vivono in armonia con la NI, che permea ogni aspetto della vita. Gli Eterni la padroneggiano completamente, mentre gli umani cercano di connettersi con essa."
        },
        {
            "user": "Continua la storia",
            "assistant": "In questo regno di armonia perfetta, dove la natura detta le regole dell'esistenza, qualcosa sta per cambiare..."
        }
    ]

    # Aggiungi domande sui personaggi principali
    for char, count in top_chars[:5]:
        if count > 10:  # Solo se menzionato abbastanza
            general.append({
                "user": f"Chi è {char}?",
                "assistant": f"{char} è uno dei personaggi chiave di questa storia. [L'AI userà la conoscenza del libro per rispondere]"
            })

    return examples + general

def main():
    parser = argparse.ArgumentParser(description='Crea dataset da libro Markdown')
    parser.add_argument('book_file', help='File .md del libro')
    parser.add_argument('--output-dir', default='data/physophia_expert',
                       help='Directory output (default: data/physophia_expert)')
    parser.add_argument('--chunk-size', type=int, default=800,
                       help='Dimensione chunks in parole (default: 800)')

    args = parser.parse_args()

    # Leggi libro
    print(f"📖 Lettura libro: {args.book_file}")
    book_content = read_markdown(args.book_file)
    word_count = len(book_content.split())
    print(f"   Parole totali: {word_count:,}")

    # Dividi per sezioni
    print("📑 Divisione in sezioni...")
    sections = split_by_headers(book_content)
    print(f"   Sezioni trovate: {len(sections)}")

    # Crea esempi
    print("🎯 Creazione esempi di training...")
    examples = create_training_examples(sections)

    # Aggiungi domande generali
    print("❓ Aggiunta domande generali...")
    examples = add_general_questions(examples, book_content)

    print(f"✅ Esempi totali: {len(examples)}")

    # Crea directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Salva JSON
    json_file = output_dir / "my_data.json"
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(examples, f, ensure_ascii=False, indent=2)

    print(f"💾 Salvato: {json_file}")
    print(f"   Dimensione: {json_file.stat().st_size / 1024:.1f} KB")

    # Converti in JSONL
    print("\n🔄 Conversione in JSONL...")
    from convert_to_jsonl import create_training_data

    train_file = output_dir / "train.jsonl"
    valid_file = output_dir / "valid.jsonl"

    create_training_data(str(json_file), str(output_dir))

    print(f"✅ Training set: {train_file}")
    print(f"✅ Validation set: {valid_file}")
    print("\n🎉 Dataset pronto per training!")

if __name__ == "__main__":
    main()
