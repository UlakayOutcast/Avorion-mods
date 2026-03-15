package.path = package.path .. ";data/scripts/lib/?.lua"

--Run the rest of the includes.
local AsyncShipGenerator = include("asyncshipgenerator")
local PirateGenerator = include("pirategenerator")

include ("galaxy")
include ("stringutility")
include ("callable")
include ("relations")
include ("randomext")

ESCCUtil = include("esccutil")

--Don't remove this or else the script might break. You know the drill by now.
--namespace ShipmentController
ShipmentController = {}
local self = ShipmentController

self._Debug = 0

self._Data = {}
--[[
    Some of these values are fairly self-explanatory, but for a handy guide for setting this thing up:
    THESE VALUES ARE REQUIRED - YOU SHOULD BE SETTING ALL OF THEM IN THE FIRST INITIALIZE CALL, OTHERWISE THE SCRIPT MAY NOT WORK CORRECTLY
        _ShipmentLeader             ==  The ID of the entity that is the "leader" of the shippers - this will broadcast. If this is destroyed, the script will pick another.
        _CodesCracked               ==  Whether hints are broadcast from the leader.
        _Broadcasted                ==  Prevents broadcasting more than once. This is managed internally by the script and does not need to be set.
        _ShipmentCycleTime          ==  The cycle time of the shippers. i.e. setting this to 120 will cause defenders to cycle ever 2 minutes.
        _ShipmentCycleTimer*        ==  Keeps track of how many seconds have elapsed for the purpose of starting a shipment cycle.
        _ShipmentWave*              ==  How many waves of defenders have spawned.
        _SupplierExtraScale         ==  The standard volume of a freighter will always get multiplied by this at least.
        _SupplierHealthScale        ==  Determines how much a supplier is buffed per wave this is a float - setting it to 0.1 will add 10% more HP per wave.
        _DangerLevel                ==  The danger level of the defenders.
        _IsPirate                   ==  Whether or not to use faction ships or pirate ships.
        _FactionId                  ==  The faction ID of the faction that the ships will spawn for. Important for picking a new defense leader, and for 
        _PirateLevel                ==  The pirate level of the pirates that will spawn. Important for setting the async pirate generator.
        _SupplyPerShip              ==  How much "Supply" each freighter has when it spawns in.
        _SupplyTransferPerCycle     ==  How much "Supply" is transferred per cycle.
        _KillWhenNoPlayers          ==  Sets the killswitch when no players are present in the sector.
        _KillSwitchSet              ==  This kills the script on its next update.

    * - This value is set in the initialize call if it is not included.
]]

--//********** EXAMPLE SETUP OF A SHIPMENT CONTROLLER FROM LONG LIVE THE EMPRESS **********

--[[
    local _Sector = Sector()
    if not _Sector:hasScript("sector/background/shipmentcontroller.lua") then
        --Shipment Controller Data
        local _SCD = {}
        _SCD._ShipmentLeader = mission.data.custom.militaryStationid
        _SCD._CodesCracked = mission.data.custom.optionalObjectiveCompleted
        _SCD._ShipmentCycleTime = mission.data.custom.freighterRespawnTime
        _SCD._DangerLevel = mission.data.custom.dangerLevel
        _SCD._IsPirate = true
        _SCD._Factionid = _MilitaryStation.factionIndex
        _SCD._PirateLevel = mission.data.custom.pirateLevel
        _SCD._SupplyTransferPerCycle = mission.data.custom.freighterSupplyTransfer
        _SCD._SupplyPerShip = mission.data.custom.freighterSupply
        _SCD._SupplierExtraScale = mission.data.custom.freighterScale
        _SCD._SupplierHealthScale = 0.1

        _Sector:addScript("sector/background/shipmentcontroller.lua", _SCD)
        mission.Log(_MethodName, "Shipment controller successfully attached.")
    else
        _Sector:invokeFunction("sector/background/shipmentcontroller.lua", "setCodesCracked", mission.data.custom.optionalObjectiveCompleted)
    end
]]
self._Data._ShipmentLeader = nil
self._Data._CodesCracked = nil
self._Data._Broadcasted = nil
self._Data._ShipmentCycleTime = nil
self._Data._ShipmentCycleTimer = nil
self._Data._ShipmentWave = nil
self._Data._SupplierExtraScale = nil
self._Data._SupplierHealthScale = nil
self._Data._DangerLevel = nil
self._Data._IsPirate = nil
self._Data._Factionid = nil
self._Data._PirateLevel = nil
self._Data._SupplyPerShip = nil
self._Data._SupplyTransferPerCycle = nil
self._Data._DelayNextShipment = nil
self._Data._KillWhenNoPlayers = nil
self._Data._KillSwitchSet = nil
--All of these values can be generated on the fly / defaulted internally and do not need to be passed.
self._Tag = nil
self._SupplyTag = nil

