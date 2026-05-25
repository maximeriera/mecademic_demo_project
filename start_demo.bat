@echo off
setlocal

set "VENV_DIR=mecademic_demo_app\.venv"
set "APP_DIR=mecademic_demo_app"
set "DEMO_DIR=mecademic_demo_lab_automation"

cd /d "%~dp0"

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

REM Start the application with the demo template as the workspace
echo Starting the application...
python "%APP_DIR%\app.py" --workspace "%DEMO_DIR%"

endlocal
