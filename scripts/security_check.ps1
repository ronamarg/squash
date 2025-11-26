# Security check script - PowerShell version

Write-Host "🔐 Running Security Checks..." -ForegroundColor Cyan
Write-Host ""

$issuesFound = 0

# Check for API keys in tracked files
Write-Host "1️⃣  Checking for API keys in tracked files..." -ForegroundColor Cyan
$apiKeyPattern = "AIza[A-Za-z0-9_-]{35}|sk-[A-Za-z0-9]{48}|[0-9a-f]{32}\.[A-Za-z0-9]{16}"
$trackedFiles = git ls-files | Where-Object { $_ -notlike "*env_config.dart" }

$foundKeys = $false
foreach ($file in $trackedFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if ($content -match $apiKeyPattern) {
            Write-Host "❌ Found API keys in: $file" -ForegroundColor Red
            $foundKeys = $true
            $issuesFound = 1
        }
    }
}

if (-not $foundKeys) {
    Write-Host "✅ No API keys found in tracked files" -ForegroundColor Green
}

# Check if sensitive files are gitignored
Write-Host ""
Write-Host "2️⃣  Checking .gitignore configuration..." -ForegroundColor Cyan
$requiredIgnores = @(
    "lib/config/env_config.dart",
    ".env",
    ".env.local",
    ".venv/"
)

$gitignoreContent = Get-Content .gitignore -Raw

foreach ($pattern in $requiredIgnores) {
    if ($gitignoreContent -match [regex]::Escape($pattern)) {
        Write-Host "✅ $pattern is ignored" -ForegroundColor Green
    } else {
        Write-Host "❌ $pattern is NOT ignored" -ForegroundColor Red
        $issuesFound = 1
    }
}

# Check if env_config.dart is tracked
Write-Host ""
Write-Host "3️⃣  Checking if sensitive files are tracked..." -ForegroundColor Cyan
$trackedFilesList = git ls-files

if ($trackedFilesList -match "lib/config/env_config.dart") {
    Write-Host "❌ env_config.dart is tracked by git!" -ForegroundColor Red
    $issuesFound = 1
} else {
    Write-Host "✅ env_config.dart is not tracked" -ForegroundColor Green
}

if ($trackedFilesList -match "^\.env$") {
    Write-Host "❌ .env is tracked by git!" -ForegroundColor Red
    $issuesFound = 1
} else {
    Write-Host "✅ .env is not tracked" -ForegroundColor Green
}

# Check for large files
Write-Host ""
Write-Host "4️⃣  Checking for large files..." -ForegroundColor Cyan
$largeFiles = Get-ChildItem -Recurse -File | Where-Object { 
    $_.Length -gt 10MB -and 
    $_.FullName -notmatch "\.git" -and 
    $_.FullName -notmatch "\.venv" -and 
    $_.FullName -notmatch "build"
}

if ($largeFiles) {
    Write-Host "⚠️  Warning: Large files found:" -ForegroundColor Yellow
    $largeFiles | ForEach-Object { Write-Host "  - $($_.FullName) ($([math]::Round($_.Length/1MB, 2)) MB)" }
} else {
    Write-Host "✅ No large files found" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host ("="*50) -ForegroundColor Cyan
if ($issuesFound -eq 0) {
    Write-Host "✅ All security checks passed!" -ForegroundColor Green
    Write-Host "🚀 Repository is ready for deployment" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "❌ Security issues found!" -ForegroundColor Red
    Write-Host "🔧 Please fix the issues above before deploying" -ForegroundColor Yellow
    exit 1
}
