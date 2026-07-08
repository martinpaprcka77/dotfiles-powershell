<#
.SYNOPSIS
    Bootstrap skript vkládaný do nativních PowerShell profilů.
.DESCRIPTION
    Minimální kód, který pouze dot-sourcuje hlavní profil z ~/.config/powershell/.
    Tento soubor slouží jako reference – install.ps1 vkládá jeho obsah do profilů.
.NOTES
    Cesta: ~/.config/powershell/bootstrap.ps1
#>

# Bootstrap: dotfiles-powershell
$dotfilesProfile = Join-Path $HOME '.config\powershell\profile.ps1'
if (Test-Path $dotfilesProfile) { . $dotfilesProfile }
