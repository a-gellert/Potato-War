@echo off
setlocal EnableDelayedExpansion

cd /d "%~dp0\.."

set "INPUT_FILE="

if exist "google-services.json" (
    set "INPUT_FILE=google-services.json"
) else if exist "tools\google-services.json" (
    set "INPUT_FILE=tools\google-services.json"
) else if not "%~1"=="" (
    if exist "%~1" set "INPUT_FILE=%~1"
)

if not defined INPUT_FILE (
    echo [ERROR] google-services.json was not found!
    echo Please place your google-services.json file into the project root directory:
    echo   %CD%\google-services.json
    echo and run this script again.
    pause
    exit /b 1
)

echo [INFO] Found Firebase configuration: %INPUT_FILE%
echo [INFO] Converting to Android XML resources...

if not exist "res\android\res\values" mkdir "res\android\res\values"

tools\generate_xml_from_google_services_json.exe -i "%INPUT_FILE%" -o "res\android\res\values\google-services.xml" -p com.turnbased.artillery.potato.war

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Converted successfully!
    echo Generated: res\android\res\values\google-services.xml
) else (
    echo [WARNING] Retrying without package flag filter...
    tools\generate_xml_from_google_services_json.exe -i "%INPUT_FILE%" -o "res\android\res\values\google-services.xml"
    if !ERRORLEVEL! EQU 0 (
        echo [SUCCESS] Converted successfully!
        echo Generated: res\android\res\values\google-services.xml
    ) else (
        echo [ERROR] Conversion failed!
    )
)

echo.
pause
