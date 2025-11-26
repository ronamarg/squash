"""
Fix config.json on HuggingFace to add model_type
This script downloads the config, adds model_type: t5, and re-uploads
"""
import json
from huggingface_hub import hf_hub_download, upload_file, login
import os

# Configuration
HF_USERNAME = "onegaiosu"
MODEL_REPO = "squash-code-corruptor"
repo_id = f"{HF_USERNAME}/{MODEL_REPO}"

# Login
token = os.getenv('HF_TOKEN')
if not token:
    print("✗ HF_TOKEN environment variable not set!")
    exit(1)

login(token=token)
print(f"Fixing config.json for {repo_id}...")

# Download current config
config_path = hf_hub_download(
    repo_id=repo_id,
    filename="config.json",
    local_dir="temp_fix"
)

# Load and modify
with open(config_path, 'r') as f:
    config = json.load(f)

print(f"Current config keys: {list(config.keys())}")

# Add model_type if missing
if 'model_type' not in config:
    config['model_type'] = 't5'
    print("✓ Added model_type: t5")
else:
    print(f"✓ model_type already exists: {config['model_type']}")

# Save modified config
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

# Upload back to HF
print("Uploading fixed config.json...")
upload_file(
    path_or_fileobj=config_path,
    path_in_repo="config.json",
    repo_id=repo_id,
    commit_message="Add model_type to config.json"
)

print(f"✓ Config fixed! Model should now load correctly.")

# Cleanup
import shutil
if os.path.exists("temp_fix"):
    shutil.rmtree("temp_fix")
