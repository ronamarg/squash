"""
Download Squash ML models from Hugging Face Hub
Run during Render build to fetch models from cloud storage
"""
import os
from huggingface_hub import snapshot_download

# Configuration
HF_USERNAME = "ronamarg"  # Change to your Hugging Face username
MODEL_REPO = "squash-code-corruptor"
LOCAL_MODEL_PATH = "code_corruptor/code_corruptor_model_final"

def download_model():
    """Download the T5 code corruption model from Hugging Face"""
    
    repo_id = f"{HF_USERNAME}/{MODEL_REPO}"
    
    print("=" * 60)
    print("Downloading Squash ML Models from Hugging Face")
    print("=" * 60)
    print(f"\nRepository: {repo_id}")
    print(f"Destination: {LOCAL_MODEL_PATH}")
    print("\nThis may take a few minutes...")
    print()
    
    try:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(LOCAL_MODEL_PATH), exist_ok=True)
        
        # Download model files
        snapshot_download(
            repo_id=repo_id,
            repo_type="model",
            local_dir=LOCAL_MODEL_PATH,
            local_dir_use_symlinks=False,  # Copy files instead of symlinks
        )
        
        print("\n✓ Model downloaded successfully!")
        print(f"✓ Model files saved to: {LOCAL_MODEL_PATH}")
        
        # Verify essential files exist
        essential_files = ["config.json", "model.safetensors", "tokenizer.json"]
        missing = []
        
        for file in essential_files:
            path = os.path.join(LOCAL_MODEL_PATH, file)
            if not os.path.exists(path):
                missing.append(file)
        
        if missing:
            print(f"\n⚠ Warning: Missing files: {', '.join(missing)}")
        else:
            print("✓ All essential model files verified!")
        
        return True
        
    except Exception as e:
        print(f"\n✗ Download failed: {e}")
        print("\nTroubleshooting:")
        print(f"1. Check if model exists: https://huggingface.co/{repo_id}")
        print("2. Ensure model is public or HF_TOKEN is set")
        print("3. Check internet connection")
        return False

if __name__ == "__main__":
    success = download_model()
    exit(0 if success else 1)
