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
├── remote-install.ps1       ← one-command bootstrapper, safe via `irm <url> | iex`
├── update.ps1               ← git pull + reload profile
├── bootstrap.ps1            ← minimal snippet injected into $PROFILE
├── starship.toml            ← Starship prompt config (30+ modules)
├── index.html               ← GitHub Pages landing page
├── .nojekyll                ← disables Jekyll for Pages
├── .gitignore
│
├── lib/
│   ├── output.ps1           ← Write-Step/Ok/Skip/Fail/Warn — shared by install.ps1/update.ps1
│   │                           only (NOT auto-loaded into the profile like core/ — these two
│   │                           scripts run standalone, often before a profile session exists)
│   └── paths.ps1            ← Resolve-DocumentsPath/Test-RootedPath/Get-NativeProfilePaths —
│                               Known-Folder-correct (OneDrive-safe) $PROFILE paths, dot-sourced
│                               by profile.ps1 and used by install.ps1/core/status.ps1; every
│                               candidate is validated before use (a corrupted Known Folder
│                               registry value falls back to $HOME\Documents instead of crashing)
│
├── core/                    ← ALWAYS loaded (shared across all PS versions/hosts)
│   ├── aliases.ps1          ← git, docker, kubectl shortcuts
│   ├── functions.ps1        ← Edit-Profile, Reload-Profile, Get-SecretKey, mkcd, Test-Admin
│   ├── env.ps1              ← $env:EDITOR, PATH, $env:DOTFILES_TOOLS
│   ├── diag.ps1             ← ETW/PSDiagnostics tracing (Windows-only, early-returns elsewhere)
│   ├── perf.ps1             ← Measure-Profile, Clear-PSCache, Optimize-ModuleLoading, Get-ProfileSize
│   ├── status.ps1           ← Show-Status — global health dashboard
│   └── extra.ps1.example    ← template for gitignored user overrides (copy to extra.ps1)
│
├── ps5/profile.ps1          ← Windows PowerShell 5.1 only (PSReadLine v2, UTF-8)
├── ps7/profile.ps1          ← PS 7+ only (PSReadLine v3, Starship/oh-my-posh, Terminal-Icons, PSFzf)
│
├── hosts/
│   ├── ConsoleHost.ps1      ← classic terminal (welcome banner, uptime, window title);
│   │                           sources wtprofile.ps1 itself (not via host detection)
│   ├── VSCode.ps1           ← VS Code integrated terminal (no banner, UTF-8)
│   ├── wtprofile.ps1        ← Windows Terminal utilities (zoxide, trash, Show-Help, …);
│   │                           only loads if $env:WT_SESSION is set — sourced from
│   │                           ConsoleHost.ps1, so it does NOT run under VSCode.ps1
│   └── shell-integration.ps1← OSC 133 prompt markers; sourced from ps7/profile.ps1 directly
│                               (not from host detection, so PS5 never gets it)
│
└── docs/
    ├── ARCHITECTURE.md       ← Mermaid UML diagrams
    ├── PURPOSE.md            ← design rationale & decisions
    └── PROMPT.md             ← original AI prompt that generated this project
