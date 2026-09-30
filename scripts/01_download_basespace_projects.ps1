#requires -Version 5.1
<#
Download the original and rescued BaseSpace projects.

Workflow implemented by:
Wanessa dos Santos

BaseSpace project IDs are intentionally not stored in this public repository.
They must be provided locally as environment variables before execution.

The BaseSpace CLI downloader is resumable. If a transfer is interrupted,
rerun the same command with the same output directory.
#>

$ErrorActionPreference = "Stop"

$BaseSpaceRoot = "E:\BaseSpace\Wanessa"

# ---------------------------------------------------------------------------
# BaseSpace Project IDs
# ---------------------------------------------------------------------------
# For security/privacy, project-specific IDs are not hard-coded in this
# public repository.
#
# Before running this script, define them locally in PowerShell:
#
# $env:BASESPACE_ORIGINAL_PROJECT_ID = "YOUR_ORIGINAL_PROJECT_ID"
# $env:BASESPACE_ICA_PROJECT_ID      = "YOUR_ICA_PROJECT_ID"
# $env:BASESPACE_RESCUE_PROJECT_ID   = "YOUR_RESCUE_PROJECT_ID"
# ---------------------------------------------------------------------------

$OriginalProjectId = $env:BASESPACE_ORIGINAL_PROJECT_ID
$ICAProjectId      = $env:BASESPACE_ICA_PROJECT_ID
$RescueProjectId   = $env:BASESPACE_RESCUE_PROJECT_ID

if ([string]::IsNullOrWhiteSpace($OriginalProjectId)) {
    throw "BASESPACE_ORIGINAL_PROJECT_ID is not defined."
}

if ([string]::IsNullOrWhiteSpace($ICAProjectId)) {
    throw "BASESPACE_ICA_PROJECT_ID is not defined."
}

if ([string]::IsNullOrWhiteSpace($RescueProjectId)) {
    throw "BASESPACE_RESCUE_PROJECT_ID is not defined."
}


# ---------------------------------------------------------------------------
# Output directories
# ---------------------------------------------------------------------------

$OriginalDir = Join-Path $BaseSpaceRoot "01_original_backup"
$ICADir      = Join-Path $BaseSpaceRoot "01b_ICA_workflow_reports"
$RescueDir   = Join-Path $BaseSpaceRoot "02_rescue_I1_7bp"

New-Item -ItemType Directory -Force -Path $OriginalDir | Out-Null
New-Item -ItemType Directory -Force -Path $ICADir | Out-Null
New-Item -ItemType Directory -Force -Path $RescueDir | Out-Null


# ---------------------------------------------------------------------------
# Verify BaseSpace CLI authentication
# ---------------------------------------------------------------------------

Write-Host "==> Verifying BaseSpace CLI authentication"
bs.exe whoami


# ---------------------------------------------------------------------------
# List accessible projects
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "==> Listing available BaseSpace projects"
bs.exe list projects


# ---------------------------------------------------------------------------
# Download original FASTQs
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "==> Downloading ORIGINAL FASTQs"
Write-Host "Destination: $OriginalDir"

bs.exe download project `
    -i $OriginalProjectId `
    -o $OriginalDir `
    --extension fastq.gz


# ---------------------------------------------------------------------------
# Download ICA workflow/report files
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "==> Downloading ICA workflow/report project"
Write-Host "Destination: $ICADir"

bs.exe download project `
    -i $ICAProjectId `
    -o $ICADir


# ---------------------------------------------------------------------------
# Download rescued FASTQs
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "==> Downloading RESCUED FASTQs"
Write-Host "Destination: $RescueDir"

bs.exe download project `
    -i $RescueProjectId `
    -o $RescueDir `
    --extension fastq.gz


# ---------------------------------------------------------------------------
# Inventory downloaded FASTQs
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "==> FASTQ inventory"

Get-ChildItem -Path $RescueDir -Recurse -Filter *.fastq.gz |
    Sort-Object FullName |
    Select-Object FullName, Length |
    Format-Table -AutoSize


# ---------------------------------------------------------------------------
# Generate SHA256 checksums
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "==> Generating SHA256 manifest"

$Manifest = Join-Path $RescueDir "SHA256SUMS.txt"

Get-ChildItem -Path $RescueDir -Recurse -Filter *.fastq.gz |
    Get-FileHash -Algorithm SHA256 |
    ForEach-Object {
        "$($_.Hash)  $($_.Path)"
    } |
    Set-Content $Manifest

Write-Host ""
Write-Host "SHA256 manifest created:"
Write-Host $Manifest

Write-Host ""
Write-Host "Workflow completed."
Write-Host "Implemented by Wanessa Dayanne dos Santos."
