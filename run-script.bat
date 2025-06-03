@echo off
:: Enable extensions and set current directory to script location
setlocal enableextensions
cd /d "%~dp0"

:: Check for admin rights by trying to list session info
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    :: Not running as admin, relaunch batch as admin
    powershell -Command "Start-Process -FilePath '%~f0' -Verb runAs"
    exit /b
)

:: Running as admin, run the PowerShell script with ExecutionPolicy bypass
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0script.ps1"

pause
