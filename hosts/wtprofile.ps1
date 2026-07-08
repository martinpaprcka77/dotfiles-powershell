<#
.SYNOPSIS
    Windows Terminal enhanced profile — CTT-inspired utilities and quality-of-life.
.DESCRIPTION
    Activates only when $env:WT_SESSION is set (Windows Terminal).
    Provides: zoxide smart jumper, trash (Recycle Bin), ff (file find),
    PSReadLine syntax colors, Show-Help, and more.
    Inspired by ChrisTitusTech/powershell-profile (MIT).
.NOTES
    Cesta: ~/.config/powershell/hosts/wtprofile.ps1
    Sources: https://github.com/ChrisTitusTech/powershell-profile
#>

# Only activate in Windows Terminal
if (-not $env:WT_SESSION) { return }

# ── Telemetry opt-out ──────────────────────────────────────────
[System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'User')

# ── zoxide — smart directory jumper ────────────────────────────
# https://github.com/ajeetdsouza/zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (zoxide init --cmd z powershell | Out-String)
}

# ── PSReadLine — syntax colors + keybinds ──────────────────────
if ($null -ne (Get-Module -ListAvailable -Name PSReadLine | Sort-Object Version -Descending | Select-Object -First 1)) {
    Set-PSReadLineOption -Colors @{
        Command   = '#87CEEB'   # SkyBlue
        Parameter = '#98FB98'   # PaleGreen
        Operator  = '#FFB6C1'   # LightPink
        Variable  = '#DDA0DD'   # Plum
        String    = '#FFDAB9'   # PeachPuff
        Number    = '#B0E0E6'   # PowderBlue
        Type      = '#F0E68C'   # Khaki
        Comment   = '#6A9955'   # Green comment
        Keyword   = '#569CD6'   # Blue keyword
        Error     = '#F44747'   # Red error
    }

    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord 'Alt+d'  -Function DeleteWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

    # ── History scrubbing — prevent secrets from being saved ──
    # Patterns to detect: API keys, tokens, passwords, connection strings
    $sensitivePatterns = @(
        '(?i)(api.?key|token|secret|password|credential)\s*[=:]\s*\S+',
        '(?i)(Bearer\s+\S+)',
        '(?i)(connect.*-Password\s+\S+)',
        '(?i)(Set-Secret|Set-SecretInfo)\s',
        '(?i)(export\s+.*TOKEN)'
    )
    Set-PSReadLineOption -AddToHistoryHandler {
        param($command)
        foreach ($pattern in $sensitivePatterns) {
            if ($command -match $pattern) {
                return $false  # Don't save to history
            }
        }
        return $true
    }
}

# ═══════════════════════════════════════════════════════════════
# Utility Functions
# ═══════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    Vytvoří soubor nebo aktualizuje jeho čas (jako Linux touch).
#>
function touch {
    [CmdletBinding()]
    param([string]$File)
    if (Test-Path $File) {
        (Get-Item $File).LastWriteTime = Get-Date
    } else {
        New-Item $File -ItemType File | Out-Null
    }
}

<#
.SYNOPSIS
    Přesune soubor/adresář do Koše (místo trvalého smazání).
#>
function trash {
    [CmdletBinding()]
    param([string]$Path)
    if (-not (Test-Path $Path)) { Write-Warning "Not found: $Path"; return }
    if (Test-Path $Path -PathType Container) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
    } else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
}

<#
.SYNOPSIS
    Rekurzivně hledá soubory podle názvu (jako Linux find -name).
#>
function ff {
    [CmdletBinding()]
    param([string]$Name)
    Get-ChildItem -Recurse -Filter $Name -File -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
}

<#
.SYNOPSIS
    Najde cestu k příkazu (jako Linux which).
#>
function which {
    [CmdletBinding()]
    param([string]$Name)
    (Get-Command $Name -ErrorAction SilentlyContinue).Source
}

<#
.SYNOPSIS
    Nahradí text v souboru (jako Linux sed).
#>
function sed {
    [CmdletBinding()]
    # ponytail: case-sensitive .Replace(), not regex like real sed; add -Replace for regex if needed
    param([string]$File, [string]$Find, [string]$Replace)
    (Get-Content $File -Raw).Replace($Find, $Replace) | Set-Content $File -NoNewline
}

<#
.SYNOPSIS
    Zobrazí první řádky souboru (jako Linux head).
    PS5 fallback: Select-Object -First (no -Head parameter).
