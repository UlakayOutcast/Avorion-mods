package.path = package.path .. ";data/scripts/lib/?.lua"

include("weapontype")
include("relations")
include("defaultscripts")

local ShipUtility = include ("shiputility")
local MissionUT = include("missionutility")
local PirateGenerator = include("pirategenerator")
local ConsumerGoods = include ("consumergoods")
local SectorTurretGenerator = include ("sectorturretgenerator")
local UpgradeGenerator = include ("upgradegenerator")

local HorizonUtil = {}
local self = HorizonUtil

HorizonUtil._Debug = 0

--region #FACTION GENERATION / INTERACTION

function HorizonUtil.getFriendlyFaction()
    local methodName = "Get Friendly Faction"
    self.Log(methodName, "Getting friendly faction.")

    local name = "Frostbite Company"

    local galaxy = Galaxy()
    local faction = galaxy:findFaction(name)
    if faction == nil then
        faction = galaxy:createFaction(name, 175, 0) --175 is the maximum distance at which these missions are offered.
        faction.initialRelations = 0
        faction.initialRelationsToPlayer = 0
        faction.staticRelationsToAll = true
        faction.staticRelationsToPlayers = true
        faction.homeSectorUnknown = true
    end

    return faction
end

function HorizonUtil.addFriendlyFactionRep(_player, _amount)
    local _MethodName = "Add Friendly Faction Rep"
    local _faction = self.getFriendlyFaction()

    if not _faction then
        self.Log(_MethodName, "Could not find friendly faction.")
        return
    end

    local _Galaxy = Galaxy()
    local _Rel = _Galaxy:getFactionRelations(_faction, _player)
    _Galaxy:setFactionRelations(_faction, _player, _Rel + _amount)
end

function HorizonUtil.setFriendlyFactionRep(_player, _amount)
    local _MethodName = "Set Friendly Faction Rep"
    local _faction = self.getFriendlyFaction()

    if not _faction then
        self.Log(_MethodName, "Could not find friendly faction.")
        return
    end

    Galaxy():setFactionRelations(_faction, _player, _amount)
end

function HorizonUtil.getEnemyFaction()
    local name = "Horizon Keepers"

    local galaxy = Galaxy()
    local faction = galaxy:findFaction(name)
    if faction == nil then
        faction = galaxy:createFaction(name, 175, 0)
        faction.initialRelations = -100000
        faction.initialRelationsToPlayer = -100000
        faction.staticRelationsToAll = true
        faction.staticRelationsToPlayers = true
        faction.homeSectorUnknown = true
        faction.alwaysAtWar = true
    end

    return faction
end

--endregion

--region #DIALOG / CHAT MSG UTIL

function HorizonUtil.getDialogVarlanceTalkerColor()
    return self.getDialogVarlanceTextColor()
end

function HorizonUtil.getDialogVarlanceTextColor()
    return ColorRGB(0.9, 0.9, 1.0)
end

function HorizonUtil.getDialogMaceTalkerColor()
    return self.getDialogMaceTextColor()
end

function HorizonUtil.getDialogMaceTextColor()
    return ColorRGB(0.8, 0.37, 1.0)
end

function HorizonUtil.getDialogSophieTalkerColor()
    return self.getDialogSophieTextColor()
end

function HorizonUtil.getDialogSophieTextColor()
    return ColorRGB(0.8, 0.9, 1.0)
end

function HorizonUtil.varlanceChatter(_chatter)
    local _MethodName = "Varlance Chatter"
    local _Sector = Sector()
    local _Varlances = { _Sector:getEntitiesByScriptValue("is_varlance") }
    if #_Varlances > 0 then
        _Sector:broadcastChatMessage(_Varlances[1], ChatMessageType.Chatter, _chatter)
    end
end

--endregion

--region #SHIP GENERATION

--region Ships / Frostbite / Varlance
function HorizonUtil.spawnFrostbiteTorpedoLoader(_DeleteOnLeft, sabotOnly)
    local _MethodName = "Spawn Frostbite Torpedo Loader"
    self.Log(_MethodName, "Running.")

    local possiblePlans = {
        "data/plans/horizon/frostbitetloader1.xml",
        "data/plans/horizon/frostbitetloader2.xml",
        "data/plans/horizon/frostbitetloader3.xml",
    }

    shuffle(random(), possiblePlans)

    local _TorpLoaderData = {
        _PlanFile = possiblePlans[1],
        _ShipTitle = "Torpedo Loader",
        _ShipIcon = "data/textures/icons/pixel/torpedoboat.png",
        _ScriptValues = { "is_torpedoloader", "is_frostbite_torpedoloader" }
    }

    if sabotOnly then
        _TorpLoaderData._ArmamentFunction = function(_ship)
            ShipUtility.addMilitaryEquipment(_ship, 0.5, 0)
            _ship:addScriptOnce("entity/frostbitetorpedoloader.lua", {sabotOnly = true})
        end
    else
        _TorpLoaderData._ArmamentFunction = function(_ship)
            ShipUtility.addMilitaryEquipment(_ship, 0.5, 0)
            _ship:addScriptOnce("entity/frostbitetorpedoloader.lua", {sabotOnly = false})
        end
    end

    return HorizonUtil.spawnFrostbiteShip(_TorpLoaderData, _DeleteOnLeft)
