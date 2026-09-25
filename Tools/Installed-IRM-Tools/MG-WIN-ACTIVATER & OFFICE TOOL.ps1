<#
.SYNOPSIS
    Installed IRM Tool: MG-WIN-ACTIVATER & OFFICE TOOL

.DESCRIPTION
    This tool was created by IRM-Tool-Saver and stored separately from normal custom tools.

.SAVED COMMAND
    irm https://get.activated.win | iex
#>

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Running Installed IRM Tool: MG-WIN-ACTIVATER & OFFICE TOOL" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Saved command:" -ForegroundColor Yellow
Write-Host 'irm https://get.activated.win | iex' -ForegroundColor White
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

    $SavedCommand = 'irm https://get.activated.win | iex'
    Invoke-Expression $SavedCommand
}
catch {
    Write-Host ""
    Write-Host "Tool failed." -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
}

pause
