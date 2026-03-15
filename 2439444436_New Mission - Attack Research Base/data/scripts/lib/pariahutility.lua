include("galaxy")

ESCCUtil = include("esccutil")

local PariahUtil = {}
local self = PariahUtil

self._Debug = 0

function PariahUtil.getFaction()
    local _Galaxy = Galaxy()
    local name = "The Pariah"%_T
    local faction = _Galaxy:findFaction(name)
    if faction == nil then
        faction = _Galaxy:createFaction(name, 0, 0)
        faction.initialRelations = 0
        faction.initialRelationsToPlayer = 0
        faction.staticRelationsToPlayers = true
    end

    faction.initialRelationsToPlayer = 0
    faction.staticRelationsToPlayers = true
    faction.homeSectorUnknown = true

    return faction
end

function PariahUtil.spawnSuperWeapon(_MainWeapon, _AuxWeapon)
    local _MethodName = "Spawn Superweapon"
    self.Log(_MethodName, "Beginning...")

    local _Faction = self.getFaction()
    if not _Faction then
        self.Log(_MethodName, "ERROR - Could not get faction.")
        return
    end

    local _Rgen = ESCCUtil.getRand()
    _MainWeapon = _MainWeapon or _Rgen:getInt(1, 2)
    _AuxWeapon = _AuxWeapon or _Rgen:getInt(1, 2)

    local _Type = tostring(_Rgen:getInt(1, 6))
    if _MainWeapon == 2 then
        _Type = tostring(_Rgen:getInt(1, 6))
        _Type = "X" .. _Type
    end

    local _PlanFileName = "data/plans/researchbase/Type" .. tostring(_Type) .. ".xml"
    self.Log(_MethodName, "Loading plan : " .. tostring(_PlanFileName))

    local _Plan = LoadPlanFromFile(_PlanFileName)
    local _Scale = 3

    local PirateGenerator = include("pirategenerator")
    local ShipUtility = include("shiputility")

    local _Factor = 70
    local _DamageFactor = 85
    local _Amp = 1

    --Calculate amp here.
    local _ActiveMods = Mods()
    local _ic1 = false
    local _ic2 = false

    self.Log(_MethodName, "Checking Amp")

    local _AmpTable = {
        ["2017677089"] = 0.0,     --Weapon Engineering is _Amp + 3 - Just want to note that it is on the list here. We have a special set of detection triggers for this later in the file.
        ["3487893402"] = 0.0,     --Upgradable Player Turret Blueprints is same as above.
        ["2849203442"] = 4,       --Overpowerinator. I mean, it's deliberately designed to be overpowered.
        ["3229979623"] = 4,       --Same comment as above.
        ["3452526124"] = 2,       --Nuclear Warhead Item Wheel. Can auto-damage the boss.
        ["2191291553"] = 2,       --HarderEnemys - Your wish has been granted.
        ["2442089978"] = 2,       --Amped UP DPS - Sure, it makes the Gordian Knot hit harder, but we need to compensate with HP.
        ["2674515274"] = 2,       --Voidspark upgrade
        ["2673565613"] = 2,       --Doomsday weapon
        ["2629827943"] = 2,       --Add exotic and legendary blueprints to turret factor
        ["2623306700"] = 2,       --"Easy and powerful system XSTN-K V"
        ["2601660342"] = 2,       --Turrets x20 - how original!
        ["2601660284"] = 2,       --Turrets x4 to x20
        ["1990599419"] = 2,       --v31-DmgFix
        ["1821043731"] = 1.33,    --High Efficiency Turrets (HET)
        ["2620549321"] = 1.33,    --1.1.4 turret balancing
        ["1991691736"] = 1.33,    --Turret Replicator for turret factories
        ["1789307930"] = 1.33,    --PowerTurrets (WIP)
        ["2014035735"] = 1.33,    --Scaling Turret System
        ["2601660220"] = 1.33,    --Turrets x10
        ["2572559206"] = 1.33,    --Pulse Accelerators
        ["2514027747"] = 1.33,    --Wave motion gun
        ["2668246868"] = 1.33,    --Capital weapon foundry
        ["2745345613"] = 1.33,    --Xsotan Civil War
        ["2108001003"] = 1.33,    --SDK mainframes
        ["3490328541"] = 1,       --XSTN-Keys Overhauled
        ["1905374778"] = 1,       --Nanobot System Upgrade
        ["2021277562"] = 1,       --Nanobot updated and reworked
        ["2656616473"] = 0.66,    --The large AI
        ["2566347474"] = 0.66,    --Typhon turret
        ["2575213622"] = 0.66,    --BFG turret
        ["2635630603"] = 0.66,    --Star wars weapon
        ["2286575730"] = 0.66,    --Ancient Weapons
        ["2289497873"] = 0.66,    --Just Sell Me Guns Already
        ["2188351263"] = 0.66,    --Customize Turret Factory
        ["2751734558"] = 0.66,    --Turrets x8
        ["2713507250"] = 0.66,    --Oh look, it's another Turrets x8 mod.
        ["2043905084"] = 0.66,   
        ["2033776157"] = 0.66,
        ["2201230263"] = 0.66,    --Turret X4 - 28 RNG Edition!
        ["2187486306"] = 0.66,    --Turret Rebalance
        ["2091059429"] = 0.66,
        ["2002338565"] = 0.66,    --Custom Turret Builder II
        ["2039371866"] = 0.66,    --Custom Turret Builder III
        ["2130593404"] = 0.66,    --Custom Turret Designer
        ["2202592882"] = 0.66,    --Custom Turret Builder IV - SR
        ["2180668115"] = 0.66,    --Custom Turret Builder IV
        ["2084524044"] = 0.66,    --Specialized Military Shield Enhancer (SDK)
        ["2083280364"] = 0.66,    --Specialized Military Shield Booster (SDK)
        ["2087270794"] = 0.66,    --Specialized Military Hull Reinforcement (SDK)
        ["2093389493"] = 0.66,    --Specialized Military Turret Control System (SDK)
        ["2224360054"] = 0.66,    --Box Corp. !A Box Full Of Weapons!
        ["1912649093"] = 0.66,    --8x Turrets with reduced energy drain
        ["2287007906"] = 0.66,    --Custom Armed Turret Slots
        ["1847988904"] = 0.66,    --Weapon Pack Extended
        ["1817506461"] = 0.66,    --Turrets_x4
        ["2052687922"] = 0.33,    --Pirate Drop Extra Turrets
        ["2738498925"] = 0.33,    --Ballistic Missile
        ["2021071111"] = 0.33,    --Plasma blaster turret
        ["2021183079"] = 0.33,    --Autocannon turret
        ["2033631749"] = 0.33,    --Armour Hardener
        ["1987912889"] = 0.33,    --Custom Fighter Builder II
        ["2287007906"] = 0.33,    --Custom Armed Turret Slots
        ["2021850808"] = 0.33,
        ["2127387501"] = 0.33,
        ["2201245637"] = 0.33,
        ["2070272331"] = 0.33,    --Capital Class Weapons
        ["2573925137"] = 0.33     --Another autocannon mod.
    }

    local genericModMultiplier = 1.0

    for _, _Xmod in pairs(_ActiveMods) do
        --There are way too many mods to go through them manually anymore. Sad but we take the easy way out here.
        genericModMultiplier = genericModMultiplier + 0.1 

        if _Xmod.id == "2017677089" or _Xmod.id == "3487893402" or _Xmod.title == "Upgradable Player Turret Blueprints" or _Xmod.name == "DccWeaponEngineering" or _Xmod.title == "Weapon Engineering" then
            _Amp = _Amp + 3
            _ic2 = true
        end
        if _Xmod.id == "2052687922" or _Xmod.id == "1991691736" or _Xmod.id == "2289497873" then
            _ic1 = true
        end
        local _xAmp = _AmpTable[_Xmod.id]
        if _xAmp then
            _Amp = _Amp + _xAmp
        end
    end

    if not _ic2 then
        --Extra check to see if people are being sneaky.
        local _Players = {Sector():getPlayers()}
        for _, _P in pairs(_Players) do
            if _P:hasScript("TurretModding") or _P:hasScript("mods/DccTurretEditor/Commands/TurretModding") then
                _Amp = _Amp + 6
                _ic2 = true
                break
            end
        end
    end

    if _ic1 and _ic2 then
        _Amp = _Amp * 2
    end

    local _FinalFactor = _Factor * _Amp * genericModMultiplier
    local _FinalDamageFactor = _DamageFactor * _Amp * genericModMultiplier

    if _MainWeapon == 1 then
        _FinalDamageFactor = _FinalDamageFactor * 1.25
    end

    _Plan:scale(vec3(_Scale, _Scale, _Scale))

    local _Superweapon = Sector():createShip(_Faction, "", _Plan, PirateGenerator.getGenericPosition())
    local _AdjustSlammer = false
    local _TurnFactor = 1.0
    if _ic1 and _ic2 then
        _Superweapon:setValue("autokill", true)
    end

    local _ShipNameTitle = "SW-T" .. tostring(_Type) .. "-MW"
    if _MainWeapon == 1 then
        _ShipNameTitle = _ShipNameTitle .. "SG-AW"
        --Siege Gun
        --Siege Gun Data
        local _SGD = {}
		_SGD._CodesCracked = false
		_SGD._Velocity = 400
		_SGD._ShotCycle = 30
		_SGD._ShotCycleSupply = 0
		_SGD._ShotCycleTimer = 30
		_SGD._UseSupply = false
		_SGD._FragileShots = false
		_SGD._TargetPriority = 3 --Target the most dangerous enemies first.

        local _Damage = 500000000 --500 million base damage, since this can't go through shields.
        _Damage = _Damage * math.max(1, _Amp / 2) * math.max(1, genericModMultiplier / 2)
        _SGD._BaseDamagePerShot = _Damage

        _Superweapon:addScript("entity/stationsiegegun.lua", _SGD)
        _Superweapon:setValue("_gk_superweaponscript", "stationsiegegun.lua")
        ShipAI(_Superweapon.id):setAggressive()
        self.Log(_MethodName, "Attached siege gun script to SuperWeapon.")
    else
        _ShipNameTitle = _ShipNameTitle .. "LB-AW"
        --Laser Boss
        _AdjustSlammer = true
        _Superweapon:addScript("entity/gordianlaserboss.lua", _Amp)
        _Superweapon:setValue("_gk_superweaponscript", "gordianlaserboss.lua")
        _TurnFactor = 2
        self.Log(_MethodName, "Attached laser boss script to SuperWeapon.")
    end

    local _TurretFactor = 18
    if _AuxWeapon == 1 then
        _ShipNameTitle = _ShipNameTitle .. "ML"
        ShipUtility.addMegaLasers(_Superweapon, _TurretFactor)
    else
        if _MainWeapon == 1 then
            _ShipNameTitle = _ShipNameTitle .. "HS"
            ShipUtility.addMegaSeekers(_Superweapon, _TurretFactor)
            _FinalDamageFactor = _FinalDamageFactor * 1.25
        else
            --Passive shooting doesn't trigger the seeking property, so we add a different type of artillery.
            _ShipNameTitle = _ShipNameTitle .. "VC"
            ShipUtility.addVelocityCannons(_Superweapon, _TurretFactor)
        end
    end

    _Superweapon.name = _ShipNameTitle
    _Superweapon.title = "The Gordian Knot"

    _Superweapon.crew = _Superweapon.idealCrew
    _Superweapon:addScript("icon.lua", "data/textures/icons/pixel/skull_big.png")
    _Superweapon:setValue("is_attackresearchbase_superweapon", true)
    _Superweapon:setValue("IW_nuclear_m", 0.05) --If you can live long enough to drop 20 nukes on this thing, you deserve to win.
    
    --Just remember. If you alter the code to make this easier, you cheated :P
    self.Log(_MethodName, "Upgrading Thrusters and engine to x2")
    local _Thrusters = Thrusters(_Superweapon)
    _Thrusters.baseYaw = _Thrusters.baseYaw * 2 * _TurnFactor
    _Thrusters.basePitch = _Thrusters.basePitch * 2 * _TurnFactor
    _Thrusters.baseRoll = _Thrusters.baseRoll * 2 * _TurnFactor
    _Thrusters.fixedStats = true
    _Superweapon:addMultiplier(StatsBonuses.Acceleration, 2)
    _Superweapon:addMultiplier(StatsBonuses.Velocity, 2)

    self.Log(_MethodName, "Upgrading Weapons")
    _Superweapon.damageMultiplier = (_Superweapon.damageMultiplier or 1) * _FinalDamageFactor

    self.Log(_MethodName, "Upgrading Hull")
    local _Dura = Durability(_Superweapon)
    if _Dura then 
        _Dura.maxDurabilityFactor = (_Dura.maxDurabilityFactor or 0) + _FinalFactor
        _Dura:setWeakness(DamageType.AntiMatter, -0.6)
    end

    self.Log(_MethodName, "Upgrading Shields")
    local _Shield = Shield(_Superweapon)
    if _Shield then 
        _Shield.maxDurabilityFactor = (_Shield.maxDurabilityFactor or 0) + _FinalFactor
        _Shield:setResistance(DamageType.Plasma, 0.6)
    end

    self.Log(_MethodName, "Upgrading Boarding and Docking")
    Boarding(_Superweapon).boardable = false
    _Superweapon.dockable = false

    --Obviously this drops an incredible amount of loot.
    self.Log(_MethodName, "Adding loot.")
    local SectorTurretGenerator = include ("sectorturretgenerator")
    local SectorUpgradeGenerator = include ("upgradegenerator")
    local _X, _Y = Sector():getCoordinates()
    local _TurretGenerator = SectorTurretGenerator()
    local _UpgradeGenerator = SectorUpgradeGenerator()

    local _Loot = Loot(_Superweapon)
    local _TurretCount = _Rgen:getInt(30, 40)
    local _SystemCount = _Rgen:getInt(30, 40)

    for _ = 1, _TurretCount do
        _Loot:insert(InventoryTurret(_TurretGenerator:generate(_X, _Y, -156, Rarity(self.getRandomRarity()))))
    end
    for _ = 1, _SystemCount do
        _Loot:insert(_UpgradeGenerator:generateSectorSystem(_X, _Y, Rarity(self.getRandomRarity())))
    end

    local _TorpDamageFactor = 2
    local _TorpDurabilityFactor = 32
    local _TechLevel = Balancing_GetTechLevel(_X, _Y)
    if _TechLevel <= 45 then
        _TorpDamageFactor = 4
    end
    if _TechLevel <= 40 then
        _TorpDamageFactor = 6
    end
    if _ic1 and _ic2 then
        _TorpDamageFactor = _TorpDamageFactor * 16
        _TorpDurabilityFactor = _TorpDurabilityFactor * 16
    end

    local useTorpOffset = -750
    local useForwardAdjFactor = 1
    local _tta = 10
    local _avtFactor = 1.5
    local _shockFactor = 2
    if _ic1 and _ic2 then
        _tta = 0
        _avtFactor = 4
        _shockFactor = 10
    end

    local _TorpSlammerValues = {
        _TimeToActive = _tta,
        _ROF = 1,
        _TorpOffset = useTorpOffset,
        _UpAdjust = _AdjustSlammer,
        _DamageFactor = _TorpDamageFactor,
        _ForwardAdjustFactor = useForwardAdjFactor,
        _DurabilityFactor = _TorpDurabilityFactor,
        _ReachFactor = 10,
        _AccelFactor = _avtFactor,
        _VelocityFactor = _avtFactor,
        _TurningSpeedFactor = _avtFactor,
        _ShockwaveFactor = _shockFactor,
        _TargetPriority = 4 --Random enemy
    }

    _Superweapon:addAbsoluteBias(StatsBonuses.ShieldImpenetrable, true)
    _Superweapon:addScriptOnce("internal/common/entity/background/legendaryloot.lua")
    _Superweapon:addScriptOnce("terminalblocker.lua", 1)
    _Superweapon:addScriptOnce("ai/hyperaggro.lua")
    _Superweapon:addScriptOnce("torpedoslammer.lua", _TorpSlammerValues)
    _Superweapon:addScriptOnce("absolutepointdefense.lua")
    _Superweapon:addScriptOnce("gordianknotbehavior.lua")
    if _ic2 then
        _Superweapon:addScriptOnce("ironcurtain.lua")
    end
    if _Amp > 4 or _ic2 then
        _Superweapon:addScriptOnce("eternal.lua")
    end

    _Superweapon:setDropsAttachedTurrets(false)

    _Superweapon:setValue("is_gordian_knot", true)

    return _Superweapon
end

function PariahUtil.getRandomRarity()
    local _MethodName = "Random Rarity"

    local _Raregen = ESCCUtil.getRand()
    if _Raregen:getInt(1, 2) == 1 then
        return RarityType.Legendary
    else
        return RarityType.Exotic
    end
end

function PariahUtil.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[PariahUtility] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

return PariahUtil