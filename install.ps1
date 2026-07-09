<#
.SYNOPSIS
    Idempotentní instalace dotfiles-powershell a dotfiles-tools.
.DESCRIPTION
    Naklonuje/aktualizuje repozitáře, vloží bootstrap do všech známých
    profilových souborů, nastaví PATH a nabídne konfiguraci Windows Terminálu.
    Idempotentní — opakované spuštění nezdvojí položky.
.PARAMETER NoTerminal
    Přeskočí nabídku pro nastavení Windows Terminálu.
.PARAMETER NoUpdates
    Přeskočí git pull (použije lokální verzi).
.PARAMETER WhatIf
    Pouze zobrazí, co by se provedlo, beze změn.
.PARAMETER Force
    Přepíše existující bootstrap (výchozí: přeskočí již nainstalované).
.EXAMPLE
    .\install.ps1
    .\install.ps1 -NoTerminal -NoUpdates
    .\install.ps1 -WhatIf
    .\install.ps1 -Force
.NOTES
    Cesta: ~/.config/powershell/install.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$NoTerminal,
    [switch]$NoUpdates,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib' 'output.ps1')

$script:Summary = [System.Collections.Generic.List[string]]::new()

# install.ps1 needs a run summary; override the shared writers from lib/output.ps1
# to also record each line. update.ps1 uses the shared writers unmodified — do not
# "simplify" this by removing the overrides, the summary list depends on them.
function Write-Ok   { param([string]$M) Write-Host "  [+] $M" -ForegroundColor Green;  $null = $script:Summary.Add("  [+] $M") }
function Write-Skip { param([string]$M) Write-Host "  [=] $M" -ForegroundColor Gray;   $null = $script:Summary.Add("  [=] $M") }
function Write-Fail { param([string]$M) Write-Host "  [x] $M" -ForegroundColor Red;    $null = $script:Summary.Add("  [x] $M") }
function Write-Warn { param([string]$M) Write-Host "  [!] $M" -ForegroundColor Yellow; $null = $script:Summary.Add("  [!] $M") }

$script:restartNeeded = $false

$dotfilesPwshUrl = 'https://github.com/martinpaprcka77/dotfiles-powershell.git'
$dotfilesToolsUrl = 'https://github.com/martinpaprcka77/dotfiles-tools.git'

# Prefer the env vars profile.ps1 already sets (covers re-running install.ps1
# from an already-bootstrapped session); fall back to the well-known default
# for a true first run, where no profile session — and no env var — exists yet.
$dotfilesPwshPath  = if ($env:DOTFILES_PWSH)  { $env:DOTFILES_PWSH }  else { Join-Path $HOME '.config\powershell' }
$dotfilesToolsPath = if ($env:DOTFILES_TOOLS) { $env:DOTFILES_TOOLS } else { Join-Path $HOME 'Projects\tools' }

# $IsWindows doesn't exist on PS5.1 (PS6+ automatic variable); PS5.1 only ever
# runs on Windows, so treat that case as Windows too. Use this instead of the
# raw $IsWindows anywhere below.
$isWindowsHost = if ($PSVersionTable.PSVersion.Major -ge 6) { $IsWindows } else { $true }

# ── Git clone/update ──────────────────────────────────────────
Write-Step "Setting up dotfiles repositories..."

function CloneOrUpdate {
    # Uses $PSCmdlet.ShouldProcess — must declare SupportsShouldProcess itself
    # rather than relying on inheriting the caller's $PSCmdlet by scope accident.
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Url, [string]$Path)
    $isRepo = Test-Path (Join-Path $Path '.git')

    if ($isRepo -and -not $NoUpdates) {
        Write-Step "Updating $Path..."
        if ($PSCmdlet.ShouldProcess($Path, 'git pull --ff-only')) {
            try {
                Push-Location $Path
                git pull --ff-only 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { Write-Ok "Updated: $Path" }
                else { Write-Fail "git pull failed in $Path" }
            } catch {
                Write-Fail "Update failed: $_"
            } finally {
                Pop-Location
            }
        }
    }
    elseif (-not $isRepo) {
        # If directory exists but isn't a git repo, remove it so git clone can succeed
        if (Test-Path $Path) {
            Write-Warn "Directory exists but is not a git repo: $Path"
            if ($PSCmdlet.ShouldProcess($Path, 'Remove directory before clone')) {
                Remove-Item -Path $Path -Recurse -Force
                Write-Ok "Removed: $Path"
            } else { return }
        }
        Write-Step "Cloning $Url to $Path..."
        if ($PSCmdlet.ShouldProcess($Path, "git clone $Url")) {
            try {
                $parent = Split-Path $Path -Parent
                if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
                git clone $Url $Path 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { Write-Ok "Cloned: $Path" }
                else { Write-Fail "Clone failed for $Url" }
            } catch {
                Write-Fail "Clone failed: $_"
            }
        }
    }
    else { Write-Skip "Skipping update (--NoUpdates): $Path" }
}

CloneOrUpdate -Url $dotfilesPwshUrl -Path $dotfilesPwshPath
CloneOrUpdate -Url $dotfilesToolsUrl -Path $dotfilesToolsPath

# ── Bootstrap profiles ────────────────────────────────────────
Write-Step "Injecting bootstrap into PowerShell profiles..."

