"""
Upload Squash ML models to Hugging Face Hub
Run this once to upload your trained models to cloud storage
"""
import os
from huggingface_hub import HfApi, create_repo, login

# Configuration
HF_USERNAME = "onegaiosu"  # Your Hugging Face username
MODEL_REPO = "squash-code-corruptor"
LOCAL_MODEL_PATH = "ml_models/code_corruptor/code_corruptor_model_final"

def upload_model():
    """Upload the T5 code corruption model to Hugging Face"""
    
    print("=" * 60)
    print("Squash ML Model Upload to Hugging Face")
    print("=" * 60)
    
    # Step 1: Login (you'll need to paste your HF token)
    print("\n1. Logging in to Hugging Face...")
    
    # Get token from environment variable
    token = os.getenv('HF_TOKEN')
    if not token:
        print("✗ HF_TOKEN environment variable not set!")
        print("  Set it with: $env:HF_TOKEN='your_token_here'")
        return
    
    try:
        login(token=token)
        print("✓ Login successful!")
    except Exception as e:
        print(f"✗ Login failed: {e}")
        print("\nCheck your token has 'write' permissions")
        print("  Get token from: https://huggingface.co/settings/tokens")
        return
    
    # Step 2: Create repository
    print(f"\n2. Creating repository '{HF_USERNAME}/{MODEL_REPO}'...")
    repo_id = f"{HF_USERNAME}/{MODEL_REPO}"
    
    try:
        create_repo(
            repo_id=repo_id,
            repo_type="model",
            exist_ok=True,
            private=False  # Set to True if you want private repo
        )
        print(f"✓ Repository created/exists: https://huggingface.co/{repo_id}")
    except Exception as e:
        print(f"✗ Failed to create repo: {e}")
        return
    
    # Step 3: Upload model files
    print(f"\n3. Uploading model files from {LOCAL_MODEL_PATH}...")
    print("   This may take several minutes (uploading ~3.4GB)...")
    
    api = HfApi()
    
    try:
        # Upload the entire model directory
        api.upload_folder(
            folder_path=LOCAL_MODEL_PATH,
            repo_id=repo_id,
            repo_type="model",
            commit_message="Upload Squash T5 code corruptor model",
        )
        print("✓ Model uploaded successfully!")
        print(f"\n✓ Model available at: https://huggingface.co/{repo_id}")
        
    except Exception as e:
        print(f"✗ Upload failed: {e}")
        return
    
    # Step 4: Create model card (README)
    print("\n4. Creating model card...")
    
    model_card = f"""---
tags:
- code
- python
- code-generation
- bug-injection
- education
license: mit
---

# Squash Code Corruptor Model

T5-based model for generating realistic Python code bugs for educational purposes.

## Model Description

This model is trained to introduce realistic bugs into Python code, including:
- Logic errors (operator swaps, off-by-one errors, wrong variables)
- Syntax errors (missing colons, indentation issues)

Trained on 1500 examples:
- 1000 syntax error pairs
- 500 logic error pairs (7 different categories)

## Usage

```python
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

model = AutoModelForSeq2SeqLM.from_pretrained("{repo_id}")
tokenizer = AutoTokenizer.from_pretrained("{repo_id}")

# Corrupt code
code = "def add(a, b):\\n    return a + b"
inputs = tokenizer(code, return_tensors="pt", max_length=512, truncation=True)
outputs = model.generate(**inputs, max_length=512, temperature=0.8)
corrupted = tokenizer.decode(outputs[0], skip_special_tokens=True)
```

## Training Data

Custom dataset of Python code pairs (correct → buggy) focusing on common programming mistakes
for beginner and intermediate learners.

## Intended Use

Educational tool for the Squash app - helping students learn Python by fixing intentionally buggy code.

## Limitations

- Trained specifically on Python code
- May not work well with very long or complex code snippets
- Best for code snippets under 50 lines

## Citation

```
@misc{{squash-code-corruptor,
  author = {{Mao Abel}},
  title = {{Squash Code Corruptor}},
  year = {{2025}},
  publisher = {{Hugging Face}},
  howpublished = {{\\url{{https://huggingface.co/{repo_id}}}}}
}}
```
"""
    
    try:
        api.upload_file(
            path_or_fileobj=model_card.encode(),
            path_in_repo="README.md",
            repo_id=repo_id,
            repo_type="model",
        )
        print("✓ Model card created!")
    except Exception as e:
        print(f"⚠ Failed to create model card: {e}")
    
    print("\n" + "=" * 60)
    print("✓ Upload complete!")
    print("=" * 60)
    print(f"\nModel URL: https://huggingface.co/{repo_id}")
    print(f"\nNext steps:")
    print(f"1. Update revertV3.py to load from Hugging Face")
    print(f"2. Update Render build command to download model")
    print(f"3. Remove local model files from .gitignore")

if __name__ == "__main__":
    upload_model()
