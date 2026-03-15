--0x7363616C657461626C657374617274
scales[WeaponType.ShortRangeMissile] = {
    {from = 0, to = 30, size = 0.5, usedSlots = 1},
    {from = 31, to = 39, size = 1.0, usedSlots = 2},
    {from = 40, to = 48, size = 1.5, usedSlots = 3},
    {from = 49, to = 52, size = 2.0, usedSlots = 4},
}
--0x7363616C657461626C65656E64

--0x7370656369616C74797461626C657374617274
--This used to have HighShootingTime as a specialty, but those were ridiculously overpowered.
possibleSpecialties[WeaponType.ShortRangeMissile] = {
    {specialty = Specialty.HighDamage, probability = 0.25},
    {specialty = Specialty.HighRange, probability = 0.1},
}
--0x7370656369616C74797461626C65656E64

--0x67656E657261746566756E637374617274
function TurretGenerator.generateShortRangeMissileTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)

    local weapon = WeaponGenerator.generateShortRangeMissile(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    local positions = {}
    if rand:getBool() then
        table.insert(positions, vec3(0, 0.3, 0))
    else
        table.insert(positions, vec3(0.4, 0.3, 0))
        table.insert(positions, vec3(-0.4, 0.3, 0))
    end

    -- attach
    for _, position in pairs(positions) do
        weapon.localPosition = position * result.size
        result:addWeapon(weapon)
    end

    local shootingTime = 3 * rand:getFloat(0.8, 1.2) --Standard rocket launcher is 20
    local coolingTime = 4 * rand:getFloat(0.8, 1.2) --Standard rocket launcher is 15
    TurretGenerator.createStandardCooling(result, coolingTime, shootingTime)

    TurretGenerator.scale(rand, result, WeaponType.ShortRangeMissile, tech, 0.6)
    local specialties = TurretGenerator.addSpecialties(rand, result, WeaponType.ShortRangeMissile)

    result.slotType = TurretSlotType.Armed

    result:updateStaticStats()

    local name = "SRM Launcher"

    if result.slots == 3 then 
        name = "SRM Battery"
    elseif result.slots == 4 then
        name = "SRM Phalanx"
    end

    if specialties[Specialty.HighDamage] and specialties[Specialty.HighRange] then
        name = "Streak " .. name
        specialties[Specialty.HighDamage] = nil
        specialties[Specialty.HighRange] = nil
    end

    local dmgAdjective, outerAdjective, barrel, multishot, coax, serial = makeTitleParts(rand, specialties, result, DamageType.Physical)
    --/* [outer-adjective][barrel][coax][dmg-adjective][multishot][name][serial], e.g. Enduring Dual Coaxial Anti-Tri-Missile Battery T-F */
    result.title = Format("%1%%2%%3%%4%%5%%6%%7%", outerAdjective, barrel, coax, dmgAdjective, multishot, name, serial)

    return result
end
--0x67656E657261746566756E63656E64

--0x6D6574617461626C6566756E636C696E65
generatorFunction[WeaponType.ShortRangeMissile] = TurretGenerator.generateShortRangeMissileTurret