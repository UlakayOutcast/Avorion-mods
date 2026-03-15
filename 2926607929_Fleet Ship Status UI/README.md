# Fleet Ship Status UI

This mod adds the ability to add certain ships' durability+shield status to the HUD using an overlay. This allows you to keep track of ships in other sectors who may be under attack, or can help you command your ships when engaging in fleet vs fleet combat.

### Installation

This mod should be available in the Steam Workshop. Simply navigate to Avorion steam page, click Workshop, then search for 'Fleet Ship Status' and click Subscribe. This will download the mod and will be available the next time you start Avorion. Make sure it's enabled in the game's Settings > Mods screen.

If you're playing on a multiplayer server you will also need to ask your server admin to add this mod to the server's `modconfig.lua` file.

### Usage

With the mod installed and a galaxy loaded, you won't see anything at first. You will need to enable it by going to the FSS menu (hold shift -> click the `FSS` icon in the top right). This will open the FSS Settings menu. Here you can select which ships/stations you want to see in the HUD by clicking on them (and removing them the same way). You will also need to click the `Enable` checkbox. You can also change the HUD overlay location with the arrow buttons, and change the opacity with the slider.

### How it works

This is a fully client-side mod that attaches a script to all player-owned ships and stations. Since each copy of the script would create its own HUD overlay, the script is designed to disable itself unless it's running from the ship that the player is current occupying. This ensures that exactly 1 copy of the script is running at any moment, and therefore only 1 HUD overlay. It maintains the configuration settings in the Avorion `moddata` directory with the file format `<base 64 of GameSeed>_fss_config.lua` which keeps the configs separate for each galaxy you play in.


### Known Issues

- The mod's script is sometimes automatically removed from certain ships that have a mining subsystem installed. WORKAROUND: Just remove the mining subsystem (and exit, re-enter the ship).

### Author
zaigan