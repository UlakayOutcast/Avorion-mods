package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"

include ("randomext")
local DockAI = include ("ai/dock")

--Add debug info.
local _Debug = 0

local stationIndex = Uuid()
local stage
local waitCount
local tractorWaitCount

function getStationIndex()
    return stationIndex
end

function getUpdateInterval()
    return 2
end

function initialize(stationIndex_in)
    local _MethodName = "Initialize"
    Log(_MethodName, "Starting v4 of LLTE Supply AI script.")
    stationIndex = stationIndex_in or Uuid()
end

function updateServer(timeStep)
    local _MethodName = "Update Server"

    local ship = Entity()

    local station = Sector():getEntity(stationIndex)

    -- in case the station doesn't exist any more, leave the sector
    if not station then
        if ship.aiOwned then
            -- in case the station doesn't exist any more, leave the sector
            ship:addScript("ai/passsector.lua", random():getDirection() * 2000)
        end

        -- if this is a player / alliance owned ship, terminate the script
        terminate()
        return
    end

    local docks = DockingPositions(station)

    -- stages
    if not valid(docks) or docks.numDockingPositions == 0 or not docks.docksEnabled then
        -- something is not right, abort
        startFlyAway()
        return
    end

    stage = stage or 0

    -- stage 0 is flying towards the light-line
    if stage == 0 then
        local flyToDock, tractorActive = DockAI.flyToDock(ship, station)

        if flyToDock then
            stage = 2
        end

        if tractorActive then
            tractorWaitCount = tractorWaitCount or 0
            tractorWaitCount = tractorWaitCount + timeStep
            ship:setValue("_escc_Transfer_Initiated", 1)

            if tractorWaitCount > 2 * 60 then -- seconds

                docks:stopPulling(ship)
                startFlyAway()
            end
        end
    end

    -- stage 2 is tranferring supplies.
    if stage == 2 then
        local _SupplyRemaining = ship:getValue("_escc_Mission_Supply")
        local _SupplyTransfer = ship:getValue("_escc_SupplyTransferPerCycle")

        if _SupplyRemaining and _SupplyTransfer then
            if _SupplyRemaining > 0 then
                local _SupplyToTransfer = 0
                --Set the amount to transfer - if the amount remaining is less than the transfer rate, just use the amount remaining
                --Otherwise, use the transfer rate.
                if _SupplyRemaining < _SupplyTransfer then 
                    _SupplyToTransfer = _SupplyRemaining 
                else 
                    _SupplyToTransfer = _SupplyTransfer 
                end
                Log(_MethodName, "Transferring " .. tostring(_SupplyToTransfer) .. " supply.")
                ship:setValue("_escc_Mission_Supply", _SupplyRemaining - _SupplyToTransfer)

                local _StationSupply = station:getValue("_escc_Mission_Supply") or 0
                Log(_MethodName, "Station supply is " .. tostring(_StationSupply))
                _StationSupply = _StationSupply + _SupplyToTransfer
                Log(_MethodName, "Station supply is " .. tostring(_StationSupply) .. " after transfer.")
                station:setValue("_escc_Mission_Supply", _StationSupply)
            else
                Log(_MethodName, "Successfully transferred supplies. Leaving area.")
                stage = 3 
            end
        else
            Log(_MethodName, "Successfully transferred supplies. Leaving area.")
            stage = 3
        end
    end

    -- fly back to the end of the lights
    if stage == 3 then
        if DockAI.flyAwayFromDock(ship, station) then
            startFlyAway()
        end
    end
end

function startFlyAway()
    -- player crafts should NEVER fly away since this will DELETE the ship
    local faction = Faction()
    if faction and (faction.isPlayer or faction.isAlliance) then
        print ("Warning: A player craft wanted to enter trader fly away stage")
        terminate()
        return
    end

    Entity():addScript("ai/passsector.lua", random():getDirection() * 1500)
    terminate()
end

--region #SECURE / RESTORE

function restore(values)
    stationIndex = Uuid(values.stationIndex)
    script = values.script
    stage = values.stage
    waitCount = values.waitCount

    DockAI.restore(values)
end

function secure()
    local values =
    {
        stationIndex = stationIndex.string,
        script = script,
        stage = stage,
        waitCount = waitCount,
    }

    DockAI.secure(values)

    return values
end

--endregion

--region #LOGGING

function Log(_MethodName, _Msg)
    if _Debug == 1 then
        print("[ESCC Supply AI] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion