<#
.SYNOPSIS
    Aliasy pro každodenní použití.
.DESCRIPTION
    Definice PowerShell aliasů. Načítá se z profile.ps1.
.NOTES
    Cesta: ~/.config/powershell/core/aliases.ps1
#>

# Navigation
Set-Alias -Name ll  -Value Get-ChildItem -Force

# Edit profile
Set-Alias -Name ep  -Value Edit-Profile -Force

# Reload profile
Set-Alias -Name rp  -Value Reload-Profile -Force

# Git shortcuts (if git is available)
if (Get-Command git -ErrorAction SilentlyContinue) {
    function g {
        [CmdletBinding()]
        param([Parameter(ValueFromRemainingArguments)]$GitArgs)
        git @GitArgs
    }
    function gst { git status @args }
    function gco { git checkout @args }
    function gbr { git branch @args }
    function gcm { git commit -m @args }
    function gpl { git pull @args }
    function gps { git push @args }
    function gdf { git diff @args }
    function glo { git log --oneline --graph --decorate -20 @args }
}

# Kubernetes shortcuts (if kubectl is available)
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Set-Alias -Name k   -Value kubectl
    Set-Alias -Name kx  -Value kubectx -Force
    Set-Alias -Name kns -Value kubens -Force
}

# Docker shortcuts (if docker is available)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    function dps { docker ps $args }
    function dpsa { docker ps -a $args }
    function dcu { docker compose up -d $args }
    function dcd { docker compose down $args }
}
