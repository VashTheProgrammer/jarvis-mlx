#!/usr/bin/env python3
"""
Script per creare dataset di training da book2.md con chunk MOLTO piccoli (200 parole max)
per evitare OOM durante il training.
"""

import json
import re
from pathlib import Path
from typing import List, Dict

def read_book(file_path: str) -> str:
    """Legge il file markdown del libro"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return f.read()

def split_by_headers(text: str) -> List[Dict[str, str]]:
    """Divide il testo per headers markdown (# Titolo)"""
    sections = []

    # Pattern per trovare headers (# ## ###)
    pattern = r'^(#{1,3})\s+(.+)$'
    parts = re.split(pattern, text, flags=re.MULTILINE)

    current_title = "Introduzione"
    current_content = []

    i = 0
    while i < len(parts):
        part = parts[i].strip()

        if not part:
            i += 1
            continue

        # Se troviamo un header level
        if part.startswith('#'):
            # Salva la sezione precedente
            if current_content:
                sections.append({
                    "title": current_title,
                    "content": '\n'.join(current_content).strip()
                })

            # Prendi il titolo
            if i + 1 < len(parts):
                current_title = parts[i + 1].strip()
                i += 2
                current_content = []
            else:
                i += 1
        else:
            # È contenuto
            if part:
                current_content.append(part)
            i += 1

    # Aggiungi l'ultima sezione
    if current_content:
        sections.append({
            "title": current_title,
            "content": '\n'.join(current_content).strip()
        })

    return sections

def split_into_small_chunks(text: str, max_words: int = 200) -> List[str]:
    """
    Divide il testo in chunk MOLTO piccoli.
    Ogni chunk è max 200 parole per evitare OOM.
    """
    words = text.split()
    chunks = []

    for i in range(0, len(words), max_words):
        chunk = ' '.join(words[i:i + max_words])
        if chunk.strip():
            chunks.append(chunk.strip())

    return chunks

def create_training_examples(sections: List[Dict[str, str]], max_words: int = 200) -> List[Dict[str, str]]:
    """
    Crea esempi di training dal libro.
    Ogni esempio ha MAX 200 parole per gestibilità memoria.
    """
    examples = []

    prompts_templates = [
        "Parlami di {}",
        "Cosa succede in {}?",
        "Continua la storia di {}",
        "Descrivi {}",
        "Raccontami di {}",
        "Dimmi qualcosa su {}",
    ]

    for section in sections:
        title = section["title"]
        content = section["content"]

        # Sempre dividi in chunk piccoli
        chunks = split_into_small_chunks(content, max_words=max_words)

        for i, chunk in enumerate(chunks):
            # Varia i prompt
            prompt_template = prompts_templates[i % len(prompts_templates)]

            # Se ci sono più chunk, aggiungi "parte X"
            if len(chunks) > 1:
                prompt = prompt_template.format(f"{title} (parte {i+1})")
            else:
                prompt = prompt_template.format(title)

            examples.append({
                "user": prompt,
                "assistant": chunk
            })

    return examples

def main():
    # Path del libro
    book_path = Path.home() / "Desktop" / "book2.md"
    output_dir = Path("data/physophia_expert")
    output_dir.mkdir(parents=True, exist_ok=True)

    print("📖 Leggo il libro...")
    book_text = read_book(book_path)

    print("✂️  Divido per sezioni...")
    sections = split_by_headers(book_text)
    print(f"   Trovate {len(sections)} sezioni")

    print("🔪 Creo chunk MOLTO piccoli (max 200 parole)...")
    examples = create_training_examples(sections, max_words=200)

    # Statistiche
    word_counts = [len(ex['assistant'].split()) for ex in examples]
    total_words = sum(word_counts)
    avg_words = total_words / len(examples) if examples else 0
    max_words_in_example = max(word_counts) if word_counts else 0

    print(f"\n📊 Statistiche dataset:")
    print(f"   Esempi totali: {len(examples)}")
    print(f"   Parole totali: {total_words:,}")
    print(f"   Media parole per esempio: {avg_words:.1f}")
    print(f"   Max parole in un esempio: {max_words_in_example}")

    # Salva dataset completo
    output_file = output_dir / "my_data_small.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(examples, f, ensure_ascii=False, indent=2)

    print(f"\n✅ Dataset salvato in: {output_file}")
    print(f"   Ora procedo a creare i batch per training incrementale...")

    return examples

if __name__ == "__main__":
    examples = main()
