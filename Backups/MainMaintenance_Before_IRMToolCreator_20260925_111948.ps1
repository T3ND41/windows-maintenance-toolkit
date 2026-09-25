<#
.SYNOPSIS
    Modular Windows Maintenance Toolkit
.DESCRIPTION
    Ready-to-run Windows maintenance toolkit with:
    - Double-click BAT launcher support
    - Administrator elevation
    - GitHub self-update with permission
    - GitHub custom tools sync with permission
    - Daily logs
    - Reports folder
    - Backups before update
    - Safe cleanup options
    - System repair, network reset, drive scan, USB checks, driver reports
#>

# =========================
# ADMIN CHECK
# =========================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Host "Elevating privileges to Administrator..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# =========================
# CONFIGURATION
# =========================

$ScriptVersion = "1.0.0"

# GitHub repository settings for T3ND41/windows-maintenance-toolkit
$GitHubRawUrl      = "https://raw.githubusercontent.com/T3ND41/windows-maintenance-toolkit/main/MainMaintenance.ps1"
$GitHubApiToolsUrl = "https://api.github.com/repos/T3ND41/windows-maintenance-toolkit/contents/Tools"

$BaseFolder     = $PSScriptRoot
$ToolsFolder    = Join-Path $BaseFolder "Tools"
$LogsFolder     = Join-Path $BaseFolder "Logs"
$ReportsFolder  = Join-Path $BaseFolder "Reports"
$BackupsFolder  = Join-Path $BaseFolder "Backups"

foreach ($Folder in @($ToolsFolder, $LogsFolder, $ReportsFolder, $BackupsFolder)) {
    if (-not (Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder | Out-Null
    }
}

$LogFileName = "MaintenanceLog_$(Get-Date -Format 'yyyy-MM-dd').log"
$Global:LogFilePath = Join-Path $LogsFolder $LogFileName

# =========================
# LOGGING
# =========================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        [System.ConsoleColor]$Color = [System.ConsoleColor]::White
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Timestamp] [$Level] $Message"

    Write-Host $Message -ForegroundColor $Color

    try {
        Add-Content -Path $Global:LogFilePath -Value $Entry -ErrorAction Stop
    }
    catch {
        Write-Host "Could not write to log file: $_" -ForegroundColor Red
    }
}

function Pause-Tool {
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Invoke-MaintenanceCommand {
    param(
        [string]$TaskName,
        [scriptblock]$CommandBlock
    )

    Write-Log "--------------------------------------------------" "INFO" DarkGray
    Write-Log "Starting Task: $TaskName" "INFO" Cyan

    try {
        $Output = & $CommandBlock 2>&1

        foreach ($Line in $Output) {
            if ($Line -is [System.Management.Automation.ErrorRecord]) {
                Write-Log "  [ERROR OUTPUT] $Line" "ERROR" Red
            }
            else {
                Write-Log "  $Line" "INFO" Gray
            }
        }

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            Write-Log "Task '$TaskName' finished with exit code: $LASTEXITCODE" "WARN" Yellow
        }
        else {
            Write-Log "Task '$TaskName' completed." "SUCCESS" Green
        }
    }
    catch {
        Write-Log "Critical error while running '$TaskName': $_" "ERROR" Red
    }

    Write-Log "--------------------------------------------------" "INFO" DarkGray
}

# =========================
# GITHUB UPDATE SYSTEM
# =========================

