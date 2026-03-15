TurretIngredients[WeaponType.TMLauncher] =
{
    {name = "Servo",                amount = 20,   investable = 10, minimum = 5,},
    {name = "Rocket",               amount = 15,    investable = 6,  minimum = 1,    weaponStat = "damage",  },
    {name = "High Pressure Tube",   amount = 5,    investable = 6,  minimum = 1,    weaponStat = "reach", investFactor = 0.75 },
    {name = "Fuel",                 amount = 10,    investable = 6,  minimum = 1,    weaponStat = "reach", investFactor = 0.5 },
    {name = "Targeting Card",       amount = 2,    investable = 3,  minimum = 0, weaponStat = "seeker", investFactor = 1, changeType = StatChanges.Flat},
    {name = "Steel",                amount = 40,    investable = 10, minimum = 3,}
}

local _Version = GameVersion()
if _Version.major <= 1 then
    table.insert(TurretIngredients[WeaponType.TMLauncher], {name = "Targeting System",     amount = 0,    investable = 2,  minimum = 0, turretStat = "automatic", investFactor = 1, changeType = StatChanges.Flat})
end