end

function HorizonUtil.spawnFrostbiteAWACS(_DeleteOnLeft)
    local _MethodName = "Spawn Frostbite AWACS"
    self.Log(_MethodName, "Running.")

    local _VarlanceData = {
        _PlanFile = "data/plans/horizon/frostbiteawacs.xml", 
        _ShipTitle = "AWACS",
        _ShipIcon = "data/textures/icons/pixel/block.png",
        _ScriptValues = { "is_awacs", "is_frostbite_awacs" },
        _ArmamentFunction = function(_ship)
            ShipUtility.addMilitaryEquipment(_ship, 0.5, 0)
        end
    }

    return HorizonUtil.spawnFrostbiteShip(_VarlanceData, _DeleteOnLeft)
end

function HorizonUtil.spawnFrostbiteWarship(_DeleteOnLeft)
    local _MethodName = "Spawn Frostbite Warship"
    self.Log(_MethodName, "Running.")

    local possiblePlans = {
        "data/plans/horizon/frostbitewarship1.xml",
        "data/plans/horizon/frostbitewarship2.xml",
        "data/plans/horizon/frostbitewarship3.xml"
    }

    shuffle(random(), possiblePlans)

    local _WarshipData = {
        _PlanFile = possiblePlans[1],
        _ScriptValues = { "is_frostbite_warship" },
        _ArmamentFunction = function(_ship)
            ShipUtility.addMilitaryEquipment(_ship, 2.0, 1)
        end
    }

    return HorizonUtil.spawnFrostbiteShip(_WarshipData, _DeleteOnLeft)
end

function HorizonUtil.spawnFrostbiteReliefShip(_DeleteOnLeft)
    local _MethodName = "Spawn Relief Ship"
    self.Log(_MethodName, "Running.")

    local _ReliefShipData = {
        _PlanFile = "data/plans/horizon/frostbiterelief.xml",
        _ShipTitle = "Relief Ship",
        _ShipIcon = "data/textures/icons/pixel/civil-ship.png",
        _ScriptValues = { "is_relief", "is_frostbite_relief" },
        _WithdrawFunction = function(ship)
            --We'll just not allow this ship to get destroyed.
            local _WithdrawData = {
                _Threshold = 0.25,
                _Invincibility = 0.02,
                _MinTime = 1,
                _MaxTime = 2
            }
    
            ship:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        end
    }

    return HorizonUtil.spawnFrostbiteShip(_ReliefShipData, _DeleteOnLeft)
end

function HorizonUtil.spawnVarlanceNormal(_DeleteOnLeft)
    local _MethodName = "Spawn Varlance Normal"
    self.Log(_MethodName, "Running.")

    local _VarlanceData = {
        _PlanFile = "data/plans/horizon/varlance.xml", 
        _ShipTitle = "Varlance's Ship",
        _ShipIcon = "data/textures/icons/pixel/flagship.png",
        _ScriptValues = { "is_varlance" },
        _ArmamentFunction = function(_ship)
            ShipUtility.addSpecificScalableWeapon(_ship, { WeaponType.Bolter }, 3, 1, nil)
            ShipUtility.addSpecificScalableWeapon(_ship, { WeaponType.PlasmaGun }, 3, 0, nil)
            ShipUtility.addBossAntiTorpedoEquipment(_ship)
        end,
        _WithdrawFunction = function(ship)
            --This can sometimes result in schrodinger's varlance with two of him showing up but trust me when I say that's better than the alternative.
            --Tweaked mintime / maxtime to hopefully prevent schrodinger's varlance occurences.
            local _WithdrawData = {
                _Threshold = 0.10,
                _Invincibility = 0.02,
                _MinTime = 1,
                _MaxTime = 3,
                _WithdrawMessage = "Taking heavy damage. Need to withdraw.",
                _SetValueOnWithdraw = "varlance_withdrawing"
            }
    
            ship:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        end
    }

    return HorizonUtil.spawnFrostbiteShip(_VarlanceData, _DeleteOnLeft)
end

function HorizonUtil.spawnVarlanceBattleship(_DeleteOnLeft)
    local _MethodName = "Spawn Varlance Battleship"
    self.Log(_MethodName, "Running.")

    local _VarlanceData = {
        _PlanFile = "data/plans/horizon/varlancebattleship.xml", 
        _ShipName = "Ice Nova", 
        _ShipTitle = "Varlance's Ship",
        _ShipIcon = "data/textures/icons/pixel/flagship.png",
        _ScriptValues = { "is_varlance" },
        _ArmamentFunction = function(_ship)
            ShipUtility.addSpecificScalableWeapon(_ship, { WeaponType.Cannon }, 4, 1, nil)
            ShipUtility.addSpecificScalableWeapon(_ship, { WeaponType.PlasmaGun }, 3, 0, nil)
            ShipUtility.addBossAntiTorpedoEquipment(_ship)
        end,
        _WithdrawFunction = function(ship)
            --This can sometimes result in schrodinger's varlance with two of him showing up but trust me when I say that's better than the alternative.
            --Tweaked mintime / maxtime to hopefully prevent schrodinger's varlance occurences.
            local _WithdrawData = {
                _Threshold = 0.10,
                _Invincibility = 0.02,
                _MinTime = 1,
                _MaxTime = 3,
                _WithdrawMessage = "Taking heavy damage. I'll be back, buddy.",
                _SetValueOnWithdraw = "varlance_withdrawing"
            }
    
            ship:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        end
    }

    return HorizonUtil.spawnFrostbiteShip(_VarlanceData, _DeleteOnLeft)
