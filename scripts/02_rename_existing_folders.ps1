#requires -Version 5.1
<#
OPTIONAL migration helper for files that were already downloaded before
the final repository naming convention was established.

The operations are moves/renames on the same E: drive; FASTQ contents are
not modified. The script asks for confirmation before changing anything.

Target layout:
E:\BaseSpace\Wanessa\
  01_original_backup\
  01b_ICA_workflow_reports\
  02_rescue_I1_7bp\
  CellRanger_Wanessa\
#>

$ErrorActionPreference = "Stop"

$Root = "E:\BaseSpace"
$WanessaRoot = Join-Path $Root "Wanessa"
$OriginalRoot = Join-Path $WanessaRoot "01_original_backup"
$ICARoot = Join-Path $WanessaRoot "01b_ICA_workflow_reports"
$RescueRoot = Join-Path $WanessaRoot "02_rescue_I1_7bp"
$CellRangerRoot = Join-Path $WanessaRoot "CellRanger_Wanessa"

New-Item -ItemType Directory -Force -Path $WanessaRoot | Out-Null
New-Item -ItemType Directory -Force -Path $OriginalRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ICARoot | Out-Null
New-Item -ItemType Directory -Force -Path $RescueRoot | Out-Null

$planned = New-Object System.Collections.Generic.List[string]

# 1) Original downloaded BaseSpace project
$OldOriginal = Join-Path $Root "Fabio_P11-4_2026-09-11T11_35_39_125f78c-519115698"
$NewOriginal = Join-Path $OriginalRoot "Wanessa_P11-4_original_2026-09-11"
if (Test-Path $OldOriginal) {
    $planned.Add("$OldOriginal -> $NewOriginal")
}

# 2) Run-level metadata folder
$OldMetadata = Join-Path $Root "Fabio_P11-4-330834505"
$NewMetadata = Join-Path $OriginalRoot "Wanessa_P11-4_run_metadata_330834505"
if (Test-Path $OldMetadata) {
    $planned.Add("$OldMetadata -> $NewMetadata")
}

# 3) ICA workflow folder
$OldICA = Join-Path $Root "ICA_Workflows_2026_09-519276763"
$NewICA = Join-Path $ICARoot "ICA_Workflows_2026_09-519276763"
if (Test-Path $OldICA) {
    $planned.Add("$OldICA -> $NewICA")
}

# 4) Cell Ranger working directory created earlier
$OldCellRanger = Join-Path $Root "CellRanger_Fabio"
if (Test-Path $OldCellRanger) {
    $planned.Add("$OldCellRanger -> $CellRangerRoot")
}

# 5) Rescue datasets downloaded directly into E:\BaseSpace.
# Find them by the rescued FASTQ names rather than by random BaseSpace dataset suffix.
$SamplePatterns = @(
    "P11_S1_L001_R1_001.fastq.gz",
    "DMem_S2_L001_R1_001.fastq.gz",
    "P11_O_S3_L001_R1_001.fastq.gz",
    "O_S4_L001_R1_001.fastq.gz",
    "Undetermined_S0_L001_R1_001.fastq.gz"
)

$RescueDirs = New-Object System.Collections.Generic.HashSet[string]
foreach ($pattern in $SamplePatterns) {
    Get-ChildItem -Path $Root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $hit = Get-ChildItem -Path $_.FullName -Filter $pattern -File -ErrorAction SilentlyContinue
        if ($hit) {
            [void]$RescueDirs.Add($_.FullName)
        }
    }
}

foreach ($dir in $RescueDirs) {
    $dest = Join-Path $RescueRoot (Split-Path $dir -Leaf)
    $planned.Add("$dir -> $dest")
}

# Rescue project JSON, if present
Get-ChildItem -Path $Root -File -Filter "*P11-4_rescue_I1_7bp*520938419*.json" -ErrorAction SilentlyContinue |
    ForEach-Object {
        $destName = $_.Name -replace "^Fabio_", "Wanessa_"
        $dest = Join-Path $RescueRoot $destName
        $planned.Add("$($_.FullName) -> $dest")
    }

if ($planned.Count -eq 0) {
    Write-Host "Nothing matching the old layout was found. No changes needed."
    exit 0
}

Write-Host "Planned moves/renames:"
$planned | ForEach-Object { Write-Host "  $_" }

$answer = Read-Host "Type YES to execute"
if ($answer -ne "YES") {
    Write-Host "No changes made."
    exit 0
}

if (Test-Path $OldOriginal) {
    Move-Item -Path $OldOriginal -Destination $NewOriginal
}
if (Test-Path $OldMetadata) {
    Move-Item -Path $OldMetadata -Destination $NewMetadata
}
if (Test-Path $OldICA) {
    Move-Item -Path $OldICA -Destination $NewICA
}
if (Test-Path $OldCellRanger) {
    Move-Item -Path $OldCellRanger -Destination $CellRangerRoot
}

foreach ($dir in $RescueDirs) {
    $dest = Join-Path $RescueRoot (Split-Path $dir -Leaf)
    if (-not (Test-Path $dest)) {
        Move-Item -Path $dir -Destination $dest
    }
}

Get-ChildItem -Path $Root -File -Filter "*P11-4_rescue_I1_7bp*520938419*.json" -ErrorAction SilentlyContinue |
    ForEach-Object {
        $destName = $_.Name -replace "^Fabio_", "Wanessa_"
        $dest = Join-Path $RescueRoot $destName
        Move-Item -Path $_.FullName -Destination $dest
    }

Write-Host ""
Write-Host "Migration complete."
Write-Host "New root: $WanessaRoot"
