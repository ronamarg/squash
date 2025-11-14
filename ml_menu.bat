@echo off
REM Quick access menu for ML models

:menu
cls
echo ============================================================
echo SQUASH ML MODELS - Quick Access Menu
echo ============================================================
echo.
echo 1. Skill Classifier (Random Forest)
echo 2. Code Similarity Scorer
echo 3. Code Corruptor (Deep Learning)
echo 4. View Directory Structure
echo 5. Open Documentation
echo 6. Exit
echo.
echo ============================================================
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto skill_classifier
if "%choice%"=="2" goto code_similarity
if "%choice%"=="3" goto code_corruptor
if "%choice%"=="4" goto directory
if "%choice%"=="5" goto docs
if "%choice%"=="6" goto end

echo Invalid choice. Please try again.
pause
goto menu

:skill_classifier
cls
echo ============================================================
echo SKILL CLASSIFIER
echo ============================================================
echo.
echo What would you like to do?
echo 1. Train model
echo 2. Open directory
echo 3. View README
echo 4. Back to main menu
echo.
set /p sc_choice="Enter choice: "

if "%sc_choice%"=="1" (
    cd ml_models\skill_classifier
    python train.py
    cd ..\..
    pause
    goto menu
)
if "%sc_choice%"=="2" (
    start explorer ml_models\skill_classifier
    goto menu
)
if "%sc_choice%"=="3" (
    start ml_models\skill_classifier\README.md
    goto menu
)
if "%sc_choice%"=="4" goto menu
goto skill_classifier

:code_similarity
cls
echo ============================================================
echo CODE SIMILARITY SCORER
echo ============================================================
echo.
echo What would you like to do?
echo 1. Start API server
echo 2. Run test
echo 3. Open directory
echo 4. View README
echo 5. Back to main menu
echo.
set /p cs_choice="Enter choice: "

if "%cs_choice%"=="1" (
    cd ml_models\code_similarity
    echo Starting API server...
    python api.py
    cd ..\..
    pause
    goto menu
)
if "%cs_choice%"=="2" (
    cd ml_models\code_similarity
    python scorer.py
    cd ..\..
    pause
    goto menu
)
if "%cs_choice%"=="3" (
    start explorer ml_models\code_similarity
    goto menu
)
if "%cs_choice%"=="4" (
    start ml_models\code_similarity\README.md
    goto menu
)
if "%cs_choice%"=="5" goto menu
goto code_similarity

:code_corruptor
cls
echo ============================================================
echo CODE CORRUPTOR (Deep Learning)
echo ============================================================
echo.
echo What would you like to do?
echo 1. Analyze dataset
echo 2. Train model (long process!)
echo 3. Run inference
echo 4. Start API server
echo 5. Evaluate model
echo 6. Open directory
echo 7. View README
echo 8. Back to main menu
echo.
set /p cc_choice="Enter choice: "

if "%cc_choice%"=="1" (
    cd ml_models\code_corruptor
    python analyze_data.py
    cd ..\..
    pause
    goto menu
)
if "%cc_choice%"=="2" (
    cd ml_models\code_corruptor
    echo WARNING: This will take several hours!
    pause
    python train.py
    cd ..\..
    pause
    goto menu
)
if "%cc_choice%"=="3" (
    cd ml_models\code_corruptor
    set /p code="Enter code to corrupt: "
    python infer.py --code "%code%"
    cd ..\..
    pause
    goto menu
)
if "%cc_choice%"=="4" (
    cd ml_models\code_corruptor
    echo Starting API server...
    python api.py
    cd ..\..
    pause
    goto menu
)
if "%cc_choice%"=="5" (
    cd ml_models\code_corruptor
    python evaluate.py
    cd ..\..
    pause
    goto menu
)
if "%cc_choice%"=="6" (
    start explorer ml_models\code_corruptor
    goto menu
)
if "%cc_choice%"=="7" (
    start ml_models\code_corruptor\README.md
    goto menu
)
if "%cc_choice%"=="8" goto menu
goto code_corruptor

:directory
cls
type DIRECTORY_TREE.txt
pause
goto menu

:docs
cls
echo ============================================================
echo DOCUMENTATION
echo ============================================================
echo.
echo 1. DIRECTORY_TREE.txt - Visual structure
echo 2. ML_ORGANIZATION.md - Organization guide
echo 3. ORGANIZATION_SUMMARY.md - What was done
echo 4. ml_models/README.md - Models overview
echo 5. CODE_CORRUPTION_GUIDE.md - DL guide
echo 6. QUICK_REFERENCE.txt - Quick reference
echo 7. Back to main menu
echo.
set /p doc_choice="Enter choice: "

if "%doc_choice%"=="1" start DIRECTORY_TREE.txt
if "%doc_choice%"=="2" start ML_ORGANIZATION.md
if "%doc_choice%"=="3" start ORGANIZATION_SUMMARY.md
if "%doc_choice%"=="4" start ml_models\README.md
if "%doc_choice%"=="5" start CODE_CORRUPTION_GUIDE.md
if "%doc_choice%"=="6" start QUICK_REFERENCE.txt
if "%doc_choice%"=="7" goto menu
goto docs

:end
echo.
echo Goodbye!
timeout /t 1 >nul
