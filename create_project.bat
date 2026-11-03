@echo off
setlocal

if "%~1"=="" (
    echo Usage: create_project.bat ^<new_workspace_name^>
    echo Example: create_project.bat mecademic_client_line1
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

set "TEMPLATE_DIR=mecademic_demo_template"
set "TARGET_DIR=%~1"

if not exist "%TEMPLATE_DIR%" (
    echo ERROR: Template directory not found: "%TEMPLATE_DIR%"
    exit /b 1
)

if exist "%TARGET_DIR%" (
    echo ERROR: Target directory already exists: "%TARGET_DIR%"
    exit /b 1
)

echo Creating project workspace "%TARGET_DIR%" from "%TEMPLATE_DIR%"...
xcopy "%TEMPLATE_DIR%" "%TARGET_DIR%" /E /I /H /Y >nul
if errorlevel 1 (
    echo ERROR: Failed to copy template workspace.
    exit /b 1
)

echo.
echo Project created successfully: "%TARGET_DIR%"
echo.
echo Next steps:
echo 1. Edit "%TARGET_DIR%\config.yaml" and "%TARGET_DIR%\production_context.yaml"
echo 2. Customize "%TARGET_DIR%\manual_actions.py" and "%TARGET_DIR%\prod.py"
echo 3. Run: start_demo.bat "%TARGET_DIR%"
echo.
echo Optional dev reload mode:
echo set MECADEMIC_DEV_RELOAD=1
echo start_demo.bat "%TARGET_DIR%"

endlocal
