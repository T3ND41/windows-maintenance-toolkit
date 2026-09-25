<#
.SYNOPSIS
    Upgrade Windows Maintenance Toolkit to separate installed IRM tools.

.DESCRIPTION
    This upgrade does three things:
    1. Creates a separate folder:
       MaintenanceSuite\Tools\Installed-IRM-Tools

    2. Updates/creates:
       MaintenanceSuite\Tools\IRM-Tool-Saver.ps1

       The saver will now save new IRM tools into:
       Tools\Installed-IRM-Tools

    3. Updates MainMaintenance.ps1 to add a separate menu option:
       [19] Installed IRM Tools

    This keeps manually created custom tools separate from tools installed through IRM-Tool-Saver.
#>

$SuitePath = "C:\Users\ARCHEIDIES\Downloads\Windows_Maintenance_Toolkit\MaintenanceSuite"
$MainScript = Join-Path $SuitePath "MainMaintenance.ps1"
$ToolsFolder = Join-Path $SuitePath "Tools"
$InstalledIRMFolder = Join-Path $ToolsFolder "Installed-IRM-Tools"
$BackupsFolder = Join-Path $SuitePath "Backups"
$SaverPath = Join-Path $ToolsFolder "IRM-Tool-Saver.ps1"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Upgrade: Separate Installed IRM Tools" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $SuitePath)) {
    Write-Host "ERROR: MaintenanceSuite folder not found:" -ForegroundColor Red
    Write-Host $SuitePath -ForegroundColor Yellow
    pause
    exit
}

if (-not (Test-Path $MainScript)) {
    Write-Host "ERROR: MainMaintenance.ps1 not found:" -ForegroundColor Red
    Write-Host $MainScript -ForegroundColor Yellow
    pause
    exit
}

foreach ($Folder in @($ToolsFolder, $InstalledIRMFolder, $BackupsFolder)) {
    if (-not (Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
    }
}

$BackupPath = Join-Path $BackupsFolder "MainMaintenance_Before_Separate_IRM_Tools_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
Copy-Item $MainScript $BackupPath -Force

Write-Host "Backup created:" -ForegroundColor Green
Write-Host $BackupPath -ForegroundColor White
Write-Host ""

# -------------------------------------------------------------------
# Create upgraded IRM-Tool-Saver.ps1
# -------------------------------------------------------------------

$SaverCode = @'
<#
.SYNOPSIS
    IRM / Command Tool Saver - Separate Installed Tools Version

.DESCRIPTION
    Saves pasted IRM/IWR/PowerShell commands into:
    Tools\Installed-IRM-Tools

    This keeps installed IRM tools separate from normal custom tools.
#>

$SuitePath = "C:\Users\ARCHEIDIES\Downloads\Windows_Maintenance_Toolkit\MaintenanceSuite"
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
Write-Host "They will show under:" -ForegroundColor Yellow
Write-Host "[19] Installed IRM Tools" -ForegroundColor White
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
    Write-Host "To run it:" -ForegroundColor Yellow
    Write-Host "1. Go back to the main menu." -ForegroundColor White
    Write-Host "2. Open [19] Installed IRM Tools." -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "FAILED TO SAVE TOOL" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
}

pause
'@

$SaverCode | Out-File -FilePath $SaverPath -Encoding utf8 -Force
Write-Host "Updated IRM-Tool-Saver.ps1." -ForegroundColor Green
Write-Host $SaverPath -ForegroundColor White
Write-Host ""

# -------------------------------------------------------------------
# Patch MainMaintenance.ps1
# -------------------------------------------------------------------

$Content = Get-Content $MainScript -Raw

$InstalledFunction = @'

# =========================
# INSTALLED IRM TOOLS MENU
# =========================

