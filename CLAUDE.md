# CLAUDE.md — dotfiles-powershell

> Memory file for Claude. Load this before working with the repo.

## Identity
This is the **profile orchestration** repo of the PowerShell Dotfiles Ecosystem.
Companion: `dotfiles-tools` at `~/Projects/tools/`.

## Key files
- `profile.ps1` — main orchestrator, dot-sources everything
- `install.ps1` — idempotent installer (git clone, bootstrap injection, PATH setup)
- `update.ps1` — git pull + profile reload
- `lib/output.ps1` — shared Write-Step/Ok/Skip/Fail/Warn for install.ps1/update.ps1 (not auto-loaded like core/)
- `core/functions.ps1` — Edit-Profile, Reload-Profile, Get-SecretKey, mkcd
- `core/status.ps1`, `core/perf.ps1`, `core/diag.ps1` — health dashboard, load-time profiling, ETW tracing (Windows-only)

## Architecture decisions
- `~/.config/powershell/` chosen over `Documents\` to bypass OneDrive
- Two repos (profiles vs tools) for independent version cycles
- `PSModulePath` fixed on PS7 to avoid OneDrive pollution
- Host detection via `$host.Name -match 'Code'`

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
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — 4 Mermaid UML diagrams
- [docs/PURPOSE.md](docs/PURPOSE.md) — design rationale
- [docs/PROMPT.md](docs/PROMPT.md) — original AI prompt
