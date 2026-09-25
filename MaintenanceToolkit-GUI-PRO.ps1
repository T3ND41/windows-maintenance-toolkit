<#
.SYNOPSIS
    Windows Maintenance Toolkit PRO GUI

.DESCRIPTION
    Button-based app-style launcher for the Windows Maintenance Toolkit.

    Adds:
    - Dashboard home screen
    - PC health overview
    - Full Performance Boost
    - Restore point safety button/prompt
    - GitHub Sync buttons
    - Normal custom tools
    - Separate Installed IRM Tools
    - Search/filter for tools
    - Log viewer
    - Reports and folder shortcuts

.NOTES
    Place this file in your MaintenanceSuite folder next to MainMaintenance.ps1.
    Launch with RunMaintenance-GUI-PRO.bat.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Script:SuitePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:MainScript = Join-Path $Script:SuitePath "MainMaintenance.ps1"
$Script:RunBat = Join-Path $Script:SuitePath "RunMaintenance.bat"
$Script:ToolsFolder = Join-Path $Script:SuitePath "Tools"
$Script:InstalledIRMFolder = Join-Path $Script:ToolsFolder "Installed-IRM-Tools"
$Script:LogsFolder = Join-Path $Script:SuitePath "Logs"
$Script:ReportsFolder = Join-Path $Script:SuitePath "Reports"
$Script:BackupsFolder = Join-Path $Script:SuitePath "Backups"

foreach ($folder in @($Script:ToolsFolder, $Script:InstalledIRMFolder, $Script:LogsFolder, $Script:ReportsFolder, $Script:BackupsFolder)) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

# -------------------------
# Shared helpers
# -------------------------

function Show-Info {
    param([string]$Message, [string]$Title = "Maintenance Toolkit")
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, "OK", "Information") | Out-Null
}

function Show-Warning {
    param([string]$Message, [string]$Title = "Warning")
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, "OK", "Warning") | Out-Null
}

function Confirm-Action {
    param([string]$Message, [string]$Title = "Confirm")
    $result = [System.Windows.Forms.MessageBox]::Show($Message, $Title, "YesNo", "Question")
    return ($result -eq [System.Windows.Forms.DialogResult]::Yes)
}

function Start-AdminPowerShellCommand {
    param([string]$Command)

    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Command))
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
}

