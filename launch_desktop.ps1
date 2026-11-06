# 桌面启动逻辑：定位 R、选择本地端口、启动本地 Shiny 并打开浏览器。
﻿param([int]$PreferredPort = 7827)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

function Show-VetBLCMMessage([string]$Message, [string]$Title = 'VetBLCM') {
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show($Message, $Title, 'OK', 'Information') | Out-Null
    } catch {
        # Last-resort fallback if the GUI assembly is unavailable.
        try { (New-Object -ComObject WScript.Shell).Popup($Message, 0, $Title, 0x40) | Out-Null } catch {}
    }
}

function Find-Rscript {
    $cmd = Get-Command Rscript.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $keys = @(
        'HKCU:\Software\R-core\R',
        'HKLM:\Software\R-core\R',
        'HKCU:\Software\WOW6432Node\R-core\R',
        'HKLM:\Software\WOW6432Node\R-core\R'
    )
    foreach ($key in $keys) {
        try { $install = (Get-ItemProperty -LiteralPath $key -ErrorAction Stop).InstallPath } catch { $install = $null }
        if ($install) {
            foreach ($candidate in @((Join-Path $install 'bin\Rscript.exe'), (Join-Path $install 'bin\x64\Rscript.exe'))) {
                if (Test-Path -LiteralPath $candidate) { return $candidate }
            }
        }
    }
    return $null
}

function Test-PortFree([int]$Port) {
    $listener = $null
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start(); return $true
    } catch { return $false }
    finally { if ($listener) { try { $listener.Stop() } catch {} } }
}

function Get-DesktopPort([int]$Preferred) {
    if (Test-PortFree $Preferred) { return $Preferred }
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $listener.Start()
    try { return ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port }
    finally { $listener.Stop() }
}

function Find-Renderer {
    $pf = [Environment]::GetFolderPath('ProgramFiles')
    $pfx86 = [Environment]::GetFolderPath('ProgramFilesX86')
    $local = [Environment]::GetFolderPath('LocalApplicationData')
    $candidates = @(
        (Join-Path $pfx86 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $pf 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $local 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $pf 'Google\Chrome\Application\chrome.exe'),
        (Join-Path $pfx86 'Google\Chrome\Application\chrome.exe'),
        (Join-Path $local 'Google\Chrome\Application\chrome.exe')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    if ($candidates.Count -gt 0) { return $candidates[0] }
    return $null
}

$mutex = New-Object System.Threading.Mutex($false, 'Local\VetBLCM_Desktop')
$ownsMutex = $false
$rProcess = $null
$profileDir = $null
try {
    $ownsMutex = $mutex.WaitOne(0, $false)
    if (-not $ownsMutex) {
        Show-VetBLCMMessage 'VetBLCM is already running. / VetBLCM 已经在运行。'
        exit 0
    }

    $rscript = Find-Rscript
    if (-not $rscript) {
        Show-VetBLCMMessage "Rscript.exe was not found. Install R 4.4+ first, then start VetBLCM again.`n`n未找到 Rscript.exe。请先安装 R 4.4+，然后重新启动 VetBLCM。" 'VetBLCM - R not found'
        exit 1
    }
    $renderer = Find-Renderer
    if (-not $renderer) {
        Show-VetBLCMMessage "Microsoft Edge or Google Chrome is required only as the embedded desktop rendering engine.`nNo ordinary browser window will be used.`n`n未找到可用的 Edge/Chrome 渲染引擎。" 'VetBLCM - renderer not found'
        exit 1
    }

    $port = Get-DesktopPort $PreferredPort
    $env:LC_ALL=''; $env:LC_CTYPE=''; $env:LC_COLLATE=''; $env:LC_MONETARY=''; $env:LC_TIME=''
    $env:VETBLCM_PORT = [string]$port
    $env:VETBLCM_BROWSER = 'false'
    $env:VETBLCM_DESKTOP = 'true'

    $logDir = Join-Path $PSScriptRoot '.vetblcm\logs'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $stdout = Join-Path $logDir "desktop_$stamp.out.log"
    $stderr = Join-Path $logDir "desktop_$stamp.err.log"

    $rProcess = Start-Process -FilePath $rscript -ArgumentList @('--vanilla','scripts\launch.R') -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $url = "http://127.0.0.1:$port"
    $ready = $false
    $deadline = (Get-Date).AddSeconds(90)
    while ((Get-Date) -lt $deadline) {
        $rProcess.Refresh()
        if ($rProcess.HasExited) { break }
        try {
            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
            if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) { $ready = $true; break }
        } catch {}
        Start-Sleep -Milliseconds 500
    }
    if (-not $ready) {
        $detail = ''
        if (Test-Path -LiteralPath $stderr) {
            $tail = @(Get-Content -LiteralPath $stderr -Tail 16 -ErrorAction SilentlyContinue)
            if ($tail.Count) { $detail = "`n`n" + ($tail -join "`n") }
        }
        Show-VetBLCMMessage ("VetBLCM backend did not start successfully. Check:`n$stderr$detail`n`nVetBLCM 后端未能正常启动，请检查上述日志。") 'VetBLCM - startup failed'
        exit 1
    }

    $profileDir = Join-Path ([IO.Path]::GetTempPath()) ("VetBLCM-Desktop-" + [Diagnostics.Process]::GetCurrentProcess().Id)
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    $rendererArgs = @(
        "--app=$url",
        "--user-data-dir=`"$profileDir`"",
        '--no-first-run',
        '--no-default-browser-check',
        '--disable-sync',
        '--disable-background-mode',
        '--disable-features=Translate'
    )
    # The per-session user-data-dir forces a dedicated Chromium browser process,
    # so the process returned by Start-Process remains the lifetime owner of the
    # app-mode window. Waiting on it avoids any dependency on WMI/CIM inspection.
    $ui = Start-Process -FilePath $renderer -ArgumentList $rendererArgs -PassThru
    $ui.WaitForExit()
}
catch {
    Show-VetBLCMMessage ("VetBLCM could not start:`n" + $_.Exception.Message + "`n`nVetBLCM 启动失败。") 'VetBLCM - error'
    exit 1
}
finally {
    if ($rProcess) {
        try { $rProcess.Refresh(); if (-not $rProcess.HasExited) { Stop-Process -Id $rProcess.Id -Force -ErrorAction SilentlyContinue } } catch {}
    }
    if ($profileDir -and (Test-Path -LiteralPath $profileDir)) {
        Start-Sleep -Milliseconds 500
        try { Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }
    if ($ownsMutex) { try { $mutex.ReleaseMutex() } catch {} }
    if ($mutex) { $mutex.Dispose() }
}
