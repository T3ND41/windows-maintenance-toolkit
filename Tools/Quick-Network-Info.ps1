<#
Example custom tool.
Shows quick network information.
#>

Write-Host "Quick Network Information" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
ipconfig /all
Write-Host ""
Write-Host "Testing internet connectivity..." -ForegroundColor Yellow
Test-Connection 8.8.8.8 -Count 4
