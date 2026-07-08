<#
.SYNOPSIS
    Aktualizuje dotfiles ekosystém na nejnovější verzi.
.DESCRIPTION
    Provede git pull v obou repozitářích, znovu spustí bootstrap
    a nabídne restart PowerShell session. Bezpečné pro opakované spuštění.
.PARAMETER WhatIf
    Pouze zobrazí, co by se provedlo.
.EXAMPLE
    .\update.ps1
    .\update.ps1 -WhatIf
.NOTES
    Cesta: ~/.config/powershell/update.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param()

$dotfilesPwshPath = Join-Path $HOME '.config\powershell'
$dotfilesToolsPath = Join-Path $HOME 'Projects\tools'
$updateNeeded = $false

function Write-Step { param([string]$M) Write-Host "==> $M" -ForegroundColor Cyan }
function Write-Ok   { param([string]$M) Write-Host "  [+] $M" -ForegroundColor Green }
function Write-Skip { param([string]$M) Write-Host "  [=] $M" -ForegroundColor Gray }
function Write-Fail { param([string]$M) Write-Host "  [x] $M" -ForegroundColor Red }

$repos = @(
    @{ Name = 'dotfiles-powershell'; Path = $dotfilesPwshPath },
    @{ Name = 'dotfiles-tools';      Path = $dotfilesToolsPath }
)

foreach ($repo in $repos) {
    if (-not (Test-Path (Join-Path $repo.Path '.git'))) {
        Write-Fail "$($repo.Name): not a git repo at $($repo.Path). Run install.ps1 first."
        continue
    }

    Write-Step "Checking $($repo.Name)..."

    if ($PSCmdlet.ShouldProcess($repo.Name, 'git fetch && git status')) {
        try {
            Push-Location $repo.Path

            # Save current HEAD
            $before = git rev-parse HEAD 2>&1
            if ($LASTEXITCODE -ne 0) { throw "git rev-parse failed" }

            # Fetch
            git fetch origin 2>&1 | Out-Null

            # Check if behind
            $behind = git rev-list HEAD..origin/main --count 2>&1
            if ($LASTEXITCODE -eq 0 -and [int]$behind -gt 0) {
                Write-Step "Pulling $([int]$behind) new commits..."
                git pull --ff-only 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Ok "Updated: $($repo.Name) ($([int]$behind) commits)"
                    $updateNeeded = $true
                } else {
                    Write-Fail "Pull failed — try manual: cd $($repo.Path); git pull"
                }
            }
            else {
                Write-Skip "Already up-to-date: $($repo.Name)"
            }

            Pop-Location
        }
        catch {
            Write-Fail "Update failed: $_"
            Pop-Location
        }
    }
}

# ── If anything updated, rebootstrap ──────────────────────────
if ($updateNeeded) {
    Write-Step "Changes pulled — reloading profile..."

    $mainProfile = Join-Path $dotfilesPwshPath 'profile.ps1'
    if (Test-Path $mainProfile) {
        if ($PSCmdlet.ShouldProcess($mainProfile, 'Reload profile')) {
            try {
                . $mainProfile
                Write-Ok "Profile reloaded."
            } catch {
                Write-Fail "Profile reload failed: $_"
                Write-Host "  Tip: restart your PowerShell session to apply changes." -ForegroundColor Yellow
            }
        }
    }

    Write-Host "`nUpdate complete!" -ForegroundColor Green
    Write-Host "  dotfiles-powershell: $dotfilesPwshPath" -ForegroundColor Gray
    Write-Host "  dotfiles-tools:      $dotfilesToolsPath" -ForegroundColor Gray
}
else {
    Write-Host "`nEverything is up-to-date." -ForegroundColor Green
}
