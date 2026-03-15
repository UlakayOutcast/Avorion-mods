# HyperBlocker

HyperBlocker ist eine vollwertige Avorion-Mod, die ein neues permanentes Systemmodul hinzufügt. Wird der "Hyperraumblocker" auf einem Schiff installiert, entsteht eine seltenheitsabhängige Blockade-Blase, die Spieler- oder Allianz-Schiffe in der Nähe am Hypersprung hindert. Zusätzlich wurde das Debug-Skript `data/scripts/lib/entitydbg.lua` erweitert, sodass das Modul jederzeit per UI gespawnt werden kann.

## Features
- **Neues Systemmodul** `data/scripts/systems/hyperblocker.lua`
  - Muss permanent installiert werden.
  - Aktiviert das Entity-Skript `data/scripts/entity/hyperblockerfield.lua`, das alle 2 Sekunden die Umgebung scannt.
  - Blockiert HyperspaceEngines von Spieler- und Allianz-Schiffen innerhalb der Reichweite.
  - Reichweite je nach Seltenheit (Common 10 km bis Legendary 60 km).
  - Hoher Energiebedarf: von 50 GW (Common) bis 450 GW (Legendary).
- **Warnmeldung** wenn das Modul nicht permanent installiert wurde (`hyperblockerwarning.lua`).
- **Debug-Spawning** über das bestehende Entity-Debug-UI (`data/scripts/lib/entitydbg.lua`).
  - Der vorhandene Button "Systems" liefert jetzt zusätzlich ein komplettes Hyperraumblocker-Set (alle Seltenheiten) direkt ins Inventar.
  - Zusätzlich gibt es unten rechts im Debug-Fenster einen dedizierten Button **"Hyperblocker"**, der die gleiche Funktion mit einem Klick auslöst.
- **Reguläre Drops & Händler** dank `data/scripts/lib/systemupgradegenerator.lua`, `data/scripts/galaxy/server.lua` & einem Equipment-Dock-Hook.
  - Patcht den Vanilla-`UpgradeGenerator` zur Laufzeit, ohne dessen Datei zu überschreiben.
  - Die RNG-Gewichtung ist über `HyperblockerConfig.generatorWeight` konfigurierbar (Standard 1.0, analog zu seltenen Spezial-Upgrades).
  - Optionales Merkmal "Garantierter Slot" (per `HyperblockerConfig.equipmentDock.guaranteedSlot = true` aktivierbar, Standard aus) injiziert per Hook nach jedem Dock-Restock automatisch einen Hyperblocker, überschreibt aber keine Vanilla-Dateien.
  - Fügt Hyperblocker automatisch in alle Loot- und Shop-Pools ein, die Systemmodule generieren.
    - Die RNG-Gewichtung ist über `HyperblockerConfig.generatorWeight` konfigurierbar (Standard 1.0, analog zu seltenen Spezial-Upgrades).
    - Optionaler Shop-Hook: `HyperblockerConfig.equipmentDock.guaranteedSlot = true` erzwingt 1 Slot, `rngReplacementChance` (Standard 0.05) tauscht mit RNG ein Item gegen Hyperblocker.
  - Funktioniert in allen aktiven Mods/Servern, sobald der HyperBlocker-Mod geladen ist.

## Installation
1. Kopiere den Ordner `mods/HyperBlocker` in deinen `%AppData%/Avorion/mods/` Pfad.
2. Aktiviere den Mod im Avorion Mods-Menü (Dev Mode empfohlen während der Entwicklung).
3. Starte ein neues Spiel oder lade einen Spielstand, um das Modul zu nutzen.

## Nutzung
- System-Modul in der Systemstation kaufen, droppen oder per Debug-UI spawnen.
- Modul muss permanent eingebaut sein. Mehrere Kopien addieren sich nicht, der höchste Raritätswert bestimmt die Reichweite.
- Zum Debug-Spawning einen Spieler-/Allianz-Schiff anwählen, `Entity():addScript("lib/entitydbg.lua")` und im Dev-Menü den Button **"Systems"** drücken **oder** den neuen Button **"Hyperblocker"** unten rechts verwenden. In beiden Fällen landen alle Seltenheiten direkt im Inventar.
- Ab sofort erscheinen Hyperblocker auch automatisch in Beute-Drops und Systemmodul-Shops; der Debug-Button ist nur noch optional.

## Dateien
```
mods/HyperBlocker/
├── modinfo.lua
├── README.md
└── data/scripts/
    ├── lib/
    │   ├── hyperblockerconfig.lua
    │   └── entitydbg.lua (Erweiterung)
    ├── systems/hyperblocker.lua
    └── entity/
        ├── hyperblockerfield.lua
        └── hyperblockerwarning.lua
```

## Tests
Avorion-Mods besitzen kein automatisiertes Test- oder Buildsystem. Stelle sicher, dass der Mod im Mods-Menü angezeigt wird und überprüfe das Server-/Client-Log (`clientlog*.txt`), falls Fehler auftreten.
