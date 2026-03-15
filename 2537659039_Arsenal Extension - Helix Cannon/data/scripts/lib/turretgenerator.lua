--0x7363616C657461626C657374617274
scales[WeaponType.HelixCannon] = {
    {from = 0, to = 30, size = 0.5, usedSlots = 1},
    {from = 31, to = 36, size = 1.0, usedSlots = 2},
    {from = 37, to = 43, size = 1.5, usedSlots = 3},
    {from = 44, to = 47, size = 2.0, usedSlots = 4},
    {from = 48, to = 52, size = 3.0, usedSlots = 5}
}
--0x7363616C657461626C65656E64

--0x7370656369616C74797461626C657374617274
possibleSpecialties[WeaponType.HelixCannon] = {
    {specialty = Specialty.HighDamage, probability = 0.12},
    {specialty = Specialty.HighRange, probability = 0.12},
    {specialty = Specialty.LessEnergyConsumption, probability = 0.2},
    {specialty = Specialty.HighFireRate, probability = 0.1}
}
--0x7370656369616C74797461626C65656E64

--0x67656E657261746566756E637374617274
function TurretGenerator.generateHelixCannonTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = 4

    --We pre-determine a lot of values here to keep things consistent between the four weapons that get generated.
    local _WROF = rand:getFloat(0.14, 0.24)
    local _WACC1 = 0.99 - rand:getFloat(0, 0.01)
    local _WACC2 = 0.89 - rand:getFloat(0, 0.30)
    local _WACC3 = 0.79 - rand:getFloat(0, 0.30)

    local _COLOR = ColorHSV(rand:getFloat(135, 180), 1, 1)
    local _WRANGE = rand:getFloat(350, 575) --Plasma gun is normaly 550 - 800
    local _WVEL = rand:getFloat(430, 630) --Plasma gun is normally 400 - 600
    local _WSIZE = rand:getFloat(0.4, 0.8) --Plasma gun is normally 0.4 to 0.8
    local _XSEED = rand:getInt()
    local _XPLAS = rand:test(0.05)

    local weapon = WeaponGenerator.generateHelixCannon(rand, dps, tech, material, rarity, _WROF, _WACC1, _COLOR, _WRANGE, _WVEL, _WSIZE, _XSEED, _XPLAS)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    local weapon2 = WeaponGenerator.generateHelixCannon(rand, dps, tech, material, rarity, _WROF, _WACC2, _COLOR, _WRANGE, _WVEL, _WSIZE, _XSEED, _XPLAS)
    weapon2.fireDelay = weapon2.fireDelay * numWeapons

    local weapon3 = WeaponGenerator.generateHelixCannon(rand, dps, tech, material, rarity, _WROF, _WACC3, _COLOR, _WRANGE, _WVEL, _WSIZE, _XSEED, _XPLAS)
    weapon3.fireDelay = weapon3.fireDelay * numWeapons

    -- attach weapons to turret
    -- the order of attachment matters. This should cause the weapon to fire in a [tight => loose => very loose => loose] blast pattern.
    TurretGenerator.attachHelixWeapons(rand, result, { weapon, weapon2, weapon3, weapon2 })

    local rechargeTime = 18 * rand:getFloat(0.8, 1.2)
    local shootingTime = 34 * rand:getFloat(0.8, 1.2)
    TurretGenerator.createHelixCannonCooling(result, rechargeTime, shootingTime)

    -- add further descriptions
    TurretGenerator.scale(rand, result, WeaponType.HelixCannon, tech, 0.7)
    local specialties = TurretGenerator.addSpecialties(rand, result, WeaponType.HelixCannon)

    result.slotType = TurretSlotType.Armed

    result:updateStaticStats()

    local name = "Helix Cannon"

    local dmgAdjective, outerAdjective, barrel, multishot, coax, serial = makeTitleParts(rand, specialties, result, DamageType.Energy)
    --/* [outer-adjective][coax][dmg-adjective][name][serial], e.g. Enduring Dual Coaxial E-Tri-Plasma Cannon T-F */
    result.title = Format("%1%%2%%3%%4%%5%", outerAdjective, coax, dmgAdjective, name, serial)

    return result
end
--0x67656E657261746566756E63656E64

--0x61747461636866756E637374617274
function TurretGenerator.attachHelixWeapons(rand, turret, weapons)
    turret:clearWeapons()

    local places = {TurretGenerator.createWeaponPlaces(rand, #weapons)}

    local _widx = 1
    for _, position in pairs(places) do
        local _localWeapon = weapons[_widx]

        _localWeapon.localPosition = position * turret.size
        turret:addWeapon(_localWeapon)

        _widx = _widx+1
    end
end
--0x61747461636866756E63656E64

--0x636F6F6C66756E637374617274
function TurretGenerator.createHelixCannonCooling(turret, rechargeTime, shootingTime)
    turret:updateStaticStats()

    local maxCharge
    if turret.dps > 0 then
        maxCharge = turret.dps * 50
    else
        maxCharge = 25
    end

    local rechargeRate = maxCharge / rechargeTime -- must be smaller than consumption rate or the weapon will never run out of energy
    local consumptionDelta = maxCharge / shootingTime
    local consumptionRate = consumptionDelta + rechargeRate

    local consumptionPerShot = consumptionRate / turret.firingsPerSecond

    turret.coolingType = CoolingType.BatteryCharge
    turret.maxHeat = maxCharge
    turret.heatPerShot = consumptionPerShot or 0
    turret.coolingRate = rechargeRate or 0
end
--0x636F6F6C66756E63656E64

--0x6D6574617461626C6566756E636C696E65
generatorFunction[WeaponType.HelixCannon] = TurretGenerator.generateHelixCannonTurret