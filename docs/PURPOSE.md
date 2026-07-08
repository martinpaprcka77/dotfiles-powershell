# Účel a návrhová filozofie

## Proč tento projekt vznikl

Standardní PowerShell profil (`$PROFILE`) má několik zásadních problémů, které tento projekt řeší:

### 1. OneDrive přepisuje vše

Windows 11 (a částečně Windows 10) přesměrovává `Documents` do OneDrivu. To znamená:
- `$HOME\Documents\PowerShell\` → `$HOME\OneDrive\Documents\PowerShell\`
- `$HOME\Documents\WindowsPowerShell\` → `$HOME\OneDrive\Documents\WindowsPowerShell\`

PowerShell 7 navíc ukládá moduly do `$HOME\Documents\PowerShell\Modules` — tedy do OneDrivu. To způsobuje:
- Pomalé načítání modulů (síťové zpoždění OneDrivu)
- Konflikty při synchronizaci mezi stroji
- Problémy s přístupem offline

**Řešení:** Profily jsou v `~/.config/powershell/` (mimo OneDrive). `PSModulePath` je opraven na `%LOCALAPPDATA%\PowerShell\Modules`.

### 2. Jeden monolitický profil

Výchozí přístup "jeden soubor `$PROFILE`" neškáluje. Při přidávání funkcí, aliasů a nastavení se z profilu stane nepřehledný soubor o stovkách řádků.

**Řešení:** Modulární architektura:
- `core/` — sdílené napříč všemi prostředími
- `ps5/` / `ps7/` — verze-specifické
- `hosts/` — hostitel-specifické

### 3. Nepřenositelnost mezi stroji

Každý stroj má vlastní kopii profilu. Změny se ručně kopírují nebo se na ně zapomíná.

**Řešení:** Vše verzováno v Gitu. `install.ps1` nastaví nový stroj jedním příkazem.

### 4. Manuální nastavení Windows Terminálu

Přidání profilů do Windows Terminálu vyžaduje ruční editaci `settings.json`, která je náchylná k chybám (JSON syntax, komentáře `//`, správné GUID).

**Řešení:** `Add-WTProfiles.ps1` automaticky přidá 4 profily, zálohuje původní nastavení a odstraní nevalidní komentáře.

## Návrhová rozhodnutí

### Proč `~/.config/powershell/` a ne `$PROFILE`?

- Konvence XDG (`~/.config/`) je standard na Linuxu a čím dál častější i na Windows.
- Je to mimo OneDrive.
- Umožňuje verzovat celý adresář, ne jen jeden soubor.

### Proč dva repozitáře?

- **Oddělení zájmů:** Profily a nástroje mají jiný životní cyklus.
- **Nezávislá instalace:** Někdo může chtít jen profily bez tools, nebo naopak.
- **Různé frekvence změn:** Tools se mění častěji, profily jsou stabilnější.

### Proč `%LOCALAPPDATA%\PowerShell\Modules`?

- `LOCALAPPDATA` je vždy lokální (není v OneDrivu).
- Je to doporučené umístění pro uživatelské moduly ve Windows.
- PowerShell 7 tam standardně nehledá, tak to explicitně přidáváme.

### Proč `Get-SecretKey` místo plaintextu?

- API klíče v kódu = bezpečnostní riziko.
- `Microsoft.PowerShell.SecretManagement` je standardní trezor.
- Fallback na `$env:VAR` umožňuje testování bez trezoru.

### Proč benchmark profilu?

- Výkon profilu je kritický — čekání 2 sekundy při každém otevření terminálu je nepřijatelné.
- Měření umožňuje identifikovat pomalé části.
- Výchozí vypnuto (žádná režie).

## Co tento projekt NENÍ

- **Není to framework** — je to minimální sada skriptů, ne závislost.
- **Není to "one-size-fits-all"** — každý si to může upravit; je to výchozí bod, ne dogma.
- **Není to náhrada za `oh-my-posh` nebo `starship`** — ty lze přidat volitelně v `ps7/profile.ps1`.
