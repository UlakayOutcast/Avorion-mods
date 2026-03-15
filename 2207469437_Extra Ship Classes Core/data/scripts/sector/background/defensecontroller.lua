package.path = package.path .. ";data/scripts/lib/?.lua"

--Run the rest of the includes.
local AsyncShipGenerator = include("asyncshipgenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local SpawnUtility = include ("spawnutility")
local Placer = include("placer")

include ("galaxy")
include ("stringutility")
include ("callable")
include ("relations")
include ("randomext")

ESCCUtil = include("esccutil")

--Don't remove this or else the script might break. You know the drill by now.
--namespace DefenseController
DefenseController = {}
local self = DefenseController

self._Debug = 0

self._Data = {}
--[[
    Some of these values are fairly self-explanatory, but for a handy guide for setting this thing up:
    THESE VALUES ARE REQUIRED - YOU SHOULD BE SETTING ALL OF THEM IN THE FIRST INITIALIZE CALL, OTHERWISE THE SCRIPT MAY NOT WORK CORRECTLY
        Unless it has an asterisk - * - This value is set in the initialize call if it is not included.
        ** - this value will function equally well as nil or false

        _DefenseLeader              ==  The ID of the entity that is the "leader" of the defenders - this will broadcast. If this is destroyed, the script will pick another.
        _CanTransfer*               ==  Determines whether or not the defense leader can jump to another entity after the initial defense leader is destroyed. Defaults to true.
        _CanTransferToShip*         ==  Determines whether or not the defense leader can jump to a ship after the initial defense leader is destroyed. Defaults to false.
        _CodesCracked**             ==  Whether hints are broadcast from the leader.
        _CanBroadcast*              ==  Sets whether or not the main station can broadcast a message. Used to prevent repeatedly broadcasting. There's no need to set this. The script manages it itself.
        _DefenderCycleTime          ==  The cycle time of the defenders. i.e. setting this to 120 will cause defenders to cycle ever 2 minutes.
        _DefenderCycleTimer*        ==  Keeps track of how many seconds have elapsed for the purpose of starting a defender wave cycle.
        _DefenderWave*              ==  How many waves of defenders have spawned.
        _DefenderDistance*          ==  How far from the center of the sector, roughly, to spawn defenders. This defaults to 1000.
        _DeleteDefendersOnLeave*    ==  Deletes the defenders when the players leave the sector. Defaults to false.
        _AutoWithdrawDefenders*     ==  Defenders will withdraw themeselves at low health - skips initiaing withdraw actions. Defaults to false.
        _DangerLevel                ==  The danger level of the defenders - used for ESCCUtil's table functions.
        _UseFixedDanger*            ==  Will use danger level 5 always. Defaults to false.
        _MaxDefenders               ==  The maximum number of defenders this 
        _MaxDefendersSpawn*         ==  The maximum number of defenders that can spawn at once. Defaults to MaxDefenders unless otherwise set.
        _DefenderHPThreshold        ==  Defenders under this HP threshold will withdraw each cycle. Expresed as a percentage.
        _DefenderOmicronThreshold   ==  Defenders under this omicron threshold will withdraw each cycle. Expressed as a percentage.
        _PrependToDefenderTitle     ==  Defenders will have this prepended to their title. Can be left nil with no issues.
        _ForceWaveAtThreshold*      ==  If the leader's HP drops below a certain threshold, this will force a wave to spawn. Expressed as a float (0.5 means 50% HP) - set to 0 or -1 to bypass this.
                                    ==      - NOTE: This will set _FirstWaveSpawned to true, and waves can no longer be forced afterwards.
        _InvincibleOnForced*        ==  If this is set to true, the _DefenseLeader entity will be set to be immune to damage while ships from the forced spawn wave are around.
        _FirstWaveSpawned*          ==  This will be set to true once the first wave has spawned.
        _ForcedDefenderDamageScale* ==  All forcibly spawned defenders (see _ForceWaveAtThreshold / _InvincibleOnForced, etc.) will have their damage multiplier multiplied by this value.
        _AllDefenderDamageScale*    ==  Multiplies the damage of all ships spawned by this amount. Defaults to 1.
        _IsPirate                   ==  Whether or not to use faction ships or pirate ships.
        _Factionid                  ==  The faction ID of the faction that the ships will spawn for. Important for picking a new defense leader, and for 
        _PirateLevel                ==  The pirate level of the pirates that will spawn. Important for setting the async pirate generator.
        _AddToEachWave              ==  Automatically adds these to each wave. No questions asked. Set this to { "Jammer" } for instance, and a jammer will be added to each wave.
        _AddPctToEachWave           ==  Adds these to each wave based on a % chance. Set this to { pct = 0.35, name = "Jammer" } for instance, and a jammer will have a 35% chance to be added to each wave.
        _UseLeaderSupply            ==  Uses the supply mechanic for the defense leader. This is otherwise managed by shipmentcontroller.lua
        _LowTable                   ==  A "low" value table.
        _HighTable                  ==  A "high" value table.
        _SwapTables                 ==  Enable swapping tables on modulo
        _SwapOnModulo               ==  Swap every X waves, where X is this value.
        _SupplyPerLevel             ==  How many supplies constitute a "level" - default is 500.
        _SupplyFactor               ==  How much each supply level buffs defenders.
        _KillWhenNoPlayers          ==  Sets the killswitch when no players are present in the sector.
        _KillSwitchSet              ==  This kills the script on its next update.
        _ForceDebug*                ==  Forces debug mode on for this defense controller. Set to nil by default.
        _AbsoluteFactionLimit*      ==  If set, makes it so that no more than this number of ships will spawn for the current faction. For example, if this is set to 20, this will not spawn more than 20 ships from that faction, even if the ships aren't from this script. Set to nil by default.
        _NoHazard*                  ==  If set, ships spawned by this script will not cause a hazard zone when destroyed. Defaults to false.
        _PreventLootDrop*           ==  If set, ships spawned by this script will not drop loot. Defaults to false.
]]

--//********** EXAMPLE SETUP OF A DEFENSE CONTROLLER FROM LONG LIVE THE EMPRESS **********

--[[
    local _Sector = Sector()
    if not _Sector:hasScript("sector/background/defensecontroller.lua") then
        --Defense Controller Data
        local _DCD = {}
        _DCD._DefenseLeader = mission.data.custom.militaryStationid
        _DCD._CodesCracked = mission.data.custom.optionalObjectiveCompleted
        _DCD._DefenderCycleTime = mission.data.custom.defenderRespawnTime
        _DCD._DangerLevel = mission.data.custom.dangerLevel
        _DCD._MaxDefenders = mission.data.custom.maxDefenders
        _DCD._DefenderHPThreshold = 0.5
        _DCD._DefenderOmicronThreshold = 0.5
        _DCD._ForceWaveAtThreshold = 0.8
        _DCD._ForcedDefenderDamageScale = mission.data.custom.forcedDefenderScale
        _DCD._IsPirate = true
        _DCD._Factionid = _MilitaryStation.factionIndex
        _DCD._PirateLevel = mission.data.custom.pirateLevel
        _DCD._UseLeaderSupply = true
        _DCD._LowTable = "Standard"
        _DCD._HighTable = "High"
        _DCD._SupplyPerLevel = 500
        _DCD._SupplyFactor = 0.1 --+10% buff per level.
        if mission.data.custom.dangerLevel >= 8 then
            _DCD._SwapTables = true
            _DCD._SwapOnModulo = 3
        end
        if mission.data.custom.dangerLevel == 10 then
            _DCD._AddToEachWave = { "Jammer" }
        end

        _Sector:addScript("sector/background/defensecontroller.lua", _DCD)
        mission.Log(_MethodName, "Defense controller successfully attached.")
    else
        _Sector:invokeFunction("sector/background/defensecontroller.lua", "setCodesCracked", mission.data.custom.optionalObjectiveCompleted)
    end
]]
self._Data._DefenseLeader = nil
self._Data._CanTransfer = nil
self._Data._CanTransferToShip = nil
self._Data._CodesCracked = nil
self._Data._CanBroadcast = nil
self._Data._DefenderCycleTime = nil
self._Data._DefenderCycleTimer = nil
self._Data._DefenderWave = nil
self._Data._DefenderDistance = nil
self._Data._DeleteDefendersOnLeave = nil
self._Data._AutoWithdrawDefenders = nil
self._Data._DangerLevel = nil
self._Data._MaxDefenders = nil
self._Data._DefenderHPThreshold = nil
self._Data._DefenderOmicronThreshold = nil
self._Data._PrependToDefenderTitle = nil
self._Data._ForceWaveAtThreshold = nil
self._Data._FirstWaveSpawned = nil
self._Data._ForcedDefenderDamageScale = nil
self._Data._InvincibleOnForced = nil
self._Data._IsPirate = nil
self._Data._Factionid = nil
self._Data._PirateLevel = nil
self._Data._AddToEachWave = nil
self._Data._AddPctToEachWave = nil
self._Data._UseLeaderSupply = nil
self._Data._LowTable = nil
self._Data._HighTable = nil
self._Data._SwapTables = nil
self._Data._SwapOnModulo = nil
self._Data._SupplyPerLevel = nil
self._Data._SupplyFactor = nil
self._Data._KillWhenNoPlayers = nil
self._Data._KillSwitchSet = nil
self._Data._ForceDebug = nil
self._Data._AbsoluteFactionLimit = nil
self._Data._NoHazard = nil
--All of these values can be generated on the fly / defaulted internally and do not need to be passed.
self._Tag = nil
self._LevelTag = nil
self._ForcingWave = false
self._StartForcedWaveTimer = nil
self._Withdrawing = nil

--region #INIT

function DefenseController.initialize(_Values)
    local _MethodName = "inizialize"
    if onServer() then
        
        if not _restoring then
            self._Data = _Values

            if self._Data._ForceDebug then
                self._Debug = 0
                self.Log(_MethodName, "_ForceDebug enabled.")
            end

            self.Log(_MethodName, "Beginning on Sever - v4")
            --We can set some of these reliably if they're not included.
            self._Data._CanTransfer = self._Data._CanTransfer or true
            self._Data._CanTransferToShip = self._Data._CanTransferToShip or false
            self._Data._DefenderWave = self._Data._DefenderWave or 1
            self._Data._DeleteDefendersOnLeave = self._Data._DeleteDefendersOnLeave or false
            self._Data._AutoWithdrawDefenders = self._Data._AutoWithdrawDefenders or false
            self._Data._DefenderCycleTimer = self._Data._DefenderCycleTimer or 0
            self._Data._ForceWaveAtThreshold = self._Data._ForceWaveAtThreshold or -1
            self._Data._FirstWaveSpawned = self._Data._FirstWaveSpawned or false
            self._Data._InvincibleOnForced = self._Data._InvincibleOnForced or false
            self._Data._ForcedDefenderDamageScale = self._Data._ForcedDefenderDamageScale or 1
            self._Data._AllDefenderDamageScale = self._Data._AllDefenderDamageScale or 1
            self._Data._CanBroadcast = true
            self._Data._MaxDefendersSpawn = self._Data._MaxDefendersSpawn or self._Data._MaxDefenders
            self._Data._UseFixedDanger = self._Data._UseFixedDanger or false
            self._Data._DefenderDistance = self._Data._DefenderDistance or 1000
            self._Data._NoHazard = self._Data._NoHazard or false
            self._Data._PreventLootDrop = self._Data._PreventLootDrop or false
        else
            self.Log(_MethodName, "Values would have been restored in restore()")
        end
        --We can always set tags.
        self.setTags()
    else
        self.Log(_MethodName, "Beginning on Client")
    end
end

function DefenseController.getUpdateInterval()
    return 1.0
end

--endregion

--region #SERVER CALLS

function DefenseController.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    local _Sector = Sector()
    if _Sector.numPlayers == 0 then 
        if self._Data._KillWhenNoPlayers then
            self.Log(_MethodName, "No players remaining and script is set to terminate self on no remaining players. Setting killswitch.")
            self._Data._KillSwitchSet = true
        else
            --Don't update with no players. If the killswitch is set for when there are no players, the script will terminate itself shortly.
            return
        end
    end
    
    --Check the leader.
    self.checkDefenseLeader()
    if self._Data._KillSwitchSet then
        terminate()
        return
    end

    --If we have an absolute faction limit set, check that.
    if self._Data._AbsoluteFactionLimit then
        local _Entities = {_Sector:getEntitiesByFaction(self._Data._Factionid)}
        local _ShipCount = 0
        for _, _En in pairs(_Entities) do
            if _En.type == EntityType.Ship then
                _ShipCount = _ShipCount + 1
            end
        end

        if _ShipCount >= self._Data._AbsoluteFactionLimit then
            return
        end
    end

    --Every _DefenderCycleTime seconds, we initiate a withdraw, then 10 seconds later we will spawn in a wave of defenders.
    self._Data._DefenderCycleTimer = self._Data._DefenderCycleTimer + _TimeStep
    if self._StartForcedWaveTimer then
        self._StartForcedWaveTimer = self._StartForcedWaveTimer + _TimeStep
    end

    if math.floor(self._Data._DefenderCycleTimer % 30) == 0 then
        self.Log(_MethodName, "Defense Controller has run 30 update ticks.")
    end

    if self._Data._DefenderCycleTimer > (self._Data._DefenderCycleTime - 10) then
        --Initiate a withdraw, then set conditions to spawn the next wave in.
        if not self._Data._AutoWithdrawDefenders and not self._Withdrawing then
            --Broadcast if we can.
            if self._Data._CodesCracked then
                self.broadcastWithdrawCall()
            end
            self.Log(_MethodName, "Initiating withdraw action - defenders will spawn in 10 seconds.")
            self.initiateWithdraw()
        end
    end
    if self._Data._DefenderCycleTimer > self._Data._DefenderCycleTime then
        self.Log(_MethodName, "Spawning wave and resetting timer.")
        self.initiateNextWave()
        self._Withdrawing = false
        self._Data._DefenderCycleTimer = 0
    end

    if self.forceWave() then
        if self._Data._CodesCracked then
            self.broadcastForcedWave()
        end
        self._StartForcedWaveTimer = 0
        self._ForcingWave = true
    end
    if self._StartForcedWaveTimer and self._StartForcedWaveTimer > 2 then
        --Start the forced wave. No need to reset this.
        self.initiateNextWave()
        self._StartForcedWaveTimer = nil
    end
end

function DefenseController.forceWave()
    local _MethodName = "Check Force Wave"
    local _DefenseLeader = Entity(self._Data._DefenseLeader)

    self.Log(_MethodName, "Ratio of durability is: " .. tostring(_DefenseLeader.durability / _DefenseLeader.maxDurability) .. " threshold is " .. self._Data._ForceWaveAtThreshold, 0)
    if self._Data._FirstWaveSpawned then --If the first wave has spawned, we cannot force a wave.
        return false
    else
        self.Log(_MethodName, "First wave has not spawned. Checking to see if we are already forcing a wave.")
        if self._ForcingWave then --If we are already forcing a wave, we can't force a wave.
            return false
        else
            self.Log(_MethodName, "We are not already forcing a wave. Check to see if defense leader HP is too high.")
            if _DefenseLeader.durability / _DefenseLeader.maxDurability > self._Data._ForceWaveAtThreshold then --If our defense leader's HP is above the threshold, don't bother.
                return false
            else
                self.Log(_MethodName, "Defense leader HP is not too high. Forcing wave.")
                return true
            end
        end
    end
end

function DefenseController.checkDefenseLeader()
    local _MethodName = "Check Defense Leader"
    local _DefenseLeader = Entity(self._Data._DefenseLeader)

    if not _DefenseLeader or not valid(_DefenseLeader) then
        self.Log(_MethodName, "Defense leader was destroyed or is otherwise invalid, checking sector for a new defense leader candidate.")
        local _DefenseCandidates = {}
        if self._Data._CanTransfer then
            local _OtherStations = {Sector():getEntitiesByType(EntityType.Station)}
            for _, _Station in pairs(_OtherStations) do
                if _Station.factionIndex == self._Data._Factionid then
                    table.insert(_DefenseCandidates, _Station)
                end
            end
            if self._Data._CanTransferToShip then
                local _OtherShips = {Sector():getEntitiesByType(EntityType.Ship)}
                for _, _Ship in pairs(_OtherShips) do
                    if _Ship.factionIndex == self._Data._Factionid then
                        table.insert(_DefenseCandidates, _Ship)
                    end
                end
            end
        end
        
        local _Rgen = ESCCUtil.getRand()

        if _DefenseCandidates and #_DefenseCandidates > 0 then
            self._Data._DefenseLeader = _DefenseCandidates[_Rgen:getInt(1, #_DefenseCandidates)].id
        else
            self.Log(_MethodName, "Could not find a new defense leader station - script will terminate on next update.")
            self._Data._KillSwitchSet = true
        end
    else
        if not _DefenseLeader:getValue("_DefenseController_Manage_Own_Invincibility") then
            --Check to see if the defense leader should be made invincible.
            local _ForceImmunityDefenders = ESCCUtil.countEntitiesByValue(self._InvincibleTag)
            _DefenseLeader.invincible = _ForceImmunityDefenders > 0
            local _DefenseLeaderShield = Shield(self._Data._DefenseLeader)
            if _DefenseLeaderShield then
                _DefenseLeaderShield.invincible = _ForceImmunityDefenders > 0
            end
        end
    end
end

function DefenseController.initiateWithdraw()
    local _MethodName = "Withdraw Damaged Defenders"
    self.Log(_MethodName, "Beginning...")
    --Grab all defenders with our tag. Forced defenders do not have our tag, so they will not count against the cap or withdraw normally.
    self._Withdrawing = true
    local _Defenders = {Sector():getEntitiesByScriptValue(self._Tag)}
    local _Rgen = ESCCUtil:getRand()

    local _DefenseLeader = Entity(self._Data._DefenseLeader)
    local _NewDefenderLevel = 0
    if self._Data._UseLeaderSupply and _DefenseLeader:getValue(self._SupplyTag) then
        _NewDefenderLevel = math.floor(_DefenseLeader:getValue(self._SupplyTag) / self._Data._SupplyPerLevel)
    end

    for _, _Defender in pairs(_Defenders) do
        local _WarpOut = false
        if _Defender.durability / _Defender.maxDurability < self._Data._DefenderHPThreshold then
            --Defender HP has dropped below threshold - defender will withdraw and be replaced in the next weave.
            _WarpOut = true
        end

        local _DefenderOriginalDPS = _Defender:getValue(self._DPSTag)
        self.Log(_MethodName, "Defender original DPS " .. tostring(_DefenderOriginalDPS) .. " current DPS: " .. tostring(_Defender.firePower) .. " ratio is -- " .. tostring(_Defender.firePower / _DefenderOriginalDPS))
        if _DefenderOriginalDPS and _Defender.firePower / _DefenderOriginalDPS < self._Data._DefenderOmicronThreshold then
            --Defender DPS has dropped below threshold - defender will withdraw and be replaced in the next wave.
            _WarpOut = true
        end

        local _DefenderLevel = _Defender:getValue(self._LevelTag)
        if _DefenderLevel and _NewDefenderLevel > _DefenderLevel + 1 then
            --New defenders would be significantly stronger than this defender - defender will withdraw and be replaced in the next wave.
            _WarpOut = true
        end

        if _WarpOut then
            _Defender:addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(4, 8))
        end
    end
end

function DefenseController.initiateNextWave()
    local _MethodName = "Initiate Next Wave"
    local _DefenderCount = ESCCUtil.countEntitiesByValue(self._Tag)
    local _Rgen = ESCCUtil.getRand()

    local _DefendersToSpawn = self._Data._MaxDefenders - _DefenderCount

    if _DefendersToSpawn > self._Data._MaxDefendersSpawn then
        _DefendersToSpawn = self._Data._MaxDefendersSpawn
    end

    local _Threat = self._Data._LowTable
    if self._Data._SwapTables then
        if self._Data._DefenderWave % self._Data._SwapOnModulo == 0 then
            _Threat = self._Data._HighTable
        end
    end

    local _DangerLevel = self._Data._DangerLevel
    if self._Data._UseFixedDanger then
        _DangerLevel = 5
    end

    local _WaveTable = nil
    if self._Data._IsPirate then
        _WaveTable = ESCCUtil.getStandardWave(_DangerLevel, _DefendersToSpawn, _Threat, false)
    else
        _WaveTable = ESCCUtil.getStandardWave(_DangerLevel, _DefendersToSpawn, _Threat, true)
    end
    if not _WaveTable then
        self.Log(_MethodName, "ERROR - _WaveTable was not set.")
    end
    
    if self._Data._AddToEachWave then
        self.Log(_MethodName, "Adding guaranteed spawns to wave.")
        for _, _Ex in pairs(self._Data._AddToEachWave) do
            table.insert(_WaveTable, _Ex)
        end
    end

    if self._Data._AddPctToEachWave then
        self.Log(_MethodName, "Adding % spawns to each wave.")
        for _, _Ex in pairs(self._Data._AddPctToEachWave) do
            if _Rgen:getFloat(0.0, 1.0) <= _Ex.pct then
                table.insert(_WaveTable, _Ex.name)
            end
        end
    end

    if _DefendersToSpawn > 0 then
        if self._Data._IsPirate then
            self.spawnPirateDefenders(_WaveTable)
        else
            self.spawnFactionDefenders(_WaveTable)
        end
    end
end

function DefenseController.spawnPirateDefenders(_WaveTable)
    local _MethodName = "Spawn Pirate Defender Wave"
    local _Faction = Faction(self._Data._Factionid)

    self.Log(_MethodName, "Spawning wave " .. tostring(self._Data._DefenderWave) .. " - includes " .. tostring(#_WaveTable) .. " [" .. tostring(_Faction.name):upper() .. "] defenders. This is a level " .. tostring(self._Data._PirateLevel) .. "Pirate Faction.")

    local generator = AsyncPirateGenerator(DefenseController, DefenseController.onNextWaveGenerated)
    generator.pirateLevel = self._Data._PirateLevel

    generator:startBatch()

    local posCounter = 1
    local distance = 250 --_#DistAdj

    local pirate_positions = generator:getStandardPositions(#_WaveTable, distance, self._Data._DefenderDistance)
    for _, p in pairs(_WaveTable) do
        generator:createScaledPirateByName(p, pirate_positions[posCounter])
        posCounter = posCounter + 1
    end

    generator:endBatch()
end

function DefenseController.spawnFactionDefenders(_WaveTable)
    local _MethodName = "Spawn Faction Defender Wave"
    local _Faction = Faction(self._Data._Factionid)

    self.Log(_MethodName, "Spawning wave " .. tostring(self._Data._DefenderWave) .. " - includes " .. tostring(#_WaveTable) .. " [" .. tostring(_Faction.name):upper() .. "] defenders.")

    local _Generator = AsyncShipGenerator(DefenseController, DefenseController.onNextWaveGenerated)
    _Generator:startBatch()

    local _PosCounter = 1
    local _Distance = 350

    local _Positions = _Generator:getStandardPositions(#_WaveTable, _Distance, self._Data._DefenderDistance)
    for _, _F in pairs(_WaveTable) do
        _Generator:createDefenderByName(_Faction, _Positions[_PosCounter], _F)
        _PosCounter = _PosCounter + 1
    end

    _Generator:endBatch()
end

function DefenseController.onNextWaveGenerated(_Generated)
    local _MethodName = "On Next Wave Generated"
    self.Log(_MethodName, "Beginning...")

    local _DefenseLeader = Entity(self._Data._DefenseLeader)
    local _DefenderLevel = 0
    local _SupplyMultiplier = 0
    if self._Data._UseLeaderSupply and _DefenseLeader:getValue(self._SupplyTag) then
        _DefenderLevel = math.floor(_DefenseLeader:getValue(self._SupplyTag) / self._Data._SupplyPerLevel)
        _SupplyMultiplier = self._Data._SupplyFactor
    end

    local _Factor = 1 + (_DefenderLevel * _SupplyMultiplier)

    self.Log(_MethodName, "Adding enemy buffs...")
    SpawnUtility.addEnemyBuffs(_Generated)

    for _, _Defender in pairs(_Generated) do
        --:setValues of the defenders.
        if not self._ForcingWave then
            _Defender:setValue(self._Tag, true)
        else
            self.Log(_MethodName, "Wave is being forced - self._Forcing wave is " .. tostring(self._ForcingWave))
            if self._Data._InvincibleOnForced then
                _Defender:setValue(self._InvincibleTag, true)
            end
        end
        _Defender:setValue(self._LevelTag, _DefenderLevel)
        _Defender:setValue(self._DPSTag, _Defender.firePower)
        if not self._Data._IsPirate then
            _Defender:setValue("npc_chatter", nil)
            _Defender:removeScript("antismuggle.lua")
            --Add some specific triggers for the DLC factions.
            local _DefenderFaction = Faction(_Defender.factionIndex)
            if _DefenderFaction.name == "The Cavaliers" then
                _Defender:setValue("is_cavaliers", true)
            elseif _DefenderFaction.name == "The Commune" then
                _Defender:setValue("is_commune", true)
            elseif _DefenderFaction.name == "The Family" then
                _Defender:setValue("is_family", true)
            end
        end
        if self._Data._NoHazard then
            _Defender:setValue("_ESCC_bypass_hazard", true)
        end

        --Set damage / shield / HP buffs.
        local _Dura = Durability(_Defender)
        if _Dura then
            _Dura.maxDurabilityFactor = _Dura.maxDurabilityFactor * _Factor
        end

        local _Shield = Shield(_Defender)
        if _Shield then
            _Shield.maxDurabilityFactor = _Shield.maxDurabilityFactor * _Factor
        end

        _Defender.damageMultiplier = _Defender.damageMultiplier * _Factor
        _Defender.damageMultiplier = _Defender.damageMultiplier * self._Data._AllDefenderDamageScale
        if self._ForcingWave then
            _Defender.damageMultiplier = _Defender.damageMultiplier * self._Data._ForcedDefenderDamageScale
        end

        --Set some final values / scripts.
        if self._Data._AutoWithdrawDefenders then
            self.Log(_MethodName, "Adding AI withdraw script at " .. tostring(self._Data._DefenderHPThreshold) .. " threshold.")
            local _WithdrawData = {
                _Threshold = self._Data._DefenderHPThreshold
            }
            _Defender:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
        end
        if self._Data._PreventLootDrop then
            _Defender:setDropsLoot(false)
        end
        if self._Data._DeleteDefendersOnLeave then
            MissionUT.deleteOnPlayersLeft(_Defender)
        end
        if self._Data._PrependToDefenderTitle then
            _Defender.title = self._Data._PrependToDefenderTitle .. " " .. _Defender.title
        end
    end

    Placer.resolveIntersections(_Generated)

    self._Data._DefenderWave = self._Data._DefenderWave + 1
    --We don't really care about setting either of these repeatedly.
    self._Data._FirstWaveSpawned = true 
    self._ForcingWave = false
end

function DefenseController.broadcastWithdrawCall()
    local _MethodName = "Broadcast Withdraw Call"

    self.Log(_MethodName, "Beginning call.")

        local _DefenseLeader = Entity(self._Data._DefenseLeader)
    
        local _Lines = {
            "CHRRK.... Damaged..... withdraw.... CHRRRK..... incoming..... CHRRRK",
            "CHRRK... More... CHRRRK... on... CHRRRK... way... CHRRK",
            "CHRRK... Enemy... CHRRRK... destroy... CHRRRK... reinforcements... CHRRK",
            "CHRRK... Withdraw... CHRRRK... reinforcements... CHRRK"
        }
    
        Sector():broadcastChatMessage(_DefenseLeader, ChatMessageType.Chatter, randomEntry(_Lines))
end

function DefenseController.broadcastForcedWave()
    local _MethodName = "Broadcast Forced Wave Call"
    self.Log(_MethodName, "Beginning call.")

    local _DefenseLeader = Entity(self._Data._DefenseLeader)

    local _Lines = {
        "CHRRK.... Save..... Save.... Hurt..... Them..... CHRRRK",
        "CHRRRK.... HELP..... CHRRRRRK",
        "CHRRK... Overrun... CHRRRK... send... CHRRRK... help... CHRRK",
        "CHRRK... Alert... CHRRRK... Alert... CHRRRK... Alert... CHRRK",
        "CHRRK... Distress... CHRRRK... help... CHRRK",
        "CHRRK... HELP... CHRRRK... help... CHRRK"
    }

    Sector():broadcastChatMessage(_DefenseLeader, ChatMessageType.Chatter, randomEntry(_Lines))
end

function DefenseController.setTags()
    local _X, _Y = Sector():getCoordinates()
    local _Rgen = ESCCUtil.getRand()
    --Should be good enough to avoid overlap with multiple defense controllers running in a single sector.
    local _BaseTag = tostring(_X) .. "_" .. tostring(_Y) .. tostring(_Rgen:getInt(1, 10000000))

    self._Tag = "_DefenseController_" .. _BaseTag
    self._LevelTag = "_DefenseController_" .. _BaseTag .. "_Level"
    self._SupplyTag = "_escc_Mission_Supply"
    self._DPSTag = "_DefenseController_" .. _BaseTag .. "_DPS"
    self._InvincibleTag = "_DefenseController_" .. _BaseTag .. "_Invincible"
end

function DefenseController.setKillSwitchOnPlayersLeft()
    self._Data._KillWhenNoPlayers = true
end

function DefenseController.setCodesCracked(_Val)
    self._Data._CodesCracked = _Val
end

function DefenseController.setDangerLevel(_Val)
    _Val = _Val or 1
    self._Data._DangerLevel = _Val
end

function DefenseController.incrementCycleTime(_Val)
    _Val = _Val or 0
    self._Data._DefenderCycleTime = self._Data._DefenderCycleTime + _Val
end

--endregion

--region #CLIENT / SERVER CALLS

function DefenseController.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[ESCC Defense Controller] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

--endregion

--region #SECURE / RESTORE

function DefenseController.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function DefenseController.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
    self.setTags()
end

--endregion