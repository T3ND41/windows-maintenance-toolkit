@echo off
title Fix Toolkit Git and Tool Menu
color 0A

set "SUITE=C:\Users\ARCHEIDIES\Downloads\Windows_Maintenance_Toolkit\MaintenanceSuite"
set "TOOLS=%SUITE%\Tools"
set "INSTALLERS=%SUITE%\Installers"

echo ============================================================
echo  Fixing Toolkit Git Uploads and Custom Tools Menu
echo ============================================================
echo.

cd /d "%SUITE%"

echo Creating Installers folder...
if not exist "%INSTALLERS%" mkdir "%INSTALLERS%"

echo.
echo Moving upgrade installer files out of Tools menu...
if exist "%TOOLS%\Upgrade-Separate-IRM-Tools.ps1" move "%TOOLS%\Upgrade-Separate-IRM-Tools.ps1" "%INSTALLERS%\Upgrade-Separate-IRM-Tools.ps1"
if exist "%TOOLS%\Run_Upgrade_Separate_IRM_Tools.bat" move "%TOOLS%\Run_Upgrade_Separate_IRM_Tools.bat" "%INSTALLERS%\Run_Upgrade_Separate_IRM_Tools.bat"

echo.
echo Creating safer .gitignore...
(
echo # Do not upload local logs, reports, and backups
echo Logs/*
echo Reports/*
echo Backups/*
echo.
echo # Keep folders if .gitkeep files exist
echo !Logs/.gitkeep
echo !Reports/.gitkeep
echo !Backups/.gitkeep
echo.
echo # Temporary files
echo *.log
echo *.tmp
echo *.bak
echo.
echo # Windows noise
echo Thumbs.db
echo Desktop.ini
echo.
echo # Optional local-only installer storage
echo Installers/*
echo !Installers/.gitkeep
) > ".gitignore"

echo.
echo Creating .gitkeep files so empty folders can stay...
if not exist "Logs" mkdir "Logs"
if not exist "Reports" mkdir "Reports"
if not exist "Backups" mkdir "Backups"
if not exist "Installers" mkdir "Installers"

type nul > "Logs\.gitkeep"
type nul > "Reports\.gitkeep"
type nul > "Backups\.gitkeep"
type nul > "Installers\.gitkeep"

echo.
echo Removing logs, reports, backups, and installers from Git tracking only...
git rm -r --cached Logs 2>nul
git rm -r --cached Reports 2>nul
git rm -r --cached Backups 2>nul
git rm -r --cached Installers 2>nul

echo.
echo Setting Git line ending handling...
git config core.autocrlf true

echo.
echo Adding cleaned files...
git add .

echo.
echo Committing cleanup...
git commit -m "Clean toolkit repo and separate installer files"

echo.
echo Pushing cleanup to GitHub...
git push -u origin main

echo.
echo ============================================================
echo  FIX COMPLETE
echo ============================================================
echo.
echo What changed:
echo - Logs will no longer upload.
echo - Backups will no longer upload.
echo - Reports will no longer upload.
echo - Upgrade installer files were moved out of Tools menu.
echo - Custom Tools menu should look cleaner.
echo.
echo Now restart your toolkit and check [14] Custom Tools.
echo.
pause