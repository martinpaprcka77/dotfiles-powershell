<#
.SYNOPSIS
    Nastavení pro klasickou konzoli (ConsoleHost).
.DESCRIPTION
    Titulek okna, uvítací zpráva, vlastní prompt prefix.
.NOTES
    Cesta: ~/.config/powershell/hosts/ConsoleHost.ps1
#>

# Window title
$host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion)"

# Welcome message
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$uptime = if ($os) { (Get-Date) - $os.LastBootUpTime }
$uptimeStr = if ($uptime) { "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" } else { "unknown" }

Write-Host @"
╔══════════════════════════════════════════════╗
║  PowerShell $($PSVersionTable.PSVersion.ToString().PadRight(29)) ║
║  $($env:USERNAME)@$($env:COMPUTERNAME).PadRight(39) ║
║  Uptime: $($uptimeStr.PadRight(33)) ║
╚══════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
