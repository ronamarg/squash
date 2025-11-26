"""
Test that RevertV3 can load from Hugging Face successfully
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from code_corruptor.revertV3 import RevertV3

def test_hf_model():
    print("=" * 60)
    print("Testing RevertV3 with Hugging Face Model")
    print("=" * 60)
    print()
    
    # Test code
    test_code = """def add(a, b):
    return a + b

result = add(5, 3)
print(result)"""
    
    print("Test code:")
    print(test_code)
    print()
    
    # Initialize with HF model (default)
    print("Initializing RevertV3 (will download from HF on first run)...")
    corruptor = RevertV3()  # Uses default: onegaiosu/squash-code-corruptor
    
    # Corrupt the code
    print("\nCorrupting code...")
    buggy_code = corruptor.corrupt(test_code)
    
    print("\nBuggy code generated:")
    print(buggy_code)
    print()
    
    # Verify it's different
    if buggy_code != test_code:
        print("✓ SUCCESS: Model loaded from HF and generated buggy code!")
        return True
    else:
        print("✗ FAIL: Corrupted code is identical to original")
        return False

if __name__ == "__main__":
    try:
        success = test_hf_model()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
