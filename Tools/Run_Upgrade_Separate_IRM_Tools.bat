@echo off
title Upgrade Separate IRM Tools
color 0A

set "PS1=%~dp0Upgrade-Separate-IRM-Tools.ps1"

if not exist "%PS1%" (
    echo ERROR: Could not find:
    echo %PS1%
    echo.
    pause
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"

pause