end

--Base spawn.
function HorizonUtil.spawnFrostbiteShip(_Data, _DeleteOnLeft)
    local _MethodName = "Spawn Frostbite Ship"
    self.Log(_MethodName, "Running.")

    local _Faction = self.getFriendlyFaction()
    if not _Faction then
        self.Log(_MethodName, "Could not find faction.")
        return
    end

    local _PlanName = _Data._PlanFile
    self.Log(_MethodName, "Spawning from plan " .. tostring(_PlanName))
    local _Plan = LoadPlanFromFile(_PlanName)
    local _Scale = 1.0

    _Plan:scale(vec3(_Scale, _Scale, _Scale))

    local _Ship = Sector():createShip(_Faction, "", _Plan, PirateGenerator.getGenericPosition())

    if _Data._ArmamentFunction then
        _Data._ArmamentFunction(_Ship)
    end

    _Ship:setDropsAttachedTurrets(false)

    --Need to have this after the armament func or else the title could get overwritten.
    if _Data._ShipName then
        _Ship.name = _Data._ShipName
    end
    if _Data._ShipTitle then
        _Ship.title = _Data._ShipTitle
    end

    _Ship.crew = _Ship.idealCrew
    if _Data._ShipIcon then
        _Ship:addScript("icon.lua", _Data._ShipIcon)
    end

    if _Data._WithdrawFunction then
        _Data._WithdrawFunction(_Ship)
    end

    _Ship:setValue("is_frostbite", true)
    _Ship:setValue("is_frostbite_ship", true)
    _Ship:setValue("_ESCC_bypass_hazard", true)
    _Ship:setValue("bDisableXAI", true) --Disable any Xavorion AI
    _Ship:setValue("SDKEDSDisabled", true) --Also need to disable SDK extended docking shields.
    for _, _value in pairs(_Data._ScriptValues) do
        _Ship:setValue(_value, true)
    end
    --_Ship.damageMultiplier = (_Ship.damageMultiplier or 1 ) * 2

    Boarding(_Ship).boardable = false
    _Ship.dockable = false

    if _DeleteOnLeft then
        self.Log(_MethodName, "Deleting entity on player leaving...")
        MissionUT.deleteOnPlayersLeft(_Ship)
    else
        self.Log(_MethodName, "Entity will not be deleted on player leaving.")
    end

    return _Ship
end
--endregion

--region Ships / Horizon
function HorizonUtil.spawnHorizonArtyCruiser(_DeleteOnLeft, _Position, _Faction)
    local _MethodName = "Spawn Horizon Artillery Cruiser"
    self.Log(_MethodName, "Running.")

    local _ShipData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnAsFaction = _Faction,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizonartycruiser.xml",
        _ShipTitle = "Cruiser",
        _ShipIcon = "data/textures/icons/pixel/artillery.png",
        _ShipClassValue = { "is_artycruiser", "is_horizon_artycruiser" },
        _ArmamentFunction = function(_ship)
            ShipUtility.addSpecificScalableWeapon(_ship, { WeaponType.Cannon }, 1, 1, nil)
        end
    }

    return HorizonUtil.spawnHorizonShip(_ShipData)
end

function HorizonUtil.spawnHorizonCombatCruiser(_DeleteOnLeft, _Position, _Faction)
    local _MethodName = "Spawn Horizon Combat Cruiser"
    self.Log(_MethodName, "Running.")

    local _ShipData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnAsFaction = _Faction,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizoncombatcruiser.xml",
        _ShipTitle = "Cruiser",
        _ShipIcon = "data/textures/icons/pixel/military-ship.png",
        _ShipClassValue = { "is_combatcruiser", "is_horizon_combatcruiser" },
        _ArmamentFunction = function(_ship)
            ShipUtility.addMilitaryEquipment(_ship, 3, 1)
        end
    }

    return HorizonUtil.spawnHorizonShip(_ShipData)
end

function HorizonUtil.spawnHorizonFreighter(_DeleteOnLeft, _Position, _Faction)
    local _MethodName = "Spawn Horizon Freighter"
    self.Log(_MethodName, "Running.")

    local _ShipData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnAsFaction = _Faction,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizonfreighter.xml",
        _ShipTitle = "Freighter",
        _ShipIcon = "data/textures/icons/pixel/civil-ship.png",
        _ShipClassValue = {"is_freighter", "is_horizon_freighter"},
        _ShipDamageMultiplier = 0.5,
        _ArmamentFunction = function(_ship)
            ShipUtility.addMilitaryEquipment(_ship, 1, 0)
        end
    }

    return HorizonUtil.spawnHorizonShip(_ShipData)
