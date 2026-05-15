@echo off
setlocal

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ========================================
    echo  FarmaBook Installer - Needs Admin Rights
    echo ========================================
    echo.
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

echo.
echo ========================================
echo  FarmaBook - Installing Certificate
echo ========================================
echo.

certutil -addstore -f Root farmabook.cer >nul 2>&1
if %errorLevel% equ 0 (
    echo  [OK] Certificate installed successfully.
) else (
    echo  [!] Certificate may already be installed. Continuing...
)

echo.
echo ========================================
echo  FarmaBook - Installing Application
echo ========================================
echo.

powershell -Command "Add-AppxPackage -Path '%~dp0farmabook_flutter.msix'"
if %errorLevel% equ 0 (
    echo.
    echo  [OK] FarmaBook installed successfully!
    echo  [OK] You can now launch it from the Start Menu.
) else (
    echo.
    echo  [!] Installation failed. Please try running the .msix file manually.
)

echo.
echo ========================================
pause