function Show-InstalledIRMTools {
    $InstalledIRMFolder = Join-Path $ToolsFolder "Installed-IRM-Tools"

    if (-not (Test-Path $InstalledIRMFolder)) {
        New-Item -ItemType Directory -Path $InstalledIRMFolder -Force | Out-Null
    }

    while ($true) {
        Clear-Host
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host " INSTALLED IRM TOOLS" -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "These are tools saved using IRM-Tool-Saver." -ForegroundColor Yellow
        Write-Host "Folder: $InstalledIRMFolder" -ForegroundColor Gray
        Write-Host ""

        $InstalledTools = Get-ChildItem -Path $InstalledIRMFolder -Filter "*.ps1" -File -ErrorAction SilentlyContinue

        if (-not $InstalledTools -or $InstalledTools.Count -eq 0) {
            Write-Host "No installed IRM tools found yet." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "To add one:" -ForegroundColor White
            Write-Host "1. Go to [14] Custom Tools." -ForegroundColor White
            Write-Host "2. Run IRM-Tool-Saver." -ForegroundColor White
            Write-Host "3. Paste your IRM command and save it." -ForegroundColor White
            Write-Host ""
            Write-Host "[Q] Back"
            $EmptyChoice = Read-Host "Select option"
            if ($EmptyChoice -eq "Q" -or $EmptyChoice -eq "q") {
                return
            }
            continue
        }

        $Map = @{}
        $Index = 1

        foreach ($Tool in $InstalledTools) {
            Write-Host "[$Index] $($Tool.BaseName)"
            $Map[$Index] = $Tool.FullName
            $Index++
        }

        Write-Host ""
        Write-Host "[O] Open Installed IRM Tools Folder"
        Write-Host "[Q] Back"
        Write-Host ""

        $Choice = Read-Host "Select installed IRM tool"

        if ($Choice -eq "Q" -or $Choice -eq "q") {
            return
        }

        if ($Choice -eq "O" -or $Choice -eq "o") {
            Invoke-Item $InstalledIRMFolder
            continue
        }

        $Number = 0

        if ([int]::TryParse($Choice, [ref]$Number)) {
            if ($Map.ContainsKey($Number)) {
                $SelectedTool = $Map[$Number]

                if (Get-Command Invoke-MaintenanceCommand -ErrorAction SilentlyContinue) {
                    Invoke-MaintenanceCommand -TaskName "Installed IRM Tool: $([System.IO.Path]::GetFileNameWithoutExtension($SelectedTool))" -CommandBlock {
                        & $SelectedTool
                    }
                }
                else {
                    & $SelectedTool
                }

                Pause-Tool
            }
            else {
                Write-Host "Invalid selection." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        else {
            Write-Host "Invalid selection." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

'@

# Add function before Show-MainMenu
if ($Content -notmatch "function Show-InstalledIRMTools") {
    if ($Content -match "function Show-MainMenu") {
        $Content = $Content -replace "function Show-MainMenu", "$InstalledFunction`r`nfunction Show-MainMenu"
        Write-Host "Added Show-InstalledIRMTools function." -ForegroundColor Green
    }
    else {
        Write-Host "WARNING: Could not find function Show-MainMenu. Function not inserted." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Show-InstalledIRMTools function already exists." -ForegroundColor Yellow
}

# Add main menu display line
if ($Content -notmatch "\[19\] Installed IRM Tools") {
    $MenuInserted = $false

    $patterns = @(
        'Write-Host\s+" \[18\] Add IRM / Command Tool"',
        'Write-Host\s+" \[17\] Open Reports Folder"',
        'Write-Host\s+" \[14\] Custom Tools"'
    )

    foreach ($pattern in $patterns) {
        if (-not $MenuInserted -and $Content -match $pattern) {
            $Content = [regex]::Replace(
                $Content,
                $pattern,
                { param($m) $m.Value + "`r`n" + '        Write-Host " [19] Installed IRM Tools"' },
                1
            )
            $MenuInserted = $true
        }
    }

    if ($MenuInserted) {
        Write-Host "Added menu option [19] Installed IRM Tools." -ForegroundColor Green
    }
    else {
        Write-Host "WARNING: Could not insert [19] menu display line automatically." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Menu option [19] already exists." -ForegroundColor Yellow
}

# Add switch action
if ($Content -notmatch '"19"\s*\{\s*Show-InstalledIRMTools\s*\}') {
    $SwitchInserted = $false

    $switchPatterns = @(
        '"18"\s*\{\s*Add-IRMCommandTool\s*\}',
        '"17"\s*\{\s*Invoke-Item\s+\$ReportsFolder\s*\}',
        '"14"\s*\{\s*Show-CustomTools\s*\}'
    )

    foreach ($pattern in $switchPatterns) {
        if (-not $SwitchInserted -and $Content -match $pattern) {
            $Content = [regex]::Replace(
                $Content,
                $pattern,
                { param($m) $m.Value + "`r`n" + '            "19" { Show-InstalledIRMTools }' },
                1
            )
            $SwitchInserted = $true
        }
    }

    if ($SwitchInserted) {
        Write-Host "Added switch action for [19]." -ForegroundColor Green
    }
    else {
        Write-Host "WARNING: Could not insert switch action [19] automatically." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Switch action [19] already exists." -ForegroundColor Yellow
}

$Content | Out-File -FilePath $MainScript -Encoding utf8 -Force

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " UPGRADE COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "What changed:" -ForegroundColor Yellow
Write-Host "1. IRM-Tool-Saver now saves new IRM tools to:" -ForegroundColor White
Write-Host "   $InstalledIRMFolder" -ForegroundColor Cyan
Write-Host "2. Your main toolkit should now show:" -ForegroundColor White
Write-Host "   [19] Installed IRM Tools" -ForegroundColor Cyan
Write-Host "3. Normal custom tools remain under:" -ForegroundColor White
Write-Host "   [14] Custom Tools" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart RunMaintenance.bat" -ForegroundColor White
Write-Host "2. Use [14] Custom Tools > IRM-Tool-Saver to install tools" -ForegroundColor White
Write-Host "3. Use [19] Installed IRM Tools to run them separately" -ForegroundColor White
Write-Host ""

pause
