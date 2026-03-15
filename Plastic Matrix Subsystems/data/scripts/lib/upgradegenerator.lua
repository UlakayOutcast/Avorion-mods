
-- Starting with version 0.29, the upgradegenerator.lua was changed
if GameVersion() >= Version(0, 29, 0) then

    --Different Vesions Have Different Seed Modifiers To Produce More Variations.
    --Collectively All Modules Will Add Up To The Same Drop Chance Of The Normal Version.
    add("data/scripts/systems/PlasticMatrix.lua", 0.25)

else
    -- use this for version 0.28 and below
    UpgradeGenerator.add("data/scripts/systems/PlasticMatrix.lua", 0.25)

end