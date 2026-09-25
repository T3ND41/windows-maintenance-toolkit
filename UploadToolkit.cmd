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
    echo Git is not installed or not found.
    echo Install Git for Windows first, then run this again.
    pause
    exit /b
)

echo.
echo Initializing Git repo if needed...
if not exist ".git" (
    git init
)

echo.
echo Setting branch to main...
git branch -M main

echo.
echo Removing old remote if it exists...
git remote remove origin 2>nul

echo.
echo Adding correct GitHub remote...
git remote add origin https://github.com/T3ND41/windows-maintenance-toolkit.git

echo.
echo Adding files...
git add .

echo.
echo Committing files...
git commit -m "Upload Windows Maintenance Toolkit"

echo.
echo Pushing to GitHub...
git push -u origin main

echo.
echo ============================================================
echo  Done. Now test option 15 in the toolkit again.
echo ============================================================
pause