end

function HorizonUtil.spawnHorizonBattleship(_DeleteOnLeft, _Position, _Faction)
    local _MethodName = "Spawn Horizon Battleship"
    self.Log(_MethodName, "Running.")

    local _ShipData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnAsFaction = _Faction,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizonbattleship.xml",
        _ShipTitle = "Battleship",
        _ShipIcon = "data/textures/icons/pixel/defender.png",
        _ShipClassValue = { "is_battleship", "is_horizon_battleship" },
        _ShipDamageMultiplier = 3,
        _ArmamentFunction = function(_ship)
            ShipUtility.addSpecificScalableWeapon(_ship, { WeaponType.Cannon }, 4, 1, nil)
            ShipUtility.addBossAntiTorpedoEquipment(_ship)
        end,
        _NuclearModifier = 0.5
    }

    return HorizonUtil.spawnHorizonShip(_ShipData)
end

function HorizonUtil.spawnHorizonAWACS(_DeleteOnLeft, _Position, _Faction)
    local _MethodName = "Spawn Horizon AWACS"
    self.Log(_MethodName, "Running.")

    local _ShipData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnAsFaction = _Faction,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizonawacs.xml",
        _ShipTitle = "AWACS",
        _ShipIcon = "data/textures/icons/pixel/block.png",
        _ShipClassValue = {"is_awacs", "is_horizon_awacs" },
        _ShipDamageMultiplier = 0.5,
        _ArmamentFunction = function(_ship)
            ShipUtility.addMilitaryEquipment(_ship, 0.5, 0)
            _ship:addScript("blocker.lua", 1)
        end
    }

    return HorizonUtil.spawnHorizonShip(_ShipData)
end

function HorizonUtil.spawnAlphaHansel(_DeleteOnLeft, _Position, addGoodLoot, _Spawnv2)
    local _MethodName = "Spawn Horizon Alpha Hansel"
    self.Log(_MethodName, "Running.")

    local _ShipData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizonpwhansel.xml",
        _ShipTitle = "Horizon PW α \"Hansel\"",
        _ShipIcon = "data/textures/icons/pixel/skull_big.png",
        _ShipDamageMultiplier = 2,
        _ShipClassValue = { "is_alpha_hansel", "is_horizon_prototype" },
        _ArmamentFunction = function(_ship)
            ShipUtility.addSpecificScalableWeapon(_ship, { WeaponType.Cannon }, 4, 1, nil)
            ShipUtility.addHorizonPrototypePlasmaGuns(_ship, 4)

            local _APDValues = {
                _ROF = 0.5,
                _TargetTorps = true,
                _TargetFighters = true,
                _FighterDamage = 36,
                _TorpDamage = 12,
                _MaxTargets = 4,
                _RangeFactor = 80
            }
            
            _ship:addScriptOnce("absolutepointdefense.lua", _APDValues)

            _ship:addScriptOnce("avenger.lua", { _Multiplier = 2 })
        end,
        _LootFunction = HorizonUtil.getPWXLootFunc(addGoodLoot),
        _NuclearModifier = 0.125
    }

    if _Spawnv2 then
        _ShipData._ShipTitle = "HPW α \"Hansel\" Mk II"
        _ShipData._ShipDamageMultiplier = 4

        _ShipData._SetAIFunction = function(ship)
            ship:addScriptOnce("player/missions/horizon/story6/horizonstory6boss.lua")

            local ai = ShipAI(ship)
            ai:setAggressive()
        end
    
        _ShipData._LootFunction = HorizonUtil.getPWXv2LootFunc()
    end

    return HorizonUtil.spawnHorizonShip(_ShipData)
end

