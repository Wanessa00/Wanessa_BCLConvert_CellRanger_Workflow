#requires -Version 5.1
<#
Download the original and rescued BaseSpace projects.

The project IDs below are the IDs used for this analysis.
Change them if reproducing the workflow on another run.

The BaseSpace CLI downloader is resumable. If a transfer is interrupted,
rerun the same command with the same output directory.
#>

$ErrorActionPreference = "Stop"

$BaseSpaceRoot = "E:\BaseSpace\Wanessa"
$OriginalProjectId = "519115698"
$ICAProjectId      = "519276763"
$RescueProjectId   = "520938419"

$OriginalDir = Join-Path $BaseSpaceRoot "01_original_backup"
$ICADir      = Join-Path $BaseSpaceRoot "01b_ICA_workflow_reports"
$RescueDir   = Join-Path $BaseSpaceRoot "02_rescue_I1_7bp"

New-Item -ItemType Directory -Force -Path $OriginalDir | Out-Null
New-Item -ItemType Directory -Force -Path $ICADir | Out-Null
New-Item -ItemType Directory -Force -Path $RescueDir | Out-Null

Write-Host "==> Verifying BaseSpace CLI"
bs.exe whoami

Write-Host ""
Write-Host "==> Listing available projects"
bs.exe list projects

Write-Host ""
Write-Host "==> Downloading ORIGINAL FASTQs"
bs.exe download project -i $OriginalProjectId -o $OriginalDir --extension fastq.gz

Write-Host ""
Write-Host "==> Downloading small ICA workflow/report project"
bs.exe download project -i $ICAProjectId -o $ICADir

Write-Host ""
Write-Host "==> Downloading RESCUED FASTQs"
bs.exe download project -i $RescueProjectId -o $RescueDir --extension fastq.gz

Write-Host ""
Write-Host "==> Download complete. FASTQ file inventory:"
Get-ChildItem -Path $RescueDir -Recurse -Filter *.fastq.gz |
    Sort-Object FullName |
    Select-Object FullName, Length |
    Format-Table -AutoSize

Write-Host ""
Write-Host "==> Writing SHA256 manifest for the rescue project"
$Manifest = Join-Path $RescueDir "SHA256SUMS.txt"
Get-ChildItem -Path $RescueDir -Recurse -Filter *.fastq.gz |
    Get-FileHash -Algorithm SHA256 |
    ForEach-Object { "$($_.Hash)  $($_.Path)" } |
    Set-Content $Manifest

Write-Host "Manifest: $Manifest"
