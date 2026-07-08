<#
.SYNOPSIS
    Nastavení proměnných prostředí.
.DESCRIPTION
    Inicializuje $env:EDITOR, přidá tools/bin do PATH, nastaví $env:DOTFILES_TOOLS.
.NOTES
    Cesta: ~/.config/powershell/core/env.ps1
#>

# Editor
if (-not $env:EDITOR) {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        $env:EDITOR = 'code'
    }
    elseif (Get-Command nvim -ErrorAction SilentlyContinue) {
        $env:EDITOR = 'nvim'
    }
    elseif (Get-Command vim -ErrorAction SilentlyContinue) {
        $env:EDITOR = 'vim'
    }
    else {
        $env:EDITOR = 'notepad'
    }
}

# Tools PATH (idempotent)
$toolsBin = Join-Path $env:DOTFILES_TOOLS 'bin'
if ($toolsBin -notin ($env:PATH -split [IO.Path]::PathSeparator)) {
    $env:PATH = "$toolsBin$([IO.Path]::PathSeparator)$env:PATH"
}

# Confirm DOTFILES_TOOLS
if (-not $env:DOTFILES_TOOLS) {
    $env:DOTFILES_TOOLS = Join-Path $HOME 'Projects\tools'
}
