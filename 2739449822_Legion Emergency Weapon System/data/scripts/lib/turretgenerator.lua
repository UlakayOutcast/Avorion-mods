scales[WeaponType.EmergencyWeapon] = {
    {from = 28, to = 39, size = 1.0, usedSlots = 1},
    {from = 40, to = 48, size = 1.5, usedSlots = 1},
    {from = 49, to = 52, size = 2.0, usedSlots = 1},
}

possibleSpecialties[WeaponType.EmergencyWeapon] = {
    {specialty = Specialty.HighDamage, probability = 0.15},
    {specialty = Specialty.HighRange, probability = 0.10}
}

function TurretGenerator.generateEmergencyWeaponTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- Turret Crew
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- Generate Weapons
    local numWeapons = rand:getInt(1, 2)
    local weapon = WeaponGenerator.generateEmergencyWeapon(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- Weapon Attaching
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)
	
    -- Cooling / Recharge
    local shootingTime = 6 * rand:getFloat(0.8, 1.2) -- plasma is 20
    local coolingTime = 80 * rand:getFloat(0.9, 1.1) -- plasma is 15
    TurretGenerator.createStandardCooling(result, coolingTime, shootingTime)

    -- Turret Generator Scale, Specialties, and Slot Type
    local scaleLevel = TurretGenerator.scale(rand, result, WeaponType.EmergencyWeapon, tech, 0.6)
    local specialties = TurretGenerator.addSpecialties(rand, result, WeaponType.EmergencyWeapon)
    result.slotType = TurretSlotType.Unarmed
    result:updateStaticStats()

    -- Naming The Turret
    local name = "Emergency Weapon System"

    if result.slots == 2 then 
        name = "Emergency Weapon System"
    elseif result.slots == 3 then
        name = "Advanced Emergency Weapon System"
    end

    if specialties[Specialty.HighDamage] and specialties[Specialty.HighRange] then
        name = "Emergency Salvo Device"
        specialties[Specialty.HighDamage] = nil
        specialties[Specialty.HighRange] = nil
    end

    -- Turret Adjective and Title
    local dmgAdjective, outerAdjective, barrel, multishot, coax, serial = makeTitleParts(rand, specialties, result, DamageType.Plasma)
    result.title = Format("%1%%2%%3%%4%%5%%6%%7% /* [outer-adjective][barrel][coax][dmg-adjective][multishot][name][serial], e.g. Enduring Coaxial Advanced Emergency Weapon System T-F */"%_T, outerAdjective, barrel, coax, dmgAdjective, multishot, name, serial)

    return result
end

generatorFunction[WeaponType.EmergencyWeapon] = TurretGenerator.generateEmergencyWeaponTurret