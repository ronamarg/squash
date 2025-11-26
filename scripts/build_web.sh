#!/bin/bash
# Build script for Flutter Web (Production)

echo "🚀 Building Squash Flutter Web for Production..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if env_config.dart exists
if [ ! -f "lib/config/env_config.dart" ]; then
    echo -e "${YELLOW}⚠️  Warning: lib/config/env_config.dart not found!${NC}"
    echo "Copy env_config.example.dart and configure it first."
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web
echo "🔨 Building Flutter web (release mode)..."
flutter build web --release \
    --web-renderer canvaskit \
    --source-maps \
    --dart-define=FLUTTER_WEB_USE_SKIA=true

# Check build success
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo "📁 Output: build/web/"
    echo ""
    echo "Next steps:"
    echo "  - Deploy with Firebase: firebase deploy --only hosting"
    echo "  - Deploy with Vercel: cd build/web && vercel --prod"
    echo "  - Deploy with Netlify: netlify deploy --prod --dir=build/web"
else
    echo "❌ Build failed!"
    exit 1
fi
