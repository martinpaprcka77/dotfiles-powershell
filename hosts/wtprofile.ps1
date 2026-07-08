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
    Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
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
}

# ═══════════════════════════════════════════════════════════════
# Utility Functions
# ═══════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    Vytvoří soubor nebo aktualizuje jeho čas (jako Linux touch).
#>
function touch {
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
    param([string]$Path)
    if (-not (Test-Path $Path)) { Write-Warn "Not found: $Path"; return }
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
    param([string]$Name)
    Get-ChildItem -Recurse -Filter $Name -File -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
}

<#
.SYNOPSIS
    Najde cestu k příkazu (jako Linux which).
#>
function which {
    param([string]$Name)
    (Get-Command $Name -ErrorAction SilentlyContinue).Source
}

<#
.SYNOPSIS
    Nahradí text v souboru (jako Linux sed).
#>
function sed {
    param([string]$File, [string]$Find, [string]$Replace)
    (Get-Content $File -Raw).Replace($Find, $Replace) | Set-Content $File -NoNewline
}

<#
.SYNOPSIS
    Zobrazí prvních 10 řádků souboru (jako Linux head).
#>
function head {
    param([string]$Path, [int]$Lines = 10)
    Get-Content $Path -Head $Lines
}

<#
.SYNOPSIS
    Najde proces podle názvu.
#>
function pgrep {
    param([string]$Name)
    Get-Process -Name $Name -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Ukončí proces podle názvu.
#>
function pkill {
    param([string]$Name)
    Get-Process -Name $Name -ErrorAction SilentlyContinue | Stop-Process -Force
}

<#
.SYNOPSIS
    Alias pro pkill.
#>
function k9 { param([string]$Name) pkill $Name }

<#
.SYNOPSIS
    Zobrazí dobu běhu systému.
#>
function uptime {
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
    Write-Host @"


$($PSStyle.Foreground.BrightMagenta)⚡ Windows Terminal Profile — Help$($PSStyle.Reset)
$($PSStyle.Foreground.BrightBlack)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($PSStyle.Reset)

$($PSStyle.Foreground.BrightBlue)📂 Navigation$($PSStyle.Reset)
$($PSStyle.Foreground.BrightBlack)─────────────────────────────────────────────$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)z <dir>$($PSStyle.Reset)         $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Smart jump to directory (learns your habits)$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)mkcd <dir>$($PSStyle.Reset)      $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Create + enter directory$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)docs$($PSStyle.Reset)            $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Jump to Documents$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)ll$($PSStyle.Reset)              $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)List files with hidden$($PSStyle.Reset)

$($PSStyle.Foreground.BrightBlue)📁 Files$($PSStyle.Reset)
$($PSStyle.Foreground.BrightBlack)─────────────────────────────────────────────$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)touch <file>$($PSStyle.Reset)   $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Create file or update timestamp$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)trash <path>$($PSStyle.Reset)   $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Move to Recycle Bin$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)ff <name>$($PSStyle.Reset)      $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Recursive file search$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)grep <pattern>$($PSStyle.Reset) $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Search text in files$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)head <file>$($PSStyle.Reset)    $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)First 10 lines$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)sed <f> <old> <new>$($PSStyle.Reset) $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Replace text in file$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)unzip <file>$($PSStyle.Reset)   $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Expand archive$($PSStyle.Reset)

$($PSStyle.Foreground.BrightBlue)🔧 System$($PSStyle.Reset)
$($PSStyle.Foreground.BrightBlack)─────────────────────────────────────────────$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)uptime$($PSStyle.Reset)         $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)System uptime$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)which <cmd>$($PSStyle.Reset)    $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Locate command path$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)pgrep <name>$($PSStyle.Reset)   $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Find process$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)pkill <name>$($PSStyle.Reset)   $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Kill process$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)k9 <name>$($PSStyle.Reset)      $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Alias for pkill$($PSStyle.Reset)

$($PSStyle.Foreground.BrightBlue)🎨 Profile$($PSStyle.Reset)
$($PSStyle.Foreground.BrightBlack)─────────────────────────────────────────────$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)ep$($PSStyle.Reset)              $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Edit profile$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)rp$($PSStyle.Reset)              $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Reload profile$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)menu$($PSStyle.Reset)            $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Interactive main menu$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)check$($PSStyle.Reset)           $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)System diagnostics$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)update$($PSStyle.Reset)          $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)Git pull + reload$($PSStyle.Reset)
  $($PSStyle.Foreground.BrightGreen)Show-Help$($PSStyle.Reset)      $($PSStyle.Foreground.BrightYellow)→$($PSStyle.Reset) $($PSStyle.Foreground.BrightWhite)This help screen$($PSStyle.Reset)

$($PSStyle.Foreground.BrightBlack)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($PSStyle.Reset)
"@
}
