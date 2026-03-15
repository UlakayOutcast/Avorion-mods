--region #SPECIAL XSOTAN

--Appears specially in the Eradicate Xsotan Infestation mission
function Xsotan.createInfestor(_position, _volumeFactor, _extraLoot)
    local _MethodName = "Spawn Xsotan Infestor"
    mission.Log(_MethodName, "Beginning...")

    local _X, _Y = Sector():getCoordinates()
    --Initialize a bunch of turret generator stuff.
    local _TurretGenerator = SectorTurretGenerator()
    local _TurretRarities = _TurretGenerator:getSectorRarityDistribution(_X, _Y)
    local _UpgradeGenerator = UpgradeGenerator()
    local _UpgradeRarities = _UpgradeGenerator:getSectorRarityDistribution(_X, _Y)

    local _XsotanInfestor = Xsotan.createSummoner(_position, _volumeFactor)

    local name = "Infestor"
    _XsotanInfestor:setTitle("${toughness}Xsotan ${ship}", {toughness = "", ship = name})
    _XsotanInfestor:setValue("is_infestor", true)
    _XsotanInfestor:setValue("is_special_xsotan", true)
    _XsotanInfestor:setValue("xsotan_infestor", true)

    --Add extra loot. Guarantee rare+ with less likely rares.
    local _DropCount = 2
    _TurretRarities[-1] = 0 --No petty.
    _TurretRarities[0] = 0 --No common
    _TurretRarities[1] = 0 --No uncommon
    _TurretRarities[2] = _TurretRarities[2] * 0.5 --Cut rare chance in half

    _UpgradeRarities[-1] = 0
    _UpgradeRarities[0] = 0
    _UpgradeRarities[1] = 0
    _UpgradeRarities[2] = _UpgradeRarities[2] * 0.5 --See above.

    _TurretGenerator.rarities = _TurretRarities
    for _ = 1, _DropCount do
        Loot(_XsotanInfestor):insert(InventoryTurret(_TurretGenerator:generate(_X, _Y)))
    end
    for _ = 1, _DropCount do
        Loot(_XsotanInfestor):insert(_UpgradeGenerator:generateSectorSystem(_X, _Y, getValueFromDistribution(_UpgradeRarities)))
    end

    if _extraLoot then 
        _TurretRarities[2] = 0
        _UpgradeRarities[2] = 0

        _TurretGenerator.rarities = _TurretRarities
        Loot(_XsotanInfestor):insert(InventoryTurret(_TurretGenerator:generate(_X, _Y)))
        Loot(_XsotanInfestor):insert(_UpgradeGenerator:generateSectorSystem(_X, _Y, getValueFromDistribution(_UpgradeRarities)))
    end

    _XsotanInfestor.damageMultiplier = (_XsotanInfestor.damageMultiplier or 1 ) * 2

    return _XsotanInfestor
end

--Appears as part of the gang of special Xsotan in xsotan-based missions.
function Xsotan.createOppressor(_position, _volumeFactor)
    _position = _position or Matrix()
    local volume = Xsotan.getShipVolume()

    volume = volume * (_volumeFactor or 1)

    local classification = { volume = 2.5, damage = 4.0, name = "Oppressor" }
    volume = volume * classification.volume

    local x, y = Sector():getCoordinates()
    local probabilities = Balancing_GetTechnologyMaterialProbability(x, y)
    local material = Material(getValueFromDistribution(probabilities))
    local faction = Xsotan.getFaction()
    local plan = PlanGenerator.makeXsotanShipPlan(volume, material)
    local ship = Sector():createShip(faction, "", plan, _position, EntityArrivalType.Jump)

    --Add turrets
    local generator = SectorTurretGenerator()
    generator.coaxialAllowed = false

    local turret = generator:generateArmed(x, y, 0, Rarity(RarityType.Exceptional))
    local numTurrets = math.max(2, Balancing_GetEnemySectorTurrets(x, y))

    ShipUtility.addTurretsToCraft(ship, turret, numTurrets)

    ship:setTitle("${toughness}Xsotan ${ship}"%_T, {toughness = "", ship = classification.name})
    ship.crew = ship.idealCrew
    ship.shieldDurability = ship.shieldMaxDurability
    ship.damageMultiplier = ship.damageMultiplier * classification.damage

    Xsotan.applyCenterBuff(ship)
    Xsotan.applyDamageBuff(ship)

    AddDefaultShipScripts(ship)

    ship:addScriptOnce("ai/patrol.lua")
    ship:addScriptOnce("story/xsotanbehaviour.lua")
    ship:addScriptOnce("utility/aiundockable.lua")
    ship:addScriptOnce("enemies/oppressor.lua")
    ship:addScriptOnce("avenger.lua")
    ship:setValue("is_xsotan", true)
    ship:setValue("is_oppressor", true)
    ship:setValue("is_special_xsotan", true)
    ship:setValue("xsotan_oppressor", true)

    Boarding(ship).boardable = false
    ship.dockable = false

    return ship
