@echo off
title Upload Windows Maintenance Toolkit to GitHub
color 0A

echo ============================================================
echo  Uploading Windows Maintenance Toolkit to GitHub
echo ============================================================
echo.

cd /d "C:\Users\ARCHEIDIES\Downloads\Windows_Maintenance_Toolkit\MaintenanceSuite"

echo Current folder:
cd
echo.

echo Checking Git...
git --version
if errorlevel 1 (
    echo.
    echo Git is still not detected.
    echo Close this window, open a new CMD, and try again.
    echo If it still fails, reinstall Git and select:
    echo "Git from the command line and also from 3rd-party software"
    pause
    exit /b
)

echo.
echo Initializing Git repo if needed...
if not exist ".git" (
    git init
)

echo.
echo Setting Git identity...
git config user.name "T3ND41"
git config user.email "T3ND41@users.noreply.github.com"

echo.
echo Setting branch to main...
git branch -M main

echo.
echo Removing old remote if it exists...
git remote remove origin 2>nul

echo.
echo Adding GitHub remote...
git remote add origin https://github.com/T3ND41/windows-maintenance-toolkit.git

echo.
echo Adding all files...
git add .

echo.
echo Committing files...
git commit -m "Upload Windows Maintenance Toolkit"

echo.
echo Pushing to GitHub...
git push -u origin main

echo.
echo ============================================================
echo  Upload complete.
echo  Now check your GitHub repo:
echo  https://github.com/T3ND41/windows-maintenance-toolkit
echo ============================================================
pause