function Start-AdminScript {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Show-Warning "Could not find:`n$Path"
        return
    }

    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Path`""
}

function Open-Folder {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }

    Invoke-Item $Path
}

function Add-Button {
    param(
        [System.Windows.Forms.Control]$Parent,
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$W = 210,
        [int]$H = 42,
        [scriptblock]$Action
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($W, $H)
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $button.FlatStyle = "Standard"
    $button.Add_Click($Action)
    $Parent.Controls.Add($button)
    return $button
}

function Add-Label {
    param(
        [System.Windows.Forms.Control]$Parent,
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$W = 700,
        [int]$H = 30,
        [int]$Size = 11,
        [string]$Style = "Regular"
    )

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($W, $H)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", $Size, [System.Drawing.FontStyle]::$Style)
    $Parent.Controls.Add($label)
    return $label
}

function Add-Card {
    param(
        [System.Windows.Forms.Control]$Parent,
        [string]$Title,
        [string]$Value,
        [int]$X,
        [int]$Y,
        [int]$W = 190,
        [int]$H = 75
    )

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size = New-Object System.Drawing.Size($W, $H)
    $panel.BorderStyle = "FixedSingle"
    $panel.BackColor = [System.Drawing.Color]::WhiteSmoke

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $Title
    $titleLabel.Location = New-Object System.Drawing.Point(10, 8)
    $titleLabel.Size = New-Object System.Drawing.Size($W - 20, 22)
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $panel.Controls.Add($titleLabel)

    $valueLabel = New-Object System.Windows.Forms.Label
    $valueLabel.Text = $Value
    $valueLabel.Location = New-Object System.Drawing.Point(10, 35)
    $valueLabel.Size = New-Object System.Drawing.Size($W - 20, 26)
    $valueLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $panel.Controls.Add($valueLabel)

    $Parent.Controls.Add($panel)
    return $valueLabel
}

function Get-AdminStatus {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            return "Admin"
        }
        return "Not Admin"
    }
    catch {
        return "Unknown"
    }
}

function Get-InternetStatus {
    try {
        $result = Test-Connection -ComputerName "github.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($result) { return "Connected" }
        return "Offline"
    }
    catch {
        return "Unknown"
    }
}

function Get-CDriveFree {
    try {
        $drive = Get-PSDrive C -ErrorAction Stop
        return ([math]::Round($drive.Free / 1GB, 1)).ToString() + " GB free"
    }
    catch {
        return "Unknown"
    }
}

function Get-WindowsVersionText {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        return "$($os.Caption)"
    }
    catch {
        return "Windows"
    }
}

function Get-ToolCount {
    param([string]$Folder)

    if (-not (Test-Path $Folder)) { return 0 }
    return @(Get-ChildItem -Path $Folder -Filter "*.ps1" -File -ErrorAction SilentlyContinue).Count
}

function Get-LastLogText {
    if (-not (Test-Path $Script:LogsFolder)) { return "None" }
    $latest = Get-ChildItem -Path $Script:LogsFolder -Filter "*.log" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        return $latest.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
    }
    return "None"
}

function Refresh-ToolList {
    param(
        [System.Windows.Forms.ListBox]$ListBox,
        [string]$Folder,
        [string]$SearchText = ""
    )

    $ListBox.Items.Clear()
    $ListBox.DisplayMember = "Name"
    $ListBox.ValueMember = "FullName"

    if (-not (Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
    }

    $tools = Get-ChildItem -Path $Folder -Filter "*.ps1" -File -ErrorAction SilentlyContinue | Sort-Object BaseName

    if (-not [string]::IsNullOrWhiteSpace($SearchText)) {
        $tools = $tools | Where-Object { $_.BaseName -like "*$SearchText*" }
    }

    foreach ($tool in $tools) {
        $item = New-Object PSObject -Property @{
            Name = $tool.BaseName
            FullName = $tool.FullName
        }
        [void]$ListBox.Items.Add($item)
    }
}

function Get-SelectedToolPath {
    param([System.Windows.Forms.ListBox]$ListBox)

    if (-not $ListBox.SelectedItem) { return $null }
    return $ListBox.SelectedItem.FullName
}

function Create-RestorePoint-GUI {
    if (-not (Confirm-Action "Create a Windows restore point now?`nThis is recommended before running debloaters, IRM tools, or major repair tasks." "Create Restore Point")) {
        return
    }

    Start-AdminPowerShellCommand @"