#>
function head {
    [CmdletBinding()]
    param([string]$Path, [int]$Lines = 10)
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Get-Content $Path -Head $Lines
    } else {
        Get-Content $Path | Select-Object -First $Lines
    }
}

<#
.SYNOPSIS
    Najde proces podle názvu.
#>
function pgrep {
    [CmdletBinding()]
    param([string]$Name)
    Get-Process -Name $Name -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Ukončí proces podle názvu.
#>
function pkill {
    [CmdletBinding()]
    param([string]$Name)
    Get-Process -Name $Name -ErrorAction SilentlyContinue | Stop-Process -Force
}

<#
.SYNOPSIS
    Alias pro pkill.
#>
function k9 {
    [CmdletBinding()]
    param([string]$Name) pkill $Name }

<#
.SYNOPSIS
    Zobrazí dobu běhu systému.
#>
function uptime {
    [CmdletBinding()]
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
}

# ── Additional Aliases ─────────────────────────────────────────
Set-Alias -Name unzip -Value Expand-Archive
Set-Alias -Name grep  -Value Select-String

# ═══════════════════════════════════════════════════════════════
# Show-Help
# ═══════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    Zobrazí přehled všech dostupných funkcí a zkratek.
#>
function Show-Help {
    [CmdletBinding()]
    # $PSStyle only exists in PS7+; fallback to plain text on PS5
    $s = if ($PSVersionTable.PSVersion.Major -ge 7) { $PSStyle } else { $null }
    $m = if ($s) { $s.Foreground.BrightMagenta } else { '' }; $r = if ($s) { $s.Reset } else { '' }
    $b = if ($s) { $s.Foreground.BrightBlue } else { '' };   $k = if ($s) { $s.Foreground.BrightBlack } else { '' }
    $g = if ($s) { $s.Foreground.BrightGreen } else { '' };   $y = if ($s) { $s.Foreground.BrightYellow } else { '' }
    $w = if ($s) { $s.Foreground.BrightWhite } else { '' }

    Write-Host @"


${m}⚡ Windows Terminal Profile — Help${r}
${k}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${r}

${b}📂 Navigation${r}
${k}─────────────────────────────────────────────${r}
  ${g}z <dir>${r}         ${y}→${r} ${w}Smart jump to directory (learns your habits)${r}
  ${g}mkcd <dir>${r}      ${y}→${r} ${w}Create + enter directory${r}
  ${g}docs${r}            ${y}→${r} ${w}Jump to Documents${r}
  ${g}ll${r}              ${y}→${r} ${w}List files with hidden${r}

${b}📁 Files${r}
${k}─────────────────────────────────────────────${r}
  ${g}touch <file>${r}   ${y}→${r} ${w}Create file or update timestamp${r}
  ${g}trash <path>${r}   ${y}→${r} ${w}Move to Recycle Bin${r}
  ${g}ff <name>${r}      ${y}→${r} ${w}Recursive file search${r}
  ${g}grep <pattern>${r} ${y}→${r} ${w}Search text in files${r}
  ${g}head <file>${r}    ${y}→${r} ${w}First N lines${r}
  ${g}sed <f> <old> <new>${r} ${y}→${r} ${w}Replace text in file${r}
  ${g}unzip <file>${r}   ${y}→${r} ${w}Expand archive${r}

${b}🔧 System${r}
${k}─────────────────────────────────────────────${r}
  ${g}uptime${r}         ${y}→${r} ${w}System uptime${r}
  ${g}which <cmd>${r}    ${y}→${r} ${w}Locate command path${r}
  ${g}pgrep <name>${r}   ${y}→${r} ${w}Find process${r}
  ${g}pkill <name>${r}   ${y}→${r} ${w}Kill process${r}
  ${g}k9 <name>${r}      ${y}→${r} ${w}Alias for pkill${r}

${b}🎨 Profile${r}
${k}─────────────────────────────────────────────${r}
  ${g}ep${r}              ${y}→${r} ${w}Edit profile${r}
  ${g}rp${r}              ${y}→${r} ${w}Reload profile${r}
  ${g}menu${r}            ${y}→${r} ${w}Interactive main menu${r}
  ${g}check${r}           ${y}→${r} ${w}System diagnostics${r}
  ${g}update${r}          ${y}→${r} ${w}Git pull + reload${r}
  ${g}Show-Help${r}      ${y}→${r} ${w}This help screen${r}

${k}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${r}
"@
}
