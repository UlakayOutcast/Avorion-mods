package.path = package.path .. ";data/scripts/lib/?.lua"

include("galaxy")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace ITBackground
ITBackground = {}
local self = ITBackground

self._Debug = 0
self._OverallDecayTime = (24 * 60 * 60)
self._UnpauseFrames = 0
self._OOSResetTicks = 0

function ITBackground.initialize()
    self._OOSResetTicks = 0
    if onServer() then
        local _Sector = Sector()
        local _Player = Player()
    
        _Player:registerCallback("onSectorArrivalConfirmed", "onSectorArrivalConfirmed")
    
        _Sector:registerCallback("onWaveEncounterFinished", "onWaveEncounterFinished")
        _Sector:registerCallback("onIncreasingThreatPirateShipyardDestroyed", "onIncreasingThreatPirateShipyardDestroyed")
        _Sector:registerCallback("onDestroyed", "onDestroyed")
    end
end

function ITBackground.onSectorArrivalConfirmed()
    if onServer() then
        local _MethodName = "On Sector Arrival Confirmed"
        self.Log(_MethodName, "Registering callback.")
    
        local _Sector = Sector()
    
        _Sector:registerCallback("onWaveEncounterFinished", "onWaveEncounterFinished")
        _Sector:registerCallback("onIncreasingThreatPirateShipyardDestroyed", "onIncreasingThreatPirateShipyardDestroyed")
        _Sector:registerCallback("onDestroyed", "onDestroyed")
    end
end

function ITBackground.onWaveEncounterFinished()
    local _MethodName = "On Wave Encounter Finished"
    self.Log(_MethodName, "Player has finished a wave encounter.")

    self.normalizeHatredTowards(500, 0.02)
end

function ITBackground.onIncreasingThreatPirateShipyardDestroyed()
    local _MethodName = "On Increasing Threat Pirate Shipyard Destroyed"
    self.Log(_MethodName, "Player has destroyed a pirate shipyard.")

    self.normalizeHatredTowards(500, 0.03)
end

function ITBackground.onDestroyed(_DestroyedEntityID, _DestroyerID)
    local _MethodName = "On Destroyed"
    
    local _DestroyerEntity = Entity(_DestroyerID)
    if _DestroyerEntity and valid(_DestroyerEntity) then
        local _DestroyerFaction = Faction(_DestroyerEntity.factionIndex)
        local _Player = Player()
    
        if _DestroyerFaction.index == _Player.index then
            local _DestroyedEntity = Entity(_DestroyedEntityID)
    
            local _AttackerValue = false 
            if _DestroyedEntity:getValue("background_attacker") or _DestroyedEntity:getValue("is_passive_attack") then
                _AttackerValue = true
            end
    
            if _DestroyedEntity:getValue("is_pirate") and _AttackerValue then
                local _Player = Player(_DestroyerEntity.factionIndex)
                local _PirateFaction = Faction(_DestroyedEntity.factionIndex)
        
                local _HatredIndex = "_increasingthreat_hatred_" .. tostring(_PirateFaction.index)
                self.Log(_MethodName, "Hatred index is : " .. tostring(_HatredIndex))
                local _Hatred = _Player:getValue(_HatredIndex) or 0
        
                --We specifically don't mess with the values using Tempered here, becasue tempered calculates using Ceil(...) and that would just bump it back to 1/2
                if _DestroyedEntity:getValue("background_attacker") then
                    _Hatred = _Hatred + 1
                end
                if _DestroyedEntity:getValue("is_passive_attack") then
                    _Hatred = _Hatred + 2
                end
        
                self.Log(_MethodName, "Setting new hatred value of player to : " .. tostring(_Hatred))
                _Player:setValue(_HatredIndex, _Hatred)
            end
        end
    end
end