end

--Appears as part of the gang of special Xsotan in xsotan-based missions.
function Xsotan.createSunmaker(_position, _volumeFactor)
    local xsotanShip = Xsotan.createShip(_position, _volumeFactor)

    local name = "Sunmaker"
    xsotanShip:setTitle("${toughness}Xsotan ${ship}", {toughness = "", ship = name})
    xsotanShip:setValue("is_sunmaker", true)
    xsotanShip:setValue("is_special_xsotan", true)
    xsotanShip:setValue("xsotan_sunmaker", true)

    --Add Scripts
    local _X, _Y = Sector():getCoordinates()

    local _SunGData = {} --Sunmaker Seige Gun
    _SunGData._TimeToActive = 12
    _SunGData._Velocity = 180
    _SunGData._ShotCycle = 30
    _SunGData._ShotCycleSupply = 0
    _SunGData._ShotCycleTimer = 0
    _SunGData._UseSupply = false
    _SunGData._FragileShots = false
    _SunGData._TargetPriority = 8 --Random non-xsotan.
    _SunGData._UseEntityDamageMult = true
    _SunGData._BaseDamagePerShot = Balancing_GetSectorWeaponDPS(_X, _Y) * 1500

    xsotanShip:addScriptOnce("entity/stationsiegegun.lua", _SunGData)

    return xsotanShip
end

--Appears as part of the gang of special Xsotan in xsotan-based missions.
function Xsotan.createBallistyx(_position, _volumeFactor)
    local xsotanShip = Xsotan.createShip(_position, _volumeFactor)

    local name = "Ballistyx"
    xsotanShip:setTitle("${toughness}Xsotan ${ship}", {toughness = "", ship = name})
    xsotanShip:setValue("is_ballistyx", true)
    xsotanShip:setValue("is_special_xsotan", true)
    xsotanShip:setValue("xsotan_ballistyx", true)

    --Add Scripts
    local _TorpSlammerValues = {
        _TimeToActive = 12,
        _ROF = 4,
        _UpAdjust = false,
        _DurabilityFactor = 4,
        _ForwardAdjustFactor = 1,
        _UseEntityDamageMult = true,
        _TargetPriority = 3 --Random non-xsotan.
    }

    xsotanShip:addScriptOnce("torpedoslammer.lua", _TorpSlammerValues)

    return xsotanShip
end

--Appears as part of the gang of special Xsotan in xsotan-based missions.
function Xsotan.createLonginus(_position, _volumeFactor)
    local xsotanShip = Xsotan.createShip(_position, _volumeFactor)

    local name = "Longinus"
    xsotanShip:setTitle("${toughness}Xsotan ${ship}", {toughness = "", ship = name})
    xsotanShip:setValue("is_longinus", true)
    xsotanShip:setValue("is_special_xsotan", true)
    xsotanShip:setValue("xsotan_longinus", true)

    --Add Scripts
    local _X, _Y = Sector():getCoordinates()

    local _LaserDamage = Balancing_GetSectorWeaponDPS(_X, _Y) * 125

    local _LaserSniperValues = { --#LONGINUS_SNIPER
        _DamagePerFrame = _LaserDamage,
        _UseEntityDamageMult = true,
        _TargetPriority = 2, --Random non-xsotan.
        _TargetCycle = 15,
        _TargetingTime = 2.25 --Take longer than normal to target.
    }

    xsotanShip:addScriptOnce("lasersniper.lua", _LaserSniperValues)

    return xsotanShip
