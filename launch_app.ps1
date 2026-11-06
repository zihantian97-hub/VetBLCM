# 常规启动器：定位 Rscript，清理可能冲突的区域设置，再调用 scripts/launch.R。
param([string]$RscriptPath, [int]$Port = 7827, [switch]$NoBrowser)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
if (-not $RscriptPath) {
    $rCommand = Get-Command Rscript.exe -ErrorAction SilentlyContinue
    if ($rCommand) { $RscriptPath = $rCommand.Source }
}
if (-not $RscriptPath) {
    foreach ($registry in @('HKCU:\Software\R-core\R', 'HKLM:\Software\R-core\R')) {
        $rInstallation = (Get-ItemProperty -LiteralPath $registry -ErrorAction SilentlyContinue).InstallPath
        if ($rInstallation) {
            $candidate = Join-Path $rInstallation 'bin\Rscript.exe'
            if (Test-Path -LiteralPath $candidate) { $RscriptPath = $candidate; break }
        }
    }
}
if (-not $RscriptPath -or -not (Test-Path -LiteralPath $RscriptPath)) {
    Write-Host 'Rscript was not found. Install R, or run launch_app.ps1 -RscriptPath C:\your\R\bin\Rscript.exe'
    Read-Host 'Press Enter to close'
    exit 1
}
$env:LC_ALL = ''
$env:LC_CTYPE = ''
$env:LC_COLLATE = ''
$env:LC_MONETARY = ''
$env:LC_TIME = ''
$env:VETBLCM_PORT = [string]$Port
$env:VETBLCM_BROWSER = if ($NoBrowser) { 'false' } else { 'true' }
Write-Host "VetBLCM: http://127.0.0.1:$Port"
Write-Host 'Keep this console open. Ctrl+C stops the local app.'
& $RscriptPath --vanilla 'scripts\launch.R'
if ($LASTEXITCODE -ne 0) { Read-Host 'Startup failed; see README. Press Enter to close'; exit $LASTEXITCODE }
