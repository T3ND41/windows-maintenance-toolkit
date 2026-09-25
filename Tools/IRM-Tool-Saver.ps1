<#
.SYNOPSIS
    IRM / Command Tool Saver - Separate Installed Tools Version

.DESCRIPTION
    Saves pasted IRM/IWR/PowerShell commands into:
    Tools\Installed-IRM-Tools

    This keeps installed IRM tools separate from normal custom tools.
#>

$SuitePath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ToolsFolder = Join-Path $SuitePath "Tools"
$InstalledIRMFolder = Join-Path $ToolsFolder "Installed-IRM-Tools"

if (-not (Test-Path $SuitePath)) {
    Write-Host "ERROR: MaintenanceSuite folder not found:" -ForegroundColor Red
    Write-Host $SuitePath -ForegroundColor Yellow
    pause
    exit
}

foreach ($Folder in @($ToolsFolder, $InstalledIRMFolder)) {
    if (-not (Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
    }
}

Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " IRM / COMMAND TOOL SAVER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "New IRM tools will be saved separately here:" -ForegroundColor Yellow
Write-Host $InstalledIRMFolder -ForegroundColor White
Write-Host ""
Write-Host "They will show under the GUI tab:" -ForegroundColor Yellow
Write-Host "Installed IRM Tools" -ForegroundColor White
Write-Host ""

Write-Host "Example IRM command:" -ForegroundColor Yellow
Write-Host 'irm "https://christitus.com/win" | iex' -ForegroundColor White
Write-Host ""

Write-Host "SECURITY WARNING:" -ForegroundColor Red
Write-Host "Only save commands from sources you fully trust." -ForegroundColor White
Write-Host "IRM + IEX downloads and runs online code on your computer." -ForegroundColor White
Write-Host ""

$ToolName = Read-Host "Enter tool name, e.g. ChrisTitus-WinUtil"

if ([string]::IsNullOrWhiteSpace($ToolName)) {
    Write-Host "Tool name cannot be empty. Cancelled." -ForegroundColor Red
    pause
    exit
}

Write-Host ""
$CommandToSave = Read-Host "Paste the IRM/IWR/PowerShell command"

if ([string]::IsNullOrWhiteSpace($CommandToSave)) {
    Write-Host "No command entered. Cancelled." -ForegroundColor Red
    pause
    exit
}

$SafeToolName = $ToolName -replace '[\\/:*?"<>|]', '-'
$SafeToolName = $SafeToolName.Trim()

if (-not $SafeToolName.ToLower().EndsWith(".ps1")) {
    $SafeToolName = "$SafeToolName.ps1"
}

$ToolPath = Join-Path $InstalledIRMFolder $SafeToolName

if (Test-Path $ToolPath) {
    Write-Host ""
    Write-Host "Installed IRM tool already exists:" -ForegroundColor Yellow
    Write-Host $ToolPath -ForegroundColor White
    $Overwrite = Read-Host "Overwrite it? (Y/N)"

    if ($Overwrite -ne "Y" -and $Overwrite -ne "y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        pause
        exit
    }
}

$EscapedCommand = $CommandToSave.Replace("'", "''")

$NewToolScript = @"
<#
.SYNOPSIS
    Installed IRM Tool: $ToolName

.DESCRIPTION
    This tool was created by IRM-Tool-Saver and stored separately from normal custom tools.

.SAVED COMMAND
    $CommandToSave
#>

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Running Installed IRM Tool: $ToolName" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Saved command:" -ForegroundColor Yellow
Write-Host '$EscapedCommand' -ForegroundColor White
Write-Host ""

Write-Host "WARNING:" -ForegroundColor Red
Write-Host "This command may download and run code from the internet." -ForegroundColor White
Write-Host "Only continue if you trust the source." -ForegroundColor White
Write-Host ""

`$Confirm = Read-Host "Run this installed IRM tool now? (Y/N)"

if (`$Confirm -ne "Y" -and `$Confirm -ne "y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    pause
    exit
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host ""
    Write-Host "Running command..." -ForegroundColor Green
    Write-Host ""
    `$SavedCommand = '$EscapedCommand'
    Invoke-Expression `$SavedCommand
}
catch {
    Write-Host ""
    Write-Host "Tool failed." -ForegroundColor Red
    Write-Host `$_ -ForegroundColor Red
}

pause
"@

try {
    $NewToolScript | Out-File -FilePath $ToolPath -Encoding utf8 -Force
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " INSTALLED IRM TOOL SAVED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Saved as:" -ForegroundColor Yellow
    Write-Host $ToolPath -ForegroundColor White
    Write-Host ""
    Write-Host "Open the GUI and go to Installed IRM Tools." -ForegroundColor Yellow
}
catch {
    Write-Host ""
    Write-Host "FAILED TO SAVE TOOL" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
}

pause