Write-Host 'Creating restore point...' -ForegroundColor Cyan
try {
    Checkpoint-Computer -Description 'Before Maintenance Toolkit Changes' -RestorePointType 'MODIFY_SETTINGS'
    Write-Host 'Restore point created successfully.' -ForegroundColor Green
}
catch {
    Write-Host 'Could not create restore point.' -ForegroundColor Red
    Write-Host `$_.Exception.Message -ForegroundColor Red
    Write-Host ''
    Write-Host 'Tip: System Protection may be disabled on this PC.' -ForegroundColor Yellow
}
pause
"@
}

function Run-PerformanceBoost {
    if (-not (Confirm-Action "Run Full Performance Boost?`n`nThis will:`n- Clean user temp files`n- Clean Windows temp files`n- Empty recycle bin`n- Flush DNS`n- Optimize C drive`n- Create a startup-app report`n`nIt will not intentionally delete personal files." "Full Performance Boost")) {
        return
    }

    $createRestore = Confirm-Action "Create a restore point first?`nRecommended before performance changes." "Safety First"

    $restoreBlock = ""
    if ($createRestore) {
        $restoreBlock = @"
try {
    Write-Host 'Creating restore point...' -ForegroundColor Cyan
    Checkpoint-Computer -Description 'Before Full Performance Boost' -RestorePointType 'MODIFY_SETTINGS'
    Write-Host 'Restore point created.' -ForegroundColor Green
}
catch {
    Write-Host 'Restore point could not be created. Continuing...' -ForegroundColor Yellow
}
"@
    }

    $report = Join-Path $Script:ReportsFolder ("PerformanceBoost_StartupApps_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

    Start-AdminPowerShellCommand @"
$restoreBlock

Write-Host 'Cleaning user temp files...' -ForegroundColor Cyan
Get-ChildItem -Path `$env:TEMP -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host 'Cleaning Windows temp files...' -ForegroundColor Cyan
Get-ChildItem -Path 'C:\Windows\Temp' -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host 'Emptying recycle bin...' -ForegroundColor Cyan
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

Write-Host 'Flushing DNS...' -ForegroundColor Cyan
ipconfig /flushdns

Write-Host 'Optimizing C drive...' -ForegroundColor Cyan
Optimize-Volume -DriveLetter C -Verbose

Write-Host 'Creating startup apps report...' -ForegroundColor Cyan
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User | Format-List | Out-File -FilePath "$report" -Encoding utf8

Write-Host ''
Write-Host 'Full Performance Boost complete.' -ForegroundColor Green
Write-Host 'Startup report saved to:' -ForegroundColor Yellow
Write-Host "$report"
pause
"@
}

function Run-GitHubUploadTool {
    $tool = Join-Path $Script:ToolsFolder "Upload-LocalChanges-ToGitHub.ps1"
    if (Test-Path $tool) {
        Start-AdminScript $tool
    }
    else {
        Show-Warning "Upload-LocalChanges-ToGitHub.ps1 was not found in the Tools folder."
    }
}

# -------------------------
# Main form
# -------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Maintenance Toolkit PRO"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1000, 700)
$form.MinimumSize = New-Object System.Drawing.Size(1000, 700)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$header = New-Object System.Windows.Forms.Label
$header.Text = "Windows Maintenance Toolkit PRO"
$header.Font = New-Object System.Drawing.Font("Segoe UI", 19, [System.Drawing.FontStyle]::Bold)
$header.Location = New-Object System.Drawing.Point(20, 15)
$header.Size = New-Object System.Drawing.Size(650, 40)
$form.Controls.Add($header)

$sub = New-Object System.Windows.Forms.Label
$sub.Text = "Dashboard, performance boost, reports, custom tools, IRM tools, GitHub sync, and logs."
$sub.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$sub.Location = New-Object System.Drawing.Point(23, 55)
$sub.Size = New-Object System.Drawing.Size(900, 25)
$form.Controls.Add($sub)

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(20, 90)
$tabs.Size = New-Object System.Drawing.Size(940, 540)
$form.Controls.Add($tabs)

$tabDashboard = New-Object System.Windows.Forms.TabPage
$tabDashboard.Text = "Dashboard"
$tabs.Controls.Add($tabDashboard)

$tabPerformance = New-Object System.Windows.Forms.TabPage
$tabPerformance.Text = "Performance"
$tabs.Controls.Add($tabPerformance)

$tabReports = New-Object System.Windows.Forms.TabPage
$tabReports.Text = "Reports"
$tabs.Controls.Add($tabReports)

$tabCustom = New-Object System.Windows.Forms.TabPage
$tabCustom.Text = "Custom Tools"
$tabs.Controls.Add($tabCustom)

$tabIRM = New-Object System.Windows.Forms.TabPage
$tabIRM.Text = "Installed IRM Tools"
$tabs.Controls.Add($tabIRM)

$tabGithub = New-Object System.Windows.Forms.TabPage
$tabGithub.Text = "GitHub Sync"
$tabs.Controls.Add($tabGithub)

$tabLogs = New-Object System.Windows.Forms.TabPage
$tabLogs.Text = "Logs"
$tabs.Controls.Add($tabLogs)

$tabFolders = New-Object System.Windows.Forms.TabPage
$tabFolders.Text = "Folders"
$tabs.Controls.Add($tabFolders)

# -------------------------
# Dashboard tab
# -------------------------

Add-Label $tabDashboard "System Dashboard" 20 20 500 30 14 "Bold" | Out-Null

$cardWindows = Add-Card $tabDashboard "Windows" (Get-WindowsVersionText) 20 65 280 80
$cardAdmin = Add-Card $tabDashboard "Admin Status" (Get-AdminStatus) 320 65 180 80
$cardInternet = Add-Card $tabDashboard "Internet" (Get-InternetStatus) 520 65 180 80
$cardDrive = Add-Card $tabDashboard "C Drive" (Get-CDriveFree) 720 65 180 80

$cardTools = Add-Card $tabDashboard "Custom Tools" (Get-ToolCount $Script:ToolsFolder) 20 165 180 80
$cardIRM = Add-Card $tabDashboard "Installed IRM Tools" (Get-ToolCount $Script:InstalledIRMFolder) 220 165 180 80
$cardLogs = Add-Card $tabDashboard "Latest Log" (Get-LastLogText) 420 165 220 80
$cardSuite = Add-Card $tabDashboard "Toolkit Folder" "MaintenanceSuite" 660 165 240 80

Add-Label $tabDashboard "Quick Actions" 20 280 500 30 13 "Bold" | Out-Null

Add-Button $tabDashboard "Full Performance Boost" 20 320 220 45 {
    Run-PerformanceBoost
} | Out-Null

Add-Button $tabDashboard "Create Restore Point" 260 320 220 45 {
    Create-RestorePoint-GUI
} | Out-Null

Add-Button $tabDashboard "Open Console Toolkit" 500 320 220 45 {
    if (Test-Path $Script:RunBat) {
        Start-Process $Script:RunBat -Verb RunAs
    }
    else {
        Start-AdminScript $Script:MainScript
    }
} | Out-Null

Add-Button $tabDashboard "Refresh Dashboard" 740 320 160 45 {
    $cardWindows.Text = Get-WindowsVersionText
    $cardAdmin.Text = Get-AdminStatus
    $cardInternet.Text = Get-InternetStatus
    $cardDrive.Text = Get-CDriveFree
    $cardTools.Text = (Get-ToolCount $Script:ToolsFolder).ToString()
    $cardIRM.Text = (Get-ToolCount $Script:InstalledIRMFolder).ToString()
    $cardLogs.Text = Get-LastLogText
} | Out-Null

Add-Label $tabDashboard "Recommended: create a restore point before running debloaters or IRM tools." 20 400 820 30 10 "Regular" | Out-Null

# -------------------------
# Performance tab
# -------------------------

Add-Label $tabPerformance "Performance and Repair" 20 20 500 30 14 "Bold" | Out-Null
Add-Label $tabPerformance "Safe performance tasks. These avoid deleting personal files." 20 50 800 25 10 "Regular" | Out-Null

Add-Button $tabPerformance "Full Performance Boost" 20 90 260 45 {
    Run-PerformanceBoost
} | Out-Null

Add-Button $tabPerformance "System Repair: DISM + SFC" 310 90 260 45 {
    if (Confirm-Action "Run DISM RestoreHealth and SFC scan now?`nThis may take a long time.") {
        Start-AdminPowerShellCommand @"
Write-Host 'Running DISM RestoreHealth...' -ForegroundColor Cyan
DISM /Online /Cleanup-Image /RestoreHealth
Write-Host ''
Write-Host 'Running SFC scan...' -ForegroundColor Cyan
sfc /scannow
Write-Host ''
pause
"@
    }
} | Out-Null

