--0x7767656E657261746566756E637374617274
function WeaponGenerator.generateSpreadFire(rand, dps, tech, material, rarity, _ROF, _ACC, _COLOR, _RANGE, _VELOCITY, _SIZE, _SEED, _ADDPLASMA)
    local weapon = Weapon()
    weapon:setProjectile()

    --NULL values come into play when generating a single weapon for fighters -- anything after "Rarity" will be null.
    local fireDelay = _ROF or rand:getFloat(0.28, 0.38) --In case it is nil
    local reach = _RANGE or rand:getFloat(620, 920)
    local damage = dps * fireDelay
    local speed = _VELOCITY or rand:getFloat(500, 700)
    local weaponcolor = _COLOR or ColorHSV(rand:getFloat(195, 240), 1, 1)
    local weaponaccuracy =  _ACC or 0.99 - rand:getFloat(0, 0.01) --Favor the more accurate variety for just the weapon generation.
    local projectilesize = _SIZE or rand:getFloat(0.4, 0.7)
    local existingTime = reach / speed
    local addPlasma = _ADDPLASMA or rand:test(0.05)

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = _SEED or rand:getInt()
    weapon.appearance = WeaponAppearance.PlasmaGun
    weapon.name = "Spreadfire Cannon /* Weapon Name*/"%_t
    weapon.prefix = "Spreadfire /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/spreadfire.png" -- previously tesla-turret.png
    weapon.sound = "plasma"
    weapon.accuracy = weaponaccuracy

    weapon.damage = damage
    weapon.damageType = DamageType.Energy
    weapon.impactParticles = ImpactParticles.Energy
    weapon.impactSound = 1
    weapon.pshape = ProjectileShape.Plasma

    weapon.psize = projectilesize
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.pcolor = weaponcolor
    
    weapon.shotsFired = 3
    weapon.damage = weapon.damage * 1.5 / weapon.shotsFired

    --5% for plasma damage - determined in the turret generator function to prevent a situation where one weapon has +plasma but not the others.
    if addPlasma then
        WeaponGenerator.addPlasmaDamage(rand, weapon, rarity, 2, 0.15, 0.2)     
    end

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    weapon.recoil = weapon.damage * 4

    return weapon
end
--0x7767656E657261746566756E63656E64

--0x776D6574617461626C6566756E636C696E65
generatorFunction[WeaponType.SpreadFire] = WeaponGenerator.generateSpreadFire