function ITBackground.normalizeHatredTowards(_Value, _Pct)
    local _MethodName = "Normalize Hatred Towards"
    --Get the local pirate faction.
    --Normalize hatred towards 500 - move it 2% in that direction.
    local _Player = Player()
    local x, y = Sector():getCoordinates()

    local _PirateLevel = Balancing_GetPirateLevel(x, y)
    local _PirateFaction = Galaxy():getPirateFaction(_PirateLevel)

    --Tempered pirates don't lose / gain hatred as quickly.
    local _TemperedFactor = 1.0
    local _Tempered = _PirateFaction:getTrait("tempered")
    if _Tempered then
        if _Tempered >= 0.25 then
            _TemperedFactor = 0.8
        end
        if _Tempered >= 0.75 then
            _TemperedFactor = 0.7
        end
        self.Log(_MethodName, "Faction is tempered - hatred multiplier is (" .. tostring(_TemperedFactor) .. ")")
    end

    local _HatredIndex = "_increasingthreat_hatred_" .. tostring(_PirateFaction.index)
    local _Hatred = _Player:getValue(_HatredIndex) or 0
    local _HatredNormalized = math.floor((_Hatred - _Value) * _Pct * -1 * _TemperedFactor)

    self.Log(_MethodName, "Player hatred value is : " .. tostring(_Hatred) .. " incrementing it by : " .. tostring(_HatredNormalized))

    _Player:setValue(_HatredIndex, _Hatred + _HatredNormalized)
end

function ITBackground.getUpdateInterval()
    return 10 --Need to update every 10 seconds to handle unpausing.
end

function ITBackground.updateServer(_TimeStep)
    local _MethodName = "Update Server"
    --We actually don't care about the timestep.
    local _ServerTime = Server().unpausedRuntime
    local _Player = Player()
    local _DecayTickValueName = "_increasingthreat_next_hatreddecay"
    local _HatredValueName = "_increasingthreat_hatred_"

    --Handle unpause frames.
    if self._UnpauseFrames > 0 then
        self.Log(_MethodName, "Unpausing events for " .. tostring(self._UnpauseFrames) .. " more update frames.")
        _Player:invokeFunction("player/events/eventscheduler.lua", "unPause")
        self._UnpauseFrames = self._UnpauseFrames - 1
    end

    --Handle OOS Attempts resets
    local _OOSAttempts = _Player:getValue("_increasingthreat_oos_attack_attempts") or 0
    if _OOSAttempts > 0 then
        self._OOSResetTicks = self._OOSResetTicks + 1
        if self._OOSResetTicks >= 6 then
            self.Log(_MethodName, "6 ticks have passed since OOS attack attempts have been made - reset.")
            _Player:setValue("_increasingthreat_oos_attack_attempts", 0)
            self._OOSResetTicks = 0
        end
    end

    --Handle decay ticks.
    local _DecayTick = Player():getValue(_DecayTickValueName) or 0
    if _ServerTime >= _DecayTick then
        self.Log(_MethodName, "Server time greater than decay tick time " .. tostring(_DecayTick) .. " decay hatred values.")
        local _PlayerValues = _Player:getValues()
        for _Key, _Val in pairs(_PlayerValues) do
            if string.match(_Key, _HatredValueName) then
                self.Log(_MethodName, "Key " .. tostring(_Key) .. " is a hatred value. Checking traits of faction it is associated with.")
                local _DecayBase = 0.01
                local _FactionIndex = _Key:split("_")[3]
                local _Faction = Faction(_FactionIndex)
                if _Faction then
                    local _Covetous = _Faction:getTrait("covetous")
                    local _Tempered = _Faction:getTrait("tempered")
                    if _Covetous and _Covetous >= 0.25 then
                        _DecayBase = _DecayBase * 1.5
                    else
                        self.Log(_MethodName, "Faction " .. tostring(_FactionIndex) .. " is not covetous.")
                    end
                    if _Tempered and _Tempered >= 0.25 then
                        _DecayBase = _DecayBase * 0.5
                    else
                        self.Log(_MethodName, "Faction " .. tostring(_FactionIndex) .. " is not tempered.")
                    end
                end
                local _NewHatredValue = math.floor(_Val * (1.0 - _DecayBase))
                self.Log(_MethodName, "Decaying hatred from faction " .. tostring(_FactionIndex) .. " from " .. tostring(_Val) .. " to " .. tostring(_NewHatredValue))
                _Player:setValue(_Key, _NewHatredValue)
            end
        end

        local _NextDecayTick = _ServerTime + self._OverallDecayTime
        _Player:setValue(_DecayTickValueName, _NextDecayTick)
    end
end

function ITBackground.unpauseEvents(_Frames)
    local _MethodName = "Unpause Events"
    
    _Frames = _Frames or 3
    self._UnpauseFrames = _Frames

    self.Log(_MethodName, "Running - frames is " .. tostring(_Frames))
end

function ITBackground.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[IT Background] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end