Add-Button $tabPerformance "Network Reset" 600 90 260 45 {
    if (Confirm-Action "Reset DNS, Winsock, and TCP/IP?`nA restart is recommended after this.") {
        Start-AdminPowerShellCommand @"
Write-Host 'Flushing DNS...' -ForegroundColor Cyan
ipconfig /flushdns
Write-Host 'Resetting Winsock...' -ForegroundColor Cyan
netsh winsock reset
Write-Host 'Resetting TCP/IP...' -ForegroundColor Cyan
netsh int ip reset
Write-Host ''
Write-Host 'Done. Restart your PC if network problems continue.' -ForegroundColor Green
pause
"@
    }
} | Out-Null

Add-Button $tabPerformance "Clean User Temp Files" 20 155 260 45 {
    if (Confirm-Action "Clean current user temporary files?") {
        Start-AdminPowerShellCommand @"
Write-Host 'Cleaning user temp folder...' -ForegroundColor Cyan
Get-ChildItem -Path `$env:TEMP -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Done.' -ForegroundColor Green
pause
"@
    }
} | Out-Null

Add-Button $tabPerformance "Optimize C Drive" 310 155 260 45 {
    if (Confirm-Action "Optimize C: drive now?") {
        Start-AdminPowerShellCommand @"
Write-Host 'Optimizing C: drive...' -ForegroundColor Cyan
Optimize-Volume -DriveLetter C -Verbose
Write-Host 'Done.' -ForegroundColor Green
pause
"@
    }
} | Out-Null

Add-Button $tabPerformance "Startup Apps Report" 600 155 260 45 {
    $out = Join-Path $Script:ReportsFolder ("StartupApps_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")
    Start-AdminPowerShellCommand @"
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User | Format-List | Out-File -FilePath "$out" -Encoding utf8
notepad "$out"
pause
"@
} | Out-Null

Add-Button $tabPerformance "Create Restore Point" 20 220 260 45 {
    Create-RestorePoint-GUI
} | Out-Null

Add-Button $tabPerformance "Open Original Console Toolkit" 310 220 260 45 {
    if (Test-Path $Script:RunBat) {
        Start-Process $Script:RunBat -Verb RunAs
    }
    else {
        Start-AdminScript $Script:MainScript
    }
} | Out-Null

Add-Label $tabPerformance "Advanced drive repair and selected-drive cleanup remain available in the original console toolkit." 20 310 850 30 10 "Regular" | Out-Null

# -------------------------
# Reports tab
# -------------------------

Add-Label $tabReports "Reports and Diagnostics" 20 20 500 30 14 "Bold" | Out-Null

Add-Button $tabReports "Battery Report" 20 70 260 45 {
    $out = Join-Path $Script:ReportsFolder ("BatteryReport_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".html")
    Start-AdminPowerShellCommand @"
powercfg /batteryreport /output "$out"
Start-Process "$out"
pause
"@
} | Out-Null

Add-Button $tabReports "Energy Report" 310 70 260 45 {
    $out = Join-Path $Script:ReportsFolder ("EnergyReport_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".html")
    Start-AdminPowerShellCommand @"
powercfg /energy /output "$out"
Start-Process "$out"
pause
"@
} | Out-Null

Add-Button $tabReports "Driver Report" 600 70 260 45 {
    $out = Join-Path $Script:ReportsFolder ("DriverReport_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")
    Start-AdminPowerShellCommand @"
driverquery /v | Out-File -FilePath "$out" -Encoding utf8
notepad "$out"
pause
"@
} | Out-Null

Add-Button $tabReports "USB Device Report" 20 135 260 45 {
    $out = Join-Path $Script:ReportsFolder ("USBHealth_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")
    Start-AdminPowerShellCommand @"
'USB HEALTH CHECK - ' + (Get-Date) | Out-File "$out" -Encoding utf8
'=====================================' | Out-File "$out" -Append
Get-PnpDevice | Where-Object { `$_.InstanceId -like 'USB*' -or `$_.Class -like '*USB*' -or `$_.FriendlyName -like '*USB*' } | Format-Table -AutoSize | Out-String | Out-File "$out" -Append
notepad "$out"
pause
"@
} | Out-Null