function Sync-WithGitHub {
    Write-Log "Checking GitHub for main script updates..." "INFO" Cyan

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.Add("User-Agent", "PowerShell-Maintenance-Toolkit")

        $RemoteScriptContent = $WebClient.DownloadString($GitHubRawUrl)

        if ($RemoteScriptContent -match '\$ScriptVersion\s*=\s*"([^"]+)"') {
            $RemoteVersion = [version]$Matches[1]
            $CurrentVersion = [version]$ScriptVersion

            if ($RemoteVersion -gt $CurrentVersion) {
                Write-Host ""
                Write-Host "==================================================" -ForegroundColor Yellow
                Write-Host " NEW UPDATE AVAILABLE" -ForegroundColor Yellow
                Write-Host " Installed Version: $ScriptVersion" -ForegroundColor White
                Write-Host " Latest Version:    $RemoteVersion" -ForegroundColor Green
                Write-Host "==================================================" -ForegroundColor Yellow

                $Response = Read-Host "Download and install this update now? (Y/N)"

                if ($Response -eq "Y" -or $Response -eq "y") {
                    $BackupName = "MainMaintenance_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
                    $BackupPath = Join-Path $BackupsFolder $BackupName

                    Copy-Item -Path $PSCommandPath -Destination $BackupPath -Force
                    Write-Log "Backup created: $BackupPath" "SUCCESS" Green

                    $RemoteScriptContent | Out-File -FilePath $PSCommandPath -Encoding utf8 -Force
                    Write-Log "Main script updated successfully. Restarting..." "SUCCESS" Green

                    Start-Sleep -Seconds 2
                    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
                    exit
                }
                else {
                    Write-Log "Main script update skipped by user." "WARN" Yellow
                }
            }
            else {
                Write-Log "Main script is up to date. Version: $ScriptVersion" "SUCCESS" Green
            }
        }
        else {
            Write-Log "Could not detect remote script version." "WARN" Yellow
        }
    }
    catch {
        Write-Log "Could not check GitHub for main script updates: $_" "ERROR" Red
    }

    Write-Log "Checking GitHub for new custom tools..." "INFO" Cyan

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.Add("User-Agent", "PowerShell-Maintenance-Toolkit")

        $ApiResponse = $WebClient.DownloadString($GitHubApiToolsUrl) | ConvertFrom-Json
        $RemoteTools = $ApiResponse | Where-Object {
            $_.type -eq "file" -and $_.name -like "*.ps1"
        }

        foreach ($RemoteTool in $RemoteTools) {
            $LocalToolPath = Join-Path $ToolsFolder $RemoteTool.name

            if (-not (Test-Path $LocalToolPath)) {
                Write-Host ""
                Write-Host "New custom tool found: $($RemoteTool.name)" -ForegroundColor Yellow
                $ToolResponse = Read-Host "Download and add this tool to your local Tools folder? (Y/N)"

                if ($ToolResponse -eq "Y" -or $ToolResponse -eq "y") {
                    $ToolContent = $WebClient.DownloadString($RemoteTool.download_url)
                    $ToolContent | Out-File -FilePath $LocalToolPath -Encoding utf8 -Force
                    Write-Log "Downloaded custom tool: $($RemoteTool.name)" "SUCCESS" Green
                }
                else {
                    Write-Log "Skipped custom tool: $($RemoteTool.name)" "WARN" Yellow
                }
            }
        }

        Write-Log "Custom tools check complete." "SUCCESS" Green
    }
    catch {
        Write-Log "Could not check GitHub custom tools folder: $_" "ERROR" Red
    }
}

# =========================
# DRIVE SELECTION
# =========================

function Get-DriveChoice {
    $Drives = Get-PSDrive -PSProvider FileSystem | Where-Object {
        $_.Free -ne $null -and $_.Root -match "^[A-Z]:\\"
    }

    Write-Host ""
    Write-Host "Available Drives:" -ForegroundColor Cyan

    $Index = 1
    $Map = @{}

    foreach ($Drive in $Drives) {
        $UsedGB = [math]::Round(($Drive.Used / 1GB), 2)
        $FreeGB = [math]::Round(($Drive.Free / 1GB), 2)

        Write-Host "[$Index] $($Drive.Name):  Used: $UsedGB GB | Free: $FreeGB GB"
        $Map[$Index] = $Drive.Name
        $Index++
    }

    Write-Host "[A] All drives"
    Write-Host "[Q] Cancel"

    $Choice = Read-Host "Select drive"

    if ($Choice -eq "Q" -or $Choice -eq "q") {
        return $null
    }

    if ($Choice -eq "A" -or $Choice -eq "a") {
        return "ALL"
    }

    $Number = 0
    if ([int]::TryParse($Choice, [ref]$Number)) {
        if ($Map.ContainsKey($Number)) {
            return $Map[$Number]
        }
    }

    Write-Log "Invalid drive selection." "WARN" Yellow
    return $null
}

# =========================
# CORE MAINTENANCE TASKS
# =========================

function Run-SystemRepair {
    Write-Log "Running system repair: DISM then SFC." "INFO" Cyan

    Invoke-MaintenanceCommand "DISM CheckHealth" {
        DISM /Online /Cleanup-Image /CheckHealth
    }

    Invoke-MaintenanceCommand "DISM ScanHealth" {
        DISM /Online /Cleanup-Image /ScanHealth
    }

    Invoke-MaintenanceCommand "DISM RestoreHealth" {
        DISM /Online /Cleanup-Image /RestoreHealth
    }

    Invoke-MaintenanceCommand "System File Checker" {
        sfc /scannow
    }
}

