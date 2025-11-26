# Hugging Face Model Upload Guide

## Step 1: Create Hugging Face Account & Token

1. **Create account**: https://huggingface.co/join
2. **Create access token**: 
   - Go to https://huggingface.co/settings/tokens
   - Click "New token"
   - Name: "Squash Upload"
   - Type: **Write** (required for uploading)
   - Copy the token (starts with `hf_...`)

## Step 2: Set Token (Choose One Method)

### Option A: Environment Variable (Recommended)
```powershell
$env:HF_TOKEN='hf_your_token_here'
```

### Option B: Interactive Login
The script will prompt you to paste your token when you run it.

## Step 3: Upload Model

```powershell
# From project root
python ml_models/upload_to_huggingface.py
```

This will:
- Create repo `ronamarg/squash-code-corruptor` on Hugging Face
- Upload ~850MB model (takes 5-10 minutes)
- Skip training files (optimizer.pt, etc.) to save space

## Step 4: Verify Upload

Check your model at: https://huggingface.co/ronamarg/squash-code-corruptor

You should see:
- `model.safetensors` (850 MB)
- `tokenizer.json` (2 MB)
- `config.json`
- Other tokenizer files

## Step 5: Update Code (Automated)

The agent will update:
- `revertV3.py` - load from HF instead of local
- `render.yaml` - add model download to build
- `requirements.txt` - add huggingface_hub

## Step 6: Test Locally

```powershell
python -c "from transformers import AutoModelForSeq2SeqLM; model = AutoModelForSeq2SeqLM.from_pretrained('ronamarg/squash-code-corruptor'); print('Model loaded!')"
```

## Troubleshooting

**"HTTP 401 Unauthorized"**
- Token expired or wrong permissions
- Create new token with **Write** permission

**"Repository not found"**
- Check username is correct (`ronamarg`)
- Make sure repo was created successfully

**Upload timeout**
- Network issues, try again
- Model will resume from last checkpoint

**"Not enough disk space"**
- HF free tier: unlimited model storage ✓
- Local disk needs 1GB free for upload buffer

## Cost

- **Free tier**: Unlimited public models
- **Private models**: Free for personal use, $9/month for teams

## Next Steps

After successful upload, you're ready to deploy to Render!
The model will be downloaded automatically during Render build.
