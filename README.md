# Windows Maintenance Toolkit

A modular PowerShell toolkit for common Windows maintenance, repair, cleanup, diagnostics and reporting workflows.

> **Project goal:** reduce repetitive technician work by bringing frequently used servicing tasks into one guided, reusable toolkit.

## The problem

Routine Windows support often means switching between commands, utilities and one-off scripts. That makes common maintenance harder to repeat consistently and increases the chance of skipping a useful diagnostic step.

## The solution

Windows Maintenance Toolkit groups practical servicing workflows behind a menu-driven PowerShell interface.

### Core capabilities

- DISM and SFC system-repair workflows
- Network reset and troubleshooting actions
- Temporary/cache cleanup
- Selected-drive checks and repair workflows
- Battery, energy, driver, USB and system-information reports
- Maintenance logs and report output
- Backup behavior before selected updates
- GitHub update checks
- Extensible custom PowerShell tools from the `Tools` directory
- GUI and launcher experiments for easier technician use

## Why it is useful

The project is designed around **repeatability and clarity**. A technician can move through common actions from one toolkit instead of reconstructing the same servicing workflow every time.

## Safety approach

The toolkit is intended to avoid normal personal files during cleanup. Cleanup targets temporary/cache-style locations rather than user folders such as Documents, Pictures or Downloads.

Disk repair and system servicing can still affect a machine. Back up important data before repair operations and review the script before using it in critical environments.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or newer
- Administrator privileges for operations that require them
- Internet access only when using GitHub-backed update features

## Run

1. Clone or download the repository.
2. Review the scripts before use.
3. Launch the provided maintenance launcher or run the main PowerShell script from an elevated PowerShell session when required.

Primary script:

```text
MainMaintenance.ps1
```

## Project structure

```text
windows-maintenance-toolkit/
├── MainMaintenance.ps1
├── MaintenanceToolkit-GUI-PRO.ps1
├── RunMaintenance.bat
├── RunMaintenance-GUI-PRO.bat
├── Tools/
├── Logs/
├── Reports/
├── Backups/
└── README.md
```

## Design principles

- Prefer understandable technician workflows over hidden automation.
- Ask before operations that can materially change a system.
- Keep maintenance output reviewable through logs and reports.
- Make the toolkit extensible rather than hard-coding every future utility into one file.
- Improve from real failure cases found during testing.

## Current roadmap

- Consolidate legacy and experimental launcher paths.
- Standardize the UI and menu structure.
- Strengthen drive-protection states and operator warnings.
- Add clearer release/version management.
- Expand testing around failure states and unsupported configurations.
- Keep documentation aligned with the current build.

## Portfolio case study

The project is also documented as a problem-solving case study in the T3ND41 portfolio:

**https://T3ND41.github.io/portfolio/projects/windows-maintenance.html**

## License

See the repository's `LICENSE` file.

## Disclaimer

This project is provided as-is. Windows repair and disk-maintenance commands can change system state. Review operations before use and keep current backups of important data.
