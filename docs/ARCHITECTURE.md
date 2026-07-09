# Architektura dotfiles-powershell

## Diagram načítání profilu

```mermaid
flowchart TD
    A["PowerShell start"] --> B{"$PROFILE existuje?"}
    B -->|ano| C["Bootstrap: dot-source profile.ps1"]
    B -->|ne| Z["Nic – prázdná session"]

    C --> D["profile.ps1"]
    D --> E["Nastavit $env:DOTFILES_PWSH<br/>Nastavit $env:DOTFILES_TOOLS"]
    E --> F{"PSVersion ≥ 6?"}
    F -->|ano| G["Opravit PSModulePath<br/>(LOCALAPPDATA na začátek)"]
    F -->|ne| H["Přeskočit"]
    G --> I["Dot-source core/*.ps1"]
    H --> I

    I --> J{"PSVersion ≥ 6?"}
    J -->|ano| K["Dot-source ps7/profile.ps1"]
    J -->|ne| L["Dot-source ps5/profile.ps1"]

    K --> M{"$host.Name obsahuje 'Code'?"}
    L --> M

    M -->|ano| N["Dot-source hosts/VSCode.ps1"]
    M -->|ne| O["Dot-source hosts/ConsoleHost.ps1"]

    N --> P{"PROFILE_BENCHMARK?"}
    O --> P

    P -->|true| Q["Zobrazit dobu načtení"]
    P -->|false| R["Hotovo"]
    Q --> R
```

## Komponentová mapa

```mermaid
graph TB
    subgraph "Nativní profily"
        PS_PROF["Microsoft.PowerShell_profile.ps1"]
        VS_PROF["Microsoft.VSCode_profile.ps1"]
        PS5_PROF["WindowsPowerShell\\..."]
        VS5_PROF["WindowsPowerShell\\VSCode..."]
    end

    subgraph "dotfiles-powershell"
        BOOTSTRAP["bootstrap.ps1<br/>(vložený kód)"]
        PROFILE["profile.ps1<br/>(hlavní orchestrátor)"]
        CORE["core/<br/>aliases · functions · env · diag · perf · status"]
        PS_VER["ps5/ · ps7/<br/>verze-specifické"]
        HOSTS["hosts/<br/>ConsoleHost · VSCode · wtprofile · shell-integration"]
    end

    subgraph "Externí závislosti"
        TOOLS["dotfiles-tools<br/>~/Projects/tools/"]
        MODULES["PSReadLine<br/>Terminal-Icons<br/>oh-my-posh<br/>PSFzf"]
        SECRETS["SecretManagement<br/>vault (Default)"]
    end

    PS_PROF --> BOOTSTRAP
    VS_PROF --> BOOTSTRAP
    PS5_PROF --> BOOTSTRAP
    VS5_PROF --> BOOTSTRAP

    BOOTSTRAP -->|"dot-source"| PROFILE
    PROFILE -->|"dot-source"| CORE
    PROFILE -->|"podle verze PS"| PS_VER
    PROFILE -->|"podle hostitele"| HOSTS

    CORE -->|"$env:DOTFILES_TOOLS"| TOOLS
    PS_VER -->|"Import-Module"| MODULES
    CORE -->|"Get-SecretKey"| SECRETS
```

## Mapa proměnných prostředí

| Proměnná | Nastavuje | Hodnota | Použití |
|----------|-----------|---------|---------|
| `$env:DOTFILES_PWSH` | `profile.ps1` | `~/.config/powershell` | Cesta k profilovému repu |
| `$env:DOTFILES_TOOLS` | `profile.ps1` / `core/env.ps1` | `~/Projects/tools` | Cesta k tools repu |
| `$env:EDITOR` | `core/env.ps1` | `code` / `nvim` / `vim` / `notepad` | Výchozí editor |
| `$env:PROFILE_BENCHMARK` | Uživatel | `true` / (prázdné) | Měření doby načtení |
| `$env:TERM` | `hosts/VSCode.ps1` | `vscode` | Indikátor VS Code terminálu |
| `$env:PSModulePath` | `profile.ps1` (PS7) | + `%LOCALAPPDATA%\PowerShell\Modules` | Oprava OneDrive |

## Flow instalace (install.ps1)

```mermaid
sequenceDiagram
    actor U as Uživatel
    participant I as install.ps1
    participant G as Git
    participant FS as Souborový systém
    participant ENV as Prostředí

    U->>I: .\install.ps1
    I->>G: git clone/update dotfiles-powershell
    I->>G: git clone/update dotfiles-tools

    loop 4 profilové cesty
        I->>FS: Existuje profil?
        alt existuje
            I->>FS: Obsahuje bootstrap?
            alt ne
                I->>FS: Append bootstrap
            end
        else neexistuje
            I->>FS: Vytvořit s bootstrapem
        end
    end

    I->>ENV: Přidat tools/bin do USER PATH
    I->>ENV: Aktualizovat $env:PATH v session

    U->>I: Potvrdit WT nastavení?
    I->>G: Spustit Add-WTProfiles.ps1
```

## Detekce verze a hostitele

```powershell
# Verze PowerShellu
if ($PSVersionTable.PSVersion.Major -ge 6) { "ps7" } else { "ps5" }

# Hostitel
if ($host.Name -match 'Code') { 'VSCode' } else { 'ConsoleHost' }
```
