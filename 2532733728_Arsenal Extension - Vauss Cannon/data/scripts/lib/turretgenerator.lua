--0x7363616C657461626C657374617274
scales[WeaponType.VaussCannon] = {
    {from = 0, to = 11, size = 0.5, usedSlots = 1},
    {from = 12, to = 23, size = 1.0, usedSlots = 2},
    {from = 24, to = 35, size = 1.5, usedSlots = 3},
    {from = 36, to = 47, size = 2.0, usedSlots = 4},
    {from = 48, to = 52, size = 3.0, usedSlots = 5}
}
--0x7363616C657461626C65656E64

--0x7370656369616C74797461626C657374617274
possibleSpecialties[WeaponType.VaussCannon] = {
    {specialty = Specialty.HighDamage, probability = 0.1},
    {specialty = Specialty.HighRange, probability = 0.1},
    {specialty = Specialty.IonizedProjectile, probability = 0.05},
    {specialty = Specialty.HighFireRate, probability = 0.2},
    {specialty = Specialty.BurstFire, probability = 0.1}
}
--0x7370656369616C74797461626C65656E64

--0x67656E657261746566756E637374617274
function TurretGenerator.generateVaussCannonTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 3)

    local weapon = WeaponGenerator.generateVaussCannon(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    -- Vauss Cannons don't need cooling
    local scaleLevel = TurretGenerator.scaleVauss(rand, result, WeaponType.VaussCannon, tech, 1)
    local specialties = TurretGenerator.addSpecialties(rand, result, WeaponType.VaussCannon)

    --Have to set it to an armed turret, otherwise it will default to unarmed.
    result.slotType = TurretSlotType.Armed

    result:updateStaticStats()

    local name = "Vauss Cannon"

    if specialties[Specialty.HighDamage] and specialties[Specialty.HighFireRate] then
        name = "Vauss Sweeper"
        specialties[Specialty.HighDamage] = nil
        specialties[Specialty.HighFireRate] = nil
    elseif specialties[Specialty.HighDamage] then
        name = "Vauss Ripper"
        specialties[Specialty.HighDamage] = nil
    elseif specialties[Specialty.HighFireRate] then
        name = "Vauss Shredder"
        specialties[Specialty.HighFireRate] = nil
    end

    local dmgAdjective, outerAdjective, barrel, multishot, coax, serial = makeTitleParts(rand, specialties, result, DamageType.Physical)
    result.title = Format("%1%%2%%3%%4%%5%%6%", outerAdjective, barrel, dmgAdjective, multishot, name, serial)

    --Final check.
    if not result.coaxial then
        result.coaxial = true
    end
    return result
end
--0x67656E657261746566756E63656E64

--0x7363616C6566756E637374617274
function TurretGenerator.getVaussScaleBonus(tech)
    return 3.25 --Scale slightly better than vanilla to make it competitive with Teslas.
end

function TurretGenerator.scaleVauss(rand, turret, type, tech, turnSpeedFactor, coaxialPossible)
    --Vauss cannons are always coaxial.
    local scaleTech = tech
    if rand:test(0.5) then
        scaleTech = math.floor(math.max(1, scaleTech * rand:getFloat(0, 1)))
    end

    local scale, lvl = TurretGenerator.getScale(type, scaleTech)

    turret.size = scale.size
    turret.coaxial = true
    turret.slots = scale.usedSlots
    turret.turningSpeed = lerp(turret.size, 0.5, 3, 1, 0.5) * rand:getFloat(0.8, 1.2) * turnSpeedFactor

    local coaxialDamageScale = TurretGenerator.getVaussScaleBonus(tech)

    local weapons = {turret:getWeapons()}
    for _, weapon in pairs(weapons) do
        weapon.localPosition = weapon.localPosition * scale.size

        -- scale damage, etc. linearly with amount of used slots. Can scale any weapon since all are coaxial.
        if weapon.damage ~= 0 then
            weapon.damage = weapon.damage * scale.usedSlots * coaxialDamageScale
        end

        if weapon.hullRepair ~= 0 then
            weapon.hullRepair = weapon.hullRepair * scale.usedSlots * coaxialDamageScale
        end

        if weapon.shieldRepair ~= 0 then
            weapon.shieldRepair = weapon.shieldRepair * scale.usedSlots * coaxialDamageScale
        end

        if weapon.selfForce ~= 0 then
            weapon.selfForce = weapon.selfForce * scale.usedSlots * coaxialDamageScale
        end

        if weapon.otherForce ~= 0 then
            weapon.otherForce = weapon.otherForce * scale.usedSlots * coaxialDamageScale
        end

        if weapon.holdingForce ~= 0 then
            weapon.holdingForce = weapon.holdingForce * scale.usedSlots * coaxialDamageScale
        end

        local increase = (scale.usedSlots - 1) * 0.15 --Type is not mining / salvaging laser - so we can cut out this if/else

        weapon.reach = weapon.reach * (1 + increase)

        local shotSizeFactor = scale.size * 2
        local velocityIncrease = (scale.usedSlots - 1) * 0.25 --Weapon is always projectile.
            
        weapon.psize = weapon.psize * shotSizeFactor
        weapon.pvelocity = weapon.pvelocity * (1 + velocityIncrease)
    end

    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        turret:addWeapon(weapon)
    end

    return lvl
end
--0x7363616C6566756E63656E64

--0x6D6574617461626C6566756E636C696E65
generatorFunction[WeaponType.VaussCannon] = TurretGenerator.generateVaussCannonTurret
