--0x7767656E657261746566756E637374617274
function WeaponGenerator.generateSlugGun(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    local fireDelay = rand:getFloat(1, 2.2) --Railgun is 1 to 2.5
    local reach = rand:getFloat(950, 1400)
    local damage = dps * fireDelay * 1.5 --Compensating for the horrible, horrible accuracy.

    weapon.fireDelay = fireDelay
    weapon.appearanceSeed = rand:getInt()
    weapon.reach = reach
    weapon.continuousBeam = false
    weapon.appearance = WeaponAppearance.RailGun
    weapon.name = "Slug Gun /* Weapon Name*/"%_t
    weapon.prefix = "Slug Gun /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/slug-gun.png" -- previously beam.png
    weapon.sound = "railgun"
    weapon.accuracy = 0.90 - rand:getFloat(0, 0.07)

    weapon.damage = damage
    weapon.damageType = DamageType.Physical
    weapon.impactParticles = ImpactParticles.Physical
    weapon.impactSound = 1
    weapon.blockPenetration = rand:getInt(4, 7 + rarity.value * 2)

    -- 10 % chance for antimatter
    if rand:test(0.1) then
        WeaponGenerator.addAntiMatterDamage(rand, weapon, rarity, 2, 0.15, 0.2)
    end

    weapon.blength = weapon.reach
    weapon.bshape = BeamShape.Straight
    weapon.bwidth = 0.5
    weapon.bauraWidth = 3
    weapon.banimationSpeed = 1
    weapon.banimationAcceleration = -2
    weapon.shotsFired = rand:getInt(4, 7)
    weapon.damage = (weapon.damage * 1.5) / weapon.shotsFired

    if rand:getBool() then
        -- shades of red
        weapon.bouterColor = ColorHSV(rand:getFloat(10, 60), rand:getFloat(0.5, 1), rand:getFloat(0.1, 0.5))
        weapon.binnerColor = ColorHSV(rand:getFloat(10, 60), rand:getFloat(0.1, 0.5), 1)
    else
        -- shades of blue
        weapon.bouterColor = ColorHSV(rand:getFloat(180, 260), rand:getFloat(0.5, 1), rand:getFloat(0.1, 0.5))
        weapon.binnerColor = ColorHSV(rand:getFloat(180, 260), rand:getFloat(0.1, 0.5), 1)
    end

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    weapon.recoil = weapon.damage * 20

    return weapon
end
--0x7767656E657261746566756E63656E64

--0x776D6574617461626C6566756E636C696E65
generatorFunction[WeaponType.SlugGun] = WeaponGenerator.generateSlugGun