end

--Appears as part of the gang of special Xsotan in xsotan-based missions.
function Xsotan.createWarlock(_position, _volumeFactor)
    local xsotanShip = Xsotan.createShip(_position, _volumeFactor)

    local name = "Warlock"
    xsotanShip:setTitle("${toughness}Xsotan ${ship}", {toughness = "", ship = name})
    xsotanShip:setValue("is_warlock", true)
    xsotanShip:setValue("is_special_xsotan", true)
    xsotanShip:setValue("xsotan_warlock", true)

    --Add Scripts
    xsotanShip:addScriptOnce("enemies/reanimator.lua")

    return xsotanShip
end

--Appears as part of the gang of special Xsotan in xsotan-based missions.
function Xsotan.createTributary(_position, _volumeFactor)
    local xsotanShip = Xsotan.createShip(_position, _volumeFactor)

    local name = "Tributary"
    xsotanShip:setTitle("${toughness}Xsotan ${ship}", {toughness = "", ship = name})
    xsotanShip:setValue("is_tributary", true)
    xsotanShip:setValue("is_special_xsotan", true)
    xsotanShip:setValue("xsotan_tributary", true)

    --Add Scripts
    xsotanShip:addScriptOnce("distributor.lua")

    return xsotanShip
end

--Appears as part of the gang of special Xsotan in xsotan-based missions.
function Xsotan.createLevinstriker(_position, _volumeFactor)
    local xsotanShip = Xsotan.createShip(_position, _volumeFactor)

    local name = "Levinstriker"
    xsotanShip:setTitle("${toughness}Xsotan ${ship}", {toughness = "", ship = name})
    xsotanShip:setValue("is_levinstriker" , true)
    xsotanShip:setValue("is_special_xsotan", true)
    xsotanShip:setValue("xsotan_levinstriker", true)

    --Add scripts
    local _X, _Y = Sector():getCoordinates()

    local lightningDamage = Balancing_GetSectorWeaponDPS(_X, _Y) * 150

    local thunderstrikeValues = { --#LEVINSTRIKER_LIGHTNING
        damagePerStrike = lightningDamage,
        useEntityDamageMult = true,
        targetPriority = 2, --Random non-xsotan.
    }

    xsotanShip:addScriptOnce("thunderstrike.lua", thunderstrikeValues)

    return xsotanShip
end

--Appears at the end of The Dig if the player loses vs. the Xsotan.
function Xsotan.createParthenope(_position, _volumeFactor)
    local xsotanShip = Xsotan.createCarrier(_position, _volumeFactor, 30) --default # of fighters is fine

    local name = "Parthenope"
    xsotanShip:setTitle("${toughness}Xsotan ${ship}", {toughness = "", ship = name})
    xsotanShip:setValue("is_parthenope", true)
    xsotanShip:setValue("is_special_xsotan", true)
    xsotanShip:setValue("xsotan_parthenope", true)

    --Add Scripts
    xsotanShip:addScriptOnce("enemies/parthenope.lua")
    xsotanShip:addScriptOnce("avenger.lua")

    return xsotanShip
end

--Appears as part of the gang of special Xsotan in xsotan-based missions.
function Xsotan.createCaduceus(position, volumeFactor)
    local xsotanShip = Xsotan.createShip(position, volumeFactor)

    local name = "Caduceus"
    xsotanShip:setTitle("${toughness}Xsotan ${ship}", {toughness = "", ship = name})
    xsotanShip:setValue("is_caduceus", true)
    xsotanShip:setValue("is_special_xsotan", true)
    xsotanShip:setValue("xsotan_caduceus", true)

    local linkerValues = {
        healPctWhenLinking = 12.5
    }

    --Add Scripts
    xsotanShip:addScriptOnce("allybooster.lua")
    xsotanShip:addScriptOnce("escclinker.lua", linkerValues)
    xsotanShip:addScriptOnce("eternal.lua")

    return xsotanShip
end

