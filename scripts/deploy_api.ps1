# Deploy script for ML API - PowerShell version

Write-Host "🚀 Deploying ML API to Production..." -ForegroundColor Cyan

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  Warning: .env file not found!" -ForegroundColor Yellow
    Write-Host "Create .env from .env.example and configure it."
    exit 1
}

# Load environment variables
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}

# Check for required environment variables
if (-not $env:OLLAMA_API_KEY) {
    Write-Host "❌ OLLAMA_API_KEY not set in .env" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Pre-deployment checks..." -ForegroundColor Cyan

# Test Python imports
Write-Host "🐍 Testing Python dependencies..." -ForegroundColor Cyan
& python -c "import flask, flask_cors, waitress, torch, transformers" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Missing Python dependencies. Run: pip install -r requirements.txt" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Dependencies OK" -ForegroundColor Green

Write-Host ""
Write-Host "📤 Ready to deploy!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Choose deployment platform:" -ForegroundColor Yellow
Write-Host "  1. Render (recommended)"
Write-Host "  2. Railway"
Write-Host "  3. Fly.io"
Write-Host "  4. Docker"
Write-Host ""

$choice = Read-Host "Enter choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host "Deploying to Render..." -ForegroundColor Cyan
        Write-Host "1. Push to GitHub: git push origin main"
        Write-Host "2. Go to https://dashboard.render.com"
        Write-Host "3. Create new Web Service from your repo"
        Write-Host "4. Set environment variables in Render dashboard"
    }
    "2" {
        Write-Host "Deploying to Railway..." -ForegroundColor Cyan
        if (Get-Command railway -ErrorAction SilentlyContinue) {
            railway up
        } else {
            Write-Host "Install Railway CLI: npm install -g @railway/cli"
        }
    }
    "3" {
        Write-Host "Deploying to Fly.io..." -ForegroundColor Cyan
        if (Get-Command fly -ErrorAction SilentlyContinue) {
            fly deploy
        } else {
            Write-Host "Install Fly CLI: iwr https://fly.io/install.ps1 -useb | iex"
        }
    }
    "4" {
        Write-Host "Building Docker image..." -ForegroundColor Cyan
        docker build -t squash-ml-api .
        Write-Host "Run with: docker run -p 5001:5001 --env-file .env squash-ml-api"
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Deployment initiated!" -ForegroundColor Green