Add-Button $tabReports "System Info Report" 310 135 260 45 {
    $out = Join-Path $Script:ReportsFolder ("SystemInfo_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")
    Start-AdminPowerShellCommand @"
systeminfo | Out-File -FilePath "$out" -Encoding utf8
notepad "$out"
pause
"@
} | Out-Null

Add-Button $tabReports "Open Reports Folder" 600 135 260 45 {
    Open-Folder $Script:ReportsFolder
} | Out-Null

# -------------------------
# Custom tools tab
# -------------------------

Add-Label $tabCustom "Normal Custom Tools" 20 20 500 30 14 "Bold" | Out-Null
Add-Label $tabCustom "Search and run normal .ps1 tools saved directly inside the Tools folder." 20 50 780 25 10 "Regular" | Out-Null

$txtCustomSearch = New-Object System.Windows.Forms.TextBox
$txtCustomSearch.Location = New-Object System.Drawing.Point(20, 82)
$txtCustomSearch.Size = New-Object System.Drawing.Size(540, 28)
$txtCustomSearch.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$tabCustom.Controls.Add($txtCustomSearch)

$listCustom = New-Object System.Windows.Forms.ListBox
$listCustom.Location = New-Object System.Drawing.Point(20, 120)
$listCustom.Size = New-Object System.Drawing.Size(540, 310)
$listCustom.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$tabCustom.Controls.Add($listCustom)

