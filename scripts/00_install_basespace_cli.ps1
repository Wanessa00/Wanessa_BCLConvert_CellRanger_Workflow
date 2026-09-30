#requires -Version 5.1
<#
Install the current Illumina BaseSpace Sequence Hub CLI on Windows.

Run from PowerShell:
    Set-ExecutionPolicy -Scope Process Bypass
    .\00_install_basespace_cli.ps1
#>

$ErrorActionPreference = "Stop"

$InstallDir = "E:\Tools\BaseSpaceCLI"
$Exe = Join-Path $InstallDir "bs.exe"
$Url = "https://launch.basespace.illumina.com/CLI/latest/amd64-windows/bs.exe"

Write-Host "==> Creating installation directory"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Write-Host "==> Downloading current BaseSpace CLI from Illumina"
Invoke-WebRequest -Uri $Url -OutFile $Exe

if (-not (Test-Path $Exe)) {
    throw "BaseSpace CLI download failed: $Exe was not created."
}

Write-Host "==> Adding BaseSpace CLI to the current PowerShell PATH"
$env:Path = "$InstallDir;$env:Path"

Write-Host "==> Adding BaseSpace CLI to the user PATH if needed"
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$InstallDir*") {
    $NewPath = if ([string]::IsNullOrWhiteSpace($UserPath)) {
        $InstallDir
    } else {
        "$UserPath;$InstallDir"
    }
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
}

Write-Host "==> BaseSpace CLI help/version check"
& $Exe --help | Select-Object -First 20

Write-Host ""
Write-Host "==> Authenticating with BaseSpace Sequence Hub"
Write-Host "A browser-based authorization step may open."
& $Exe auth

Write-Host ""
Write-Host "==> Authenticated account"
& $Exe whoami

Write-Host ""
Write-Host "Installation complete."
Write-Host "Binary: $Exe"
