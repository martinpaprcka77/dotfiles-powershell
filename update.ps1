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

# Prefer the env vars profile.ps1 already sets; fall back to the well-known
# default (same reasoning as install.ps1).
$dotfilesPwshPath  = if ($env:DOTFILES_PWSH)  { $env:DOTFILES_PWSH }  else { Join-Path $HOME '.config\powershell' }
$dotfilesToolsPath = if ($env:DOTFILES_TOOLS) { $env:DOTFILES_TOOLS } else { Join-Path $HOME 'Projects\tools' }
$updateNeeded = $false

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib' 'output.ps1')

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

            # Fetch
            git fetch origin 2>&1 | Out-Null

            # Resolve the actual default branch instead of assuming 'main' —
            # the two repos could in principle differ, so this is per-repo.
            $defaultBranch = (git symbolic-ref refs/remotes/origin/HEAD 2>$null) -replace '^refs/remotes/origin/', ''
            if (-not $defaultBranch) {
                $defaultBranch = 'main'
                Write-Warn "Could not resolve default branch for $($repo.Name); assuming 'main'."
            }

            # Check if behind
            $behind = git rev-list "HEAD..origin/$defaultBranch" --count 2>&1
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

        }
        catch {
            Write-Fail "Update failed: $_"
        }
        finally {
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