function HorizonUtil.spawnBetaGretel(_DeleteOnLeft, _Position, addGoodLoot, _Spawnv2)
    local _MethodName = "Spawn Horizon Beta Gretel"
    self.Log(_MethodName, "Running.")

    local _ShipData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizonpwgretel.xml",
        _ShipTitle = "Horizon PW β \"Gretel\"",
        _ShipIcon = "data/textures/icons/pixel/skull_big.png",
        _ShipClassValue = { "is_beta_gretel", "is_horizon_prototype" },
        _ArmamentFunction = function(_ship)
            ShipUtility.addSpecificScalableWeapon(_ship, { WeaponType.Cannon }, 4, 1, nil)
            ShipUtility.addHorizonPrototypePlasmaGuns(_ship, 4)

            local x, y = Sector():getCoordinates()
            local _dpf = Balancing_GetSectorWeaponDPS(x, y) * 24

            local _LaserSniperValues = {
                _DamagePerFrame = _dpf,
                _TimeToActive = math.huge, --manually activated via trigger in mission - set to 30 seconds.
                _TargetPriority = 1,
                _UseEntityDamageMult = true
            }

            _ship:addScriptOnce("lasersniper.lua", _LaserSniperValues)

            _ship:addScriptOnce("shieldrecharger.lua")
        end,
        _LootFunction = HorizonUtil.getPWXLootFunc(addGoodLoot),
        _NuclearModifier = 0.125
    }

    if _Spawnv2 then
        _ShipData._ShipTitle = "HPW β \"Gretel\" Mk II"

        _ShipData._ArmamentFunction = function(ship)
            ShipUtility.addSpecificScalableWeapon(ship, { WeaponType.Cannon }, 4, 1, nil)
            ShipUtility.addHorizonPrototypePlasmaGuns(ship, 4)

            local x, y = Sector():getCoordinates()
            local _dpf = Balancing_GetSectorWeaponDPS(x, y) * 36

            local _LaserSniperValues = {
                _DamagePerFrame = _dpf,
                _TimeToActive = 40, --+10 seconds to account for cutscene.
                _TargetPriority = 1,
                _UseEntityDamageMult = true
            }

            ship:addScriptOnce("lasersniper.lua", _LaserSniperValues)

            ship:addScriptOnce("shieldrecharger.lua")
        end

        _ShipData._SetAIFunction = function(ship)
            ship:addScriptOnce("player/missions/horizon/story6/horizonstory6boss.lua")

            local ai = ShipAI(ship)
            ai:setAggressive()
        end

        _ShipData._LootFunction = HorizonUtil.getPWXv2LootFunc()
    end

    return HorizonUtil.spawnHorizonShip(_ShipData)
end

function HorizonUtil.spawnProjectXsologizev2(_DeleteOnLeft, _Position)
    local _MethodName = "Spawn Project Xsologize"
    self.Log(_MethodName, "Running.")

    local _ShipData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/projectxsologize.xml",
        _ShipTitle = "Project XSOLOGIZE Mk II",
        _ShipName = "XSOLOGIZE Mk II",
        _ShipIcon = "data/textures/icons/pixel/skull_big.png",
        _ShipDamageMultiplier = 5,
        _ShipClassValue = { "is_project_xsologize", "is_horizon_boss" },
        _ArmamentFunction = function(_ship)
            ShipUtility.addSpecificScalableWeapon(_ship, { WeaponType.Cannon }, 4, 1, nil)
            ShipUtility.addHorizonPrototypePlasmaGuns(_ship, 4)
            ShipUtility.addBossAntiTorpedoEquipment(_ship)

            local x, y = Sector():getCoordinates()
            local _dpf = Balancing_GetSectorWeaponDPS(x, y) * 125 

            local _LaserSniperValues = { --#LONGINUS_SNIPER
                _DamagePerFrame = _dpf,
                _TimeToActive = 30,
                _TargetPriority = 1
            }

            _ship:addScriptOnce("entity/xsologizeboss.lua")
            _ship:addScriptOnce("lasersniper.lua", _LaserSniperValues)
            _ship:addScriptOnce("shieldrecharger.lua", { _MaxRecharges = 1, _AddChargeIfActivatedUnder = 90, _FastDamageCharges = 3 })
        end,
        _LootFunction = function(_ship)
            local _Loot = Loot(_ship)
            local x, y = Sector():getCoordinates()

            local turretGenerator = SectorTurretGenerator()

            local upgradeGenerator = UpgradeGenerator()

            local _random = random()

            for _ = 1, 4 do
                local _rarity = Rarity(RarityType.Exotic)
                if _random:test(0.25) then
                    _rarity = Rarity(RarityType.Legendary)
                end

                if _random:test(0.5) then
                    _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, _rarity, nil))
                else
                    _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 16, _rarity, nil, nil)))
                end
            end

            --Some more stuff for a nice looking lootsplosion.
            local rarityTable = {
                Rarity(RarityType.Common),
                Rarity(RarityType.Uncommon),
                Rarity(RarityType.Rare),
                Rarity(RarityType.Exceptional)
            }

            for ridx, rarity in pairs(rarityTable) do
                for _ = 1, 6 do
                    if _random:test(0.5) then
                        _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, rarity, nil))
                    else
                        _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 16, rarity, nil, nil)))
                    end
                end
            end

            --Finally, add 8 wildcard items.
            for _ = 1, 8 do
                if _random:test(0.5) then
                    _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, nil, nil))
                else
                    _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 16, nil, nil, nil)))
                end
            end

            _ship:addScriptOnce("internal/common/entity/background/legendaryloot.lua")
        end,
        _SetAIFunction = function(ship)
            ship:addScriptOnce("player/missions/horizon/story9/horizonstory9boss.lua")

            local ai = ShipAI(ship)
            ai:setAggressive()
        end,
        _NuclearModifier = 0.125
    }

    return HorizonUtil.spawnHorizonShip(_ShipData)
end

