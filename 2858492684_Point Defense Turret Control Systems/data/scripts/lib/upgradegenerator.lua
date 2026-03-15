-- Starting with version 0.29, the upgradegenerator.lua was changed
if GameVersion() >= Version(0, 29, 0) then
    add("data/scripts/systems/pdtcs.lua", 2)
else
    -- use this for version 0.28 and below
    UpgradeGenerator.add("data/scripts/systems/pdtcs.lua", 2)
end