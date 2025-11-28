@echo off
setlocal
pushd "%~dp0.."

REM Load environment variables from .env file
if exist .env (
    echo Loading environment variables from .env...
    for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
        if not "%%a"=="" if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
        )
    )
) else (
    echo Warning: .env file not found. LLM features may not work.
)

call .venv\Scripts\activate
python ml_models\unified_api.py --debug --port 5002
popd
endlocal
