<#
.SYNOPSIS
    Bootstrap skript vkládaný do nativních PowerShell profilů.
.DESCRIPTION
    Minimální kód, který pouze dot-sourcuje hlavní profil z ~/.config/powershell/.
    Tento soubor slouží jako reference – install.ps1 vkládá jeho obsah do profilů.
.NOTES
    Cesta: ~/.config/powershell/bootstrap.ps1
    Cesta je záměrně napevno zapsaná — tento kód běží PŘED profile.ps1, takže
    $env:DOTFILES_PWSH ještě neexistuje. Nekonsolidovat s core/functions.ps1
    ani core/status.ps1 (ty běží až po profile.ps1 a env proměnnou už mají).
#>

# Bootstrap: dotfiles-powershell
$dotfilesProfile = Join-Path $HOME '.config\powershell\profile.ps1'
if (Test-Path $dotfilesProfile) { . $dotfilesProfile }
