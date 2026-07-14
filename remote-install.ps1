<#
.SYNOPSIS
    One-command remote bootstrapper — safe to run via `irm <raw-url> | iex`.
.DESCRIPTION
    Clones (or updates) dotfiles-powershell only, then hands off to its own
    install.ps1, which does everything else (clone dotfiles-tools, inject
    the native $PROFILE bootstrap at the real Known-Folder-correct Documents
    location, PATH setup). This script's own job is deliberately minimal —
    just enough to get install.ps1 onto disk and running, so there is
    exactly one implementation of the clone/bootstrap-inject/idempotency
    logic, not two.

    Cannot dot-source lib/output.ps1 or lib/paths.ps1 — this script's whole
    job is to fetch the repo they live in (chicken/egg), so it carries a
    minimal inline copy of the Write-* helpers, same as bootstrap.ps1
    already does for the same reason. Do not "simplify" this into a
    dot-source of lib/output.ps1 — it would break the one supported
    invocation this script exists for (irm | iex, no local clone yet).

    -WhatIf/-Force/-NoUpdates/-NoTerminal aren't reachable through `iex`
    (it executes script text, no CLI param binding) — use the
    $env:DOTFILES_* toggles below, or download this file first for full
    parameter parity via a normal invocation.
    No SupportsShouldProcess here deliberately: $PSCmdlet is $null when this
    script runs via `Invoke-Expression` (the whole point of this file) —
    calling $PSCmdlet.ShouldProcess() in that context throws, it doesn't just
    silently skip. install.ps1 (which this hands off to) has full
    ShouldProcess/-WhatIf support for direct, non-iex invocation.
.PARAMETER Force
    Forwarded to install.ps1 -Force.
.PARAMETER NoUpdates
    Forwarded to install.ps1 -NoUpdates.
.PARAMETER NoTerminal
    Forwarded to install.ps1 -NoTerminal.
.EXAMPLE
    # Already in PowerShell (5.1 or 7+):
    irm https://raw.githubusercontent.com/martinpaprcka77/dotfiles-powershell/main/remote-install.ps1 | iex

    # From cmd.exe, bash-on-Windows, or any shell with a PowerShell host on PATH:
    powershell -c "irm https://raw.githubusercontent.com/martinpaprcka77/dotfiles-powershell/main/remote-install.ps1 | iex"

    # From a Linux/macOS shell with pwsh installed:
    pwsh -c "irm https://raw.githubusercontent.com/martinpaprcka77/dotfiles-powershell/main/remote-install.ps1 | iex"

    # Passing options through iex (env-var toggles, since -Force etc. aren't reachable):
    $env:DOTFILES_FORCE=1; irm https://raw.githubusercontent.com/martinpaprcka77/dotfiles-powershell/main/remote-install.ps1 | iex
.NOTES
    Cesta: ~/.config/powershell/remote-install.ps1
    No PowerShell installed at all (Linux/macOS): this cannot help you get
    started — there is no PowerShell-free path in. Install PowerShell first:
    https://aka.ms/install-powershell
#>
param(
    [switch]$Force,
    [switch]$NoUpdates,
    [switch]$NoTerminal
)

# Inline, minimal — see the chicken/egg note above. Kept deliberately tiny;
# this is NOT the place to add features, that's what lib/output.ps1 is for
# once install.ps1 takes over.
function Write-Step { param([string]$M) Write-Host "==> $M" -ForegroundColor Cyan }
function Write-Ok   { param([string]$M) Write-Host "  [+] $M" -ForegroundColor Green }
function Write-Skip { param([string]$M) Write-Host "  [=] $M" -ForegroundColor Gray }
function Write-Fail { param([string]$M) Write-Host "  [x] $M" -ForegroundColor Red }
function Write-Warn { param([string]$M) Write-Host "  [!] $M" -ForegroundColor Yellow }

# Env-var toggles — the only way to pass options through `irm | iex`, which
# executes script text with no CLI param binding. Real -Force/-NoUpdates/
# -NoTerminal switches above still work for direct (non-iex) invocation.
if ($env:DOTFILES_FORCE)      { $Force = $true }
if ($env:DOTFILES_NO_UPDATES) { $NoUpdates = $true }
if ($env:DOTFILES_NO_TERMINAL) { $NoTerminal = $true }

$isWindowsHost = if ($PSVersionTable.PSVersion.Major -ge 6) { $IsWindows } else { $true }

Write-Step "dotfiles-powershell remote bootstrap"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Fail "git is required but not found on PATH. Install it first: https://git-scm.com/downloads"
    exit 1
}

$dotfilesPwshUrl = 'https://github.com/martinpaprcka77/dotfiles-powershell.git'
$dotfilesPwshPath = Join-Path $HOME '.config\powershell'

$isRepo = Test-Path (Join-Path $dotfilesPwshPath '.git')
if ($isRepo) {
    Write-Step "Updating $dotfilesPwshPath..."
    try {
        Push-Location $dotfilesPwshPath
        git pull --ff-only 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Ok "Updated: $dotfilesPwshPath" }
        else { Write-Fail "git pull failed in $dotfilesPwshPath — continuing with the existing local copy" }
    } catch {
        Write-Fail "Update failed: $_"
    } finally {
        Pop-Location
    }
} else {
    if (Test-Path $dotfilesPwshPath) {
        Write-Fail "Directory exists but is not a git repo: $dotfilesPwshPath"
        Write-Fail "Move or remove it, then re-run this bootstrap."
        exit 1
    }
    Write-Step "Cloning $dotfilesPwshUrl to $dotfilesPwshPath..."
    $parent = Split-Path $dotfilesPwshPath -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    git clone $dotfilesPwshUrl $dotfilesPwshPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Clone failed for $dotfilesPwshUrl"
        exit 1
    }
    Write-Ok "Cloned: $dotfilesPwshPath"
}

if (-not $isWindowsHost) {
    Write-Skip "PS5.1-without-pwsh guidance and Windows Terminal setup don't apply off-Windows."
}

# ── Hand off — install.ps1 does everything else (dotfiles-tools clone,
# native $PROFILE bootstrap injection at the real Known-Folder-correct
# location, PATH setup) exactly once, not duplicated here.
$installScript = Join-Path $dotfilesPwshPath 'install.ps1'
if (-not (Test-Path $installScript)) {
    Write-Fail "install.ps1 not found at $installScript — clone may have failed."
    exit 1
}

Write-Step "Handing off to install.ps1..."
$forwardedArgs = @{}
if ($Force) { $forwardedArgs.Force = $true }
if ($NoUpdates) { $forwardedArgs.NoUpdates = $true }
if ($NoTerminal) { $forwardedArgs.NoTerminal = $true }
if ($WhatIfPreference) { $forwardedArgs.WhatIf = $true }

& $installScript @forwardedArgs