--Created by Warlocks, and maybe some other things :)
function Xsotan.createRevenant(_Wreckage)
    local _Sector = Sector()
    --Get plan from wreckage.
    local plan = _Wreckage:getMovePlan()
    local _position = _Wreckage.position
    local faction = Xsotan.getFaction()
    --Infect.
    Xsotan.infectPlan(plan)

    local ship = _Sector:createShip(faction, "", plan, _position, EntityArrivalType.Default)

    ShipUtility.addRevenantArtillery(ship)

    local name, type = ShipUtility.getMilitaryNameByVolume(ship.volume)
    name = "Revenant"
    ship:setTitle("${toughness}Xsotan ${ship}"%_T, {toughness = "", ship = name})
    ship.crew = ship.idealCrew
    ship.shieldDurability = ship.shieldMaxDurability

    AddDefaultShipScripts(ship)

    ship:addScriptOnce("ai/patrol.lua")
    ship:addScriptOnce("story/xsotanbehaviour.lua")
    ship:addScriptOnce("utility/aiundockable.lua")
    ship:setValue("is_revenant", true)
    ship:setValue("xsotan_revenant", true)

    Boarding(ship).boardable = false
    ship.dockable = false

    _Sector:deleteEntity(_Wreckage)

    return ship
end

--endregion

--region #XSOTAN DREADNOUGHT

