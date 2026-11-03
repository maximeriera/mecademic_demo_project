@echo off
setlocal

set "VENV_DIR=mecademic_demo_app\.venv"
set "APP_DIR=mecademic_demo_app"
set "DEFAULT_WORKSPACE=mecademic_demo_template"
set "WORKSPACE_DIR=%~1"

if "%WORKSPACE_DIR%"=="" (
    set "WORKSPACE_DIR=%DEFAULT_WORKSPACE%"
)

set "DEV_RELOAD=%MECADEMIC_DEV_RELOAD%"
if "%DEV_RELOAD%"=="" (
    set "DEV_RELOAD=0"
)

cd /d "%~dp0"

if not exist "%WORKSPACE_DIR%" (
    echo ERROR: Workspace directory not found: "%WORKSPACE_DIR%"
    echo Usage: start_demo.bat [workspace_dir]
    echo Example: start_demo.bat mecademic_demo_template
    exit /b 1
)

REM Check if the virtual environment exists, create if not
if not exist "%VENV_DIR%\Scripts\activate.bat" (
    echo Virtual environment not found. Creating one...
    python -m venv "%VENV_DIR%"
)

REM Activate the virtual environment
echo Activating virtual environment...
call "%VENV_DIR%\Scripts\activate.bat"

REM Install requirements
echo Installing requirements...
pip install -r "%APP_DIR%\requirements.txt"

REM Set PYTHONPATH to include the app directory
set "PYTHONPATH=%~dp0%APP_DIR%"

REM Start the application with selected workspace
echo Starting the application...
echo Workspace: "%WORKSPACE_DIR%"
if "%DEV_RELOAD%"=="1" (
    echo Dev reload mode: ENABLED
    python "%APP_DIR%\app.py" --workspace "%WORKSPACE_DIR%" --dev-reload
) else (
    echo Dev reload mode: disabled
    python "%APP_DIR%\app.py" --workspace "%WORKSPACE_DIR%"
)

endlocal
