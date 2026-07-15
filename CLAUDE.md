# CLAUDE.md — dotfiles-powershell

> Memory file for Claude. Load this before working with the repo.

## Identity
This is the **profile orchestration** repo of the PowerShell Dotfiles Ecosystem.
Companion: `dotfiles-tools` at `~/Projects/tools/`.

## Key files
- `profile.ps1` — main orchestrator, dot-sources everything
- `install.ps1` — idempotent installer (git clone, bootstrap injection, PATH setup)
- `remote-install.ps1` — one-command bootstrapper, safe to run via `irm | iex` (no `SupportsShouldProcess` — `$PSCmdlet` is `$null` under `Invoke-Expression`)
- `update.ps1` — git pull + profile reload
- `lib/output.ps1` — shared Write-Step/Ok/Skip/Fail/Warn for install.ps1/update.ps1 (not auto-loaded like core/)
- `lib/paths.ps1` — `Resolve-DocumentsPath`/`Get-NativeProfilePaths`, Known-Folder-correct (OneDrive-safe) `$PROFILE` targets, reused by `install.ps1` and `core/status.ps1`; every candidate source is validated with `Test-RootedPath` before use, so a corrupted Known Folder registry value (field-reported: `%C:\Users\x%\Documents`) falls back to `$HOME\Documents` instead of crashing `Join-Path`
- `core/functions.ps1` — Edit-Profile, Reload-Profile, Get-SecretKey, mkcd
- `core/status.ps1`, `core/perf.ps1`, `core/diag.ps1` — health dashboard (incl. `Test-PathHealth` PATH-duplicate/User-Machine-overlap check), load-time profiling, ETW tracing (Windows-only)

## Architecture decisions
- `~/.config/powershell/` chosen over `Documents\` to bypass OneDrive
- Two repos (profiles vs tools) for independent version cycles — consolidation into one monorepo
  was considered and explicitly deferred to the roadmap (`docs/ROADMAP.md`), not abandoned: revisit
  once the ecosystem is "simple, functional, and polished"
- `PSModulePath` fixed on **both PS5.1 and PS7** to avoid OneDrive pollution — the "modern" target
  path is `$env:LOCALAPPDATA\...\Modules`, never `$env:USERPROFILE\Documents\...\Modules` (that's
  exactly the OneDrive-affected path this fix exists to avoid)
- Host detection via `$host.Name -match 'Code'`
- Environment detection (`$isPSCore`, `$isWindowsHost`) consolidated once at the top of
  `profile.ps1`, reused by both the PSModulePath fix and the ps5/ps7 profile-dir selection —
  avoids duplicate `$PSVersionTable` checks
- Before naming a short function/alias: check `Get-Command -CommandType Alias` first — a built-in
  alias silently wins over a same-named function (bit `gcm`/`gps` once, see AGENTS.md)
- Never trust a Known Folder/registry-derived path unvalidated — Windows can have a genuinely
  corrupted `User Shell Folders` value (field-reported); `lib/paths.ps1`'s `Test-RootedPath`
  checks every candidate looks like a real drive-letter/UNC path (no leftover `%...%`) before
  it's used, falling back instead of crashing

## How to build/test
- No build step — just dot-source to apply
- No tests in this repo (tests in dotfiles-tools)
- Validate: `& $PROFILE` in a fresh session, check for errors

## Patterns
- All `core/*.ps1` auto-loaded — drop new `.ps1` there
- Version-specific: `ps5/` or `ps7/` based on `$PSVersionTable.PSVersion.Major`
- Host-specific: `hosts/ConsoleHost.ps1` or `hosts/VSCode.ps1`
- `$env:PROFILE_BENCHMARK = 'true'` to measure load time

## Doc links
- [AGENTS.md](AGENTS.md) — full AI agent guide
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Mermaid UML diagrams
- [docs/PURPOSE.md](docs/PURPOSE.md) — design rationale
- [docs/PROMPT.md](docs/PROMPT.md) — original AI prompt
