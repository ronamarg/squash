# Build script for Flutter Web (Production) - PowerShell version

Write-Host "🚀 Building Squash Flutter Web for Production..." -ForegroundColor Cyan

# Check if env_config.dart exists
if (-not (Test-Path "lib\config\env_config.dart")) {
    Write-Host "⚠️  Warning: lib\config\env_config.dart not found!" -ForegroundColor Yellow
    Write-Host "Copy env_config.example.dart and configure it first."
    exit 1
}

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Cyan
flutter clean

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Cyan
flutter pub get

# Build for web
Write-Host "🔨 Building Flutter web (release mode)..." -ForegroundColor Cyan
flutter build web --release `
    --web-renderer canvaskit `
    --source-maps `
    --dart-define=FLUTTER_WEB_USE_SKIA=true

# Check build success
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host "📁 Output: build/web/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  - Deploy with Firebase: firebase deploy --only hosting"
    Write-Host "  - Deploy with Vercel: cd build/web; vercel --prod"
    Write-Host "  - Deploy with Netlify: netlify deploy --prod --dir=build/web"
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}
