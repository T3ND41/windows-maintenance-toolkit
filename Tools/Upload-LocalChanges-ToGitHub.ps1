<# 
.SYNOPSIS
    Upload local toolkit changes to GitHub.
#>

$RepoPath = "C:\Users\ARCHEIDIES\Downloads\Windows_Maintenance_Toolkit\MaintenanceSuite"
$RemoteUrl = "https://github.com/T3ND41/windows-maintenance-toolkit.git"
$Branch = "main"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Upload Local Toolkit Changes to GitHub" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $RepoPath)) {
    Write-Host "ERROR: Repo folder not found:" -ForegroundColor Red
    Write-Host $RepoPath -ForegroundColor Yellow
    pause
    exit
}

Set-Location $RepoPath

try {
    $GitVersion = git --version
    Write-Host "Git detected: $GitVersion" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Git is not detected." -ForegroundColor Red
    pause
    exit
}

if (-not (Test-Path ".git")) {
    Write-Host "This folder is not a Git repo. Initializing..." -ForegroundColor Yellow
    git init
}

git config user.name "T3ND41"
git config user.email "T3ND41@users.noreply.github.com"
git branch -M $Branch

$ExistingRemote = git remote get-url origin 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($ExistingRemote)) {
    git remote add origin $RemoteUrl
}
elseif ($ExistingRemote -ne $RemoteUrl) {
    git remote set-url origin $RemoteUrl
}

Write-Host ""
Write-Host "Checking local changes..." -ForegroundColor Cyan
$Status = git status --short

if ([string]::IsNullOrWhiteSpace($Status)) {
    Write-Host "No local changes found. Nothing to upload." -ForegroundColor Green
    pause
    exit
}

Write-Host "Changed files:" -ForegroundColor Yellow
git status --short
Write-Host ""

Write-Host "This will upload your local changes to GitHub." -ForegroundColor Yellow
$Confirm = Read-Host "Continue? ^(Y/N^)"

if ($Confirm -ne "Y" -and $Confirm -ne "y") {
    Write-Host "Upload cancelled." -ForegroundColor Yellow
    pause
    exit
}

$CommitMessage = Read-Host "Enter commit message, or press Enter for default"

if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
    $CommitMessage = "Update Windows Maintenance Toolkit"
}

Write-Host "Pulling latest GitHub changes first..." -ForegroundColor Cyan
git pull origin $Branch --allow-unrelated-histories --no-rebase

Write-Host "Adding files..." -ForegroundColor Cyan
git add .

Write-Host "Committing changes..." -ForegroundColor Cyan
git commit -m "$CommitMessage"

Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
git push -u origin $Branch

if ($LASTEXITCODE -eq 0) {
    Write-Host "Upload complete." -ForegroundColor Green
    Write-Host "https://github.com/T3ND41/windows-maintenance-toolkit" -ForegroundColor Green
} else {
    Write-Host "Push failed. Check message above." -ForegroundColor Red
}

pause