--Taken from Hammelpilaw's Xsotan Dreadnought event - there is a mission built around it.
function Xsotan.createDreadnought(position, dangerFactor, killedGuardian)
    dangerFactor = dangerFactor or 1 
    dangerFactor = math.max(dangerFactor, 1) --Should be at least 1.

    --Hammelpilaw's default config settings:
    --[USED] recharges = 1
    local shieldRecharges = 1
    --[USED] damageMultiplier = 5 => Use 1 per dangerFactor up to 5, then 0.5 * dangerFactor afterwards
    local bossDamageMultiplier = math.min(dangerFactor, 5)
    if dangerFactor > 5 then
        bossDamageMultiplier = bossDamageMultiplier + ((dangerFactor - 5) * 0.5)
    end
    --[USED] weaponRange = 20
    local weaponRange = 20
    --[USED] useTorps = true
    local useTorps = true
    --[USED] useTorpsCore = true
    local useTorpsCore = true
    --[USED] shieldMultiplier = 3 => Use 0.6 per dangerFactor up to 5, then 0.3 * dangerFactor afterwards
    local shieldMultiplier = math.min(dangerFactor * 0.6, 3)
    if dangerFactor > 5 then
        shieldMultiplier = shieldMultiplier + ((dangerFactor - 5) * 0.3)
    end
    shieldMultiplier = math.max(shieldMultiplier,  1) --Don't let it go to less than 1 though.
    --[USED] bossVolumeFactor = 50 => Use 10 per dangerFactor UP TO 5 - then add 10% HP per factor after that. Don't make it too big or it will spawn w/o engines.
    local bossVolumeFactor = math.min(10 * dangerFactor, 50)
    local bossDurabilityMultiplier = 1
    if dangerFactor > 5 then
        bossDurabilityMultiplier = bossDurabilityMultiplier + ((dangerFactor - 1) * 0.1)
    end
    --[USED] shipVolumeFactor = 2 => Use 1 + 0.2 per dangerFactor up to 5, then 0.1 aftewards.
    local allyShipVolume = 1 + math.min(dangerFactor * 0.2, 1)
    if dangerFactor > 5 then
        allyShipVolume = allyShipVolume + ((dangerFactor - 5) * 0.1)
    end
    --[USED]shipAmount = 6 --Add a 25% chance for +1 per dangerFactor after 5
    local numShipSpawns = 6
    --[USED] upScale = true
    local useUpscale = true
    --[USED] coreDistance = 150 => Just use Balancing.BlockRingMin
    local coreDist = Balancing_GetBlockRingMin()
    --[USED] strongerAtCore = 250
    local strongerAtCore = 250
    --[USED] strongerAtCore2 = 150
    local strongerAtCore2 = Balancing_GetBlockRingMin()
    --[USED] bossVolumeFactorCore = 1
    local coreVolumeFactor = 1
    --[USED] damageMultiplierCore = 1
    local coreDamageMultiplier = 1

    local x, y = Sector():getCoordinates()
    position = position or Matrix()
    local dist = length(vec2(x, y))

    local volume = Xsotan.getShipVolume()

    if dist < coreDist then
        coreVolumeFactor = 1 * (1 - (dist / coreDist))
    end

    volume = volume * bossVolumeFactor * coreVolumeFactor
    
    local probabilities = Balancing_GetTechnologyMaterialProbability(x, y)
    local material = Material(getValueFromDistribution(probabilities))
    local faction = Xsotan.getFaction()
    local plan = PlanGenerator.makeXsotanShipPlan(volume, material)

    --next, add shields.
    if not plan:getStats().shield or plan:getStats().shield == 0 then
        local shieldMatl = Material(MaterialType.Naonite)
        plan:addBlock(vec3(0, 0, 0), vec3(1, 1, 1), plan.rootIndex, -1, Color(), shieldMatl, Matrix(), BlockType.ShieldGenerator) 
    end

    local ship = Sector():createShip(faction, "", plan, position, EntityArrivalType.Jump)

    --add turrets
    local numTurrets = math.max(2, Balancing_GetEnemySectorTurrets(x, y))
    if dangerFactor >= 5 then
        numTurrets = numTurrets + 1
    end
    if dangerFactor >= 9 then
        numTurrets = numTurrets + 1
    end
    for idx = 1, 2 do
		local turret = SectorTurretGenerator():generateArmed(x, y, 0, Rarity(RarityType.Rare))
		local weapons = {turret:getWeapons()}
		turret:clearWeapons()
		for _, weapon in pairs(weapons) do
			weapon.reach = weaponRange * 100
			if weapon.isBeam then
				weapon.blength = weaponRange * 100
			else
				weapon.pmaximumTime = weapon.reach / weapon.pvelocity
			end
			turret:addWeapon(weapon)
		end

		turret.coaxial = false
		ShipUtility.addTurretsToCraft(ship, turret, numTurrets)
	end
	ShipUtility.addBossAntiTorpedoEquipment(ship)

    --add upscale
    if useUpscale then
        Xsotan.applyCenterBuff(ship)
    end

    --add damage multiplier
    local coreMulti = 1
    if dist < coreDist and coreDamageMultiplier > 1 then --will not activate under normal circumstances unless someone messes w/ the coreDamageMultiplier
        coreMulti = coreDamageMultiplier * (1 - (dist / coreDist))
    end
    ship.damageMultiplier = (ship.damageMultiplier or 1) * bossDamageMultiplier * coreMulti

    --add durability multiplier for danger > 5
    local shipDurability = Durability(ship)
    if shipDurability then
        shipDurability.maxDurabilityFactor = (shipDurability.maxDurabilityFactor or 1) * bossDurabilityMultiplier
    end

    ship:setTitle("${toughness}Xsotan ${ship}"%_T, {toughness = "", ship = "Dreadnought"})
    ship.crew = ship.idealCrew
    ship.shieldDurability = ship.shieldMaxDurability --This gets done again in the dreadnought script.

    -- From Hammelpilaw: Reduce automatic shield recharge and movement speed, its annoying when it always moves directly in front of you...
	ship:addBaseMultiplier(StatsBonuses.Velocity, -0.7)
    ship:addBaseMultiplier(StatsBonuses.Acceleration, -0.7)
	ship:addBaseMultiplier(StatsBonuses.ShieldRecharge, 10)
    
    Xsotan.applyDamageBuff(ship)

    --add loot
    local bonusAmount = 0
    if dist < coreDist and killedGuardian then
        bonusAmount = 1
    end
    local lootTable = {
        {rarity = Rarity(RarityType.Common),        amount = 6 + (bonusAmount * 3), odds = 1 },
        {rarity = Rarity(RarityType.Uncommon),      amount = 4 + (bonusAmount * 3), odds = 1 },
        {rarity = Rarity(RarityType.Rare),          amount = 3 + (bonusAmount * 2), odds = 1 },
        {rarity = Rarity(RarityType.Exceptional),   amount = 3 + (bonusAmount * 2), odds = 1 }
    }
    --A bit less generous than the original incarnation but I don't want to give the player an easy source of legendaries too far out. (or too often)
    --The original was balanced around occurring at a fixed schedule, but the player can take this mission as often as they want - especially if they have the extra mission mod.
    if dangerFactor >= 5 then
        local useOdds = 0.5
        if dist > 350 then
            useOdds = 0.25
        end
        if dist < coreDist and killedGuardian then
            useOdds = 1.0
        end
        table.insert(lootTable, {rarity = Rarity(RarityType.Exotic), amount = 2 + bonusAmount, odds = useOdds })
    end
    if dist < 250 and dangerFactor >= 9 then
        local useOdds = 0.25
        if dist < coreDist and killedGuardian then
            useOdds = 0.5
        end
        table.insert(lootTable, {rarity = Rarity(RarityType.Legendary), amount = 1 + bonusAmount, odds = useOdds })
    end

    local shipLoot = Loot(ship.index)
    local xrand = random()
    for _, p in pairs(lootTable) do
        for i = 1, p.amount do
			-- 60% upgrades, 40% weapons
            if xrand:test(p.odds) then
                if xrand:test(0.6) then
                    shipLoot:insert(UpgradeGenerator():generateSectorSystem(x, y, p.rarity))
                else
                    shipLoot:insert(InventoryTurret(SectorTurretGenerator():generate(x, y, 0, p.rarity)))
                end
            end
        end
    end

    --do normal ship things
    AddDefaultShipScripts(ship)

    local esccDreadnoughtValues = {
        dangerFactor = dangerFactor,
        shieldBonusMultiplier = shieldMultiplier,
        shieldRecharges = shieldRecharges,
        dist = dist,
        allyShipVolume = allyShipVolume,
        numShipSpawns = numShipSpawns,
        strongerAtCore = strongerAtCore,
        strongerAtCore2 = strongerAtCore2
    }

    if killedGuardian and dist < coreDist then
        esccDreadnoughtValues.sickoMode = true
    end

    ship:addScriptOnce("ai/patrol.lua")
    ship:addScriptOnce("story/xsotanbehaviour.lua")
    ship:addScriptOnce("utility/aiundockable.lua")
    ship:addScript("enemies/esccxsotandreadnought.lua", esccDreadnoughtValues)
    ship:setValue("is_xsotan", true)
    ship:setValue("is_special_xsotan", true)
    ship:setValue("xsotan_dreadnought", true)
    ship:setValue("SDKEDSDisabled", true) --Need to disable SDK extended docking shields.
    ship:setValue("IW_nuclear_m", 0.2)
    if dangerFactor > 5 then
        ship:addScript("internal/common/entity/background/legendaryloot.lua")
    end

    --normally this is done much earlier, but we can't add the torpedo slammer until after we set is_xsotan otherwise it messes up the target priority.
    --add torpedoes
    if useTorps or (useTorpsCore and dist < coreDist) then
        local torpDamageMultiplier = math.max(ship.damageMultiplier / 2, 1) --We want 1 as a minimum value
        --add a torpedo slammer - similar values to the ballistyx, except we want _UpAdjust to be true.
        --use a static multiplier that's half of what's given to the dreadnought.
        local torpROF = 6
        local torpDurability = 4
        if dangerFactor == 10 then
            torpROF = 4
            torpDurability = 8

            --much more dangerous on sicko mode.
            if killedGuardian and dist < coreDist then
                torpROF = 2
                torpDurability = 16
            end
        end 

        local _TorpSlammerValues = {
            _TimeToActive = 15,
            _ROF = torpROF,
            _DamageFactor = torpDamageMultiplier,
            _DurabilityFactor = torpDurability,
            _ForwardAdjustFactor = 1,
            _TargetPriority = 3 --Random non-xsotan.
        }
    
        ship:addScriptOnce("torpedoslammer.lua", _TorpSlammerValues)
    end

    if dangerFactor == 10 then
        local boosterValues = {
            _MaxBoostCharges = 10
        }

        --basically boosts 4x as quickly on sicko mode
        if killedGuardian and dist < coreDist then
            boosterValues._ChargesMultiplier = 2
            boosterValues._BoostCycle = 30
        end

        ship:addScriptOnce("allybooster.lua", boosterValues)
    end

    Boarding(ship).boardable = false
    ship.dockable = false

    return ship