$txtCustomSearch.Add_TextChanged({
    Refresh-ToolList $listCustom $Script:ToolsFolder $txtCustomSearch.Text
})

Add-Button $tabCustom "Refresh List" 590 120 220 40 {
    Refresh-ToolList $listCustom $Script:ToolsFolder $txtCustomSearch.Text
} | Out-Null

Add-Button $tabCustom "Run Selected Tool" 590 175 220 40 {
    $selected = Get-SelectedToolPath $listCustom
    if (-not $selected) {
        Show-Warning "Select a tool first."
        return
    }
    Start-AdminScript $selected
} | Out-Null

Add-Button $tabCustom "Open Tools Folder" 590 230 220 40 {
    Open-Folder $Script:ToolsFolder
} | Out-Null

Add-Button $tabCustom "Run IRM Tool Saver" 590 285 220 40 {
    $saver = Join-Path $Script:ToolsFolder "IRM-Tool-Saver.ps1"
    if (Test-Path $saver) {
        Start-AdminScript $saver
    }
    else {
        Show-Warning "IRM-Tool-Saver.ps1 was not found in Tools folder."
    }
} | Out-Null

Refresh-ToolList $listCustom $Script:ToolsFolder

# -------------------------
# IRM tools tab
# -------------------------

Add-Label $tabIRM "Installed IRM Tools" 20 20 500 30 14 "Bold" | Out-Null
Add-Label $tabIRM "Search and run tools saved by IRM-Tool-Saver inside Tools\Installed-IRM-Tools." 20 50 830 25 10 "Regular" | Out-Null

$txtIRMSearch = New-Object System.Windows.Forms.TextBox
$txtIRMSearch.Location = New-Object System.Drawing.Point(20, 82)
$txtIRMSearch.Size = New-Object System.Drawing.Size(540, 28)
$txtIRMSearch.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$tabIRM.Controls.Add($txtIRMSearch)

$listIRM = New-Object System.Windows.Forms.ListBox
$listIRM.Location = New-Object System.Drawing.Point(20, 120)
$listIRM.Size = New-Object System.Drawing.Size(540, 310)
$listIRM.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$tabIRM.Controls.Add($listIRM)

$txtIRMSearch.Add_TextChanged({
    Refresh-ToolList $listIRM $Script:InstalledIRMFolder $txtIRMSearch.Text
})

Add-Button $tabIRM "Refresh IRM List" 590 120 220 40 {
    Refresh-ToolList $listIRM $Script:InstalledIRMFolder $txtIRMSearch.Text
} | Out-Null

Add-Button $tabIRM "Run Selected IRM Tool" 590 175 220 40 {
    $selected = Get-SelectedToolPath $listIRM
    if (-not $selected) {
        Show-Warning "Select an installed IRM tool first."
        return
    }

    if (Confirm-Action "Create a restore point before running this installed IRM tool?`nRecommended for debloaters and system tweak tools." "Safety First") {
        Create-RestorePoint-GUI
    }

    Start-AdminScript $selected
} | Out-Null

Add-Button $tabIRM "Create New IRM Tool" 590 230 220 40 {
    $saver = Join-Path $Script:ToolsFolder "IRM-Tool-Saver.ps1"
    if (Test-Path $saver) {
        Start-AdminScript $saver
    }
    else {
        Show-Warning "IRM-Tool-Saver.ps1 was not found in Tools folder."
    }
} | Out-Null

Add-Button $tabIRM "Open IRM Tools Folder" 590 285 220 40 {
    Open-Folder $Script:InstalledIRMFolder
} | Out-Null

Refresh-ToolList $listIRM $Script:InstalledIRMFolder

# -------------------------
# GitHub tab
# -------------------------

Add-Label $tabGithub "GitHub Sync" 20 20 500 30 14 "Bold" | Out-Null
Add-Label $tabGithub "Use these to update from GitHub or upload your local toolkit changes." 20 50 800 25 10 "Regular" | Out-Null