--region #INIT

function ShipmentController.initialize(_Values)
    local _MethodName = "inizialize"
    if onServer() then
        if not _restoring then
            self.Log(_MethodName, "Beginning on Sever")
            self._Data = _Values
            --We can set some of these reliably if they're not included.
            self._Data._ShipmentWave = self._Data._ShipmentWave or 1
            self._Data._ShipmentCycleTimer = self._Data._ShipmentCycleTimer or 0
        else
            self.Log(_MethodName, "Values would have been restored in restore()")
        end
        --We can always set the tags.
        self.setTags()
    else
        self.Log(_MethodName, "Beginning on Client")
    end
end

function ShipmentController.getUpdateInterval()
    return 1.0
end

--endregion

--region #SERVER CALLS

function ShipmentController.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    if Sector().numPlayers == 0 then 
        if self._Data._KillWhenNoPlayers then
            self.Log(_MethodName, "No players remaining and script is set to terminate self on no remaining players. Setting killswitch.")
            self._Data._KillSwitchSet = true
        else
            --Don't update with no players. If the killswitch is set for when there are no players, the script will terminate itself shortly.
            return
        end
    end
    --Check the leader.
    self.checkShipmentLeader()
    if self._Data._KillSwitchSet then
        terminate()
        return
    end
    --Every _ShipmentCycleTime seconds, we initiate a prepToShip, which clears out our current freighter. 10 seconds later we send in a new one.
    self._Data._ShipmentCycleTimer = self._Data._ShipmentCycleTimer + _TimeStep

    if math.floor(self._Data._ShipmentCycleTimer % 30) == 0 then
        self.Log(_MethodName, "Shipment Controller has run 30 update ticks.")
    end

    if self._Data._ShipmentCycleTimer > (self._Data._ShipmentCycleTime - 10) then
        --Broadcast.
        self.Log(_MethodName, "Initiating prep to ship.")
        if self._Data._CodesCracked and not self._Data._Broadcasted then
            self.broadcastShipmentCall()
            self._Data._Broadcasted = true
        end
        --Run prep to ship.
        self.prepToShip()
    end
    if self._Data._ShipmentCycleTimer > self._Data._ShipmentCycleTime then
        self.Log(_MethodName, "Spawning next shipment.")
        self.initiateNextShipment()
        self._Data._ShipmentCycleTimer = 0
        self._Data._Broadcasted = false
    end
end

