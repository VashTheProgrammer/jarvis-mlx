#!/usr/bin/env python3
"""
Script SEMPLICISSIMO per convertire dataset in formato MLX.

Usa un JSON semplice con "domanda" e "risposta", lo converte
automaticamente in formato MLX per il training.
"""

import json
import argparse
from pathlib import Path


def convert_to_mlx_format(data):
    """
    Converte da formato semplice a formato MLX chat.

    Input: [{"domanda": "...", "risposta": "..."}]
    Output: [{"messages": [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]}]
    """
    mlx_data = []

    for item in data:
        # Formato semplice: domanda/risposta
        if "domanda" in item and "risposta" in item:
            mlx_item = {
                "messages": [
                    {"role": "user", "content": item["domanda"]},
                    {"role": "assistant", "content": item["risposta"]}
                ]
            }
            mlx_data.append(mlx_item)

        # Formato alternativo: question/answer (inglese)
        elif "question" in item and "answer" in item:
            mlx_item = {
                "messages": [
                    {"role": "user", "content": item["question"]},
                    {"role": "assistant", "content": item["answer"]}
                ]
            }
            mlx_data.append(mlx_item)

        # Già in formato MLX: passa direttamente
        elif "messages" in item:
            mlx_data.append(item)

        else:
            print(f"⚠️  Formato non riconosciuto, skippo: {list(item.keys())}")

    return mlx_data


def split_train_valid(data, split_ratio=0.8):
    """Divide dataset in train e validation."""
    n = len(data)
    train_size = int(n * split_ratio)

    train = data[:train_size]
    valid = data[train_size:]

    # Se valid è vuoto, usa almeno 1 esempio
    if not valid and train:
        valid = [train[-1]]

    return train, valid


def save_jsonl(data, filepath):
    """Salva in formato JSONL."""
    with open(filepath, 'w', encoding='utf-8') as f:
        for item in data:
            f.write(json.dumps(item, ensure_ascii=False) + '\n')


def main():
    parser = argparse.ArgumentParser(
        description="Converti dataset semplice in formato MLX"
    )
    parser.add_argument(
        "input_file",
        type=str,
        help="File JSON di input (es. my_data.json)"
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default="../data",
        help="Directory di output (default: ../data)"
    )
    parser.add_argument(
        "--split",
        action="store_true",
        help="Dividi dataset in 80%% train, 20%% valid (default: usa tutto)"
    )

    args = parser.parse_args()

    print("=" * 70)
    print("📝 Conversione Dataset per MLX")
    print("=" * 70)

    # Leggi file input
    input_path = Path(args.input_file)
    print(f"\n📁 Lettura: {input_path}")

    if not input_path.exists():
        print(f"❌ File non trovato: {input_path}")
        return

    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"   ✓ Caricati {len(data)} esempi")

    # Converti in formato MLX
    print("\n🔄 Conversione in formato MLX...")
    mlx_data = convert_to_mlx_format(data)
    print(f"   ✓ {len(mlx_data)} esempi convertiti")

    if not mlx_data:
        print("❌ Nessun dato convertito! Controlla il formato.")
        return

    # Split train/valid
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.split:
        # Dividi in train e valid
        print(f"\n✂️  Split dataset (80% train, 20% valid)...")
        train_data, valid_data = split_train_valid(mlx_data, 0.8)
        print(f"   Train: {len(train_data)} esempi")
        print(f"   Valid: {len(valid_data)} esempi")
    else:
        # Usa tutto per train e valid (stesso dataset) - DEFAULT
        print("\n💾 Salvataggio (usa tutto il dataset per train e valid)...")
        train_data = mlx_data
        valid_data = mlx_data

    # Salva
    train_file = output_dir / "train.jsonl"
    valid_file = output_dir / "valid.jsonl"

    save_jsonl(train_data, train_file)
    save_jsonl(valid_data, valid_file)

    print(f"\n✅ Dataset pronti!")
    print("=" * 70)
    print(f"📁 Train: {train_file}")
    print(f"📁 Valid: {valid_file}")
    print("=" * 70)

    # Mostra esempio
    print(f"\n📄 Esempio convertito:")
    print("-" * 70)
    print(json.dumps(train_data[0], ensure_ascii=False, indent=2))
    print("-" * 70)

    print("\n💡 Prossimo passo:")
    print(f"   python -m mlx_lm lora --model <MODEL> --train --data {output_dir}")
    print()


if __name__ == "__main__":
    main()
