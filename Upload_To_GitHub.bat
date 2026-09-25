@echo off
title Upload Windows Maintenance Toolkit to GitHub
cd /d "%~dp0"

echo ================================================
echo Uploading Windows Maintenance Toolkit to GitHub
echo Repo: https://github.com/T3ND41/windows-maintenance-toolkit
echo ================================================
echo.

git --version >nul 2>&1
if errorlevel 1 (
    echo Git is not installed or not found in PATH.
    echo Install Git for Windows first: https://git-scm.com/download/win
    pause
    exit /b
)

if not exist .git (
    git init
)

git add .
git commit -m "Initial Windows Maintenance Toolkit"
git branch -M main
git remote remove origin 2>nul
git remote add origin https://github.com/T3ND41/windows-maintenance-toolkit.git
git push -u origin main

echo.
echo Done. Check: https://github.com/T3ND41/windows-maintenance-toolkit
pause