function ShipmentController.checkShipmentLeader()
    local _MethodName = "Check Shipment Leader"
    local _ShipmentLeader = Entity(self._Data._ShipmentLeader)

    if not _ShipmentLeader or not valid(_ShipmentLeader) then
        self.Log(_MethodName, "Shipment leader was destroyed or is otherwise invalid, checking sector for a new Shipment leader candidate.")
        local _OtherStations = {Sector():getEntitiesByType(EntityType.Station)}
        local _Rgen = ESCCUtil.getRand()

        local _ShipmentCandidates = {}
        for _, _Station in pairs(_OtherStations) do
            if _Station.factionindex == self._Data._Factionid then
                table.inesrt(_ShipmentCandidates, _Station)
            end
        end

        if _ShipmentCandidates and #_ShipmentCandidates > 0 then
            self._Data._ShipmentLeader = _ShipmentCandidates[_Rgen:getInt(1, #_ShipmentCandidates)].id
        else
            self.Log(_MethodName, "Could not find a new Shipment leader station - script will terminate on next update.")
            self._Data._KillSwitchSet = true
        end
    end
end

function ShipmentController.prepToShip()
    local _MethodName = "Prep to Ship"
    self.Log(_MethodName, "Preparing to ship - clearing old freighter out of the area.")
    --Check to see if we need to clear any freighters in the area first.
    local _Freighters = {Sector():getEntitiesByScriptValue(self._Tag)}
    if _Freighters and #_Freighters > 0 then
        local _Rgen = ESCCUtil.getRand()
        for _, _Freighter in pairs(_Freighters) do
            --Check to see if it has successfully initiated a transfer.
            --NOTE: Be careful to give them enough time to dock and start the transfer if you are using large freighters.
            --For example, spawning a scale 20 freighter in the xanion region and having them jump out every minute will probably not
            --give the freighter enough time to start up a transfer.
            local _Initiated = _Freighter:getValue("_escc_Transfer_Initiated")
            local _ClearOut = false

            if not _Initiated then
                --If it has not initiated a transfer yet, it could be due to AI problems. Clear the ship out.
                _ClearOut = true
            else
                --If it has successfully initiated a transfer, don't clear it out unless it is empty.
                if _Freighter:getValue(self._SupplyTag) and _Freighter:getValue(self.SupplyTag) == 0 then
                    _ClearOut = true
                end
            end

            if _ClearOut then
                _Freighter:addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(4, 8))
            end
        end
    end
end

function ShipmentController.initiateNextShipment()
    local _MethodName = "Spawn Shipment"
    self.Log(_MethodName, "Spawning shipment " .. tostring(self._Data._ShipmentWave))

    local _Generator = AsyncShipGenerator(ShipmentController, ShipmentController.onFreighterGenerated)

    local _Faction = Faction(self._Data._Factionid)
    local _X, _Y = Sector():getCoordinates()
    local _SupplierVolume = Balancing_GetSectorShipVolume(_X, _Y) * self._Data._SupplierExtraScale

    _Generator:startBatch()
    _Generator:createFreighterShip(_Faction, PirateGenerator.getGenericPosition(), _SupplierVolume)
    _Generator:endBatch()
end

function ShipmentController.onFreighterGenerated(_Generated)
    local _MethodName = "On Freighter Spawned Callback"

    local _HPFactor = 1 + (self._Data._ShipmentWave * self._Data._SupplierHealthScale)
    --There should only ever be 1 ship in this batch.
    self.Log(_MethodName, "Setting Freighter Values")
    local freighter = _Generated[1]
    freighter:removeScript("civilship.lua")
    freighter:removeScript("dialogs/storyhints.lua")
    freighter:setValue(self._Tag, 1)
    freighter:setValue(self._SupplyTag, self._Data._SupplyPerShip)
    freighter:setValue("_escc_SupplyTransferPerCycle", self._Data._SupplyTransferPerCycle)
    freighter:setValue("is_civil", nil)
    freighter:setValue("is_freighter", nil)
    freighter:setValue("npc_chatter", nil)
    if self._Data._IsPirate then
        freighter:setValue("is_pirate", true)
    end

    local _Dura = Durability(freighter)
    if _Dura then
        _Dura.maxDurabilityFactor = _Dura.maxDurabilityFactor * _HPFactor
    end

    local _Shield = Shield(freighter)
    if _Shield then
        _Shield.maxDurabilityFactor = _Shield.maxDurabilityFactor * _HPFactor
    end

    --This will fly to a randomly chosen dock on the "Shipment Leader" station, transfer all "_escc_Mission_Supply", and then exit the sector.
    --Note that it is more likely that we will force exit the freighter with the prepToShip call.
    freighter:addScript("entity/ai/supply.lua", self._Data._ShipmentLeader)
    self._Data._ShipmentWave = self._Data._ShipmentWave + 1
end

function ShipmentController.broadcastShipmentCall()
    local _MethodName = "Broadcast Shipment Call"
    self.Log(_MethodName, "Beginning call.")

    local _ShipmentLeader = Entity(self._Data._ShipmentLeader)

    local _Lines = {
        "CHRRK.... Delivery..... CHRRRK",
        "CHRRK... Send... CHRRRK... supplies... CHRRRK... now... CHRRK",
        "CHRRK... Freighter... CHRRRK... protect... CHRRRK... destination... CHRRK",
        "CHRRK... Supply... CHRRRK... incoming... CHRRK",
        "CHRRK... Scheduled... CHRRRK... jumping... now... CHRRK"
    }

    Sector():broadcastChatMessage(_ShipmentLeader, ChatMessageType.Chatter, randomEntry(_Lines))
end

function ShipmentController.setTags()
    local _X, _Y = Sector():getCoordinates()
    local _Rgen = ESCCUtil.getRand()
    --Should be good enough to avoid overlap with multiple shipment controllers running in a single sector.
    local _BaseTag = tostring(_X) .. "_" .. tostring(_Y) .. tostring(_Rgen:getInt(1, 10000000))

    self._Tag = "_ShipmentController_" .. _BaseTag
    self._SupplyTag = "_escc_Mission_Supply"
end

function ShipmentController.setKillSwitchOnPlayersLeft()
    self._Data._KillWhenNoPlayers = true
end

function ShipmentController.setCodesCracked(_Val)
    self._Data._CodesCracked = _Val
end

function ShipmentController.incrementCycleTime(_Val)
    _Val = _Val or 0
    self._Data._ShipmentCycleTime = self._Data._ShipmentCycleTime + _Val
end

--endregion

--region #CLIENT / SERVER CALLS

function ShipmentController.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[ESCC Sector Shipment Controller] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

--endregion

--region #SECURE / RESTORE

function ShipmentController.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self._Data")
    return self._Data
end

function ShipmentController.restore(_Values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self._Data")
    self._Data = _Values
    self.setTags()
end

--endregion