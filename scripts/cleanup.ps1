# Clean Repository for Deployment
# SAFE MODE: Shows what will be deleted and asks for confirmation
# Removes unnecessary files, test scripts, and development artifacts

Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Repository Cleanup Tool (SAFE MODE)" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

$itemsToRemove = @()

# Define items to check for removal
$checkList = @(
    @{Path="check_snippets.py"; Desc="Test script"; Safe=$true},
    @{Path="check_intermediate.py"; Desc="Test script"; Safe=$true},
    @{Path="test_llm.py"; Desc="Test script"; Safe=$true},
    @{Path="ml_models\test_run_snippets.py"; Desc="Test script"; Safe=$true},
    @{Path="ml_models\code_snippets_0_200.py"; Desc="Dev snippet file"; Safe=$true},
    @{Path="ml_models\code_snippets_200_500.py"; Desc="Dev snippet file"; Safe=$true},
    @{Path="ml_models\code_snippets_500_700.py"; Desc="Dev snippet file"; Safe=$true},
    @{Path="ml_models\code_snippets_700_1000.py"; Desc="Dev snippet file"; Safe=$true},
    @{Path="ml_models\code_corruptor\archive"; Desc="Archive folder"; Safe=$true},
    @{Path="drive-download-20251107T015907Z-1-001"; Desc="Old download folder"; Safe=$true},
    @{Path="ml_models\__pycache__"; Desc="Python cache"; Safe=$true},
    @{Path="ml_models\code_corruptor\__pycache__"; Desc="Python cache"; Safe=$true},
    @{Path="ml_models\code_similarity\__pycache__"; Desc="Python cache"; Safe=$true},
    @{Path="ml_models\skill_classifier\__pycache__"; Desc="Python cache"; Safe=$true},
    @{Path="ml_models\shared\__pycache__"; Desc="Python cache"; Safe=$true},
    @{Path="docs\DIRECTORY_TREE.txt"; Desc="Outdated doc"; Safe=$true},
    @{Path="docs\QUICK_REFERENCE.txt"; Desc="Redundant doc"; Safe=$true},
    @{Path="docs\ML_PERFORMANCE.md"; Desc="Replaced by ml_Performance_Metrics.md"; Safe=$true},
    @{Path="ENV_SETUP.md"; Desc="Covered in DEPLOYMENT.md"; Safe=$true},
    @{Path="README-DEV.md"; Desc="Merged into README"; Safe=$true},
    @{Path="ml_menu.bat"; Desc="Old dev script"; Safe=$true},
    @{Path="ml_models\start_api.bat"; Desc="Use npm start instead"; Safe=$true}
)

# PROTECTED: Critical files that should NEVER be deleted
$protectedPaths = @(
    "ml_models\unified_api.py",
    "ml_models\code_corruptor\revertV3.py",
    "ml_models\code_corruptor\infer.py",
    "ml_models\code_corruptor\code_corruptor_model_final",
    "ml_models\skill_classifier\rf_model.joblib",
    "lib\",
    "pubspec.yaml",
    "requirements.txt",
    "Dockerfile",
    "docker-compose.yml",
    ".gitignore",
    ".env.example",
    "firebase.json"
)

Write-Host "Scanning for files to clean..." -ForegroundColor Yellow
Write-Host ""

# Check which items exist
foreach ($item in $checkList) {
    if (Test-Path $item.Path) {
        $size = ""
        if (Test-Path $item.Path -PathType Leaf) {
            $sizeBytes = (Get-Item $item.Path).Length
            $size = " ($([math]::Round($sizeBytes/1KB, 2)) KB)"
        } else {
            $size = " (folder)"
        }
        $itemsToRemove += @{Path=$item.Path; Desc=$item.Desc; Size=$size}
        Write-Host "  [FOUND] $($item.Path)$size - $($item.Desc)" -ForegroundColor Cyan
    }
}

if ($itemsToRemove.Count -eq 0) {
    Write-Host ""
    Write-Host "✓ Repository is already clean! No files to remove." -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Yellow
Write-Host "SAFETY CHECK" -ForegroundColor Yellow
Write-Host ("=" * 60) -ForegroundColor Yellow
Write-Host "Found $($itemsToRemove.Count) items to remove." -ForegroundColor White
Write-Host ""
Write-Host "The following will be DELETED:" -ForegroundColor Red
foreach ($item in $itemsToRemove) {
    Write-Host "  • $($item.Path)$($item.Size) - $($item.Desc)" -ForegroundColor White
}
Write-Host ""
Write-Host "PROTECTED files (will NOT be touched):" -ForegroundColor Green
$protectedPaths | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor DarkGreen }
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Yellow

# Ask for confirmation
Write-Host ""
$confirmation = Read-Host "Proceed with deletion? Type 'YES' to confirm, anything else to cancel"

if ($confirmation -ne "YES") {
    Write-Host ""
    Write-Host "✗ Cleanup cancelled by user. No files were deleted." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Proceeding with cleanup..." -ForegroundColor Yellow
Write-Host ""

$cleaned = 0
$errors = 0

# Function to safely remove items
function Remove-SafelyItem {
    param($Path, $Description)
    
    try {
        Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
        Write-Host "✓ Removed: $Description" -ForegroundColor Green
        return 1
    } catch {
        Write-Host "✗ Failed to remove: $Description - $_" -ForegroundColor Red
        return 0
    }
}

# Remove each item that was confirmed
foreach ($item in $itemsToRemove) {
    $result = Remove-SafelyItem $item.Path "$($item.Path) - $($item.Desc)"
    if ($result -eq 1) {
        $cleaned++
    } else {
        $errors++
    }
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Cleanup Summary" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "✓ Cleaned: $cleaned items" -ForegroundColor Green

if ($errors -gt 0) {
    Write-Host "✗ Errors: $errors items" -ForegroundColor Red
}

Write-Host ""
Write-Host "Repository is now clean for deployment!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review changes: git status" -ForegroundColor White
Write-Host "2. Commit cleanup: git add -A && git commit -m 'Clean repository for deployment'" -ForegroundColor White
Write-Host "3. Deploy using DEPLOYMENT.md guide" -ForegroundColor White
Write-Host ""