end

--endregion

--region #UNUSED... FOR NOW

function Xsotan.createHierophant(_position, _volumeFactor)
    local xsotanShip = Xsotan.createSummoner(_position, _volumeFactor)

    local name = "Hierophant"
    xsotanShip:setTitle("${toughness}Xsotan ${ship}", {toughness = "", ship = name})
    xsotanShip:setValue("is_hierophant", true)
    xsotanShip:setValue("is_special_xsotan", true)
    xsotanShip:setValue("xsotan_hierophant", true)

    --Add Scripts
    xsotanShip:addScriptOnce("enemies/reanimator.lua")

    return xsotanShip
end

function Xsotan.createPulverizer(_position, _volumeFactor)
    local xsotanShip = Xsotan.createGenericShip(_position, _volumeFactor)

    local name, type = ShipUtility.getMilitaryNameByVolume(xsotanShip.volume)
    xsotanShip:setTitle("${toughness}Xsotan Pulverizer ${ship}"%_T, {toughness = "", ship = name})
    xsotanShip:setValue("is_pulverizer", true)
    xsotanShip:setValue("is_special_xsotan", true)
    xsotanShip:setValue("xsotan_pulverizer", true)

    ShipUtility.addPulverizerCannons(xsotanShip)

    return xsotanShip
