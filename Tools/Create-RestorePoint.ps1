Write-Host "Creating a Windows restore point..." -ForegroundColor Cyan
try {
    Checkpoint-Computer -Description "Maintenance Toolkit Restore Point" -RestorePointType "MODIFY_SETTINGS"
    Write-Host "Restore point created successfully." -ForegroundColor Green
}
catch {
    Write-Host "Could not create restore point: $_" -ForegroundColor Red
    Write-Host "System Protection may be disabled on this PC." -ForegroundColor Yellow
}
