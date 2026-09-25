<#
.SYNOPSIS
    Installed IRM Tool: IDM ACTIVATER

.DESCRIPTION
    This tool was created by IRM-Tool-Saver and stored separately from normal custom tools.

.SAVED COMMAND
    irm https://coporton.com/ias | iex
#>

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Running Installed IRM Tool: IDM ACTIVATER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Saved command:" -ForegroundColor Yellow
Write-Host 'irm https://coporton.com/ias | iex' -ForegroundColor White
Write-Host ""

Write-Host "WARNING:" -ForegroundColor Red
Write-Host "This command may download and run code from the internet." -ForegroundColor White
Write-Host "Only continue if you trust the source." -ForegroundColor White
Write-Host ""

$Confirm = Read-Host "Run this installed IRM tool now? (Y/N)"

if ($Confirm -ne "Y" -and $Confirm -ne "y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    pause
    exit
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host ""
    Write-Host "Running command..." -ForegroundColor Green
    Write-Host ""
    $SavedCommand = 'irm https://coporton.com/ias | iex'
    Invoke-Expression $SavedCommand
}
catch {
    Write-Host ""
    Write-Host "Tool failed." -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
}

pause
