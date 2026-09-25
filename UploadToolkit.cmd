@echo off
title Fix GitHub Push and Upload Toolkit
color 0A

echo ============================================================
echo  Fixing GitHub push rejection and uploading toolkit
echo ============================================================
echo.

cd /d "C:\Users\ARCHEIDIES\Downloads\Windows_Maintenance_Toolkit\MaintenanceSuite"

echo Current folder:
cd
echo.

echo Checking Git...
git --version
if errorlevel 1 (
    echo Git is not detected.
    pause
    exit /b
)

echo.
echo Setting Git identity...
git config user.name "T3ND41"
git config user.email "T3ND41@users.noreply.github.com"

echo.
echo Making sure branch is main...
git branch -M main

echo.
echo Making sure remote is correct...
git remote remove origin 2>nul
git remote add origin https://github.com/T3ND41/windows-maintenance-toolkit.git

echo.
echo Pulling existing GitHub files first...
git pull origin main --allow-unrelated-histories --no-rebase

echo.
echo Adding toolkit files...
git add .

echo.
echo Committing changes...
git commit -m "Upload Windows Maintenance Toolkit"

echo.
echo Pushing to GitHub...
git push -u origin main

echo.
echo ============================================================
echo  Finished.
echo  Now check:
echo  https://github.com/T3ND41/windows-maintenance-toolkit
echo ============================================================
pause