end

function Xsotan.createHeresiarch(_position, _volumeFactor)
    --Periodically sacrifices a Xsotan to boost the damage output of other Xsotan in the area
    --Provides other boosts for Xsotan
    --Supernova script
end

function Xsotan.createSchismatic(_position, _volumeFactor)
    --Dynamic damage resistance (takes less damage from the damage type it has taken the most damage from)
    --Dynamic teleportation (gets stunned if it takes damage from the damage type it has taken the least damage from, teleports otherwise)
    --Fires volleys of torpedoes
    _position = _position or Matrix()
    local _sector = Sector()
    local _random = random()

    local volume = Xsotan.getShipVolume()
    volume = volume * (_volumeFactor or 1)

    local classification = { volume = 33, damage = 10, name = "Schismatic" }
    volume = volume * classification.volume

    local x, y = _sector:getCoordinates()
    local probabilities = Balancing_GetTechnologyMaterialProbability(x, y)
    local material = Material(getValueFromDistribution(probabilities))
    local faction = Xsotan.getFaction()
    --Make a trimaran hull for these guys
    local plan = Xsotan.getTrimaranShipPlan(_random, volume, material)

    --Finally, make the ship.
    local ship = _sector:createShip(faction, "", plan, _position, EntityArrivalType.Jump)

    --Add turrets
    local generator = SectorTurretGenerator()
    generator.coaxialAllowed = false

    local turret = generator:generateArmed(x, y, 0, Rarity(RarityType.Exotic))
    local numTurrets = math.max(3, Balancing_GetEnemySectorTurrets(x, y))

    ShipUtility.addTurretsToCraft(ship, turret, numTurrets)

    ship:setTitle("${toughness}Xsotan ${ship}"%_T, {toughness = "", ship = classification.name})
    ship.crew = ship.idealCrew
    ship.shieldDurability = ship.shieldMaxDurability
    ship.damageMultiplier = ship.damageMultiplier * classification.damage

    Xsotan.applyCenterBuff(ship)
    Xsotan.applyDamageBuff(ship)

    AddDefaultShipScripts(ship)

    local torpSlammerValues = {
        _TimeToActive = 12,
        _ROF = 10,
        _UpAdjust = false,
        _DurabilityFactor = 12,
        _ForwardAdjustFactor = 1,
        _UseEntityDamageMult = true,
        _DamageFactor = 0.5, --These are terrifying enough at x5 damage multiplier.
        _TargetPriority = 3, --Random non-xsotan.
        _FireBarrage = true,
        _BarrageCount = 5,
        _BarrageDelay = 0.5
    }

    ship:addScriptOnce("ai/patrol.lua")
    ship:addScriptOnce("story/xsotanbehaviour.lua")
    ship:addScriptOnce("utility/aiundockable.lua")
    --Set values
    ship:setValue("is_xsotan", true)
    ship:setValue("is_schismatic", true)
    ship:setValue("is_special_xsotan", true)
    ship:setValue("xsotan_schismatic", true)
    --Add special scripts :3
    ship:addScriptOnce("enemies/superbosses/schismatic.lua")
    ship:addScriptOnce("torpedoslammer.lua", torpSlammerValues) --Have to add this after is_xsotan set to true or else the script gets very unhappy.

    Boarding(ship).boardable = false
    ship.dockable = false

    return ship    
