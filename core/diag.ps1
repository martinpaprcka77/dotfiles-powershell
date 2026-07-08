<#
.SYNOPSIS
    PowerShell diagnostic tracing tools — ETW, event logs, profiling.
.DESCRIPTION
    Wraps PSDiagnostics module cmdlets for easy one-command profiling.
    Used for debugging slow profiles, module loads, and script execution.
    Windows-only (PSDiagnostics requires ETW).
.NOTES
    Cesta: ~/.config/powershell/core/diag.ps1
    Requires: PSDiagnostics module (built into PowerShell 7 on Windows)
#>

if ($IsLinux -or $IsMacOS) { return }  # PSDiagnostics is Windows-only

# ── Start-PSProfiling — one-command profile trace ──────────────
<#
.SYNOPSIS
    Starts an ETW trace session for PowerShell diagnostics.
.DESCRIPTION
    Enables PowerShellCore event provider and starts a trace.
    Use Stop-PSProfiling to stop and collect the trace.
.EXAMPLE
    Start-PSProfiling
    . $PROFILE
    Stop-PSProfiling
#>
function Start-PSProfiling {
    param([string]$SessionName = 'PSProfileTrace')
    if (-not (Get-Module PSDiagnostics -ListAvailable)) {
        Write-Warn "PSDiagnostics module not available (Windows only)"
        return
    }
    Import-Module PSDiagnostics -ErrorAction Stop
    Write-Info "Starting ETW trace session: $SessionName"
    Enable-PSTrace -Force -ErrorAction SilentlyContinue
    Start-Trace -SessionName $SessionName -ErrorAction Stop
    Write-Success "Trace started. Run your commands, then: Stop-PSProfiling"
}

<#
.SYNOPSIS
    Stops the ETW trace session and reports the trace file location.
#>
function Stop-PSProfiling {
    param([string]$SessionName = 'PSProfileTrace')
    if (-not (Get-Module PSDiagnostics)) { Write-Warn "No trace running."; return }
    Write-Info "Stopping trace session: $SessionName"
    Stop-Trace -SessionName $SessionName -ErrorAction SilentlyContinue
    Disable-PSTrace -ErrorAction SilentlyContinue
    $traceFile = "$env:TEMP\$SessionName.etl"
    if (Test-Path $traceFile) {
        Write-Success "Trace saved: $traceFile"
        Write-Host "  Open in Windows Performance Analyzer or PerfView" -ForegroundColor DarkGray
    } else {
        Write-Warn "Trace file not found. Trace may not have captured data."
    }
}

# ── Measure-PSCommand — detailed command timing via ETW ─────────
<#
.SYNOPSIS
    Measures a scriptblock with ETW-level detail (module loads, JIT, provider events).
.DESCRIPTION
    Runs Start-PSProfiling, executes the scriptblock, then stops and reports.
    More detailed than Measure-Command — captures ETW events.
.EXAMPLE
    Measure-PSCommand { . $PROFILE }
#>
function Measure-PSCommand {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        [string]$SessionName = 'PSCommandTrace'
    )
    if (-not (Get-Module PSDiagnostics -ListAvailable)) {
        Write-Warn "PSDiagnostics not available — falling back to Measure-Command"
        return Measure-Command $ScriptBlock
    }
    Start-PSProfiling -SessionName $SessionName
    try {
        $result = Measure-Command $ScriptBlock
        Write-Success "Command completed in $($result.TotalMilliseconds.ToString('F0'))ms"
    } finally {
        Stop-PSProfiling -SessionName $SessionName
    }
}

# ── Get-PSEventLog — quick event log inspection ────────────────
<#
.SYNOPSIS
    Shows PowerShell-related Windows event log properties.
#>
function Get-PSEventLog {
    $logs = @('PowerShellCore/Operational', 'Windows PowerShell', 'Microsoft-Windows-PowerShell/Operational')
    Write-Host "`n📋 PowerShell Event Logs" -ForegroundColor Cyan
    foreach ($log in $logs) {
        try {
            $props = Get-LogProperties -Name $log -ErrorAction Stop
            $size = if ($props.LogSize) { "$([math]::Round($props.LogSize/1MB, 1)) MB" } else { 'N/A' }
            Write-Host "  $log" -ForegroundColor White
            Write-Host "    Size: $size  |  Max: $($props.MaximumSizeInBytes/1MB) MB  |  Retention: $($props.LogMode)" -ForegroundColor DarkGray
        } catch {
            Write-Host "  $log — not available" -ForegroundColor DarkGray
        }
    }
}
