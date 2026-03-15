package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local ShipUtility = include ("shiputility")

include ("galaxy")

local ESCCBossUtil = {}
local self = ESCCBossUtil

self._Debug = 0

function ESCCBossUtil.spawnESCCBoss(_Faction, _BossType) --Formerly spawnIncreasingThreatBoss
    local _MethodName = "Spawn Increasing Threat Boss"
    ESCCBossUtil.Log(_MethodName, "Beginning...")

    local _ActiveMods = Mods()
    local _HETActive = false
    local _HarderEnemysActive = false
    for _, _Xmod in pairs(_ActiveMods) do
        if _Xmod.id == "1821043731" then --HET
            ESCCBossUtil.Log(_MethodName, "HET is active - increasing _Amp / _HighAmp")
            _HETActive = true
        end
        if _Xmod.id == "2191291553" then --HarderEnemys
            ESCCBossUtil.Log(_MethodName, "HarderEnemys is active - increasing _Amp / _HighAmp")
            _HarderEnemysActive = true
        end
    end

    --INCREASING THREAT BOSS QUICKREF
    --1 = Katana
    --2 = Goliath
    --3 = Hellcat
    --4 = Hunter
    --5 = Shield
    --6 = Phoenix
    local _BossTypes = {
        { _PlanFile = "data/plans/escc/Katana.xml", _Title = "Baleful Katana", _EngineFactor = 2, _ThrustFactor = 1, _CustomFunction = function(_Boss, _ShipUtil)
            _Boss:addScriptOnce("adaptivedefense.lua")
            _Boss:addScriptOnce("overdrive.lua")
            _Boss:addScriptOnce("frenzy.lua")

            local _SecondaryWeaponValues = {
                _OnlyBolters = true,
                _Threshold = 0.30,
                _TurretMultiplier = 10,
                _CustomizeWeapons = true,
                _WeaponDamageMultiplier = 2,
                _WeaponRange = 1850,
                _MinimumWeaponDamage = 1200,
                _Charges = 5
            }

            _Boss:addScriptOnce("secondaryweapons.lua", _SecondaryWeaponValues)

            _Boss:addScriptOnce("dialogs/encounters/balefulkatana.lua")
            _ShipUtil.addKatanaRailguns(_Boss)
            _ShipUtil.addKatanaMortars(_Boss)
            _ShipUtil.addBossAntiTorpedoEquipment(_Boss, nil, nil, 1850)
            _Boss:setValue("_escc_is_baleful_katana", true)
        end },
        { _PlanFile = "data/plans/escc/Goliath.xml", _Title = "Dervish Goliath", _EngineFactor = 2.5, _ThrustFactor = 1, _CustomFunction = function(_Boss, _ShipUtil)
            local _TorpedoFactor = 2
            local _TorpDuraFactor = 4
            local _ActiveMods = Mods()

            for _, _Xmod in pairs(_ActiveMods) do
            	if _Xmod.id == "2422999823" then --Ferocity
            		_TorpedoFactor = _TorpedoFactor * 16
                    _TorpDuraFactor = _TorpDuraFactor * 4
            	end
            end

            local _TorpSlammerValues = {
                _TimeToActive = 12,
                _ROF = 2,
                _UpAdjust = false,
                _DamageFactor = _TorpedoFactor,
                _DurabilityFactor = _TorpDuraFactor,
                _ForwardAdjustFactor = 1
            }

            _Boss:addScriptOnce("phasemode.lua")
            _Boss:addScriptOnce("torpedoslammer.lua", _TorpSlammerValues)
            _Boss:addScriptOnce("dialogs/encounters/dervishgoliath.lua")
            _ShipUtil.addGoliathLaunchers(_Boss)
            _ShipUtil.addBossAntiTorpedoEquipment(_Boss, nil, nil, 2000)
            _Boss:setValue("_escc_is_dervish_goliath", true)
        end },
        { _PlanFile = "data/plans/escc/Hellcat.xml", _Title = "Relentless Hellcat", _EngineFactor = 8, _ThrustFactor = 2, _CustomFunction = function(_Boss, _ShipUtil)
            _Boss:addScriptOnce("phasemode.lua")
            _Boss:addScriptOnce("eternal.lua", 0.005, 10)
            _Boss:addScriptOnce("dialogs/encounters/relentlesshellcat.lua")
            _ShipUtil.addHellcatLasers(_Boss)
            _ShipUtil.addBossAntiTorpedoEquipment(_Boss, nil, nil, 550)
            _Boss:setValue("_escc_is_relentless_hellcat", true)
        end },
        { _PlanFile = "data/plans/escc/Hunter.xml", _Title = "Steadfast Hunter", _EngineFactor = 2, _ThrustFactor = 1, _CustomFunction = function(_Boss, _ShipUtil)
            local _APDValues = {
                _ROF = 0.45,
                _TargetTorps = true,
                _TargetFighters = true,
                _TorpDamage = 12,
                _FighterDamage = 12,
                _RangeFactor = 20,
                _MaximumTargets = 4
            }

            local _LaserSniperValues = {
                _IncreaseDamageOT = true,
                _IncreaseDOTCycle = 30,
                _IncreaseDOTAmount = 5000
            }

            _Boss:addScriptOnce("dialogs/encounters/steadfasthunter.lua")
            _Boss:addScriptOnce("lasersniper.lua", _LaserSniperValues)
            _Boss:addScriptOnce("absolutepointdefense.lua", _APDValues)
            _ShipUtil.addHunterRailguns(_Boss)
            _ShipUtil.addHunterLightningGuns(_Boss)
            _Boss:setValue("_escc_is_steadfast_hunter", true)
        end },
        { _PlanFile = "data/plans/escc/Shield.xml", _Title = "Vigilant Shield", _EngineFactor = 0.25, _ThrustFactor = 1, _CustomFunction = function(_Boss, _ShipUtil)
            local _APDValues = {
                _ROF = 0.45,
                _TargetTorps = true,
                _TargetFighters = true,
                _TorpDamage = 12,
                _FighterDamage = 12,
                _RangeFactor = 20,
                _MaximumTargets = 4
            }

            _Boss:addScriptOnce("adaptivedefense.lua")
            _Boss:addScriptOnce("allybooster.lua", { _HealWhenBoosting = true, _HealPctWhenBoosting = 100, _MaxBoostCharges = 5})
            _Boss:addScriptOnce("absolutepointdefense.lua", _APDValues)
            _Boss:addScriptOnce("dialogs/encounters/vigilantshield.lua")
            _ShipUtil.addVigShieldCannons(_Boss)
            _Boss:setValue("_escc_is_vigilant_shield", true)
        end },
        { _PlanFile = "data/plans/escc/Phoenix.xml", _Title = "Scouring Phoenix", _EngineFactor = 2, _ThrustFactor = 1, _CustomFunction = function(_Boss, _ShipUtil)
            local TorpedoUtility = include ("torpedoutility")

            local _TorpedoFactor = 55
            local _TorpDuraFactor = 6
            local _ActiveMods = Mods()

            for _, _Xmod in pairs(_ActiveMods) do
            	if _Xmod.id == "2422999823" then --Ferocity
            		_TorpedoFactor = _TorpedoFactor * 16
                    _TorpDuraFactor = _TorpDuraFactor * 4
            	end
            end

            local _TorpSlammerValues = {
                _TimeToActive = 12,
                _ROF = 9,
                _UpAdjust = false,
                _DamageFactor = _TorpedoFactor,
                _DurabilityFactor = _TorpDuraFactor,
                _TorpOffset = -750,
                _ForwardAdjustFactor = 1,
                _PreferWarheadType = TorpedoUtility.WarheadType.Nuclear,
                _PreferBodyType = TorpedoUtility.BodyType.Hawk,
                _AccelFactor = 1.5,
                _VelocityFactor = 1.5,
                _TurningSpeedFactor = 1.5,
                _ShockwaveFactor = 3
            }

            _Boss:addScriptOnce("overdrive.lua", { overdriveMultiplier = 3 } )
            _Boss:addScriptOnce("torpedoslammer.lua", _TorpSlammerValues)
            _Boss:addScriptOnce("dialogs/encounters/scouringphoenix.lua")
            _ShipUtil.addPhoenixCannons(_Boss)
            _ShipUtil.addBossAntiTorpedoEquipment(_Boss, nil, nil, 2000)
            _Boss:setValue("_escc_is_scouring_phoenix", true)
        end }
    }

    local _BossData = _BossTypes[_BossType]

    local _PlanFileName = _BossData._PlanFile
    ESCCBossUtil.Log(_MethodName, "Loading plan : " .. tostring(_PlanFileName))

    local _Plan = LoadPlanFromFile(_PlanFileName)

    local PirateGenerator = include("pirategenerator")

    local _IncreasingThreatBoss = Sector():createShip(_Faction, "", _Plan, PirateGenerator.getGenericPosition())

    _IncreasingThreatBoss:setTitle(_BossData._Title, {})

    ESCCBossUtil.Log(_MethodName, "Upgrading Thrusters and engine")
    local _Thrusters = Thrusters(_IncreasingThreatBoss)
    _Thrusters.baseYaw = _Thrusters.baseYaw * 2 * _BossData._ThrustFactor
    _Thrusters.basePitch = _Thrusters.basePitch * 2 * _BossData._ThrustFactor
    _Thrusters.baseRoll = _Thrusters.baseRoll * 2 * _BossData._ThrustFactor
    _Thrusters.fixedStats = true
    _IncreasingThreatBoss:addMultiplier(StatsBonuses.Acceleration, _BossData._EngineFactor)
    _IncreasingThreatBoss:addMultiplier(StatsBonuses.Velocity, _BossData._EngineFactor)

    ESCCBossUtil.Log(_MethodName, "Upgrading Boarding and Docking")
    Boarding(_IncreasingThreatBoss).boardable = false
    _IncreasingThreatBoss.dockable = false

    --Set _Amp according to active mods and buff accordingly.
    local _Amp = 0
    local _HighAmp = 1
    if _HETActive then
        _Amp = _Amp + 1
        _HighAmp = _HighAmp * 2
    end
    if _HarderEnemysActive then
        _Amp = _Amp + 2
        _HighAmp = _HighAmp * 2
    end

    ESCCBossUtil.Log(_MethodName, "_Amp is " .. tostring(_Amp) .. " and highAmp is " .. tostring(_HighAmp))

    _IncreasingThreatBoss.damageMultiplier = (_IncreasingThreatBoss.damageMultiplier or 1) * _HighAmp

    local _ITBossShields = Shield(_IncreasingThreatBoss)
    if _ITBossShields then
        _ITBossShields.maxDurabilityFactor = (_ITBossShields.maxDurabilityFactor or 0) + _Amp
    end

    local _ITBossDurability = Durability(_IncreasingThreatBoss)
    if _ITBossDurability then
        _ITBossDurability.maxDurabilityFactor = (_ITBossDurability.maxDurabilityFactor or 0) + _Amp
    end

    --Obviously this drops an incredible amount of loot.
    ESCCBossUtil.Log(_MethodName, "Adding loot.")
    local SectorTurretGenerator = include ("sectorturretgenerator")
    local SectorUpgradeGenerator = include ("upgradegenerator")
    local _X, _Y = Sector():getCoordinates()
    local _TurretGenerator = SectorTurretGenerator()
    local _UpgradeGenerator = SectorUpgradeGenerator()

    local _Loot = Loot(_IncreasingThreatBoss)

    local legendaryLootAmt = 2
    local exoticLootAmt = 5
    local exceptionalLootAmt = 7
    local rareLootAmt = 7
    local uncommonLootAmt = 8
    local commonLootAmt = 14

    local _Upgrades =
    {
        {rarity = Rarity(RarityType.Legendary), amount = legendaryLootAmt},
        {rarity = Rarity(RarityType.Exotic), amount = exoticLootAmt},
        {rarity = Rarity(RarityType.Exceptional), amount = exceptionalLootAmt},
        {rarity = Rarity(RarityType.Rare), amount = rareLootAmt},
        {rarity = Rarity(RarityType.Uncommon), amount = uncommonLootAmt},
        {rarity = Rarity(RarityType.Common), amount = commonLootAmt},
    }

    local _Turrets =
    {
        {rarity = Rarity(RarityType.Legendary), amount = legendaryLootAmt},
        {rarity = Rarity(RarityType.Exotic), amount = exoticLootAmt},
        {rarity = Rarity(RarityType.Exceptional), amount = exceptionalLootAmt},
        {rarity = Rarity(RarityType.Rare), amount = rareLootAmt},
        {rarity = Rarity(RarityType.Uncommon), amount = uncommonLootAmt},
        {rarity = Rarity(RarityType.Common), amount = commonLootAmt},
    }

    for _, _Up in pairs(_Upgrades) do
        if _Up.amount > 0 then
            for _ = 1, _Up.amount do
                _Loot:insert(_UpgradeGenerator:generateSectorSystem(_X, _Y, _Up.rarity))
            end
        end
        
    end

    for _, _Tt in pairs(_Turrets) do
        if _Tt.amount > 0 then
            for _ = 1, _Tt.amount do
                _Loot:insert(InventoryTurret(_TurretGenerator:generate(_X, _Y, -156, _Tt.rarity)))
            end
        end
    end

    ESCCBossUtil.Log(_MethodName, "Adding standard scripts.")
    _IncreasingThreatBoss:addScriptOnce("internal/common/entity/background/legendaryloot.lua")
    _IncreasingThreatBoss:addScriptOnce("megablocker.lua", 1)
    _IncreasingThreatBoss:addScriptOnce("esccbossbehavior.lua", _BossType)
    _BossData._CustomFunction(_IncreasingThreatBoss, ShipUtility)

    _IncreasingThreatBoss.crew = _IncreasingThreatBoss.idealCrew

    _IncreasingThreatBoss:removeScript("icon.lua")
    _IncreasingThreatBoss:addScript("icon.lua", "data/textures/icons/pixel/skull_big.png")
    _IncreasingThreatBoss:setValue("_DefenseController_Manage_Own_Invincibility", true)
    _IncreasingThreatBoss:setValue("is_pirate", true) --These guys should always spawn for pirate factions.
    _IncreasingThreatBoss:setValue("IW_nuclear_m", 0.125)

    _IncreasingThreatBoss:setDropsAttachedTurrets(false)

    local Balancing = include("galaxy")
    --Finally, add a DCD.

    local _AllyFactor = 0
    if _BossType == 5 then --Vigilant Shield gets stronger allies to buff.
        _AllyFactor = 2
    end

    local _DCD = {}
    _DCD._DefenseLeader = _IncreasingThreatBoss.id
    _DCD._DefenderCycleTime = 60
    _DCD._DangerLevel = 5 + _AllyFactor
    _DCD._MaxDefenders = 4
    _DCD._DefenderHPThreshold = 0.2
    _DCD._DefenderOmicronThreshold = 0.2
    _DCD._IsPirate = true
    _DCD._Factionid = _Faction.index
    _DCD._PirateLevel = Balancing_GetPirateLevel(_X, _Y)
    _DCD._UseLeaderSupply = false
    _DCD._LowTable = "High"
    _DCD._AbsoluteFactionLimit = 5 --4 + boss.

    Sector():addScript("sector/background/defensecontroller.lua", _DCD)

    return _IncreasingThreatBoss
end

function ESCCBossUtil.Log(_MethodName, _Msg)
    if ESCCBossUtil._Debug == 1 then
        print("[ESCC Boss Utility] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

return ESCCBossUtil