function HorizonUtil.spawnProjectXsologize(_DeleteOnLeft, _Position)
    local _MethodName = "Spawn Project Xsologize"
    self.Log(_MethodName, "Running.")

    local _ShipData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/projectxsologize.xml",
        _ShipTitle = "Project XSOLOGIZE",
        _ShipName = "XSOLOGIZE Mk I",
        _ShipIcon = "data/textures/icons/pixel/skull_big.png",
        _ShipDamageMultiplier = 3,
        _ShipClassValue = { "is_project_xsologize", "is_horizon_boss" },
        _ArmamentFunction = function(_ship)
            ShipUtility.addSpecificScalableWeapon(_ship, { WeaponType.Cannon }, 4, 1, nil)
            ShipUtility.addHorizonPrototypePlasmaGuns(_ship, 4)
            ShipUtility.addBossAntiTorpedoEquipment(_ship)

            _ship:addScriptOnce("shieldrecharger.lua", { _MaxRecharges = 1, _AddChargeIfActivatedUnder = 90, _FastDamageCharges = 2 })
        end,
        _LootFunction = function(_ship)
            local _Loot = Loot(_ship)
            local x, y = Sector():getCoordinates()

            local turretGenerator = SectorTurretGenerator()

            local upgradeGenerator = UpgradeGenerator()

            --legendary system / legendary turret / guaranteed legendary m-tcs / 2 exotic turrets + 2 exotic systems.
            _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, Rarity(RarityType.Legendary), nil))
            _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 0, Rarity(RarityType.Legendary), nil, nil)))

            for _ = 1, 2 do
                _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, Rarity(RarityType.Exotic), nil))
                _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 0, Rarity(RarityType.Exotic), nil, nil)))
            end

            --Some more stuff for a nice looking lootsplosion.
            local rarityTable = {
                Rarity(RarityType.Common),
                Rarity(RarityType.Uncommon),
                Rarity(RarityType.Rare),
                Rarity(RarityType.Exceptional)
            }

            local _random = random()
            for ridx, rarity in pairs(rarityTable) do
                for _ = 1, 4 do
                    if _random:test(0.5) then
                        _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, rarity, nil))
                    else
                        _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 0, rarity, nil, nil)))
                    end
                end
            end

            _ship:addScriptOnce("internal/common/entity/background/legendaryloot.lua")
        end,
        _NuclearModifier = 0.125
    }

    return HorizonUtil.spawnHorizonShip(_ShipData)
end

--Base spawn
function HorizonUtil.spawnHorizonShip(_Data)
    local _MethodName = "Spawn Horizon Ship"
    self.Log(_MethodName, "Running.")

    --Set _Faction to nil to spawn as default enemy faction.
    local _Faction = _Data._SpawnAsFaction or HorizonUtil.getEnemyFaction()
    if not _Faction then
        self.Log(_MethodName, "Could not find faction.")
        return
    end

    local _PlanName = _Data._PlanFile
    self.Log(_MethodName, "Spawning from plan " .. tostring(_PlanName))
    local _Plan = LoadPlanFromFile(_PlanName)
    local _Scale = 1.0

    _Plan:scale(vec3(_Scale, _Scale, _Scale))

    local _SpawnAtPosition = _Data._SpawnPosition or PirateGenerator.getGenericPosition()
    local _HorizonShip = Sector():createShip(_Faction, "", _Plan, _SpawnAtPosition)

    if _Data._ArmamentFunction then
        _Data._ArmamentFunction(_HorizonShip)
    end

    _HorizonShip:setDropsAttachedTurrets(false)

    --Title is set in armament function so it needs to be reset afterwards.
    if _Data._ShipName then
        _HorizonShip.name = _Data._ShipName
    end
    if _Data._ShipTitle then
        _HorizonShip.title = _Data._ShipTitle
    end
    
    _HorizonShip.crew = _HorizonShip.idealCrew
    _HorizonShip:removeScript("icon.lua") --Get rid of all the icons on this before.
    _HorizonShip:addScript("icon.lua", _Data._ShipIcon)

    _HorizonShip:setValue("is_horizon", true)
    _HorizonShip:setValue("is_horizon_ship", true)
    _HorizonShip:setValue("_ESCC_bypass_hazard", true)
    _HorizonShip:setValue("bDisableXAI", true) --Disable any Xavorion AI
    _HorizonShip:setValue("SDKEDSDisabled", true) --Also need to disable SDK extended docking shields.
    if _Data._ShipClassValue then
        for _, _val in pairs(_Data._ShipClassValue) do
            _HorizonShip:setValue(_val, true)
        end
    end
    if _Data._NuclearModifier then
        _HorizonShip:setValue("IW_nuclear_m", _Data._NuclearModifier)
    end
    local _dmgMultiplier = _Data._ShipDamageMultiplier or 2
    _HorizonShip.damageMultiplier = (_HorizonShip.damageMultiplier or 1 ) * _dmgMultiplier

    Boarding(_HorizonShip).boardable = false
    _HorizonShip.dockable = false

    if _Data._LootFunction then
        _Data._LootFunction(_HorizonShip)
    end

    local _DeleteOnLeft = _Data._DeleteOnPlayerLeft
    if _DeleteOnLeft then
        self.Log(_MethodName, "Deleting entity on player leaving...")
        MissionUT.deleteOnPlayersLeft(_HorizonShip)
    else
        self.Log(_MethodName, "Entity will not be deleted on player leaving.")
    end

    if _Data._SetAIFunction then
        _Data._SetAIFunction(_HorizonShip)
    end

    return _HorizonShip
