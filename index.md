---
title: PowerShell Dotfiles Ecosystem
description: Modular, version-controlled PowerShell profile & toolbox — bypasses OneDrive, portable across machines
---

# ⚡ PowerShell Dotfiles Ecosystem

**Modulární, verzovaný, přenositelný** — profil, nástroje a automatické nastavení Windows Terminálu, které obchází OneDrive.

[![GitHub](https://img.shields.io/badge/repo-powershell-blue)](https://github.com/martinpaprcka77/dotfiles-powershell)
[![GitHub](https://img.shields.io/badge/repo-tools-orange)](https://github.com/martinpaprcka77/dotfiles-tools)
[![Pages](https://img.shields.io/badge/pages-powershell-green)](https://martinpaprcka77.github.io/dotfiles-powershell/)
[![Pages](https://img.shields.io/badge/pages-tools-brightgreen)](https://martinpaprcka77.github.io/dotfiles-tools/)
[![Gist](https://img.shields.io/badge/gist-install-lightgrey)](https://gist.github.com/martinpaprcka77/bafc2457fd9d93daf1b1b69c348e0cfd)
[![Gist](https://img.shields.io/badge/gist-cheatsheet-lightgrey)](https://gist.github.com/martinpaprcka77/b30ae161dfb693431a438e309f236467)

---

## 🚀 One-Liner Install

```powershell
git clone https://github.com/martinpaprcka77/dotfiles-powershell.git $HOME/.config/powershell
git clone https://github.com/martinpaprcka77/dotfiles-tools.git $HOME/Projects/tools
& $HOME/.config/powershell/install.ps1
```

**Restart PowerShell** → `menu` + `check` ready.

---

## 🗺️ Repo Boundary

| | [dotfiles-powershell](https://github.com/martinpaprcka77/dotfiles-powershell) | [dotfiles-tools](https://github.com/martinpaprcka77/dotfiles-tools) |
|---|---|---|
| **Location** | `~/.config/powershell/` | `~/Projects/tools/` |
| **Purpose** | Profile orchestration | Menu & diagnostics |
| **Module** | — | `Toolkit` (18 functions) |
| **Key files** | `profile.ps1`, `install.ps1`, `update.ps1` | `menu.ps1`, `check.ps1`, `configure.ps1` |
| **Tests** | — | 25+ Pester cases |
| **Pages** | [🔗 martinpaprcka77.github.io/dotfiles-powershell](https://martinpaprcka77.github.io/dotfiles-powershell/) | [🔗 martinpaprcka77.github.io/dotfiles-tools](https://martinpaprcka77.github.io/dotfiles-tools/) |
| **Gists** | [🚀 Install](https://gist.github.com/martinpaprcka77/bafc2457fd9d93daf1b1b69c348e0cfd) · [📋 Cheatsheet](https://gist.github.com/martinpaprcka77/b30ae161dfb693431a438e309f236467) | — |

---

## 🧩 UML: Profile Loading Flow

```mermaid
flowchart TD
    START["PowerShell starts"] --> PROF{"$PROFILE exists?"}
    PROF -->|yes| BOOT["bootstrap → profile.ps1"]
    PROF -->|no| DONE["Empty session"]
    BOOT --> MAIN["📄 profile.ps1"]
    MAIN --> ENV["Set $env:DOTFILES_PWSH<br/>Set $env:DOTFILES_TOOLS"]
    ENV --> PS7FIX["🔧 Fix PSModulePath (PS7)"]
    PS7FIX --> CORE["📁 core/*.ps1"]
    CORE --> VER{"PSVersion ≥ 6?"}
    VER -->|yes| PS7["📁 ps7/profile.ps1<br/>PSReadLine · oh-my-posh · PSFzf"]
    VER -->|no| PS5["📁 ps5/profile.ps1"]
    PS7 --> HOST{"$host.Name =~ 'Code'?"}
    PS5 --> HOST
    HOST -->|yes| VS["📁 hosts/VSCode.ps1"]
    HOST -->|no| CON["📁 hosts/ConsoleHost.ps1<br/>Welcome · Uptime · Title"]
    VS --> READY["✅ Ready"]
    CON --> READY
```

---

## 🧩 UML: Tools Component Diagram

```mermaid
graph TB
    subgraph "PATH"
        MENU["menu.ps1"]; CHECK["check.ps1"]
    end
    subgraph "Toolkit Module"
        PSD1["Toolkit.psd1<br/>18 exports"]; PSM1["Toolkit.psm1"]
    end
    subgraph "lib/"
        COMMON["common.ps1"]; MENU_LIB["menu.ps1"]; CHECKERS["checkers.ps1"]; CONFIG["config.ps1"]
    end
    subgraph "menu/"
        MAIN["menu-main.ps1"]; DOCKER["menu-docker.ps1"]; GITM["menu-git.ps1"]
    end
    subgraph "scripts/"
        WT["Add-WTProfiles"]; ICONS["Generate-Icons"]; CFG["configure.ps1"]; SETUP["setup-repos.ps1"]
    end
    MENU --> PSD1; CHECK --> PSD1; PSD1 --> PSM1
    PSM1 --> COMMON; PSM1 --> MENU_LIB; PSM1 --> CHECKERS; PSM1 --> CONFIG
    MAIN --> PSD1; DOCKER --> PSD1; GITM --> PSD1
```

---

## 🧩 UML: Menu Hierarchy

```mermaid
graph LR
    MAIN["🏠 MAIN MENU"]
    MAIN -->|1| DOCKER["🐳 Docker"]
    MAIN -->|2| DIAG["🔍 Diagnostics"]
    MAIN -->|3| GIT["📋 Git"]
    MAIN -->|4| TOOLS["🔧 Tools"]
    MAIN -->|5| EXIT["🚪 Exit"]
    DOCKER --> D1["ps -a"] --> D2["images"] --> D3["stats"] --> D4["system df"] --> D5["logs"] --> BACK["Zpět"]
    GIT --> G1["status"] --> G2["log"] --> G3["branch"] --> G4["remote"] --> G5["stash"] --> G6["commit"] --> BACK
```

---

## 📋 Command Reference

| Command | What it does |
|---------|-------------|
| `menu` | Interactive main menu |
| `check` | Full system diagnostics |
| `update` | Git pull + reload profile |
| `configure` | Interactive setup wizard |
| `ep` | Edit profile |
| `rp` | Reload profile |
| `ll` | `Get-ChildItem` with force |

### Git Shortcuts

`g` `gst` `gco` `gbr` `gcm` `gpl` `gps` `gdf` `glo`

### Docker Shortcuts

`dps` `dpsa` `dcu` `dcd`

---

## 📚 Documentation Index

### dotfiles-powershell

| Doc | Description |
|-----|-------------|
| [README](https://github.com/martinpaprcka77/dotfiles-powershell#readme) | Overview, install, function reference |
| [ARCHITECTURE.md](https://github.com/martinpaprcka77/dotfiles-powershell/blob/main/docs/ARCHITECTURE.md) | 4 Mermaid diagrams — loading flow, components, install sequence |
| [PURPOSE.md](https://github.com/martinpaprcka77/dotfiles-powershell/blob/main/docs/PURPOSE.md) | Design rationale — 4 problems solved, 5 design decisions |
| [PROMPT.md](https://github.com/martinpaprcka77/dotfiles-powershell/blob/main/docs/PROMPT.md) | Original 107-line AI prompt |

### dotfiles-tools

| Doc | Description |
|-----|-------------|
| [README](https://github.com/martinpaprcka77/dotfiles-tools#readme) | All 18 functions, UML, menu hierarchy |
| [ARCHITECTURE.md](https://github.com/martinpaprcka77/dotfiles-tools/blob/main/docs/ARCHITECTURE.md) | 6 Mermaid diagrams — components, WT sequence, menu engine |
| [MANUAL.md](https://github.com/martinpaprcka77/dotfiles-tools/blob/main/docs/MANUAL.md) | 11-section user guide with every command |
| [ROADMAP.md](https://github.com/martinpaprcka77/dotfiles-tools/blob/main/docs/ROADMAP.md) | 5 phases — completed, planned, known issues |
| [PROMPT.md](https://github.com/martinpaprcka77/dotfiles-tools/blob/main/docs/PROMPT.md) | Original AI prompt |

---

## 🗺️ Roadmap

| Phase | Status | Items |
|-------|--------|-------|
| **1. Foundation** | ✅ Done | Modular profile, install, Toolkit module (18 funcs), menus, diagnostics, WT profiles, Pester tests |
| **2. Tools** | 🟡 Planned | Custom user tools, menu extensions |
| **3. Extensions** | 🟡 Planned | Linux/macOS support, config wizard, health check, live dashboard |
| **4. Integration** | 🟢 Future | VS Code extension, WSL profiles, oh-my-posh theme, git hooks |
| **5. Ecosystem** | 🟢 Future | Windows installer, CI/CD, PowerShell Gallery, docs site |

[Full roadmap →](https://github.com/martinpaprcka77/dotfiles-tools/blob/main/docs/ROADMAP.md)

---

## ⚡ Quick Links

| Resource | URL |
|----------|-----|
| **dotfiles-powershell** | [github.com/martinpaprcka77/dotfiles-powershell](https://github.com/martinpaprcka77/dotfiles-powershell) |
| **dotfiles-tools** | [github.com/martinpaprcka77/dotfiles-tools](https://github.com/martinpaprcka77/dotfiles-tools) |
| **Pages — powershell** | [martinpaprcka77.github.io/dotfiles-powershell](https://martinpaprcka77.github.io/dotfiles-powershell/) |
| **Pages — tools** | [martinpaprcka77.github.io/dotfiles-tools](https://martinpaprcka77.github.io/dotfiles-tools/) |
| **Gist — Install** | [gist.github.com/.../bafc2457](https://gist.github.com/martinpaprcka77/bafc2457fd9d93daf1b1b69c348e0cfd) |
| **Gist — Cheatsheet** | [gist.github.com/.../b30ae16](https://gist.github.com/martinpaprcka77/b30ae161dfb693431a438e309f236467) |

---

*Built with PowerShell · Git · GitHub Pages · Mermaid*
