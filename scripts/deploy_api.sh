#!/bin/bash
# Deploy script for ML API to Render

echo "🚀 Deploying ML API to Production..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Warning: .env file not found!${NC}"
    echo "Create .env from .env.example and configure it."
    exit 1
fi

# Load environment variables
source .env

# Check for required environment variables
if [ -z "$OLLAMA_API_KEY" ]; then
    echo -e "${RED}❌ OLLAMA_API_KEY not set in .env${NC}"
    exit 1
fi

echo "📋 Pre-deployment checks..."

# Test Python imports
echo "🐍 Testing Python dependencies..."
python -c "import flask, flask_cors, waitress, torch, transformers" 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Missing Python dependencies. Run: pip install -r requirements.txt${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencies OK${NC}"

# Test API locally (optional)
echo "🧪 Testing API locally (optional, press Ctrl+C to skip)..."
timeout 5 python ml_models/unified_api.py &
sleep 3
curl -s http://localhost:5001/health > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Local API test passed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not test locally (may be already running)${NC}"
fi
pkill -f unified_api.py 2>/dev/null

echo ""
echo "📤 Ready to deploy!"
echo ""
echo "Choose deployment platform:"
echo "  1. Render (recommended)"
echo "  2. Railway"
echo "  3. Fly.io"
echo "  4. Docker"
echo ""

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "Deploying to Render..."
        echo "1. Push to GitHub: git push origin main"
        echo "2. Go to https://dashboard.render.com"
        echo "3. Create new Web Service from your repo"
        echo "4. Set environment variables in Render dashboard"
        ;;
    2)
        echo "Deploying to Railway..."
        if command -v railway &> /dev/null; then
            railway up
        else
            echo "Install Railway CLI: npm install -g @railway/cli"
        fi
        ;;
    3)
        echo "Deploying to Fly.io..."
        if command -v fly &> /dev/null; then
            fly deploy
        else
            echo "Install Fly CLI: curl -L https://fly.io/install.sh | sh"
        fi
        ;;
    4)
        echo "Building Docker image..."
        docker build -t squash-ml-api .
        echo "Run with: docker run -p 5001:5001 --env-file .env squash-ml-api"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo -e "${GREEN}✅ Deployment initiated!${NC}"
