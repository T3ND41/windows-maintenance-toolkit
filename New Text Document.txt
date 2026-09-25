@echo off
title Create Upload Local Changes Tool
color 0A

set "TOOLS_FOLDER=C:\Users\ARCHEIDIES\Downloads\Windows_Maintenance_Toolkit\MaintenanceSuite\Tools"
set "TOOL_FILE=%TOOLS_FOLDER%\Upload-LocalChanges-ToGitHub.ps1"

echo ============================================================
echo  Creating Upload Local Changes to GitHub Tool
echo ============================================================
echo.

if not exist "%TOOLS_FOLDER%" (
    echo Tools folder not found. Creating it...
    mkdir "%TOOLS_FOLDER%"
)

echo Creating:
echo %TOOL_FILE%
echo.

(
echo ^<# 
echo .SYNOPSIS
echo     Upload local toolkit changes to GitHub.
echo #^>
echo.
echo $RepoPath = "C:\Users\ARCHEIDIES\Downloads\Windows_Maintenance_Toolkit\MaintenanceSuite"
echo $RemoteUrl = "https://github.com/T3ND41/windows-maintenance-toolkit.git"
echo $Branch = "main"
echo.
echo Write-Host "============================================================" -ForegroundColor Cyan
echo Write-Host " Upload Local Toolkit Changes to GitHub" -ForegroundColor Cyan
echo Write-Host "============================================================" -ForegroundColor Cyan
echo Write-Host ""
echo.
echo if ^(-not ^(Test-Path $RepoPath^)^) {
echo     Write-Host "ERROR: Repo folder not found:" -ForegroundColor Red
echo     Write-Host $RepoPath -ForegroundColor Yellow
echo     pause
echo     exit
echo }
echo.
echo Set-Location $RepoPath
echo.
echo try {
echo     $GitVersion = git --version
echo     Write-Host "Git detected: $GitVersion" -ForegroundColor Green
echo }
echo catch {
echo     Write-Host "ERROR: Git is not detected." -ForegroundColor Red
echo     pause
echo     exit
echo }
echo.
echo if ^(-not ^(Test-Path ".git"^)^) {
echo     Write-Host "This folder is not a Git repo. Initializing..." -ForegroundColor Yellow
echo     git init
echo }
echo.
echo git config user.name "T3ND41"
echo git config user.email "T3ND41@users.noreply.github.com"
echo git branch -M $Branch
echo.
echo $ExistingRemote = git remote get-url origin 2^>$null
echo.
echo if ^($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace^($ExistingRemote^)^) {
echo     git remote add origin $RemoteUrl
echo }
echo elseif ^($ExistingRemote -ne $RemoteUrl^) {
echo     git remote set-url origin $RemoteUrl
echo }
echo.
echo Write-Host ""
echo Write-Host "Checking local changes..." -ForegroundColor Cyan
echo $Status = git status --short
echo.
echo if ^([string]::IsNullOrWhiteSpace^($Status^)^) {
echo     Write-Host "No local changes found. Nothing to upload." -ForegroundColor Green
echo     pause
echo     exit
echo }
echo.
echo Write-Host "Changed files:" -ForegroundColor Yellow
echo git status --short
echo Write-Host ""
echo.
echo Write-Host "This will upload your local changes to GitHub." -ForegroundColor Yellow
echo $Confirm = Read-Host "Continue? ^(Y/N^)"
echo.
echo if ^($Confirm -ne "Y" -and $Confirm -ne "y"^) {
echo     Write-Host "Upload cancelled." -ForegroundColor Yellow
echo     pause
echo     exit
echo }
echo.
echo $CommitMessage = Read-Host "Enter commit message, or press Enter for default"
echo.
echo if ^([string]::IsNullOrWhiteSpace^($CommitMessage^)^) {
echo     $CommitMessage = "Update Windows Maintenance Toolkit"
echo }
echo.
echo Write-Host "Pulling latest GitHub changes first..." -ForegroundColor Cyan
echo git pull origin $Branch --allow-unrelated-histories --no-rebase
echo.
echo Write-Host "Adding files..." -ForegroundColor Cyan
echo git add .
echo.
echo Write-Host "Committing changes..." -ForegroundColor Cyan
echo git commit -m "$CommitMessage"
echo.
echo Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
echo git push -u origin $Branch
echo.
echo if ^($LASTEXITCODE -eq 0^) {
echo     Write-Host "Upload complete." -ForegroundColor Green
echo     Write-Host "https://github.com/T3ND41/windows-maintenance-toolkit" -ForegroundColor Green
echo } else {
echo     Write-Host "Push failed. Check message above." -ForegroundColor Red
echo }
echo.
echo pause
) > "%TOOL_FILE%"

echo Done.
echo File created successfully:
echo %TOOL_FILE%
echo.

pause