function ArmedObjectPrice(object)

    local type = WeaponTypes.getTypeOfItem(object) or WeaponType.ChainGun

    local baseValue = object.dps / (0.5 + object.slots / 2) * 2
    local value = baseValue

    -- dps
    -- + shield / hull dmg multi -> +50% each
    -- multiplier of 1 is normal though - so substract 1
    value = value + baseValue * (object.shieldDamageMultiplier - 1) * 0.5
    value = value + baseValue * (object.hullDamageMultiplier - 1) * 0.5

    -- shield pen -> 100% -> doubled price (but only for hull damage, shield is irrelevant here)
    value = value + (baseValue * object.hullDamageMultiplier) * object.shieldPenetration

    -- bring mining beam damage up to par, only x0.25 since it's only vs. stone
    value = value + (baseValue * object.hullDamageMultiplier * object.stoneDamageMultiplier * 0.15)

    -- repair strength
    value = value + object.hullRepairRate / object.slots * 2.5
    value = value + object.shieldRepairRate / object.slots * 2.5

    -- force
    if type == WeaponType.ForceGun then
        value = value + object.holdingForce / 7500
    end

    -- ### MOD ###
    -- Define the mining weapons in a set for quick lookup
    local miningWeaponTypes = {
        [WeaponType.MiningLaser] = true,
        [WeaponType.SalvagingLaser] = true,
        [WeaponType.RawMiningLaser] = true,
        [WeaponType.RawSalvagingLaser] = true
    }

    -- Divide reach by 3 to maintain value with increased range from mod
    if miningWeaponTypes[type] then
        value = value * object.reach / 2 * (reachWeights[type] or 1)
    else
        -- Use default value calculation for everything else
        value = value * object.reach * (reachWeights[type] or 1)
    end
    -- ### MOD END ###

    -- efficiency
    local bestStoneEfficiency = math.max(object.stoneRawEfficiency, object.stoneRefinedEfficiency)
    value = value * (1 + bestStoneEfficiency * (1 + ((1.2 ^ object.material.value) - 1) * 5))

    local bestMetalEfficiency = math.max(object.metalRawEfficiency, object.metalRefinedEfficiency)
    value = value * (1 + bestMetalEfficiency * (1 + ((1.1 ^ object.material.value) - 1) * 3))

    -- rocket launchers gain value if they fire seeker rockets
    if object.seeker then value = value * 2 end

    value = value * valueWeights[type] or 1

    -- rarity
    local added = math.max(0, (object.rarity.value) * (rarityWeights[type] or 0.1))
    value = value + value * added

    value = math.max(value, 100)

    return value
end