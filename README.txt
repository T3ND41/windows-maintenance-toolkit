Windows Maintenance Toolkit

A modular Windows maintenance, repair, diagnostic, and cleanup toolkit built with PowerShell.

This toolkit was prepared for the GitHub repository:


https://github.com/T3ND41/windows-maintenance-toolkit


#What This Toolkit Does

The toolkit provides a menu-based Windows maintenance system that can:

- Run DISM and SFC system repair commands
- Reset network settings
- Clean temporary files safely
- Optimize selected drives
- Scan and repair selected drives
- Generate battery, energy, driver, USB, and system information reports
- Load custom `.ps1` scripts from the `Tools` folder
- Check GitHub for updates
- Ask permission before downloading updates
- Create backups before replacing the main script
- Log maintenance activity into the `Logs` folder

#Folder Structure


MaintenanceSuite/
│
├── MainMaintenance.ps1
├── RunMaintenance.bat
├── Upload_To_GitHub.bat
├── README.md
├── LICENSE
│
├── Tools/
├── Logs/
├── Reports/
└── Backups/


#How To Run

1. Download or clone this repository.
2. Open the `MaintenanceSuite` folder.
3. Double-click:


RunMaintenance.bat


The launcher will run the PowerShell script with a temporary execution-policy bypass.

The toolkit will request Administrator permission when needed.

#GitHub Update Links

The main script is configured for:


$GitHubRawUrl      = "https://raw.githubusercontent.com/T3ND41/windows-maintenance-toolkit/main/MainMaintenance.ps1"
$GitHubApiToolsUrl = "https://api.github.com/repos/T3ND41/windows-maintenance-toolkit/contents/Tools"


When the toolkit starts, it checks GitHub for:

1. A newer version of `MainMaintenance.ps1`
2. New `.ps1` scripts inside the GitHub `Tools` folder

It will ask before downloading or installing anything.

#How To Upload To GitHub

First create a GitHub repository named:


windows-maintenance-toolkit


Then run:


Upload_To_GitHub.bat


You can also upload manually using:


git init
git add .
git commit -m "Initial Windows Maintenance Toolkit"
git branch -M main
git remote add origin https://github.com/T3ND41/windows-maintenance-toolkit.git
git push -u origin main


#How To Add New Tools

Add any PowerShell script into the `Tools` folder.

Example:


Tools/CleanBrowserCache.ps1
Tools/CheckDiskHealth.ps1
Tools/ResetPrinterSpooler.ps1


When you run the toolkit, those scripts will appear in the Custom Tools menu.

#Safety Notes

This toolkit is designed to avoid deleting normal personal files.

Safe cleanup is limited to temporary/cache-style locations such as:

- Temp folders
- Windows Temp
- Recycle Bin folders

It does **not** intentionally delete files from:

- Desktop
- Documents
- Downloads
- Pictures
- Videos
- Music

However, maintenance tools can still affect system settings. Review the script before running it on important computers.

#Recommended Usage

Use **Full Recommended Maintenance** for a normal repair and cleanup session.

Use selected drive cleanup or drive repair only when you know which drive you want to work on.

For serious disk problems, back up important files before running repair operations.

#Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or newer
- Administrator permission
- Internet connection for GitHub update checks

#License

This project is licensed under the MIT License.

See the `LICENSE` file for details.

#Disclaimer

This software is provided as-is. Use it at your own risk. Always back up important data before running system repair, disk repair, or cleanup tools.