function Run-NetworkReset {
    Write-Log "Running network reset tools." "INFO" Cyan

    Invoke-MaintenanceCommand "Flush DNS" {
        ipconfig /flushdns
    }

    Invoke-MaintenanceCommand "Release IP" {
        ipconfig /release
    }

    Invoke-MaintenanceCommand "Renew IP" {
        ipconfig /renew
    }

    Invoke-MaintenanceCommand "Reset Winsock" {
        netsh winsock reset
    }

    Invoke-MaintenanceCommand "Reset TCP/IP Stack" {
        netsh int ip reset
    }

    Write-Log "Network reset complete. A restart is recommended." "WARN" Yellow
}

function Run-DiskCleanupC {
    Write-Log "Running Windows Disk Cleanup for C: drive." "INFO" Cyan

    Invoke-MaintenanceCommand "Disk Cleanup" {
        cleanmgr /sagerun:1
    }

    Invoke-MaintenanceCommand "Optimize C Drive" {
        Optimize-Volume -DriveLetter C -Verbose
    }
}

function Run-SelectedDriveOptimization {
    $Drive = Get-DriveChoice

    if (-not $Drive) {
        return
    }

    if ($Drive -eq "ALL") {
        $DriveLetters = Get-PSDrive -PSProvider FileSystem | Where-Object {
            $_.Free -ne $null -and $_.Root -match "^[A-Z]:\\"
        } | Select-Object -ExpandProperty Name
    }
    else {
        $DriveLetters = @($Drive)
    }

    foreach ($Letter in $DriveLetters) {
        Invoke-MaintenanceCommand "Optimize Drive $Letter" {
            Optimize-Volume -DriveLetter $Letter -Verbose
        }
    }
}

function Run-DriveScan {
    $Drive = Get-DriveChoice

    if (-not $Drive) {
        return
    }

    if ($Drive -eq "ALL") {
        $DriveLetters = Get-PSDrive -PSProvider FileSystem | Where-Object {
            $_.Free -ne $null -and $_.Root -match "^[A-Z]:\\"
        } | Select-Object -ExpandProperty Name
    }
    else {
        $DriveLetters = @($Drive)
    }

    foreach ($Letter in $DriveLetters) {
        Invoke-MaintenanceCommand "Scan Drive $Letter" {
            Repair-Volume -DriveLetter $Letter -Scan
        }

        $Fix = Read-Host "Attempt repair on $Letter if problems were found? (Y/N)"

        if ($Fix -eq "Y" -or $Fix -eq "y") {
            Invoke-MaintenanceCommand "Repair Drive $Letter" {
                Repair-Volume -DriveLetter $Letter -OfflineScanAndFix
            }
        }
        else {
            Write-Log "Skipped repair for drive $Letter." "WARN" Yellow
        }
    }
}

# =========================
# SAFE CLEANUP
# =========================

function Clear-SafeTempFolder {
    param(
        [string]$PathToClean
    )

    if (-not (Test-Path $PathToClean)) {
        Write-Log "Path not found: $PathToClean" "WARN" Yellow
        return
    }

    Write-Log "Cleaning safe temporary files from: $PathToClean" "INFO" Cyan

    try {
        Get-ChildItem -Path $PathToClean -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

        Write-Log "Cleaned: $PathToClean" "SUCCESS" Green
    }
    catch {
        Write-Log "Could not clean $PathToClean : $_" "ERROR" Red
    }
}

function Run-SafeSelectedDriveCleanup {
    $Drive = Get-DriveChoice

    if (-not $Drive) {
        return
    }

    if ($Drive -eq "ALL") {
        $DriveLetters = Get-PSDrive -PSProvider FileSystem | Where-Object {
            $_.Free -ne $null -and $_.Root -match "^[A-Z]:\\"
        } | Select-Object -ExpandProperty Name
    }
    else {
        $DriveLetters = @($Drive)
    }

    foreach ($Letter in $DriveLetters) {
        Write-Host ""
        Write-Host "Safe cleanup for drive $Letter`: only temporary/cache folders will be targeted." -ForegroundColor Yellow
        Write-Host "This will NOT delete Documents, Downloads, Pictures, Videos, Desktop, or normal user files." -ForegroundColor Yellow

        $Confirm = Read-Host "Continue safe cleanup for drive $Letter? (Y/N)"

        if ($Confirm -ne "Y" -and $Confirm -ne "y") {
            Write-Log "Skipped safe cleanup for drive $Letter." "WARN" Yellow
            continue
        }

        $TempPaths = @(
            "$Letter`:Temp",
            "$Letter`:Windows\Temp",
            "$Letter`:\`$Recycle.Bin"
        )

        foreach ($TempPath in $TempPaths) {
            Clear-SafeTempFolder -PathToClean $TempPath
        }
    }
}

