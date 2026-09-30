#requires -Version 5.1
<#
Initialize this workflow folder as a local Git repository.

Optional:
    .\06_initialize_git_repo.ps1 -RemoteUrl "https://github.com/USER/REPO.git"

The script relies on .gitignore to keep FASTQs/BAMs/references/software archives
out of the repository.
#>

param(
    [string]$RemoteUrl = ""
)

$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $PSScriptRoot

Set-Location $Repo

git --version

if (-not (Test-Path ".git")) {
    git init
}

git status

Write-Host ""
Write-Host "Reviewing ignored large sequencing files:"
git status --ignored --short

Write-Host ""
Write-Host "Adding repository documentation and scripts..."
git add README.md .gitignore scripts configs docs

git status

if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
    $existing = git remote
    if ($existing -notcontains "origin") {
        git remote add origin $RemoteUrl
    } else {
        git remote set-url origin $RemoteUrl
    }
    Write-Host "Origin set to: $RemoteUrl"
}

Write-Host ""
Write-Host "Ready for commit. Example:"
Write-Host 'git commit -m "Document BCL Convert rescue and Cell Ranger workflow"'
