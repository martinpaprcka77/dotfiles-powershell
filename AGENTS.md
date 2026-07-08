# AGENTS.md — dotfiles-powershell

> **For AI agents (Claude, DeepSeek, GPT-4, Reasonix, Copilot):**  
> This file tells you everything you need to know to work with this repo.

---

## What this repo is

**dotfiles-powershell** — the **profile orchestration** half of the PowerShell Dotfiles Ecosystem.

| Attribute | Value |
|-----------|-------|
| **Location on disk** | `~/.config/powershell/` |
| **Companion repo** | [dotfiles-tools](https://github.com/martinpaprcka77/dotfiles-tools) (`~/Projects/tools/`) |
| **Portal** | [martinpaprcka77.github.io](https://martinpaprcka77.github.io) |
| **Language** | PowerShell 5.1 / 7+ |
| **Tests** | None in this repo (tests live in dotfiles-tools) |
| **Dependencies** | Git, PowerShell 5.1+ |

---

## Directory map (what each file does)

```
~/.config/powershell/
├── profile.ps1              ← MAIN ORCHESTRATOR — dot-sources everything below
├── install.ps1              ← idempotent installer (runs git clone, injects bootstrap)
├── update.ps1               ← git pull + reload profile
├── bootstrap.ps1            ← minimal 4-line snippet injected into $PROFILE
├── index.html               ← GitHub Pages landing page
├── .nojekyll                ← disables Jekyll for Pages
├── .gitignore
│
├── core/                    ← ALWAYS loaded (shared across all PS versions/hosts)
│   ├── aliases.ps1          ← git, docker, kubectl shortcuts
│   ├── functions.ps1        ← Edit-Profile, Reload-Profile, Get-SecretKey, mkcd, Test-Admin
│   └── env.ps1              ← $env:EDITOR, PATH, $env:DOTFILES_TOOLS
│
├── ps5/profile.ps1          ← Windows PowerShell 5.1 only (PSReadLine v2, UTF-8)
├── ps7/profile.ps1          ← PS 7+ only (PSReadLine v3, oh-my-posh, Terminal-Icons, PSFzf)
│
├── hosts/
│   ├── ConsoleHost.ps1      ← classic terminal (welcome banner, uptime, window title)
│   └── VSCode.ps1           ← VS Code integrated terminal (no banner, UTF-8)
│
└── docs/
    ├── ARCHITECTURE.md       ← 4 Mermaid UML diagrams
    ├── PURPOSE.md            ← design rationale & decisions
    └── PROMPT.md             ← original AI prompt that generated this project
```

---

## How it works (loading sequence)

```
PowerShell starts
  → $PROFILE (bootstrap snippet)
    → profile.ps1
      → set $env:DOTFILES_PWSH, $env:DOTFILES_TOOLS
      → fix PSModulePath (PS7: prepend LOCALAPPDATA)
      → dot-source core/*.ps1
      → dot-source ps5/ or ps7/ (based on $PSVersionTable)
      → dot-source hosts/ConsoleHost or VSCode (based on $host.Name)
      → optionally show load time ($env:PROFILE_BENCHMARK)
```

---

## How to install

```powershell
git clone https://github.com/martinpaprcka77/dotfiles-powershell.git ~/.config/powershell
~/.config/powershell/install.ps1
# Restart PowerShell
```

`install.ps1` is idempotent — supports `-WhatIf`, `-Force`, `-NoUpdates`.

---

## How to add a new feature

1. **New function/alias** → add to `core/functions.ps1` or `core/aliases.ps1`
2. **PS7-only feature** → add to `ps7/profile.ps1` (guarded by `Import-Module` or `Get-Command`)
3. **PS5-only** → add to `ps5/profile.ps1`
4. **Host-specific** → add to `hosts/ConsoleHost.ps1` or `hosts/VSCode.ps1`
5. **New core file** → just drop a `.ps1` into `core/` — it auto-loads (profile.ps1 dot-sources all `core/*.ps1`)

---

## Coding conventions

- **Comment-based help** on every function (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`)
- **Verb-Noun naming** for functions (`Edit-Profile`, `Get-SecretKey`)
- **Error handling**: `try/catch` for network/external calls, `$ErrorActionPreference = 'Stop'` at script top
- **Idempotency**: use `Test-Path` before creating/modifying
- **No network calls in profile** — keep startup fast (lazy loading)
- **Cross-platform**: use `$IsWindows`, `$IsLinux`, `$IsMacOS` guards (available in PS6+)
- **Paths**: use `Join-Path`, not string concatenation

---

## Key patterns used

```powershell
# Dot-source all .ps1 in a directory
Get-ChildItem -Path $dir -Filter *.ps1 | ForEach-Object { . $_.FullName }

# Detect PS version
if ($PSVersionTable.PSVersion.Major -ge 6) { "PS7" } else { "PS5" }

# Detect host
if ($host.Name -match 'Code') { 'VSCode' } else { 'ConsoleHost' }

# Fix PSModulePath for PS7 (bypass OneDrive)
$localModules = "$env:LOCALAPPDATA\PowerShell\Modules"
if ($localModules -notin ($env:PSModulePath -split [IO.Path]::PathSeparator)) {
    $env:PSModulePath = "$localModules$([IO.Path]::PathSeparator)$env:PSModulePath"
}
```

---

## Prompts that understand this project

The original prompt that generated this entire ecosystem is preserved at:
- [docs/PROMPT.md](docs/PROMPT.md) — full 107-line Czech prompt
- [Gist: prompt-reference](https://gist.github.com/martinpaprcka77/d4126cd2ef53a97a6a6beb38d420bff6)

To regenerate or modify: give the PROMPT.md content to any capable AI model.

---

## Related resources

| Resource | URL |
|----------|-----|
| **Portal** | https://martinpaprcka77.github.io |
| **Companion repo** | https://github.com/martinpaprcka77/dotfiles-tools |
| **Gist: Install** | https://gist.github.com/martinpaprcka77/bafc2457fd9d93daf1b1b69c348e0cfd |
| **Gist: Cheatsheet** | https://gist.github.com/martinpaprcka77/b30ae161dfb693431a438e309f236467 |
| **Gist: Prompt** | https://gist.github.com/martinpaprcka77/d4126cd2ef53a97a6a6beb38d420bff6 |