end
--endregion

--region Stations / Horizon
function HorizonUtil.spawnHorizonShipyard1(_DeleteOnLeft, _Position)
    local _MethodName = "Spawn Horizon Shipyard 1"
    self.Log(_MethodName, "Running.")

    local _StationData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizonshipyard01.xml",
        _StationMainScript = "data/scripts/entity/merchants/shipyard.lua",
        _StationValues = { "is_horizon_shipyard" },
        _ConsumerFunction = function(_station)
            _station:addScript("data/scripts/entity/merchants/repairdock.lua")
            _station:addScript("data/scripts/entity/merchants/consumer.lua", "Shipyard"%_t, unpack(ConsumerGoods.Shipyard()))
        end
    }

    return HorizonUtil.spawnHorizonStation(_StationData)
end

function HorizonUtil.spawnHorizonShipyard2(_DeleteOnLeft, _Position)
    local _MethodName = "Spawn Horizon Shipyard 2"
    self.Log(_MethodName, "Running.")

    local _StationData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizonshipyard02.xml",
        _StationMainScript = "data/scripts/entity/merchants/shipyard.lua",
        _StationValues = { "is_horizon_shipyard" },
        _ConsumerFunction = function(_station)
            _station:addScript("data/scripts/entity/merchants/repairdock.lua")
            _station:addScript("data/scripts/entity/merchants/consumer.lua", "Shipyard"%_t, unpack(ConsumerGoods.Shipyard()))
        end,
        _ArmamentFunction = function(_station)
            ShipUtility.addScalableArtilleryEquipment(_station, 2, 0, false)
        end
    }

    return HorizonUtil.spawnHorizonStation(_StationData)
end

function HorizonUtil.spawnHorizonResearchStation(_DeleteOnLeft, _Position)
    local _MethodName = "Spawn Horizon Research Station 1"
    self.Log(_MethodName, "Running.")

    local _StationData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizonresearch01.xml",
        _StationMainScript = "data/scripts/entity/merchants/researchstation.lua",
        _StationValues = { "is_horizon_researchstation" },
        _ConsumerFunction = function(_station)
            _station:addScript("data/scripts/entity/merchants/consumer.lua", "Research Station"%_t, unpack(ConsumerGoods.ResearchStation()))
        end
    }

    return HorizonUtil.spawnHorizonStation(_StationData)
end

function HorizonUtil.spawnMilitaryOutpost(_DeleteOnLeft, _Position)
    local _MethodName = "Spawn Horizon Military Outpost 1"
    self.Log(_MethodName, "Running.")

    local _StationData = {
        _DeleteOnPlayerLeft = _DeleteOnLeft,
        _SpawnPosition = _Position,
        _PlanFile = "data/plans/horizon/horizonmilitary01.xml",
        _StationMainScript = "data/scripts/entity/merchants/militaryoutpost.lua",
        _ConsumerFunction = function(_station)
            _station:addScript("data/scripts/entity/merchants/consumer.lua", "Military Outpost"%_t, unpack(ConsumerGoods.MilitaryOutpost()))
            _station:addScript("data/scripts/entity/ai/patrol.lua")
        end,
        _ArmamentFunction = function(_station)
            ShipUtility.addScalableArtilleryEquipment(_station, 3, 1, false)
            ShipUtility.addScalableArtilleryEquipment(_station, 3, 0, false)
        end
    }

    return HorizonUtil.spawnHorizonStation(_StationData)
end

function HorizonUtil.spawnHorizonStation(_Data)
    local _MethodName = "Spawn Horizon Station"
    self.Log(_MethodName, "Running.")

    local _Faction = HorizonUtil.getEnemyFaction()
    local _Plan = LoadPlanFromFile(_Data._PlanFile)
    local _Scale = 1.0

    _Plan:scale(vec3(_Scale, _Scale, _Scale))

    local _SpawnAtPosition = _Data._SpawnPosition or PirateGenerator.getGenericPosition()
    local _StationScript = _Data._StationMainScript

    local _Station = Sector():createStation(_Faction, _Plan, _SpawnAtPosition, _StationScript)

    AddDefaultStationScripts(_Station)
    --Remove some scripts.
    _Station:removeScript("icon.lua")
    _Station:removeScript("consumer.lua")
    _Station:removeScript("backup.lua")
    _Station:removeScript("transportmode.lua")
    _Station:removeScript("bulletinboard.lua")
    _Station:removeScript("missionbulletins.lua")
    _Station:removeScript("story/bulletins.lua")

    _Station.crew = _Station.idealCrew
    _Station.shieldDurability = _Station.shieldMaxDurability

    _Station:setValue("no_chatter", true) --Finally, a way to shut these stupid things up. Some of the random messages completely ruin the vibe.
    _Station:setValue("is_horizon", true)
    _Station:setValue("is_horizon_station", true)
    _Station:setValue("_ESCC_bypass_hazard", true)
    _Station:setValue("bDisableXAI", true) --Disable any Xavorion AI
    _Station:setValue("SDKEDSDisabled", true) --Also need to disable SDK extended docking shields.
    if _Data._StationValues then
        for _, _value in pairs(_Data._StationValues) do
            _Station:setValue(_value, true)
        end
    end

    Physics(_Station).driftDecrease = 0.2    

    Boarding(_Station).boardable = false
    _Station.dockable = false

    local _DeleteOnLeft = _Data._DeleteOnPlayerLeft
    if _DeleteOnLeft then
        self.Log(_MethodName, "Deleting entity on player leaving...")
        MissionUT.deleteOnPlayersLeft(_Station)
    else
        self.Log(_MethodName, "Entity will not be deleted on player leaving.")
    end

    _Data._ConsumerFunction(_Station)
    if _Data._ArmamentFunction then
        _Data._ArmamentFunction(_Station)
    end

    _Station:setDropsAttachedTurrets(false)

    return _Station
