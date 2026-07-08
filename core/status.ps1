<#
.SYNOPSIS
    Global health dashboard for the entire dotfiles ecosystem.
.DESCRIPTION
    Shows status of: Dotfiles profiles, WT fragment, VS Code configs,
    PowerShell modules, environment variables, PATH, Git repos.
.NOTES
    Cesta: ~/.config/powershell/core/status.ps1
#>

function Show-Status {
    [CmdletBinding()]
    param()
    Write-Host "   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
    Write-Host "   $(('─' * 55))" -ForegroundColor DarkGray

    $ok = 0; $warn = 0; $fail = 0

    function Dot { param([string]$L, [string]$S, [string]$Extra)
        $c = if ($S -eq '✅') { $script:ok++; 'Green' } elseif ($S -eq '⚠️') { $script:warn++; 'Yellow' } else { $script:fail++; 'Red' }
        $line = "   $S $L"
        if ($Extra) { $line += "  $Extra" }
        Write-Host $line -ForegroundColor $c
    }

    # ── Dotfiles ───────────────────────────────────────────────
    Write-Host "`n   DOTFILES" -ForegroundColor Cyan
    Dot 'Main profile'        $(if (Test-Path (Join-Path $HOME '.config\powershell\profile.ps1')) { '✅' } else { '❌' })
    Dot 'Bootstrap (PS7)'     $(if ((Test-Path "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1") -and (Get-Content "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Raw -ErrorAction SilentlyContinue) -match 'Bootstrap') { '✅' } else { '⚠️' })
    Dot 'Bootstrap (PS5)'     $(if ((Test-Path "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1") -and (Get-Content "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Raw -ErrorAction SilentlyContinue) -match 'Bootstrap') { '✅' } else { '⚠️' })
    Dot 'tools/bin in PATH'   $(if ((Join-Path $HOME 'Projects\tools\bin') -in ($env:PATH -split [IO.Path]::PathSeparator)) { '✅' } else { '⚠️' })
    Dot '$env:DOTFILES_PWSH'  $(if ($env:DOTFILES_PWSH) { '✅' } else { '⚠️' })
    Dot '$env:DOTFILES_TOOLS' $(if ($env:DOTFILES_TOOLS) { '✅' } else { '⚠️' })

    # ── Terminal ───────────────────────────────────────────────
    Write-Host "`n   TERMINAL" -ForegroundColor Cyan
    $frag = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\Fragments\dotfiles\dotfiles.json"
    Dot 'WT fragment'         $(if (Test-Path $frag) { '✅' } else { '⚠️' })
    if (Test-Path $frag) {
        try { $fj = Get-Content $frag -Raw | ConvertFrom-Json; $sc = @($fj.schemes).Count; $pc = @($fj.profiles).Count
            Dot "  $pc profiles, $sc schemes" '✅'
        } catch { Dot '  Fragment parse error' '❌' }
    }
    Dot 'Shell integration'   $(if ($env:WT_SESSION) { '✅' } else { '⚠️' })

    # ── PowerShell ─────────────────────────────────────────────
    Write-Host "`n   POWERSHELL" -ForegroundColor Cyan
    Dot "Version"             $(if ($PSVersionTable.PSVersion.Major -ge 7) { '✅' } else { '⚠️' }) "v$($PSVersionTable.PSVersion)"
    Dot 'PSReadLine'          $(if (Get-Module PSReadLine) { '✅' } else { '⚠️' })
    Dot 'Toolkit module'      $(if (Get-Module Toolkit) { '✅' } else { '⚠️' })
    Dot 'Starship prompt'     $(if (Get-Command starship -ErrorAction SilentlyContinue) { '✅' } else { '⚠️' })
    $modCount = @(Get-Module | Where-Object { $_.Name -notmatch '^Microsoft\.' }).Count
    Dot "Extra modules"       $(if ($modCount -le 5) { '✅' } else { '⚠️' }) "$modCount loaded"

    # ── VS Code ────────────────────────────────────────────────
    Write-Host "`n   VS CODE" -ForegroundColor Cyan
    Dot 'code in PATH'        $(if (Get-Command code -ErrorAction SilentlyContinue) { '✅' } else { '⚠️' })
    Dot 'Committed settings'  $(if (Test-Path (Join-Path $env:DOTFILES_TOOLS '.vscode\settings.json')) { '✅' } else { '⚠️' })
    Dot 'Committed tasks'     $(if (Test-Path (Join-Path $env:DOTFILES_TOOLS '.vscode\tasks.json')) { '✅' } else { '⚠️' })

    # ── Git ────────────────────────────────────────────────────
    Write-Host "`n   GIT" -ForegroundColor Cyan
    Dot 'Git installed'       $(if (Get-Command git -ErrorAction SilentlyContinue) { '✅' } else { '❌' })
    Dot 'powershell repo'     $(if (Test-Path (Join-Path $HOME '.config\powershell\.git')) { '✅' } else { '⚠️' })
    Dot 'tools repo'          $(if (Test-Path (Join-Path $HOME 'Projects\tools\.git')) { '✅' } else { '⚠️' })

    # ── Docker ─────────────────────────────────────────────────
    Write-Host "`n   DOCKER" -ForegroundColor Cyan
    Dot 'Docker installed'    $(if (Get-Command docker -ErrorAction SilentlyContinue) { '✅' } else { '⚠️' })
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $running = (docker ps -q 2>$null | Measure-Object).Count
        Dot "  Running containers" '✅' "$running"
    }

    # ── Summary ────────────────────────────────────────────────
    Write-Host "`n   $(('─' * 55))" -ForegroundColor DarkGray
    Write-Host "   ✅ $ok  ⚠️ $warn  ❌ $fail" -ForegroundColor White
    if ($fail -gt 0) { Write-Host "   Run install.ps1 to fix issues." -ForegroundColor Red }
    elseif ($warn -gt 0) { Write-Host "   Run precheck.ps1 for detailed diagnostics." -ForegroundColor Yellow }
    else { Write-Host "   All systems nominal." -ForegroundColor Green }
}