end

function Xsotan.createTraditor(_position, _volumeFactor)
    --Lighting tether to all player ships, which take damage periodically
    --Tethers to all player ships, and any damage taken (including the lightning damage) spreads to nearby player ships
    --Eats other Xsotan similar to Oppressor. Does not eat wrecks.
end

function Xsotan.createScourge(_position, _volumeFactor)
    --Lots of armor + armor takes less damage
    --Regenerates HP
    --Long-range lasers (normal weapon)
end

function Xsotan.createRecreant(_position, _volumeFactor)
    --Gets a massive damage bonus if it manages to kill a player's ship.
    --Gets a minor damage bonus any time another Xsotan is killed.
    --Gets a damage buff over time when heavily damaged.
end

--endregion

--region #UTILITY

function Xsotan.getSpecialXsotanFunctions()
    local funcTable = {
        Xsotan.createSunmaker,      --Seige gun Xsotan
        Xsotan.createLonginus,      --Lasersniper Xsotan
        Xsotan.createBallistyx,     --Torpedo Xsotan
        Xsotan.createWarlock,       --Reanimator Xsotan
        Xsotan.createOppressor,     --Beefy Xsotan that eats other Xsotan (and wreckages)
        Xsotan.createCaduceus,      --Healer Xsotan
        Xsotan.createTributary,     --AOE damage specialist Xsotan
        Xsotan.createLevinstriker   --Lightning damage Xsotan
    }
    
    return funcTable
end

function Xsotan.createGenericShip(position, volumeFactor)
    position = position or Matrix()
    local volume = Xsotan.getShipVolume()

    volume = volume * (volumeFactor or 1)
    volume = volume * 0.5 -- xsotan ships aren't supposed to be very big

    local classification = Xsotan.getClassification()
    volume = volume * classification.volume

    local x, y = Sector():getCoordinates()
    local probabilities = Balancing_GetTechnologyMaterialProbability(x, y)
    local material = Material(getValueFromDistribution(probabilities))
    local faction = Xsotan.getFaction()
    local plan = PlanGenerator.makeXsotanShipPlan(volume, material)
    local ship = Sector():createShip(faction, "", plan, position, EntityArrivalType.Jump)

    --Don't add turrets.
    ship:setTitle("${toughness}Xsotan ${ship}"%_T, {toughness = "", ship = classification.name})
    ship.crew = ship.idealCrew
    ship.shieldDurability = ship.shieldMaxDurability
    ship.damageMultiplier = ship.damageMultiplier * classification.damage

    Xsotan.applyCenterBuff(ship)
    Xsotan.applyDamageBuff(ship)

    AddDefaultShipScripts(ship)

    ship:addScriptOnce("ai/patrol.lua")
    ship:addScriptOnce("story/xsotanbehaviour.lua")
    ship:addScriptOnce("utility/aiundockable.lua")
    ship:setValue("is_xsotan", true)

    Boarding(ship).boardable = false
    ship.dockable = false

    return ship
end

function Xsotan.getTrimaranShipPlan(_random, volume, material)
    local plan = PlanGenerator.makeXsotanShipPlan(volume / 3, material)
    local plan2 = PlanGenerator.makeXsotanShipPlan(volume / 3, material)
    local plan3 = PlanGenerator.makeXsotanShipPlan(volume / 3, material)
    local funcTable = {
        function(aplan, bplan)
            attachMin(aplan, bplan, "z")
        end,
        function(aplan, bplan)
            attachMin(aplan, bplan, "y")
        end,
        function(aplan, bplan)
            attachMin(aplan, bplan, "x")
        end
    }
    funcTable[_random:getInt(1, 3)](plan, plan2)
    funcTable[_random:getInt(1, 3)](plan, plan3)

    return plan
end

--endregion

