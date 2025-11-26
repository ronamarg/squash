#!/bin/bash
# Security check script - verifies no sensitive data in git

echo "🔐 Running Security Checks..."
echo ""

ISSUES_FOUND=0

# Check for API keys in tracked files
echo "1️⃣  Checking for API keys in tracked files..."
if git grep -E "AIza[A-Za-z0-9_-]{35}|sk-[A-Za-z0-9]{48}|[0-9a-f]{32}\.[A-Za-z0-9]{16}" -- ':(exclude)lib/config/env_config.dart'; then
    echo "❌ Found API keys in tracked files!"
    ISSUES_FOUND=1
else
    echo "✅ No API keys found in tracked files"
fi

# Check if sensitive files are gitignored
echo ""
echo "2️⃣  Checking .gitignore configuration..."
REQUIRED_IGNORES=(
    "lib/config/env_config.dart"
    ".env"
    ".env.local"
    ".venv/"
)

for pattern in "${REQUIRED_IGNORES[@]}"; do
    if grep -q "$pattern" .gitignore; then
        echo "✅ $pattern is ignored"
    else
        echo "❌ $pattern is NOT ignored"
        ISSUES_FOUND=1
    fi
done

# Check if env_config.dart is tracked
echo ""
echo "3️⃣  Checking if sensitive files are tracked..."
if git ls-files | grep -q "lib/config/env_config.dart"; then
    echo "❌ env_config.dart is tracked by git!"
    ISSUES_FOUND=1
else
    echo "✅ env_config.dart is not tracked"
fi

if git ls-files | grep -q "^\.env$"; then
    echo "❌ .env is tracked by git!"
    ISSUES_FOUND=1
else
    echo "✅ .env is not tracked"
fi

# Check for large files
echo ""
echo "4️⃣  Checking for large files..."
LARGE_FILES=$(find . -type f -size +10M ! -path "./.git/*" ! -path "./.venv/*" ! -path "./build/*")
if [ -n "$LARGE_FILES" ]; then
    echo "⚠️  Warning: Large files found:"
    echo "$LARGE_FILES"
else
    echo "✅ No large files found"
fi

# Summary
echo ""
echo "="*50
if [ $ISSUES_FOUND -eq 0 ]; then
    echo "✅ All security checks passed!"
    echo "🚀 Repository is ready for deployment"
    exit 0
else
    echo "❌ Security issues found!"
    echo "🔧 Please fix the issues above before deploying"
    exit 1
fi
