# dotfiles-powershell

**Modulární PowerShell profil** — verzovaný, přenositelný, nezávislý na OneDrivu.

## Adresářová struktura

```
~/.config/powershell/
├── profile.ps1              ← hlavní profil (dot-sourcuje vše níže)
├── install.ps1              ← idempotentní instalátor
├── bootstrap.ps1            ← reference: kód vkládaný do $PROFILE
├── core/
│   ├── aliases.ps1          ← aliasy (ll, g, gst, k, docker)
│   ├── functions.ps1        ← funkce (Edit-Profile, Get-SecretKey, …)
│   └── env.ps1              ← proměnné ($env:EDITOR, PATH, DOTFILES_TOOLS)
├── ps5/profile.ps1          ← Windows PowerShell 5.1
├── ps7/profile.ps1          ← PowerShell 7+ (PSReadLine, oh-my-posh, …)
├── hosts/
│   ├── ConsoleHost.ps1      ← klasická konzole (uvítání, titulek)
│   └── VSCode.ps1           ← VS Code integrovaný terminál
└── docs/
    ├── ARCHITECTURE.md       ← diagram načítání profilu
    ├── PURPOSE.md            ← návrhová filozofie
    └── PROMPT.md             ← původní prompt
```

## Jak to funguje

```
$PROFILE (bootstrap) → ~/.config/powershell/profile.ps1
                            ├── core/*.ps1          (vždy)
                            ├── ps5/ nebo ps7/       (podle verze)
                            └── hosts/ConsoleHost    (podle hostitele)
                                 hosts/VSCode
```

1. **Bootstrap** — `install.ps1` vloží do každého známého `$PROFILE` minimální kód, který dot-sourcuje `~/.config/powershell/profile.ps1`.
2. **Hlavní profil** — detekuje verzi PowerShellu (`$PSVersionTable`) a hostitele (`$host.Name`), nastaví `$env:DOTFILES_PWSH` a `$env:DOTFILES_TOOLS`, opraví `PSModulePath` pro PS7.
3. **Core** — načte všechny `.ps1` z `core/` (aliases, functions, env).
4. **Verze** — dot-sourcuje `ps5/profile.ps1` nebo `ps7/profile.ps1`.
5. **Hostitel** — dot-sourcuje `hosts/$hostname.ps1` (pokud existuje).

## Instalace

```powershell
git clone https://github.com/martinpaprcka77/dotfiles-powershell.git ~/.config/powershell
~/.config/powershell/install.ps1
```

`install.ps1` je **idempotentní** — opakované spuštění nezdvojí položky.

## Funkce

### `Get-SecretKey`

Získá API klíč z `Microsoft.PowerShell.SecretManagement` trezoru (nebo z `$env:VAR` jako fallback pro testování):

```powershell
$apiKey = Get-SecretKey -Name 'MyApiKey'
```

### `Edit-Profile`

Otevře hlavní profil v `$env:EDITOR` (nebo `code`, `notepad`):

```powershell
ep   # alias
```

### `Reload-Profile`

Znovu načte profil bez restartu:

```powershell
rp   # alias
```

## Benchmarks

Pro měření doby načtení profilu:

```powershell
$env:PROFILE_BENCHMARK = 'true'
. $PROFILE
# Profile loaded in 234ms
```

## Dokumentace

| Dokument | Popis |
|----------|-------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Diagram načítání, mapa proměnných |
| [PURPOSE.md](docs/PURPOSE.md) | Proč vzniklo, návrhová rozhodnutí |
| [PROMPT.md](docs/PROMPT.md) | Původní prompt pro AI generování |
