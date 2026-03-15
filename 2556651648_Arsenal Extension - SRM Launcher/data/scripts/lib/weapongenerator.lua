--0x7767656E657261746566756E637374617274
function WeaponGenerator.generateShortRangeMissile(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setProjectile()

    local fireDelay = rand:getFloat(0.18, 0.25) --Standard Rocket is 0.5 to 1.5
    local reach = rand:getFloat(375, 525)       --Standard Rocket is 1300 - 1800
    local damage = dps * fireDelay * 1.25        --Dropping 1.3.8 support anyways.
    local speed = rand:getFloat(250, 300)       --Standard Rocket is 150-200
    local existingTime = reach / speed

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.seeker = true --Always true
    weapon.appearance = WeaponAppearance.RocketLauncher
    weapon.name = "SRM Launcher /* Weapon Name*/"%_t
    weapon.prefix = "SRM Launcher /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/shortrangemissile.png" -- previously missile-swarm.png
    weapon.sound = "launcher"
    weapon.accuracy = 0.55 - rand:getFloat(0, 0.05)

    weapon.damage = damage
    weapon.damageType = DamageType.Physical
    weapon.impactParticles = ImpactParticles.Explosion
    weapon.impactSound = 1
    weapon.impactExplosion = true

    -- 5 % chance for anti matter damage. Antimatter SRMs are scary!!!
    if rand:test(0.05) then
        WeaponGenerator.addAntiMatterDamage(rand, weapon, rarity, 2, 0.15, 0.2)
    end

    weapon.psize = rand:getFloat(0.2, 0.4)
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.pcolor = ColorHSV(rand:getFloat(10, 60), 0.7, 1)
    weapon.pshape = ProjectileShape.Rocket

    local shots = { 1, 1, 1, 1, 2, 2 }
    weapon.shotsFired = shots[rand:getInt(1, #shots)]
    weapon.damage = (weapon.damage * 1.5) / weapon.shotsFired

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    -- these have to be assigned after the weapon was adjusted since the damage might be changed
    weapon.recoil = weapon.damage * 2
    weapon.explosionRadius = math.sqrt(weapon.damage * 2.5) --Standard rckets are x5

    return weapon
end
--0x7767656E657261746566756E63656E64

--0x776D6574617461626C6566756E636C696E65
generatorFunction[WeaponType.ShortRangeMissile] = WeaponGenerator.generateShortRangeMissile