# Hardcoded intentionally, same as bootstrap.ps1: this snippet runs before
# profile.ps1 ever executes, so $env:DOTFILES_PWSH doesn't exist yet.
$bootstrapCode = @'

# Bootstrap: dotfiles-powershell
$dotfilesProfile = Join-Path $HOME '.config\powershell\profile.ps1'
if (Test-Path $dotfilesProfile) { . $dotfilesProfile }
'@

$profilePaths = @(
    "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
    "$HOME\Documents\PowerShell\Microsoft.VSCode_profile.ps1",
    "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
    "$HOME\Documents\WindowsPowerShell\Microsoft.VSCode_profile.ps1"
)

foreach ($profilePath in $profilePaths) {
    $profileDir = Split-Path $profilePath -Parent
    if (-not (Test-Path $profileDir)) {
        if ($PSCmdlet.ShouldProcess($profileDir, 'Create directory')) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
    }

    if (Test-Path $profilePath) {
        $existing = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
        $alreadyBootstrapped = $existing -and ($existing -match [regex]::Escape('# Bootstrap: dotfiles-powershell'))

        if ($alreadyBootstrapped -and -not $Force) {
            Write-Skip "Already bootstrapped: $profilePath"
        }
        else {
            if ($PSCmdlet.ShouldProcess($profilePath, 'Append/replace bootstrap')) {
                try {
                    # Backup
                    if (-not $alreadyBootstrapped) {
                        $backup = "$profilePath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                        Copy-Item $profilePath $backup
                        Write-Ok "Backup: $backup"
                    }
                    if ($alreadyBootstrapped) {
                        # Normalize line endings before comparing — $bootstrapCode's
                        # CRLF/LF depends on how the source file was checked out, and
                        # a mismatch here means -replace silently fails to match,
                        # leaving the old block in place and appending a duplicate.
                        # Only the comparison is normalized; output stays CRLF since
                        # these are native Windows profile files.
                        $normalizedExisting = $existing -replace "`r`n", "`n"
                        $normalizedBootstrap = $bootstrapCode -replace "`r`n", "`n"
                        $newContent = ($normalizedExisting -replace [regex]::Escape($normalizedBootstrap), '') -replace "`n", "`r`n"
                        $newContent += "`r`n$bootstrapCode"
                        Set-Content -Path $profilePath -Value $newContent -NoNewline
                    } else {
                        Add-Content -Path $profilePath -Value "`r`n$bootstrapCode"
                    }
                    Write-Ok "Updated: $profilePath"
                    $script:restartNeeded = $true
                } catch {
                    Write-Fail "Failed: $profilePath — $_"
                }
            }
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess($profilePath, 'Create with bootstrap')) {
            try {
                Set-Content -Path $profilePath -Value $bootstrapCode -NoNewline
                Write-Ok "Created: $profilePath"
                $script:restartNeeded = $true
            } catch {
                Write-Fail "Failed: $profilePath — $_"
            }
        }
    }
}

# ── PATH setup ─────────────────────────────────────────────────
# [Environment]::...('User') is a Windows registry-backed target — .NET
# throws PlatformNotSupportedException for it on Linux/macOS. Session PATH
# ($env:PATH) still works everywhere; only the persistent part is Windows-only.
Write-Step "Setting user PATH..."

$toolsBin = Join-Path $dotfilesToolsPath 'bin'
try {
    $currentUserPath = if ($isWindowsHost) { [Environment]::GetEnvironmentVariable('PATH', 'User') } else { $env:PATH }
    if ($toolsBin -notin ($currentUserPath -split [IO.Path]::PathSeparator)) {
        if ($PSCmdlet.ShouldProcess('User PATH', "Add $toolsBin")) {
            if ($isWindowsHost) {
                [Environment]::SetEnvironmentVariable('PATH', "$toolsBin$([IO.Path]::PathSeparator)$currentUserPath", 'User')
            }
            $env:PATH = "$toolsBin$([IO.Path]::PathSeparator)$env:PATH"
            Write-Ok "Added to PATH: $toolsBin"
            $script:restartNeeded = $true
        }
    }
    else { Write-Skip "Already in PATH: $toolsBin" }
} catch {
    Write-Fail "PATH update failed: $_"
}

# ── Windows Terminal ───────────────────────────────────────────
if (-not $NoTerminal) {
    $wtScript = Join-Path $dotfilesToolsPath 'scripts\Add-WTProfiles.ps1'
    if ($isWindowsHost -and (Test-Path $wtScript)) {
        $response = Read-Host "`nRun Add-WTProfiles.ps1 to configure Windows Terminal? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            if ($PSCmdlet.ShouldProcess('Windows Terminal', 'Add profiles')) {
                try { & $wtScript } catch { Write-Fail "WT setup failed: $_" }
            }
        }
    }
    elseif (-not $isWindowsHost) {
        Write-Skip "Windows Terminal setup skipped (non-Windows OS)"
    }
}

# ── Summary ────────────────────────────────────────────────────
Write-Host "`n=== INSTALLATION SUMMARY ===" -ForegroundColor Magenta
$script:Summary | ForEach-Object { Write-Host $_ }
if ($script:restartNeeded) {
    Write-Host "`nRestart your PowerShell session to apply changes." -ForegroundColor Yellow
}
else {
    Write-Host "`nNo restart needed — everything was already configured." -ForegroundColor Green
}
