# VetBLCM 0.1.2 candidate changes

Updated 2026-09-22.

## Desktop shell

- Added `VetBLCM.exe`, a small native x64 Windows launcher. It has no packaged Python/Node runtime and no network client logic.
- Added `launch_desktop.ps1`. The launcher resolves its own installation directory, invokes this script silently, finds local R, starts `scripts/launch.R` with `VETBLCM_BROWSER=false`, waits for localhost readiness, and then opens the UI in Microsoft Edge or Google Chrome **App mode**.
- App mode removes normal browser chrome (address bar/tabs) while retaining the existing, already developed Shiny UI. Edge is preferred because it is normally present on supported Windows installations.
- A per-session browser profile is used so the desktop window can be tracked. Closing the desktop window stops the corresponding R backend and removes the temporary rendering profile.
- A named mutex prevents accidental duplicate desktop instances. Startup failures are shown in a Windows message box and R stdout/stderr are retained under `.vetblcm/logs/`.
- Existing `launch_app.bat` / `launch_app.ps1` remain as compatibility fallbacks.

## Statistical scope

No BLCM/JAGS statistical implementation was changed for 0.1.2. The three JAGS models, `R/00_*` through `R/08_*`, and preserved example posterior RDS files retain their 0.1.1 hashes. The 0.1.1 direct-filesystem export code remains the primary result-saving route.

## Acceptance status

The native launcher is a structurally valid 64-bit Windows GUI PE and was statically checked to contain no import table; it locates Windows APIs at runtime and only starts the bundled PowerShell launcher. This build environment cannot execute Windows GUI/R/JAGS, therefore actual double-click startup, Edge/Chrome App-mode lifecycle, 0.1.1 local export regression, and one complete desktop save operation remain **PENDING** on Windows R 4.4.1/JAGS 4.3.1. Candidate status is retained.
