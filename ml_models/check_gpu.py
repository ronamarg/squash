"""
Check GPU availability and test RevertV3 with GPU acceleration
"""
import torch
import sys
import os

ml_models_path = os.path.dirname(os.path.abspath(__file__))
if ml_models_path not in sys.path:
    sys.path.insert(0, ml_models_path)

print("=" * 60)
print("GPU Availability Check")
print("=" * 60)

# Check CUDA availability
cuda_available = torch.cuda.is_available()
print(f"CUDA Available: {cuda_available}")

if cuda_available:
    print(f"CUDA Version: {torch.version.cuda}")
    print(f"GPU Count: {torch.cuda.device_count()}")
    for i in range(torch.cuda.device_count()):
        print(f"  GPU {i}: {torch.cuda.get_device_name(i)}")
        print(f"    Memory: {torch.cuda.get_device_properties(i).total_memory / 1e9:.2f} GB")
    print("\n✓ GPU acceleration is available!")
else:
    print("\n⚠ No GPU detected - will use CPU")
    print("\nTo enable GPU:")
    print("1. Install CUDA Toolkit from NVIDIA")
    print("2. Install PyTorch with CUDA: pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121")

print("\n" + "=" * 60)
print("Testing RevertV3 with GPU")
print("=" * 60)

try:
    from code_corruptor.revertV3 import RevertV3
    
    # Test with auto-detect (will use GPU if available)
    print("\nInitializing RevertV3 (auto-detect device)...")
    model = RevertV3(device=None)  # None = auto-detect
    
    test_code = "def add(a, b):\n    return a + b"
    print(f"\nTest code: {test_code}")
    
    model._load_t5_model()
    result = model.corrupt(test_code)
    
    print(f"\nCorrupted: {result}")
    print("\n✓ RevertV3 is working!")
    
    # Show which device was used
    device_used = model.t5_model.device
    print(f"\nDevice used: {device_used}")
    
    if str(device_used) == 'cuda':
        print("🚀 GPU acceleration is ACTIVE!")
    else:
        print("💻 Using CPU")
        
except Exception as e:
    print(f"\n❌ Error testing RevertV3: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 60)