```

---

## How it works (loading sequence)

```
PowerShell starts
  → $PROFILE (bootstrap snippet, at the Known-Folder-correct Documents path)
    → profile.ps1
      → detect environment once: $isPSCore ($PSVersionTable.PSVersion.Major -ge 6),
        $isWindowsHost ($IsWindows on PS7+, always $true on PS5.1 — $IsWindows doesn't exist there)
      → set $env:DOTFILES_PWSH, $env:DOTFILES_TOOLS
      → fix PSModulePath (PS5.1 and PS7 both: prepend LOCALAPPDATA, never Documents — OneDrive-safe)
      → dot-source lib/paths.ps1, core/*.ps1
      → dot-source ps5/ or ps7/ (based on $isPSCore)
        (ps7/profile.ps1 additionally dot-sources hosts/shell-integration.ps1
         directly — not via host detection, so this never runs on PS5)
      → dot-source hosts/ConsoleHost or VSCode (based on $host.Name)
        (ConsoleHost.ps1 additionally dot-sources hosts/wtprofile.ps1 itself;
         both wtprofile.ps1 and shell-integration.ps1 no-op unless
         $env:WT_SESSION is set)
      → optionally show load time ($env:PROFILE_BENCHMARK)
```

---

## How to install

One command, from any shell that has a PowerShell host on PATH:

```powershell
irm https://raw.githubusercontent.com/martinpaprcka77/dotfiles-powershell/main/remote-install.ps1 | iex
```

Or manually, for full parameter parity:

```powershell
git clone https://github.com/martinpaprcka77/dotfiles-powershell.git ~/.config/powershell
~/.config/powershell/install.ps1
# Restart PowerShell
```

`install.ps1` is idempotent — supports `-WhatIf`, `-Force`, `-NoUpdates`, `-NoTerminal`.
`remote-install.ps1` doesn't accept switches directly (can't reach parameters through `iex`) —
use `$env:DOTFILES_FORCE` / `$env:DOTFILES_NO_UPDATES` / `$env:DOTFILES_NO_TERMINAL` instead.

---

## How to add a new feature

1. **New function/alias** → add to `core/functions.ps1` or `core/aliases.ps1`
2. **PS7-only feature** → add to `ps7/profile.ps1` (guarded by `Import-Module` or `Get-Command`)
3. **PS5-only** → add to `ps5/profile.ps1`
4. **Host-specific** → add to `hosts/ConsoleHost.ps1` or `hosts/VSCode.ps1`
5. **New core file** → just drop a `.ps1` into `core/` — it auto-loads (profile.ps1 dot-sources all `core/*.ps1`)
6. **User overrides** → copy `core/extra.ps1.example` to `core/extra.ps1` (gitignored), add your code

### New in 2026
- `core/extra.ps1` — gitignored user overrides, auto-sourced
- `remote-install.ps1` — one-command `irm | iex` bootstrapper
- `lib/paths.ps1` — Known-Folder-correct (OneDrive-safe) `$PROFILE` path resolution, with
  `Test-RootedPath` validation against corrupted Known Folder registry values (field-reported)
- `core/status.ps1` — `Test-PathHealth` (PATH duplicates, User/Machine PATH overlap) + Environment
  section (user, host, PS edition/version, WT session, cwd)
- `deps.ps1` (tools) — winget-based package installer for fresh machines
- `windows.ps1` (tools) — Explorer, taskbar, privacy defaults
- `Add-WTProfiles.ps1` — now generates JSON fragment extensions (WT 1.24+)
- `lib/detectors.ps1` (tools) — live status detectors wired into every menu item
- `.vscode/` — committed settings.json + tasks.json in tools repo

---

## Coding conventions

- **Comment-based help** on every function (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`)
- **Verb-Noun naming** for functions (`Edit-Profile`, `Get-SecretKey`) — a few intentional
  exceptions exist for shell ergonomics (`mkcd`, `touch`, `ff`, `sed`, `k9`, …)
- **Error handling**: `try/catch` for network/external calls. `$ErrorActionPreference = 'Stop'`
  and `Set-StrictMode -Version Latest` are set at the top of `install.ps1`/`update.ps1` only —
  **never** in `profile.ps1` or `core/*.ps1`, where one failing optional file must not abort
  the whole profile load.
- **Idempotency**: use `Test-Path` before creating/modifying
- **No network calls in profile** — keep startup fast (lazy loading)
- **Cross-platform**: use `$IsWindows`, `$IsLinux`, `$IsMacOS` guards (available in PS6+ only —
  these are undefined on Windows PowerShell 5.1; guard with
  `$PSVersionTable.PSVersion.Major -ge 6` first, or PS5.1 will silently treat them as `$null`/falsy
  without `Set-StrictMode`, and throw with it)
- **Paths**: use `Join-Path`, not string concatenation; prefer `$env:DOTFILES_PWSH`/
  `$env:DOTFILES_TOOLS` over hardcoding once a profile session exists (see `core/functions.ps1`,
  `core/status.ps1`) — `bootstrap.ps1` and `install.ps1`'s injected snippet are the deliberate
  exceptions, since they run before those env vars exist
- **Native `$PROFILE` paths**: never hardcode `$HOME\Documents\...` — OneDrive can redirect
  Documents elsewhere. Use `Get-NativeProfilePaths`/`Resolve-DocumentsPath` from `lib/paths.ps1`
- **Known Folder / registry-derived paths**: validate before use, don't trust the first non-null
  value. A real machine had a corrupted `User Shell Folders\Personal` registry value
  (`%C:\Users\x%\Documents` — percent-wraps an already-resolved path) that survived
  `[Environment]::ExpandEnvironmentVariables()` unchanged and crashed `Join-Path` further down
  the chain. `lib/paths.ps1`'s `Test-RootedPath` is the pattern to reuse: confirm a real
  drive-letter/UNC prefix and no leftover `%` before accepting a candidate
- **Alias/function naming**: check `Get-Command -CommandType Alias <name>` before adding a short
  function name — a built-in PowerShell alias silently wins over a same-named function with no
  error (bit `gcm`/`gps` in `core/aliases.ps1` once; fixed via `Remove-Item Alias:<name> -Force`
  before the function definition)

---

## Key patterns used

```powershell
# Dot-source all .ps1 in a directory
Get-ChildItem -Path $dir -Filter *.ps1 | ForEach-Object { . $_.FullName }

# Detect PS version
if ($PSVersionTable.PSVersion.Major -ge 6) { "PS7" } else { "PS5" }

# Detect host
if ($host.Name -match 'Code') { 'VSCode' } else { 'ConsoleHost' }

# Fix PSModulePath (bypass OneDrive) — PS5.1 and PS7 both, different subfolder names
$moduleDir = if ($isPSCore) { 'PowerShell' } else { 'WindowsPowerShell' }
$localModules = "$env:LOCALAPPDATA\$moduleDir\Modules"
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