function Run-UserTempCleanup {
    Write-Log "Cleaning current user temporary folder." "INFO" Cyan

    Clear-SafeTempFolder -PathToClean $env:TEMP
}

# =========================
# REPORTS AND DIAGNOSTICS
# =========================

function Run-BatteryReport {
    $OutputPath = Join-Path $ReportsFolder "BatteryReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

    Invoke-MaintenanceCommand "Battery Report" {
        powercfg /batteryreport /output $OutputPath
    }

    Write-Log "Battery report saved to: $OutputPath" "SUCCESS" Green
    Start-Process $OutputPath
}

function Run-EnergyReport {
    $OutputPath = Join-Path $ReportsFolder "EnergyReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

    Invoke-MaintenanceCommand "Energy Report" {
        powercfg /energy /output $OutputPath
    }

    Write-Log "Energy report saved to: $OutputPath" "SUCCESS" Green
    Start-Process $OutputPath
}

function Run-DriverReport {
    $OutputPath = Join-Path $ReportsFolder "DriverReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    Invoke-MaintenanceCommand "Driver Report" {
        driverquery /v | Out-File -FilePath $OutputPath -Encoding utf8
    }

    Write-Log "Driver report saved to: $OutputPath" "SUCCESS" Green
    notepad $OutputPath
}

function Run-USBHealthCheck {
    $OutputPath = Join-Path $ReportsFolder "USBHealth_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    Write-Log "Checking USB devices and related Plug and Play status." "INFO" Cyan

    try {
        "USB HEALTH CHECK - $(Get-Date)" | Out-File $OutputPath -Encoding utf8
        "=====================================" | Out-File $OutputPath -Append

        Get-PnpDevice |
            Where-Object {
                $_.InstanceId -like "USB*" -or
                $_.Class -like "*USB*" -or
                $_.FriendlyName -like "*USB*"
            } |
            Format-Table -AutoSize |
            Out-String |
            Out-File $OutputPath -Append

        "`nDevices with problems:" | Out-File $OutputPath -Append

        Get-PnpDevice |
            Where-Object { $_.Status -ne "OK" } |
            Format-Table -AutoSize |
            Out-String |
            Out-File $OutputPath -Append

        Write-Log "USB health report saved to: $OutputPath" "SUCCESS" Green
        notepad $OutputPath
    }
    catch {
        Write-Log "USB health check failed: $_" "ERROR" Red
    }
}

function Run-SystemInfoReport {
    $OutputPath = Join-Path $ReportsFolder "SystemInfo_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    Invoke-MaintenanceCommand "System Info Report" {
        systeminfo | Out-File -FilePath $OutputPath -Encoding utf8
    }

    Write-Log "System info report saved to: $OutputPath" "SUCCESS" Green
    notepad $OutputPath
}

# =========================
# FULL RECOMMENDED MAINTENANCE
# =========================

function Run-FullRecommendedMaintenance {
    Write-Host ""
    Write-Host "This will run recommended maintenance:" -ForegroundColor Yellow
    Write-Host "- DISM + SFC"
    Write-Host "- User temp cleanup"
    Write-Host "- Disk cleanup"
    Write-Host "- C: optimization"
    Write-Host "- USB health report"
    Write-Host "- Driver report"
    Write-Host ""
    Write-Host "It will NOT delete personal files." -ForegroundColor Green

    $Confirm = Read-Host "Continue? (Y/N)"

    if ($Confirm -ne "Y" -and $Confirm -ne "y") {
        Write-Log "Full recommended maintenance cancelled." "WARN" Yellow
        return
    }

    Run-SystemRepair
    Run-UserTempCleanup
    Run-DiskCleanupC
    Run-USBHealthCheck
    Run-DriverReport

    Write-Log "Full recommended maintenance completed." "SUCCESS" Green
}

# =========================
# CUSTOM TOOLS MENU
# =========================

