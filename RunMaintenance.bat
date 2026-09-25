@echo off
title Windows Maintenance Toolkit
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0MainMaintenance.ps1"
pause
