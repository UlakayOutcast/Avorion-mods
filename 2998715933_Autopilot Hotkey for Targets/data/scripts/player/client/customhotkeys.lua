-- This is part of the integration into Bubbet's Custom Hotkeys mod for UI-supported hotkey remap.

if RegisterHotkey then -- if the function isn't defined, that means the mod's not present

RegisterHotkey(
    "caph_autopilot_target_hotkey",
    "Smart autopilot (target)"%_t,
    { key = 53 },
    "Mines, salvages, docks, attacks, escorts, and more based on the current target."%_t,
    "Autopilot"%_t)

-- This entry is tacked on just so we can track the optional integration being enabled
CustomHotkeys.caph_contextual_autopilot_hotkey_integrated = true

end -- if RegisterHotkey