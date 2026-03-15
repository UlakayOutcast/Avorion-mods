--0x7363616C657461626C657374617274
scales[WeaponType.SlugGun] = {
    {from = 0, to = 28, size = 1.0, usedSlots = 2},
    {from = 29, to = 35, size = 1.5, usedSlots = 3},
    {from = 36, to = 42, size = 2.0, usedSlots = 4},
    {from = 43, to = 49, size = 3.0, usedSlots = 5},
    --dummy for cooaxial, add 1 to size and level
    {from = 50, to = 52, size = 3.5, usedSlots = 6},
}
--0x7363616C657461626C65656E64

--0x7370656369616C74797461626C657374617274
possibleSpecialties[WeaponType.SlugGun] = {
    {specialty = Specialty.HighDamage, probability = 0.1},
    {specialty = Specialty.HighRange, probability = 0.1}
}
--0x7370656369616C74797461626C65656E64

--0x67656E657261746566756E637374617274
function TurretGenerator.generateSlugGunTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = 1

    local weapon = WeaponGenerator.generateSlugGun(rand, dps, tech, material, rarity)
    --weapon.fireDelay = weapon.fireDelay * numWeapons --no need for this - always 1 weapon only.

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local shootingTime = 27.5 * rand:getFloat(0.8, 1.2) --Railguns are 27.5.
    local coolingTime = 10 * rand:getFloat(0.8, 1.2) --Railguns are 10
    TurretGenerator.createStandardCooling(result, coolingTime, shootingTime)

    TurretGenerator.scale(rand, result, WeaponType.SlugGun, tech, 0.35)
    local specialties = TurretGenerator.addSpecialties(rand, result, WeaponType.SlugGun)

    result.slotType = TurretSlotType.Armed

    result:updateStaticStats()

    local name = "Slug Gun"

    if specialties[Specialty.HighDamage] and specialties[Specialty.HighRange] then
        name = "Flayer"
        specialties[Specialty.HighDamage] = nil
        specialties[Specialty.HighRange] = nil
    elseif specialties[Specialty.HighDamage] then
        name = "Magnum Slug Gun"
        specialties[Specialty.HighDamage] = nil
    elseif specialties[Specialty.HighRange] then
        name = "Velocity Slug Gun"
        specialties[Specialty.HighRange] = nil
    end

    local dmgAdjective, outerAdjective, barrel, multishot, coax, serial = makeTitleParts(rand, specialties, result, DamageType.Physical)
    result.title = Format("%1%%2%%3%%4%%5%%6%", outerAdjective, barrel, coax, dmgAdjective, name, serial)

    return result
end
--0x67656E657261746566756E63656E64

--0x6D6574617461626C6566756E636C696E65
generatorFunction[WeaponType.SlugGun] = TurretGenerator.generateSlugGunTurret