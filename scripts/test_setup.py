#!/usr/bin/env python3
"""Script per verificare che tutto sia installato correttamente"""

def test_imports():
    print("🔍 Verifica importazioni...\n")
    
    tests = [
        ("MLX", "mlx.core"),
        ("MLX-LM", "mlx_lm"),
        ("PyTorch", "torch"),
        ("Transformers", "transformers"),
        ("Datasets", "datasets"),
        ("PEFT", "peft"),
        ("Accelerate", "accelerate"),
        ("TRL", "trl"),
    ]
    
    for name, module in tests:
        try:
            mod = __import__(module)
            version = getattr(mod, "__version__", "unknown")
            print(f"✅ {name:15} v{version}")
        except ImportError as e:
            print(f"❌ {name:15} non installato")
    
    print("\n🔍 Verifica hardware...\n")
    
    # Verifica architettura
    import platform
    print(f"Architettura: {platform.machine()}")
    print(f"Python: {platform.python_version()}")
    
    # Verifica MPS
    import torch
    print(f"MPS disponibile: {torch.backends.mps.is_available()}")
    if torch.backends.mps.is_available():
        print(f"MPS built: {torch.backends.mps.is_built()}")
    
    # Test MLX
    try:
        import mlx.core as mx
        a = mx.array([1, 2, 3])
        print(f"MLX funzionante: {a.sum().item() == 6}")
    except Exception as e:
        print(f"MLX error: {e}")

if __name__ == "__main__":
    test_imports()