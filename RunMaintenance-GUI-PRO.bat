@echo off
title Windows Maintenance Toolkit PRO GUI
cd /d "%~dp0"

if not exist "%~dp0MaintenanceToolkit-GUI-PRO.ps1" (
    echo ERROR: MaintenanceToolkit-GUI-PRO.ps1 was not found in this folder.
    echo Put this BAT file and MaintenanceToolkit-GUI-PRO.ps1 inside your MaintenanceSuite folder.
    echo.
    pause
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0MaintenanceToolkit-GUI-PRO.ps1"
pause