function Show-CustomTools {
    $CustomTools = Get-ChildItem -Path $ToolsFolder -Filter "*.ps1" -ErrorAction SilentlyContinue

    if (-not $CustomTools -or $CustomTools.Count -eq 0) {
        Write-Host ""
        Write-Host "No custom tools found in: $ToolsFolder" -ForegroundColor Yellow
        Pause-Tool
        return
    }

    while ($true) {
        Clear-Host
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host " CUSTOM TOOLS" -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan

        $Map = @{}
        $Index = 1

        foreach ($Tool in $CustomTools) {
            Write-Host "[$Index] $($Tool.BaseName)"
            $Map[$Index] = $Tool.FullName
            $Index++
        }

        Write-Host "[Q] Back"

        $Choice = Read-Host "Select custom tool"

        if ($Choice -eq "Q" -or $Choice -eq "q") {
            return
        }

        $Number = 0
        if ([int]::TryParse($Choice, [ref]$Number)) {
            if ($Map.ContainsKey($Number)) {
                $SelectedTool = $Map[$Number]

                Write-Log "Running custom tool: $SelectedTool" "INFO" Cyan

                Invoke-MaintenanceCommand "Custom Tool: $SelectedTool" {
                    & $SelectedTool
                }

                Pause-Tool
            }
            else {
                Write-Host "Invalid selection." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# =========================
# MAIN MENU
# =========================

function Show-MainMenu {
    Write-Log "=== Maintenance Session Started ===" "INFO" Green

    Sync-WithGitHub

    while ($true) {
        Clear-Host

        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host " WINDOWS MAINTENANCE TOOLKIT v$ScriptVersion" -ForegroundColor Cyan
        Write-Host " Logs: $Global:LogFilePath" -ForegroundColor Gray
        Write-Host "============================================================" -ForegroundColor Cyan

        Write-Host ""
        Write-Host "Recommended:" -ForegroundColor Yellow
        Write-Host " [1] Full Recommended Maintenance"

        Write-Host ""
        Write-Host "Repair & Restore:" -ForegroundColor Yellow
        Write-Host " [2] System Repair - DISM + SFC"
        Write-Host " [3] Network Reset"
        Write-Host " [4] Scan / Repair Selected Drive"

        Write-Host ""
        Write-Host "Cleanup & Optimization:" -ForegroundColor Yellow
        Write-Host " [5] Disk Cleanup + Optimize C:"
        Write-Host " [6] Optimize Selected Drive / All Drives"
        Write-Host " [7] Safe Cleanup Selected Drive / All Drives"
        Write-Host " [8] Clean Current User Temp Files"

        Write-Host ""
        Write-Host "Reports & Diagnostics:" -ForegroundColor Yellow
        Write-Host " [9] Battery Report"
        Write-Host " [10] Energy Report"
        Write-Host " [11] Driver Report"
        Write-Host " [12] USB Health Check"
        Write-Host " [13] System Info Report"

        Write-Host ""
        Write-Host "Tools & Management:" -ForegroundColor Yellow
        Write-Host " [14] Custom Tools"
        Write-Host " [15] Check GitHub Updates"
        Write-Host " [16] Open Logs Folder"
        Write-Host " [17] Open Reports Folder"
        Write-Host " [Q] Exit"

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan

        $Choice = Read-Host "Select option"

        switch ($Choice.ToUpper()) {
            "1"  { Run-FullRecommendedMaintenance; Pause-Tool }
            "2"  { Run-SystemRepair; Pause-Tool }
            "3"  { Run-NetworkReset; Pause-Tool }
            "4"  { Run-DriveScan; Pause-Tool }
            "5"  { Run-DiskCleanupC; Pause-Tool }
            "6"  { Run-SelectedDriveOptimization; Pause-Tool }
            "7"  { Run-SafeSelectedDriveCleanup; Pause-Tool }
            "8"  { Run-UserTempCleanup; Pause-Tool }
            "9"  { Run-BatteryReport; Pause-Tool }
            "10" { Run-EnergyReport; Pause-Tool }
            "11" { Run-DriverReport; Pause-Tool }
            "12" { Run-USBHealthCheck; Pause-Tool }
            "13" { Run-SystemInfoReport; Pause-Tool }
            "14" { Show-CustomTools }
            "15" { Sync-WithGitHub; Pause-Tool }
            "16" { Invoke-Item $LogsFolder }
            "17" { Invoke-Item $ReportsFolder }
            "Q"  {
                Write-Log "=== Maintenance Session Ended ===" "INFO" Green
                exit
            }
            default {
                Write-Host "Invalid option. Try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# =========================
# START
# =========================

Show-MainMenu
