scales[WeaponType.TMLauncher] = {
    {from = 0, to = 20, size = 2, usedSlots = 4},
	{from = 21, to = 30, size = 3, usedSlots = 6},
	{from = 31, to = 41, size = 6, usedSlots = 8},
    {from = 41, to = 52, size = 8, usedSlots = 12},
}

if GameVersion() >= Version(0, 31, 0) then
    possibleSpecialties[WeaponType.TMLauncher] = {
        {specialty = Specialty.HighDamage, probability = 0.2},
        {specialty = Specialty.HighRange, probability = 0.3},
    }
else
    possibleSpecialties[WeaponType.TMLauncher] = {
        Specialty.HighDamage,
        Specialty.HighRange,
    }
end

function TurretGenerator.generateTMLauncherTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)
    local shotCount = rand:getInt(1, 2)
    local shootingTime = 1.0 * numWeapons * shotCount
    local coolingTime = 10 * numWeapons * shotCount * rand:getFloat(0.9, 1.1)

    local weapon = WeaponGenerator.generateTMLauncher(rand, dps, tech, material, rarity, numWeapons, coolingTime, shotCount)

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    TurretGenerator.createStandardCooling(result, coolingTime, shootingTime)

    TurretGenerator.scale(rand, result, WeaponType.TMLauncher, tech, 0.75)
    TurretGenerator.addSpecialties(rand, result, WeaponType.TMLauncher)
    local name = "Tactical Missile Launcher /* weapon name */"%_T
    if shotCount > 1 then
        name = "Multi Tactical Missile Launcher /* weapon name */"%_T
    elseif possibleSpecialties[Specialty.HighDamage] and shotCount < 1 then
        name = "Enhanced Tactical Missile Launcher/*weapon name */"%_T
        possibleSpecialties[Specialty.HighDamage] = nil
    elseif possibleSpecialties[Specialty.HighDamage] and shotCount > 1 then
        name = "Enhanced Multi Tactical Missile Launcher /* weapon name */"%_T
        possibleSpecialties[Specialty.HighDamage] = nil
    end

    local dmgAdjective, outerAdjective, barrel, multishot, coax, serial = makeTitleParts(rand, possibleSpecialties, result, DamageType.AntiMatter)
    result.title = Format("%1%%2%%3%%4%%5%%6%%7% /* [outer-adjective][barrel][coax][dmg-adjective][multishot][name][serial], e.g. Enduring Dual Coaxial Plasmatic Tri-Bolter T-F */"%_T, outerAdjective, barrel, coax, dmgAdjective, multishot, name, serial)

    return result
end

generatorFunction[WeaponType.TMLauncher] = TurretGenerator.generateTMLauncherTurret