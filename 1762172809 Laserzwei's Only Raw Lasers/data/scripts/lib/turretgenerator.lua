
local localGameVersion = GameVersion()
function TurretGenerator.generateSeeded(seed, weaponType, dps, tech, rarity, material)
    if weaponType == WeaponType.MiningLaser then
        weaponType = WeaponType.RawMiningLaser
    end
    if weaponType == WeaponType.SalvagingLaser then
        weaponType = WeaponType.RawSalvagingLaser
    end

    if localGameVersion.major >= 1 or (localGameVersion.major >= 0 and localGameVersion.minor >= 29) then
        return TurretGenerator.generateTurret(Random(seed), weaponType, dps, tech, material, rarity)
    else
        local secured = rand
        TurretGenerator.initialize(seed)
        local turret = TurretGenerator.generateTurret(rand, weaponType, dps, tech, material, rarity)
        rand = secured
        return turret
    end

end
