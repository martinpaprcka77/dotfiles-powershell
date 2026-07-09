<#
.SYNOPSIS
    Hlavní PowerShell profil – modulární, verzovaný, přenositelný.
.DESCRIPTION
    Detekuje verzi PowerShellu (5/7) a hostitele (ConsoleHost, VSCode),
    dot-sourcuje odpovídající skripty a nastavuje prostředí mimo OneDrive.
.NOTES
    Cesta: ~/.config/powershell/profile.ps1
#>

#region Environment setup
$env:DOTFILES_PWSH = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:DOTFILES_TOOLS = Join-Path $HOME "Projects\tools"

# Fix PSModulePath for PS7 – add LOCALAPPDATA first to avoid OneDrive
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $localModules = "$env:LOCALAPPDATA\PowerShell\Modules"
    if ($localModules -notin ($env:PSModulePath -split [IO.Path]::PathSeparator)) {
        $env:PSModulePath = "$localModules$([IO.Path]::PathSeparator)$env:PSModulePath"
    }
}
#endregion

#region Benchmark
# Cheap total-time timer. For a step-by-step breakdown, use Measure-Profile
# (core/perf.ps1). For ETW-level detail (module loads, JIT), use
# Measure-PSCommand (core/diag.ps1, Windows-only).
$profileStart = if ($env:PROFILE_BENCHMARK -eq 'true') { [Diagnostics.Stopwatch]::StartNew() } else { $null }
#endregion

#region Core modules
$coreDir = Join-Path $env:DOTFILES_PWSH "core"
if (Test-Path $coreDir) {
    Get-ChildItem -Path $coreDir -Filter *.ps1 | ForEach-Object {
        . $_.FullName
    }
}
#endregion

#region Version-specific profile
$psVersionDir = if ($PSVersionTable.PSVersion.Major -ge 6) { "ps7" } else { "ps5" }
$versionProfile = Join-Path $env:DOTFILES_PWSH "$psVersionDir\profile.ps1"
if (Test-Path $versionProfile) {
    . $versionProfile
}
#endregion

#region Host-specific profile
$hostName = if ($Host.Name -match 'Code') { 'VSCode' } else { 'ConsoleHost' }
$hostProfile = Join-Path $env:DOTFILES_PWSH "hosts\$hostName.ps1"
if (Test-Path $hostProfile) {
    . $hostProfile
}
#endregion

#region Benchmark output
if ($profileStart) {
    $profileStart.Stop()
    Write-Host "Profile loaded in $($profileStart.ElapsedMilliseconds)ms" -ForegroundColor DarkGray
}
#endregion