end
--endregion

--endregion

--region #ITEM GENERATION

function HorizonUtil.getEncryptedDataChip()
    local dataChip = VanillaInventoryItem()

    local _rarity = Rarity(RarityType.Exotic)
    local _rarity2 = Rarity(RarityType.Uncommon)

    dataChip.stackable = false
    dataChip.droppable = false
    dataChip.tradeable = false
    dataChip.missionRelevant = true
    dataChip.name = "Encrypted Data Chip"
    dataChip.price = 0
    dataChip.icon = "data/textures/icons/processor.png"
    dataChip.iconColor = _rarity2.color
    dataChip.rarity = _rarity
    dataChip:setValue("subtype", "HorizonStoryDataChip")

    local tooltip = Tooltip()
    tooltip.icon = dataChip.icon
    tooltip.borderColor = _rarity.color
    tooltip.rarity = _rarity2

    local title = "Encrypted Data Chip"

    local headLineSize = 25
    local headLineFontSize = 15
    local line = TooltipLine(headLineSize, headLineFontSize)
    line.ctext = title
    line.ccolor = _rarity.tooltipFontColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(18, 14)
    line.ltext = "A data chip. It appears to be heavily encrypted."
    tooltip:addLine(line)

    dataChip:setTooltip(tooltip)

    return dataChip
end

function HorizonUtil.getPWXLootFunc(addGoodLoot)
    if addGoodLoot then
        --1 legendary / 2 exotic subsystems
        --2 exotic turrets
        --legendaryloot.lua
        return function(ship)
            local _Loot = Loot(ship)
            local x, y = Sector():getCoordinates()

            local turretGenerator = SectorTurretGenerator()

            local upgradeGenerator = UpgradeGenerator()

            _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, Rarity(RarityType.Legendary), nil))
            for _ = 1, 2 do
                _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, Rarity(RarityType.Exotic), nil))
                _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 0, Rarity(RarityType.Exotic), nil, nil)))
            end

            ship:addScriptOnce("internal/common/entity/background/legendaryloot.lua")
        end
    else
        --1 exceptional / 3 rare subsystems
        --3 rare turrets
        return function(ship)
            local _Loot = Loot(ship)
            local x, y = Sector():getCoordinates()

            local turretGenerator = SectorTurretGenerator()

            local upgradeGenerator = UpgradeGenerator()

            _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, Rarity(RarityType.Exceptional), nil))
            for _ = 1, 3 do
                _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, Rarity(RarityType.Rare), nil))
                _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 0, Rarity(RarityType.Rare), nil, nil)))
            end
        end
    end
end

function HorizonUtil.getPWXv2LootFunc()
    return function(ship)
        local _Loot = Loot(ship)
        local x, y = Sector():getCoordinates()

        local turretGenerator = SectorTurretGenerator()

        local upgradeGenerator = UpgradeGenerator()

        local _random = random()

        if _random:test(0.5) then
            _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 0, Rarity(RarityType.Exceptional), nil, nil)))
            _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, Rarity(RarityType.Exotic), nil))
        else
            _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 0, Rarity(RarityType.Exotic), nil, nil)))
            _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, Rarity(RarityType.Exceptional), nil))
        end
                    
        --Add 3x exceptional / rare loot.
        for _ = 1, 3 do
            local _rarity = Rarity(RarityType.Exceptional)
            if _random:test(0.5) then
                _rarity = Rarity(RarityType.Rare)
            end

            _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, _rarity, nil))
            _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 0, _rarity, nil, nil)))
        end

        --Add 4x wildcard items.
        for _ = 1, 4 do
            if _random:test(0.5) then
                _Loot:insert(upgradeGenerator:generateSectorSystem(x, y, nil, nil))
            else
                _Loot:insert(InventoryTurret(turretGenerator:generate(x, y, 0, nil, nil, nil)))
            end
        end

        ship:addScriptOnce("internal/common/entity/background/legendaryloot.lua")
    end
end

--endregion

--region #LOGGING

function HorizonUtil.Log(_MethodName, _Msg)
    if HorizonUtil._Debug == 1 then
        print("[Horizon Utility] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion

return HorizonUtil