Add-Button $tabGithub "Check Updates From GitHub" 20 90 270 45 {
    Show-Info "This opens the original console toolkit.`nChoose option 15 to check GitHub updates."
    if (Test-Path $Script:RunBat) {
        Start-Process $Script:RunBat -Verb RunAs
    }
    else {
        Start-AdminScript $Script:MainScript
    }
} | Out-Null

Add-Button $tabGithub "Upload Local Changes to GitHub" 320 90 270 45 {
    Run-GitHubUploadTool
} | Out-Null

Add-Button $tabGithub "Open GitHub Repo" 620 90 220 45 {
    Start-Process "https://github.com/T3ND41/windows-maintenance-toolkit"
} | Out-Null

Add-Button $tabGithub "Open Tools Folder" 20 155 270 45 {
    Open-Folder $Script:ToolsFolder
} | Out-Null

Add-Button $tabGithub "Open Installed IRM Folder" 320 155 270 45 {
    Open-Folder $Script:InstalledIRMFolder
} | Out-Null

Add-Label $tabGithub "Reminder: logs, reports, and backups should stay ignored by Git. Do not upload private logs." 20 240 830 30 10 "Regular" | Out-Null

# -------------------------
# Logs tab
# -------------------------

Add-Label $tabLogs "Log Viewer" 20 20 500 30 14 "Bold" | Out-Null

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 65)
$txtLog.Size = New-Object System.Drawing.Size(680, 390)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Both"
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.ReadOnly = $true
$tabLogs.Controls.Add($txtLog)

function Load-LatestLog {
    if (-not (Test-Path $Script:LogsFolder)) {
        $txtLog.Text = "Logs folder not found."
        return
    }

    $latest = Get-ChildItem -Path $Script:LogsFolder -Filter "*.log" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $latest) {
        $txtLog.Text = "No log files found yet."
        return
    }

    try {
        $txtLog.Text = Get-Content $latest.FullName -Raw -ErrorAction Stop
    }
    catch {
        $txtLog.Text = "Could not read log file: $($latest.FullName)"
    }
}

Add-Button $tabLogs "Load Latest Log" 730 65 170 40 {
    Load-LatestLog
} | Out-Null

Add-Button $tabLogs "Open Logs Folder" 730 120 170 40 {
    Open-Folder $Script:LogsFolder
} | Out-Null

Add-Button $tabLogs "Clear Log Viewer" 730 175 170 40 {
    $txtLog.Text = ""
} | Out-Null

Load-LatestLog

# -------------------------
# Folders tab
# -------------------------

Add-Label $tabFolders "Toolkit Folders" 20 20 500 30 14 "Bold" | Out-Null

Add-Button $tabFolders "Open MaintenanceSuite" 20 70 260 45 {
    Open-Folder $Script:SuitePath
} | Out-Null

Add-Button $tabFolders "Open Tools" 310 70 260 45 {
    Open-Folder $Script:ToolsFolder
} | Out-Null

Add-Button $tabFolders "Open Installed IRM Tools" 600 70 260 45 {
    Open-Folder $Script:InstalledIRMFolder
} | Out-Null

Add-Button $tabFolders "Open Logs" 20 135 260 45 {
    Open-Folder $Script:LogsFolder
} | Out-Null

Add-Button $tabFolders "Open Reports" 310 135 260 45 {
    Open-Folder $Script:ReportsFolder
} | Out-Null

Add-Button $tabFolders "Open Backups" 600 135 260 45 {
    Open-Folder $Script:BackupsFolder
} | Out-Null

Add-Button $tabFolders "Open MainMaintenance.ps1" 20 220 260 45 {
    if (Test-Path $Script:MainScript) {
        notepad $Script:MainScript
    }
    else {
        Show-Warning "MainMaintenance.ps1 not found."
    }
} | Out-Null

Add-Button $tabFolders "Exit App" 310 220 260 45 {
    $form.Close()
} | Out-Null

# Footer
$footer = New-Object System.Windows.Forms.Label
$footer.Text = "Suite: $Script:SuitePath"
$footer.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$footer.Location = New-Object System.Drawing.Point(20, 635)
$footer.Size = New-Object System.Drawing.Size(900, 22)
$form.Controls.Add($footer)

[void]$form.ShowDialog()
