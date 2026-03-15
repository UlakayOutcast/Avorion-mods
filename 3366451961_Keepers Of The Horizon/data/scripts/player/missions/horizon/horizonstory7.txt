--[[
    MISSION 7: Kermit Tyler's Folly
]]
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")
include("structuredmission")

ESCCUtil = include("esccutil")
HorizonUtil = include("horizonutil")

local SectorGenerator = include ("SectorGenerator")
local PirateGenerator = include("pirategenerator")
local AsyncPirateGenerator = include ("asyncpirategenerator")
local Balancing = include ("galaxy")
local SpawnUtility = include ("spawnutility")
local Placer = include("placer")

mission._Debug = 0
mission._Name = "Kermit Tyler's Folly"

--region #INIT / DATA

--Standard mission data.
mission.data.brief = mission._Name
mission.data.title = mission._Name
mission.data.autoTrackMission = true
mission.data.icon = "data/textures/icons/snowflake-2.png"
mission.data.priority = 9
mission.data.description = {
    { text = "The Horizon Keeper fleet has been crippled by the loss of their battleships and a number of their cruisers. The path forward is now clear - assault the Horizon Keepers shipyard and infiltrate their network." },
    { text = "Read Varlance's mail", bulletPoint = true, fulfilled = false },
    { text = "Head to sector (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Join Sophie in sector (${_X}:${_Y})", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Stay undetected", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Recommended) Stay at least 30 km from the Military Outpost", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Escort the freighter", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Defend the freighter", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Defend the shipyard", bulletPoint = true, fulfilled = false, visible = false },
    { text = "(Recommended) Make sure the freighter is safe before attacking the Artillery Cruisers", bulletPoint = true, fulfilled = false, visible = false },
    { text = "Leave before reinforcements arrive", bulletPoint = true, fulfilled = false, visible = false }
}

--Custom data that we'll want.
mission.data.custom.dangerLevel = 10 --Key everything off of danger 10.
mission.data.custom.phase4Timer = 0
mission.data.custom.phase4DialogSent = false
mission.data.custom.phase5MiloutpostMinDist = 3000 --30 km
--Ships get highlighted if they're less than highlight range - they are highlighted in red if they are @ urgent range.
mission.data.custom.phase5ShipHighlightRange = 2000 --20 km
mission.data.custom.phase5ShipUrgentHighlightRange = 1500 --15 km
mission.data.custom.phase5Timer = 0
mission.data.custom.phase5Chatter1Sent = false
mission.data.custom.phase5Chatter2Sent = false
mission.data.custom.phase5Chatter3Sent = false
mission.data.custom.phase5Chatter4Sent = false
mission.data.custom.phase5Chatter5Sent = false
mission.data.custom.phase5Chatter6Sent = false
mission.data.custom.phase5Chatter7Sent = false
mission.data.custom.phase5Chatter8Sent = false
mission.data.custom.phase5Chatter9Sent = false
mission.data.custom.phase5Chatter10Sent = false
mission.data.custom.waveState = 1
mission.data.custom.waveNumber = 1
mission.data.custom.phase6Chatter1Sent = false
mission.data.custom.phase7Timer = 0
mission.data.custom.phase7FinishEventDone = false

--endregion

--region #PHASE CALLS

mission.globalPhase.timers = {}

mission.globalPhase.noBossEncountersTargetSector = true
mission.globalPhase.noPlayerEventsTargetSector = true
mission.globalPhase.noLocalPlayerEventsTargetSector = true

mission.globalPhase.onAbandon = function()
    kothStory7_clearShipyardCargo()
    
    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onFail = function()
    kothStory7_sendFailureMail()
    kothStory7_clearShipyardCargo()

    if mission.data.location then
        runFullSectorCleanup(true)
    end
end

mission.globalPhase.onAccomplish = function()
    if mission.data.location then
        runFullSectorCleanup(false)
    end
end

mission.globalPhase.onTargetLocationEntered = function(_X, _Y)
    mission.data.timeLimit = nil 
    mission.data.timeLimitInDescription = false
end

mission.globalPhase.onTargetLocationLeft = function(_X, _Y)
    local phIndex = mission.internals.phaseIndex
    --Fail immediately in the stealth phases.
    if phIndex == 4 or phIndex == 5 then
        fail()
    elseif phIndex == 7 and mission.data.custom.phase7FinishEventDone then
        kothStory7_finishAndReward()
    else
        mission.data.timeLimit = mission.internals.timePassed + (5 * 60) --Player has 5 minutes to head back to the sector.
        mission.data.timeLimitInDescription = true --Show the player how much time is left.
    end
end

mission.phases[1] = {}
mission.phases[1].showUpdateOnEnd = true
mission.phases[1].onBeginServer = function()
    local _MethodName = "Phase 1 On Begin Server"
    --Get a sector that's very close to the outer edge of the barrier.
    mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))

    mission.data.custom.firstLocation = kothStory7_getNextLocation(true)

    local _X = mission.data.custom.firstLocation.x
    local _Y = mission.data.custom.firstLocation.y

    mission.data.description[3].arguments = { _X = mission.data.custom.firstLocation.x, _Y = mission.data.custom.firstLocation.y }
    
    --Send mail to player.
    local _Player = Player()
    local _Mail = Mail()
	_Mail.text = Format("Hey buddy,\n\nMy teams have been looking through all of the information we pulled off of the prototype weapons. It looks like most of it was blown up with their ships, but we did find a few interesting tidbits. Mostly related to something called \"Project XSOLOGIZE\". The only complete information we pulled was a schedule. It looks like its nearing completion. If it's anything like those prototypes we fought earlier, we can't let Horizon Keepers unleash this - the galaxy will be forced to bend the knee or face a level of suffering and death we haven't seen since the Great War.\n\nFortunately, this doesn't change our plans. We captured a freighter and we'll be using it to infiltrate their shipyard. We're going to have to be careful about how we approach this - if we've learned anything over the last few sorties it's that these bastards are quick to delete whatever information is in their databanks.\n\nCome to (%1%:%2%). I'll go over the plan with you.\n\nVarlance", _X, _Y)
	_Mail.header = "It's Time"
	_Mail.sender = "Varlance @FrostbiteCompany"
	_Mail.id = "_horizon_story7_mail"
	_Player:addMail(_Mail)
end

mission.phases[1].playerCallbacks = {
	{
		name = "onMailRead",
		func = function(_PlayerIndex, _MailIndex)
			if onServer() then
				local _Player = Player()
				local _Mail = _Player:getMail(_MailIndex)
				if _Mail.id == "_horizon_story7_mail" then
					nextPhase()
				end
			end
		end
	}
}

mission.phases[2] = {}
mission.phases[2].showUpdateOnEnd = true
mission.phases[2].onBegin = function()
    local _MethodName = "Phase 2 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.location = mission.data.custom.firstLocation

    mission.data.description[2].fulfilled = true
    mission.data.description[3].visible = true
end

mission.phases[2].onTargetLocationEntered = function(_x, _y)
    if onServer() then
        kothStory7_spawnVarlance()
    end
end

mission.phases[2].onTargetLocationArrivalConfirmed = function(_x, _y)
    --Start varlance dialog, then go to phase 3.
    invokeClientFunction(Player(), "kothStory7_onPhase2Dialog", mission.data.custom.varlanceID)
end

local kothStory7_onPhase2DialogEnd = makeDialogServerCallback("kothStory7_onPhase2DialogEnd", 2, function()
    mission.data.custom.secondLocation = kothStory7_getNextLocation(false)

    mission.data.description[4].arguments = { _X = mission.data.custom.secondLocation.x, _Y = mission.data.custom.secondLocation.y }

    local varlance = Entity(mission.data.custom.varlanceID)
    varlance:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(4, 7))

    Player():setValue("_horizonkeepers_story7_heardplan", true)

    nextPhase()
end)

mission.phases[3] = {}
mission.phases[3].showUpdateOnEnd = true
mission.phases[3].onBegin = function()
    local _MethodName = "Phase 3 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.location = mission.data.custom.secondLocation

    mission.data.description[3].fulfilled = true
    mission.data.description[4].visible = true
end

mission.phases[3].onTargetLocationEntered = function(x, y)
    if onServer() then
        local _player = Player()
        if _player:hasScript("events/alienattack.lua") then
            _player:removeScript("events/alienattack.lua")
            _player:sendChatMessage("", 3, "The subspace signals abruptly fade from your sensors.")
        end

        kothStory7_buildObjectiveSector(x, y)
    end
end

mission.phases[3].onTargetLocationArrivalConfirmed = function(_x, _y)
    --Start varlance dialog, then go to phase 3.
    HorizonUtil.varlanceChatter("<Secure Channel> Sophie here. That military installation is making me nervous. Don't get within 30 klicks or it could blow our cover. If we get hailed, just follow my lead.")
    nextPhase()
end

mission.phases[4] = {}
mission.phases[4].showUpdateOnEnd = true
mission.phases[4].onBegin = function()
    local _MethodName = "Phase 4 On Begin"
    mission.Log(_MethodName, "Beginning...")

    mission.data.location = mission.data.custom.secondLocation

    mission.data.description[4].fulfilled = true
    mission.data.description[5].visible = true
    mission.data.description[6].visible = true
    mission.data.description[7].visible = true
end

mission.phases[4].onBeginServer = function()
    --Order sophie and the freighter within 20 km of the station.
    local sophie = Entity(mission.data.custom.varlanceID)
    local freighter = Entity(mission.data.custom.freighterID)
    local shipyard = Entity(mission.data.custom.shipyardID)

    local orderTable = { sophie, freighter }

    for _, ship in pairs(orderTable) do
        local ai = ShipAI(ship)
        ai:setFlyLinear(shipyard.translationf, 2000, false)
    end
end

mission.phases[4].updateTargetLocationServer = function(timeStep)
    --after 30 seconds, hail player.
    mission.data.custom.phase4Timer = mission.data.custom.phase4Timer + timeStep

    if mission.data.custom.phase4Timer >= 30 and not mission.data.custom.phase4DialogSent then
        mission.data.custom.phase4DialogSent = true

        invokeClientFunction(Player(), "kothStory7_onPhase4Dialog", mission.data.custom.militaryOutpostID)
    end
end

mission.phases[4].onEntityDestroyed = function(id, lastDamageInflictor)
    --No idea how it gets nuked in p4 but y'know just in case.
    if id == mission.data.custom.freighterID then
        kothStory7_onFreighterDestroyed()
    end
end

local kothStory7_onPhase4DialogEndGood = makeDialogServerCallback("kothStory7_onPhase4DialogEndGood", 4, function()
    nextPhase()
end)

local kothStory7_onPhase4DialogEndBad = makeDialogServerCallback("kothStory7_oonPhase4DialogEndBad", 4, function()
    --next, every horizon ship becomes hostile
    --add a powerful defense controller to the sector.
    kothStory7_onStealthBroken(true)

    --next, fail the mission.
    fail()
end)

mission.phases[5] = {}
mission.phases[5].timers = {}
mission.phases[5].sectorCallbacks = {}
mission.phases[5].showUpdateOnEnd = true
mission.phases[5].onBeginServer = function()
    local _MethodName = "Phase 5 On Begin Server"
    mission.Log(_MethodName, "Beginning...")

    --Welcome to the stealth section!
    local freighter = Entity(mission.data.custom.freighterID)
    local shipyard = Entity(mission.data.custom.shipyardID)

    local radius = shipyard:getBoundingSphere().radius

    local ai = ShipAI(freighter)
    ai:setFlyLinear(shipyard.translationf, radius * 3, false)
end

mission.phases[5].onPreRenderHud = function()
    if atTargetLocation() then
        kothStory7_onMarkCloseShips()
    end
end

mission.phases[5].updateTargetLocationServer = function(timeStep)
    local _MethodName = "Phase 5 Update Target Location Server"

    local freighter = Entity(mission.data.custom.freighterID)
    local shipyard = Entity(mission.data.custom.shipyardID)

    local _sector = Sector()

    local dist = 0
    if freighter then 
        dist = shipyard:getNearestDistance(freighter)
    else
        kothStory7_onFreighterDestroyed()
    end

    if dist <= 500 then
        mission.data.custom.phase5Timer = mission.data.custom.phase5Timer + timeStep

        if mission.data.custom.phase5Timer >= 30 and not mission.data.custom.phase5Chatter1Sent then
            mission.data.custom.phase5Chatter1Sent = true

            mission.Log(_MethodName, "Sending message 1")

            _sector:broadcastChatMessage(freighter, ChatMessageType.Chatter, "<Secure Channel> Entry seal set. Cutting charges set. We'll be in shortly.")
        end

        if mission.data.custom.phase5Timer >= 60 and not mission.data.custom.phase5Chatter2Sent then
            mission.data.custom.phase5Chatter2Sent = true
            
            mission.Log(_MethodName, "Sending message 2")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> We're in. We've set up a relay node - any comms traffic should look like targeting or diagnostic info.")
        end

        if mission.data.custom.phase5Timer >= 90 and not mission.data.custom.phase5Chatter3Sent then
            mission.data.custom.phase5Chatter3Sent = true
            
            mission.Log(_MethodName, "Sending message 3")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> Found a terminal. Attempting to gain admin access...")
        end

        if mission.data.custom.phase5Timer >= 105 and not mission.data.custom.phase5Chatter10Sent then
            mission.data.custom.phase5Chatter10Sent = true

            mission.Log(_MethodName, "Sending message 10")

            HorizonUtil.varlanceChatter("<Secure Channel> The ships here are looking pretty ramshackle. They don't even have a Raider class - Horizon must be really hurting for forces.")
        end

        if mission.data.custom.phase5Timer >= 120 and not mission.data.custom.phase5Chatter4Sent then
            mission.data.custom.phase5Chatter4Sent = true
            
            mission.Log(_MethodName, "Sending message 4")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> Got it! Downloading the data now!")
        end

        if mission.data.custom.phase5Timer >= 150 and not mission.data.custom.phase5Chatter5Sent then
            mission.data.custom.phase5Chatter5Sent = true
            
            mission.Log(_MethodName, "Sending message 5")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> We got the data, but... uh oh.")
        end

        if mission.data.custom.phase5Timer >= 160 and not mission.data.custom.phase5Chatter6Sent then
            mission.data.custom.phase5Chatter6Sent = true
            
            mission.Log(_MethodName, "Sending message 6")

            HorizonUtil.varlanceChatter("<Secure Channel> \"Uh oh\"? I don't like \"uh oh\". Give me a sitrep.")
        end

        if mission.data.custom.phase5Timer >= 180 and not mission.data.custom.phase5Chatter7Sent then
            mission.data.custom.phase5Chatter7Sent = true

            mission.Log(_MethodName, "Sending message 7")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> There's alarms going off everywhere! What do you mean we \"tripped a network alert\"?")
        end

        if mission.data.custom.phase5Timer >= 210 and not mission.data.custom.phase5Chatter8Sent then
            mission.data.custom.phase5Chatter8Sent = true

            mission.Log(_MethodName, "Sending message 8")

            _sector:broadcastChatMessage(shipyard, ChatMessageType.Chatter, "<Secure Channel> Shit. Security?! We're going to have to fight our way out!")
        end

        if mission.data.custom.phase5Timer >= 225 and not mission.data.custom.phase5Chatter9Sent then
            --once you see this, you don't need to worry about detection anymore, but you stil can't start blowing stuff up yet!
            mission.data.custom.phase5Chatter9Sent = true

            mission.Log(_MethodName, "Sending message 9")

            HorizonUtil.varlanceChatter("They know we're here now, Captain! No more point in stealth - warm those guns up!")
        end

        if mission.data.custom.phase5Timer >= 230 then
            nextPhase()
        end
    end
end

mission.phases[5].onEntityDestroyed = function(id, lastDamageInflictor)
    local destroyer = Entity(lastDamageInflictor)

    if id == mission.data.custom.freighterID then
        kothStory7_onFreighterDestroyed()
    end

    if destroyer and valid(destroyer) then
        local _player = Player()
        
        if destroyer.factionIndex == _player.index then
            kothStory7_onStealthBroken(true)
            fail()
        end

        if _player.allianceIndex and destroyer.factionIndex == _player.allianceIndex then
            kothStory7_onStealthBroken(true)
            fail()
        end
    end
end

--region #PHASE 5 CALLBACK CALLS

mission.phases[5].sectorCallbacks[1] = {
    name = "startHorizon7StealthTimer",
    func = function(defenderidx, playershipidx)
        local _MethodName = "Phase 5 Custom Callback 1"
        mission.Log(_MethodName, "Calling.")

        local pShip = Entity(playershipidx)
        local eShip = Entity(defenderidx)
        
        Player():sendChatMessage("", 3, "Your ship ${_PLAYERSHIP} is too close to the Horizon ship ${_ENEMYSHIP}. Move 10 km away before it can scan you." % { _PLAYERSHIP = pShip.name, _ENEMYSHIP = eShip.name})
        --Check timer slots 6 to 30. Use the first one that's available (timer 3 runs cleanup)
        local _MINTIMERSLOT = 6
        local _MAXTIMERSLOT = 30

        for tidx = _MINTIMERSLOT, _MAXTIMERSLOT do
            if not mission.phases[5].timers[tidx] then
                mission.phases[5].timers[tidx] = {
                    time = 15,
                    callback = function()
                        local _MethodName = "Phase 5 Timer [6 to 30]"
                        mission.Log(_MethodName, "Calling.")

                        local _sector = Sector()

                        if atTargetLocation() then
                            local playerEntities = { _sector:getEntitiesByFaction(Player().index) }
                            local playerShips = {}
                            for _, _e in pairs(playerEntities) do
                                if _e.type == EntityType.Ship then
                                    table.insert(playerShips, _e)
                                end
                            end
                            local defenderShips = { _sector:getEntitiesByScriptValue("is_horizon_defender") }
    
                            for _, pShip in pairs(playerShips) do
                                for _, dShip in pairs(defenderShips) do
                                    --same as sus script. Distance needed is decreased by chameleon.
                                    local baseDist = 1000

                                    local dist = pShip:getNearestDistance(dShip)
                                    if dist <= baseDist then --Don't bother doing any of this unless we're even within 10km. Waste of processing power otherwise.
                                        local adjDist = baseDist
                                        local ret, detectionRangeFactor = pShip:invokeFunction("internal/dlc/blackmarket/systems/badcargowarningsystem.lua", "getDetectionRangeFactor")
                                        if ret == 0 then
                                            adjDist = baseDist * detectionRangeFactor
                                        end

                                        if dist <= adjDist then
                                            kothStory7_onStealthBroken(true)
                                            fail()
                                        end
                                    end
                                end
                            end
                        end
                    end,
                    repeating = false
                }
                break
            end
        end
    end
}

--endregion

--region #PHASE 5 TIMER CALLS

--TIMER SLOTS
--1 = is player within 30km of the military outpost? alternately, check to see if the outpost's shields are damaged.
--2 = every 30 seconds, clear all stopped timers from idx 3 to 30
--3 = is the player within 20km of the freighter? if not, start a timer to fail.
--4 = 20 seconds until military outpost breaks stealth - set in timer 1.
--5 = 20 seconds until player needs to get back within 20 km of freighter - set in timer 3.
--6 to 30 = 10 seconds until defender breaks stealth - set via a sent callback.

if onServer() then

mission.phases[5].timers[1] = {
    time = 10,
    callback = function()
        local _sector = Sector()
        if atTargetLocation() then
            local militaryOutpost = Entity(mission.data.custom.militaryOutpostID)
            local playerEntities = { _sector:getEntitiesByFaction(Player().index) }
            local playerShips = {}
            for _, _e in pairs(playerEntities) do
                if _e.type == EntityType.Ship then
                    table.insert(playerShips, _e)
                end
            end

            --Start a timer if the player is within 30km of the outpost.
            --This actually be one of the most tortured pieces of logic I've ever written but damn if it doesn't work.
            local _TIMERSLOT = 4

            for _, pShip in pairs(playerShips) do
                local dist = militaryOutpost:getNearestDistance(pShip)
                if dist <= mission.data.custom.phase5MiloutpostMinDist and not mission.phases[5].timers[_TIMERSLOT] then
                    Player():sendChatMessage("", 3, "Your ship is too close to the Military Installation. Move 30 km away before it can scan you.")
                    --add timer slot 3 - if the player is still within 30km of the outpost in 30 seconds, fail.
                    mission.phases[5].timers[_TIMERSLOT] = {
                        time = 20,
                        callback = function()
                            local _MethodName = "Phase 5 Timer 3 Callback"
                            mission.Log(_MethodName, "Calling.")

                            local _sector = Sector()

                            if atTargetLocation() then
                                local militaryOutpost = Entity(mission.data.custom.militaryOutpostID)
                                local playerEntities = { _sector:getEntitiesByFaction(Player().index) }
                                local playerShips = {}
                                for _, _e in pairs(playerEntities) do
                                    if _e.type == EntityType.Ship then
                                        table.insert(playerShips, _e)
                                    end
                                end

                                for _, pShip in pairs(playerShips) do
                                    local dist = militaryOutpost:getNearestDistance(pShip)
                                    if dist <= mission.data.custom.phase5MiloutpostMinDist then
                                        kothStory7_onStealthBroken(true)
                                        fail()
                                    end
                                end
                            end
                        end,
                        repeating = false
                    }
                end
            end

            --Also, check to see if the outpost's shields are damaged.
            local shieldPct = militaryOutpost.shieldDurability / militaryOutpost.shieldMaxDurability
            if shieldPct <= 0.95 then
                kothStory7_onStealthBroken(true)
                fail()
            end
        end
    end,
    repeating = true
}

mission.phases[5].timers[2] = {
    time = 30,
    callback = function()
        local _MethodName = "Phase 5 Timer 2 Callback"

        local _MINTIMERSLOT = 4
        local _MAXTIMERSLOT = 30

        for tidx = _MINTIMERSLOT, _MAXTIMERSLOT do
            --Clearing stopped timers.
            if mission.phases[5].timers[tidx] and mission.phases[5].timers[tidx].stopped then
                mission.Log(_MethodName, "Cleaning timer " .. tostring(tidx))
                mission.phases[5].timers[tidx] = nil
            end
        end
    end,
    repeating = true
}

mission.phases[5].timers[3] = {
    time = 10,
    callback = function()
        local _sector = Sector()
        if atTargetLocation() then
            local freighter = Entity(mission.data.custom.freighterID)
            local playerEntities = { _sector:getEntitiesByFaction(Player().index) }
            local playerShips = {}
            for _, _e in pairs(playerEntities) do
                if _e.type == EntityType.Ship then
                    table.insert(playerShips, _e)
                end
            end
    
            --need to have at least 1 player ship within 20 km of the freighter.
            local escortOK = false
            for _, pShip in pairs(playerShips) do
                local dist  = 0
                if freighter then
                    dist = freighter:getNearestDistance(pShip)
                else
                    kothStory7_onFreighterDestroyed()
                end
                if dist <= 2000 then
                    escortOK = true
                    break
                end
            end
            
            local _TIMERSLOT = 5

            if not escortOK and not mission.phases[5].timers[_TIMERSLOT] then
                Player():sendChatMessage("", 3, "You are too far from the freighter. Stay within 20km of it or Horizon will get suspicious.")

                mission.phases[5].timers[_TIMERSLOT] = {
                    time = 20,
                    callback = function()
                        local _sector = Sector()

                        if atTargetLocation() then
                            local freighter = Entity(mission.data.custom.freighterID)
                            local playerEntities = { _sector:getEntitiesByFaction(Player().index) }
                            local playerShips = {}
                            for _, _e in pairs(playerEntities) do
                                if _e.type == EntityType.Ship then
                                    table.insert(playerShips, _e)
                                end
                            end

                            local escortOK = false
                            for _, pShip in pairs(playerShips) do
                                local dist = freighter:getNearestDistance(pShip)
                                if dist <= 2000 then
                                    escortOK = true
                                    break
                                end
                            end

                            if not escortOK then
                                kothStory7_onStealthBroken(true)
                                fail()
                            end
                        end
                        
                    end,
                    repeating = false
                }
            end
        end

    end,
    repeating = true
}

end

--endregion

mission.phases[6] = {}
mission.phases[6].timers = {}
mission.phases[6].showUpdateOnEnd = true
mission.phases[6].onBegin = function()
    local _MethodName = "Phase 6 On Begin"
    mission.Log(_MethodName, "Beginning...")
    
    mission.data.description[5].fulfilled = true
    mission.data.description[6].fulfilled = true
    mission.data.description[7].fulfilled = true
    mission.data.description[8].visible  = true
    mission.data.description[9].visible  = true
end

mission.phases[6].onBeginServer = function()
    local _MethodName = "Phase 6 On Begin Server"
    mission.Log(_MethodName, "Beginning...")

    kothStory7_onStealthBroken(false)

    local frostbiteFaction = HorizonUtil.getFriendlyFaction()
    local shipyard = Entity(mission.data.custom.shipyardID)
    shipyard.factionIndex = frostbiteFaction.index

    local sophie = Entity(mission.data.custom.varlanceID)
    local sophieAI = ShipAI(sophie)
    sophieAI:registerFriendEntity(mission.data.custom.militaryOutpostID)
    sophieAI:setAggressive()

    HorizonUtil.varlanceChatter("We need to buy time for the boarding team! Make sure Horizon doesn't wipe out the shipyard.")

    invokeClientFunction(Player(), "kothStory7_changeOutpostTrack", mission.data.custom.militaryOutpostID)
end

mission.phases[6].updateTargetLocationServer = function()
    local _MethodName = "Phase 6 Update Target Location Server"

    local horizonCt = ESCCUtil.countEntitiesByValue("is_horizon_ship")
    if horizonCt == 0 then
        if mission.data.custom.waveState == 2 then
            mission.Log(_MethodName, "Sending freighter chat for " .. tostring(mission.data.custom.waveNumber) .. " and resetting wave state.")

            local lineidx = mission.data.custom.waveNumber - 1
            local msgFuncs = {
                function()
                    local shipyard = Entity(mission.data.custom.shipyardID)
                    Sector():broadcastChatMessage(shipyard, ChatMessageType.Chatter, "We're pinned down! Attempting breakout now!")
                end,
                function()
                    local shipyard = Entity(mission.data.custom.shipyardID)
                    Sector():broadcastChatMessage(shipyard, ChatMessageType.Chatter, "Meeting fierce resistance. We need a little longer, Captain!")
                end,
                function()
                    local freighter = Entity(mission.data.custom.freighterID)
                    Sector():broadcastChatMessage(freighter, ChatMessageType.Chatter, "Team has made it back to the ship! Setting hyperspace coordinates now!")
                end
            }

            msgFuncs[lineidx]()

            mission.data.custom.waveState = 3
        elseif mission.data.custom.waveState == 3 then
            mission.Log(_MethodName, "Resetting wave state. Ships may spawn now.")
            mission.data.custom.waveState = 1
        end

        if mission.data.custom.waveNumber == 4 then
            nextPhase()
        end
    end
end

mission.phases[6].onEntityDestroyed = function(id, lastDamageInflictor)
    if id == mission.data.custom.freighterID then
        kothStory7_onFreighterDestroyed()
    end

    if id == mission.data.custom.shipyardID then
        kothStory7_onShipyardDestroyed()
    end
end

--region #PHASE 6 TIMER CALLS

if onServer() then

mission.phases[6].timers[1] = {
    time = 60,
    callback = function()
        local _MethodName = "Phase 6 Timer 1 Callback"
        mission.Log(_MethodName, "Running...")

        --Don't do anything if we're not on location. Technically not needed since the player jumping out fails the mission at this point.
        if atTargetLocation() then
            if mission.data.custom.waveState == 1 and mission.data.custom.waveNumber < 4 then
                mission.Log(_MethodName, "Spawning pirate wave " .. tostring(mission.data.custom.waveNumber))
                kothStory7_spawnPirateWave(mission.data.custom.waveNumber == 3)
                if mission.data.custom.waveNumber == 3 then
                    kothStory7_spawnHorizonWave()
                end

                mission.data.custom.waveNumber = mission.data.custom.waveNumber + 1
            end
        end
    end,
    repeating = true
}

mission.phases[6].timers[2] = {
    time = 15,
    callback = function()
        if atTargetLocation() and not mission.data.custom.phase6Chatter1Sent then
            mission.data.custom.phase6Chatter1Sent = true

            local militaryOutpost = Entity(mission.data.custom.militaryOutpostID)

            Sector():broadcastChatMessage(militaryOutpost, ChatMessageType.Chatter, "<Intercepted> ALERT! Project XSOLOGIZE data has been compromised! Situation critical! Send response team NOW! ALERT!")
        end
    end,
    repeating = true
}

end

--endregion

mission.phases[7] = {}
mission.phases[7].onBegin = function()
    mission.data.description[9].fulfilled = true
    mission.data.description[10].fulfilled = true
end

mission.phases[7].onBeginServer = function()
    local _MethodName = "Phase 7 On Begin Server"
    mission.Log(_MethodName, "Running...")
    
    local shipyard = Entity(mission.data.custom.shipyardID)
    local horizonFaction = HorizonUtil.getEnemyFaction()

    shipyard.factionIndex = horizonFaction.index

    local freighter = Entity(mission.data.custom.freighterID)

    local frPos = freighter.translationf

    local dir = freighter.look * -1 --should be right behind it.
    local frMoveToPos = frPos + (dir * 20000)

    local freighterAI = ShipAI(freighter)
    freighterAI:setFlyLinear(frMoveToPos, 0, false)
end

mission.phases[7].updateTargetLocationServer = function(timeStep)
    mission.data.custom.phase7Timer = mission.data.custom.phase7Timer + timeStep

    if mission.data.custom.phase7Timer >= 15 and not mission.data.custom.phase7FinishEventDone then
        mission.data.custom.phase7FinishEventDone = true --Keep from broadcasting twice.

        local freighter = Entity(mission.data.custom.freighterID)
        local sophie = Entity(mission.data.custom.varlanceID)

        HorizonUtil.varlanceChatter("Jumping out now, Captain - I'd suggest you do the same! We'll be in touch!")

        freighter:addScriptOnce("utility/delayeddelete.lua", random():getFloat(4, 7))
        sophie:addScriptOnce("utility/delayeddelete.lua", random():getFloat(4, 7))

        kothStory7_addDefenseController(Sector())

        mission.data.description[8].fulfilled = true
        mission.data.description[11].visible = true

        sync()
    end
end

--endregion

--region #SERVER CALLS

function kothStory7_getNextLocation(_onBlockRing)
    local _MethodName = "Get Next Location"
    
    mission.Log(_MethodName, "Getting a location.")
    local x, y = Sector():getCoordinates()
    local target = {}

    if _onBlockRing then
        --Get a sector that's very close to the outer edge of the barrier.
        mission.Log(_MethodName, "BlockRingMax is " .. tostring(Balancing.BlockRingMax))
        local _Nx, _Ny = ESCCUtil.getPosOnRing(x, y, Balancing.BlockRingMax + 10)
        target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 2, 4, false)
        local _safetyBreakout = 0
        while target.x == x and target.y == y and _safetyBreakout <= 100 do
            target.x, target.y = MissionUT.getEmptySector(_Nx,_Ny, 2, 4, false)
            _safetyBreakout = _safetyBreakout + 1
        end
    else
        target.x, target.y = MissionUT.getEmptySector(x, y, 4, 8, false)
    end

    mission.Log(_MethodName, "X coordinate of next location is : " .. tostring(target.x) .. " Y coordinate of next location is : " .. tostring(target.y))
    if not target or not target.x or not target.y then
        mission.Log(_MethodName, "Could not find a suitable mission location. Terminating script.")
        terminate()
        return
    end

    return target
end

function kothStory7_spawnVarlance()
    local _MethodName = "Spawn Varlance"
    
    local _spawnVarlance = true
    if mission.data.custom.varlanceID then
        local _Varlance = Entity(mission.data.custom.varlanceID)
        if _Varlance and valid(_Varlance) and not _Varlance:getValue("varlance_withdrawing") then
            _spawnVarlance = false
        end
    end

    if _spawnVarlance then
        mission.Log(_MethodName, "No Varlance in sector - spawning him in.")

        local _Varlance = HorizonUtil.spawnVarlanceBattleship(false)

        --It's incredibly unlikely that Varlance's ship takes enough damage to withdraw, so we may as well formalize it.
        local _VarlanceDurability = Durability(_Varlance)
        _VarlanceDurability.invincibility = 0.5

        mission.data.custom.varlanceID = _Varlance.index
    end
end

function kothStory7_spawnSophie()
    local _MethodName = "Spawn Sophie"
    
    kothStory7_spawnVarlance()

    local varlance = Entity(mission.data.custom.varlanceID)
    varlance.title = "Sophie's Ship"
    varlance.name = "Day In Hell"
end

function kothStory7_buildObjectiveSector(x, y)
    local _MethodName = "Build Objective Sector"
    mission.Log(_MethodName, "Beginning.")

    local _random = random()

    local _Generator = SectorGenerator(x, y)

    --Make asteroid fields.
    _Generator:createAsteroidField()

    local _fields = _random:getInt(3, 5)
    --Add: 3-5 small asteroid fields.
    for _ = 1, _fields do
        _Generator:createSmallAsteroidField()
    end

    --Make shipyard.
    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos = vec3(0, 0, 0)
    local _Player = Player()
    local _Ship = Entity(_Player.craftIndex)

    if _Ship then
        pos = _Ship.translationf
    end

    local sypos = ESCCUtil.getVectorAtDistance(pos, 3500, true)
    local symatrix = MatrixLookUpPosition(look, up, sypos)

    --Make military outpost approx. 30 km from shipyard and hopefully more than 30 km from player.
    local dir = normalize(sypos - pos)
    local bmopos = sypos + (dir * 3000)

    local mopos = ESCCUtil.getVectorAtDistance(bmopos, 1000, false)
    local momatrix = MatrixLookUpPosition(look, up, mopos)

    local sy = HorizonUtil.spawnHorizonShipyard1(false, symatrix)
    mission.data.custom.shipyardID = sy.index

    local mo = HorizonUtil.spawnMilitaryOutpost(false, momatrix)
    mission.data.custom.militaryOutpostID = mo.index
    local moDura = Durability(mo)
    moDura.invincibility = 0.94
    mo:setValue("_DefenseController_Manage_Own_Invincibility", true)
    mo:addScriptOnce("player/missions/horizon/story7/horizonstory7miloutpost.lua")

    local frostbiteFaction = HorizonUtil.getFriendlyFaction()
    local _HorizonFaction = HorizonUtil.getEnemyFaction()

    kothStory7_spawnSophie()
    --spawn horizon freighter, then turn it over to frostbite control.
    local sophie = Entity(mission.data.custom.varlanceID)

    local fPos = ESCCUtil.getVectorAtDistance(sophie.translationf, 1000, false)

    local freighter = HorizonUtil.spawnHorizonFreighter(false, MatrixLookUpPosition(sophie.look, sophie.up, fPos), frostbiteFaction)
    mission.data.custom.freighterID = freighter.index
    freighter:setValue("is_horizon", nil)
    freighter:setValue("is_horizon_ship", nil)
    freighter:setValue("is_horizon_freighter", nil)
    freighter:setValue("is_frostbite", true)
    freighter:setValue("is_frostbite_ship", true)
    freighter:setValue("is_frostbite_freighter", true)

    --spawn pirate defenders, then register everything as ally EXCEPT for the military outpost.
    --these guys aren't particularly intimidating - spawn @ danger 5.
    local _PirateTable = ESCCUtil.getStandardWave(mission.data.custom.dangerLevel / 2, 12, "Low")
    local _CreatedPirateTable = {}
    local _AIManipulationTable = {}

    table.insert(_AIManipulationTable, sy)

    for _, _Pirate in pairs(_PirateTable) do
        local pLook = _random:getVector(-100, 100)
        local pUp = _random:getVector(-100, 100)
        local pPos = ESCCUtil.getVectorAtDistance(sy.translationf, 1000, false)

        local _ship = PirateGenerator.createScaledPirateByName(_Pirate, MatrixLookUpPosition(pLook, pUp, pPos))
        _ship.factionIndex = _HorizonFaction.index
        _ship:setValue("is_horizon", true)
        _ship:setValue("is_horizon_defender", true)
        _ship:addScriptOnce("player/missions/horizon/story7/horizonstory7patrol.lua")        

        table.insert(_CreatedPirateTable, _ship)
        table.insert(_AIManipulationTable, _ship)
    end

    SpawnUtility.addEnemyBuffs(_CreatedPirateTable)

    Placer.resolveIntersections()

    --register all ships as friendly - use the swoks trick. Need this in case players bring in multiple ships.
    for _, _ship in pairs(_AIManipulationTable) do
        local allianceIndex = _Player.allianceIndex
        local ai = ShipAI(_ship)
        ai:registerFriendFaction(_Player.index)
        ai:registerFriendFaction(frostbiteFaction.index)
        if allianceIndex then
            ai:registerFriendFaction(allianceIndex)
        end
    end

    --Register frostbite as a friend faction for the military installation so they won't attack it.
    local mai = ShipAI(mo)
    mai:registerFriendFaction(frostbiteFaction.index)

    mission.data.custom.cleanUpSector = true
end

function kothStory7_onStealthBroken(runMissionFailed)
    local _sector = Sector()

    local horizonUnits = {_sector:getEntitiesByScriptValue("is_horizon")}
    for _, horizonShip in pairs(horizonUnits) do
        local horizonAI = ShipAI(horizonShip)
        horizonAI:clearFriendFactions()
        horizonAI:clearFriendEntities()
    end

    if runMissionFailed then
        --mission ends. first, frostbite ships immediately jump out
        HorizonUtil.varlanceChatter("They detected us! Break off! Break off!")
        local sophie = Entity(mission.data.custom.varlanceID)
        local freighter = Entity(mission.data.custom.freighterID)

        local orderTable = { sophie, freighter }

        for _, ship in pairs(orderTable) do
            ship:addScript("utility/delayeddelete.lua", random():getFloat(2, 3))
        end

        invokeClientFunction(Player(), "kothStory7_changeOutpostTrack", mission.data.custom.militaryOutpostID)

        kothStory7_addDefenseController(_sector)
    end
end

function kothStory7_spawnPirateWave(lastWave)
    --common vals
    local _WaveDanger = 5 + mission.data.custom.waveNumber
    local _Distance = 250 --_#DistAdj

    local _spawnFunc = function(onSpawnFunc, isAlpha, lastWave)
        local wingGenerator = AsyncPirateGenerator(nil, onSpawnFunc)
        wingGenerator.pirateLevel = mission.data.custom.pirateLevel

        local threatTable = "Low"
        if lastWave then
            threatTable = "Standard"
        end

        local _ct = 4
        if isAlpha then
            _ct = 3 --Alpha wing always has a jammer.
        end

        local wingTable = ESCCUtil.getStandardWave(_WaveDanger, _ct, threatTable, false)
        local wingPositions = wingGenerator:getStandardPositions(_Distance, _ct)
        if isAlpha then
            table.insert(wingTable, "Jammer")
        end

        wingGenerator:startBatch()

        for posIdx, _pirate in pairs(wingTable) do
            wingGenerator:createScaledPirateByName(_pirate, wingPositions[posIdx])
        end

        wingGenerator:endBatch()
    end

    --spawn alpha wing
    _spawnFunc(kothStory7_onSpawnAlphaWingFinished, true, lastWave)

    --spawn beta wing
    _spawnFunc(kothStory7_onSpawnBetaWingFinished, false, lastWave)
end

function kothStory7_spawnHorizonWave()
    local _MethodName = "Spawn Horizon Wave"
    mission.Log(_MethodName, "Beginning.")

    local _random = random()
    local horizonShipyard = Entity(mission.data.custom.shipyardID)
    local syPos = horizonShipyard.translationf
    local look = _random:getVector(-100, 100)
    local up = _random:getVector(-100, 100)
    local pos1 = ESCCUtil.getVectorAtDistance(syPos, 3000, true)
    local pos2 = ESCCUtil.getVectorAtDistance(pos1, 1000, false) --Get one reasonably close
    local pos3 = ESCCUtil.getVectorAtDistance(pos1, 1000, false)

    --Spawn 3 arty cruisers
    local _arty1 = HorizonUtil.spawnHorizonArtyCruiser(false, MatrixLookUpPosition(look, up, pos1), nil)
    local _arty2 = HorizonUtil.spawnHorizonArtyCruiser(false, MatrixLookUpPosition(look, up, pos2), nil)
    local _arty3 = HorizonUtil.spawnHorizonArtyCruiser(false, MatrixLookUpPosition(look, up, pos3), nil)

    Placer.resolveIntersections()

    local _artyTable = { _arty1, _arty2, _arty3 }
    for _, _arty in pairs(_artyTable) do
        local _artyAI = ShipAI(_arty)
        
        _artyAI:setIdle()
        _artyAI:setPassiveShooting(true)
        _artyAI:setFlyLinear(syPos, 2500, false)

        local tTag = "is_horizon_shipyard"

        local torpSlammerValues = {
            _TimeToActive = 5,
            _ROF = 4,
            _PreferWarheadType = 3, --Fusion
            _PreferBodyType = 7, --Osprey
            _DurabilityFactor = 4,
            _TargetPriority = 2, --Script value
            _TargetTag = tTag
        }

        local torpSlammerValues2 = {
            _TimeToActive = 20,
            _ROF = 2,
            _DamageFactor = 1.2,
            _PreferWarheadType = 3, --Fusion
            _PreferBodyType = 7, --Osprey
            _DurabilityFactor = 8,
            _TargetPriority = 2, --Script value
            _TargetTag = tTag,
            _AccelFactor = 1.5,
            _VelocityFactor = 1.5
        }

        local torpSlammerValues3 = {
            _TimeToActive = 40,
            _ROF = 2,
            _DamageFactor = 1.4,
            _PreferWarheadType = 3, --Fusion
            _PreferBodyType = 8, --Eagle
            _DurabilityFactor = 16,
            _TargetPriority = 2, --Script value
            _TargetTag = tTag,
            _AccelFactor = 2,
            _VelocityFactor = 2,
            _ShockwaveFactor = 2
        }

        --The death torps - the shipyard should fall to these pretty quickly.
        local torpSlammerValues4 = {
            _TimeToActive = 60,
            _ROF = 2,
            _DamageFactor = 1.6,
            _PreferWarheadType = 2, --Neutron
            _PreferBodyType = 9, --Hawk
            _DurabilityFactor = 72,
            _TargetPriority = 2, --Script value
            _TargetTag = tTag,
            _AccelFactor = 3,
            _VelocityFactor = 3,
            _ShockwaveFactor = 6
        }

        _arty:addScript("torpedoslammer.lua", torpSlammerValues)
        _arty:addScript("torpedoslammer.lua", torpSlammerValues2)
        _arty:addScript("torpedoslammer.lua", torpSlammerValues3)
        _arty:addScript("torpedoslammer.lua", torpSlammerValues4)
    end

    HorizonUtil.varlanceChatter("Ugh. This trick again. The station can take a few dings. Make sure the freigther is safe before you go for the cruisers.")
 
    mission.data.description[10].visible = true
    sync()
end

function kothStory7_onSpawnAlphaWingFinished(generated)
    mission.data.custom.waveState = 2

    --Attacks Varlance
    local _TargetPriorityData = {
        _TargetPriority = 1,
        _TargetTag = "is_frostbite_freighter"
    }

    local horizonFaction = HorizonUtil.getEnemyFaction()

    for _, _ship in pairs(generated) do
        _ship.factionIndex = horizonFaction.index
        _ship:setValue("is_horizon_ship", true)

        _ship:addScript("ai/priorityattacker.lua", _TargetPriorityData)
    end

    SpawnUtility.addEnemyBuffs(generated)

    Placer.resolveIntersections()
end

function kothStory7_onSpawnBetaWingFinished(generated)
    mission.data.custom.waveState = 2

    --Attacks the player
    local _TargetPriorityData = {
        _TargetPriority = 1,
        _TargetTag = "is_horizon_shipyard"
    }

    local horizonFaction = HorizonUtil.getEnemyFaction()

    for _, _ship in pairs(generated) do
        _ship.factionIndex = horizonFaction.index
        _ship:setValue("is_horizon_ship", true)

        _ship:addScript("ai/priorityattacker.lua", _TargetPriorityData)
    end

    SpawnUtility.addEnemyBuffs(generated)

    Placer.resolveIntersections()
end

function kothStory7_onFreighterDestroyed()
    local sophie = Entity(mission.data.custom.varlanceID)

    if sophie then
        HorizonUtil.varlanceChatter("We lost the freighter! Break off! Break off!")

        sophie:addScriptOnce("utility/delayeddelete.lua", random():getFloat(4, 7))
    end

    invokeClientFunction(Player(), "kothStory7_changeOutpostTrack", mission.data.custom.militaryOutpostID)

    fail()
end

function kothStory7_onShipyardDestroyed()
    local sophie = Entity(mission.data.custom.varlanceID)

    if sophie then
        HorizonUtil.varlanceChatter("We lost the shipyard! Break off! Break off!")

        sophie:addScriptOnce("utility/delayeddelete.lua", random():getFloat(4, 7))
    end

    local freighter = Entity(mission.data.custom.freighterID)

    if freighter and valid(freighter) then
        freighter:addScriptOnce("utility/delayeddelete.lua", random():getFloat(4, 7))
    end

    invokeClientFunction(Player(), "kothStory7_changeOutpostTrack", mission.data.custom.militaryOutpostID)

    fail()
end

function kothStory7_addDefenseController(_sector)
    local horizonFaction = HorizonUtil.getEnemyFaction()
    local defControlValues = {
        _DefenseLeader = mission.data.custom.militaryOutpostID,
        _DefenderCycleTime = 60,
        _DangerLevel = mission.data.custom.dangerLevel,
        _MaxDefenders = 12,
        _AllDefenderDamageScale = 2,
        _MaxDefendersSpawn = 6,
        _DefenderDistance = 5000,
        _LowTable = "High",
        _IsPirate = false,
        _Factionid = horizonFaction.index,
        _DefenderHPThreshold = 0.5,
        _DefenderOmicronThreshold = 0.5,
        _PreventLootDrop = true
    }

    _sector:addScriptOnce("sector/background/defensecontroller.lua", defControlValues)
end

function kothStory7_sendFailureMail()
    if not mission.data.custom.sentFailMail then
        local _player = Player()
        local _Mail = Mail()
        _Mail.text = Format("Hey buddy,\n\nThe op didn't go off as planned, but we can still hit a few more of their mercs. With enough losses, they'll have to change the guard dogs. When that happens, the new guys won't know anything about us. Between that and another opening I found in their shipping schedule, we can try to relaunch the op again later.\n\nI'll be in touch.\n\nVarlance")
        _Mail.header = "Mission Failed"
        _Mail.sender = "Varlance @FrostbiteCompany"
        _Mail.id = "_horizon_story7_mail3"
        _player:addMail(_Mail)

        mission.data.custom.sentFailMail = true
    end
end

function kothStory7_clearShipyardCargo()
    if atTargetLocation() then
        local horizonShipyard = Entity(mission.data.custom.shipyardID)
        if horizonShipyard and valid(horizonShipyard) then
            local syBay = CargoBay(horizonShipyard)
            syBay:clear()
        end
    end
end

function kothStory7_finishAndReward()
    local _MethodName = "Finish and Reward"
    mission.Log(_MethodName, "Running win condition.")

    local _player = Player()

    local _AccomplishMessage = "Frostbite Company thanks you. Here's your compensation."
    local _BaseReward = 53790000

    _player:setValue("_horizonkeepers_story_stage", 8)
    _player:setValue("encyclopedia_koth_sophie", true)

    _player:sendChatMessage("Frostbite Company", 0, _AccomplishMessage)
    mission.data.reward = {credits = _BaseReward, paymentMessage = "Earned %1% credits for stealing the data." }

    --Send the player a mail from Sophie.
    local _Mail = Mail()
	_Mail.text = Format("Hey Captain!\n\nIt's Sophie Netreba, from Frostbite. Just wanted to say that I enjoyed nabbing that data with you - nothing like a good stealth mission to get the blood pumping, yeah? Sorry for the abrupt exit, but it was only a matter of time before those reinforcements showed up! Varlance said he'd contact you when we manage to figure out what's up with this data. There's a lot to sort through and it looks like most of it is still encrypted, despite our precautions.\n\nLooking forward to next time!\n\nSophie")
	_Mail.header = "Good Times!"
	_Mail.sender = "Sophie @FrostbiteCompany"
	_Mail.id = "_horizon_story7_mail2"
	_player:addMail(_Mail)

    HorizonUtil.addFriendlyFactionRep(_player, 12500)

    reward()
    accomplish()
end

--endregion

--region #CLIENT CALLS

function kothStory7_onMarkCloseShips()
    local _MethodName = "On Mark Ships"

    local player = Player()
    if not player then return end

    local _Ship = Entity(player.craftIndex)

    if not _Ship then
        return
    end

    if player.state == PlayerStateType.BuildCraft or player.state == PlayerStateType.BuildTurret then return end

    local renderer = UIRenderer()

    local horizonShips = { Sector():getEntitiesByScriptValue("is_horizon_defender") }

    for _, ship in pairs(horizonShips) do
        local dist = ship:getNearestDistance(_Ship)
        if dist <= mission.data.custom.phase5ShipHighlightRange then
            local rColor = 255
            local bColor = 0
            local gColor = 127
            if dist <= mission.data.custom.phase5ShipUrgentHighlightRange then
                gColor = 0
            end

            local warningColor = ESCCUtil.getSaneColor(rColor, gColor, bColor)

            local _, size = renderer:calculateEntityTargeter(ship)

            renderer:renderEntityTargeter(ship, warningColor, size * 1.25)
            renderer:renderEntityArrow(ship, 30, 10, 250, warningColor)
        end
    end

    renderer:display()
end

--endregion

--region #CLIENT DIALOG CALLS

function kothStory7_changeOutpostTrack(outpostID)
    Entity(outpostID):invokeFunction("horizonstory7miloutpost.lua", "switchTracks")
end

function kothStory7_onPhase2Dialog(varlanceID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}
    local d7 = {}
    local d8 = {}

    local playerHeardPlan = Player():getValue("_horizonkeepers_story7_heardplan")

    d0.text = "Glad you could make it, buddy."
    d0.followUp = d1

    d1.text = "Here's the plan. We'll have your ship and the Ice Nova escort our captured freighter into the sector. Unfortunately, they have plenty of footage of us trashing their ships. I expect them to recognize our ship profiles instantly."
    if playerHeardPlan then
        d8.text = "Understood. I'm sending you the coordinates of the shipyard now. Sophie will meet you there with the captured freighter."
        d8.onEnd = kothStory7_onPhase2DialogEnd

        d1.answers = {
            { answer = "Go on.", followUp = d2 },
            { answer = "We've gone over this before.", followUp = d8 }
        }
    else
        d1.followUp = d2
    end

    d2.text = "So I'm getting \"executed\" for this mission. My second in command - Sophie Netreba - is going to pretend to be a pirate captain that recently took over this ship."
    d2.followUp = d3

    d3.text = "It's a pleasure, Captain. I've seen your work firsthand and I'm a fan. It will be exciting to fight alongside you!"
    d3.followUp = d4

    d4.text = "You two will hang back and let the freighter fly in. It'll have a boarding team, and they'll try to sneak the data off the network - this time without setting off any alarms."
    d4.followUp = d5

    d5.text = "Between the data we've recovered from the prototypes and some scraping our AWACS did, we recovered a number of their IFF codes. As long as you don't let any of the defenders patrolling the sector get near you, you should have no problem. Stand by with the Ice Nova in case any issues come up."
    d5.answers = {
        { answer = "I understand.", followUp = d7 },
        { answer = "Do I need to equip a subsystem?", followUp = d6 }
    }

    d6.text = "What do you think we are, The Family? Nah. Our tech is better - we've got you covered. But if you're feeling nervous, you can install a chameleon."
    d6.followUp = d7

    d7.text = "I'm sending you the coordinates of the shipyard now. Sophie will meet you there with the captured freighter."
    d7.onEnd = kothStory7_onPhase2DialogEnd

    ESCCUtil.setTalkerTextColors({d0, d1, d2, d4, d5, d6, d7, d8 }, "Varlance", HorizonUtil.getDialogVarlanceTalkerColor(), HorizonUtil.getDialogVarlanceTextColor())

    ESCCUtil.setTalkerTextColors({d3}, "Sophie", HorizonUtil.getDialogSophieTalkerColor(), HorizonUtil.getDialogSophieTextColor())

    ScriptUI(varlanceID):interactShowDialog(d0, false)
end

function kothStory7_onPhase4Dialog(outpostID)
    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}
    local d7 = {}
    local d8 = {}
    local d9 = {}
    local d10 = {}
    local d11 = {}
    local d12 = {}
    local d13 = {}
    local d14 = {}
    local d15 = {}
    local d16 = {}
    local d17 = {}
    local d18 = {}

    local _PlayerName = Player().name

    d0.text = "Unidentified ships, this is Military Installation MRI-7873-SRD6F6C - sector traffic control. Your target profiles match the mercenaries that have been raiding our convoys over the last few weeks."
    d0.followUp = d1

    d1.text = "Stand down and prepare to be boarded."
    d1.followUp = d2

    d2.text = "Day In Hell here. This is captain Sophie Netreba - what are you on about, control?"
    d2.followUp = d3

    d3.text = "Our records indicate that battleship is Horizon Keepers property and was stolen in a raid by captain Varlance Calder of Frostbite Company. You are to turn it over immediately."
    d3.followUp = d4

    d4.text = "Varlance? Must have been the guy we fragged last week. Should have heard him scream right before we spaced his ass. Finders keepers, control. I won't be turning over this ship."
    d4.followUp = d5

    d5.text = "So do you want to show a little more gratitude for us escorting your freighter here, or are you just going to bitch?"
    d5.followUp = d6

    d6.text = "Your attitude is unwelcome, captain."
    d6.followUp = d7

    d7.text = "Acknowledged, control. We'll put it in the complaint box."
    d7.followUp = d8

    d8.text = "... Fine. What about you?"
    d8.answers = {
        { answer = "Me?", followUp = d9 }
    }
    
    d9.text = "Yes, you. Stand down and prepare to be boarded."
    d9.answers = {
        { answer = "Negative. We will not stand down.", followUp = d10 },
        { answer = "What are you talking about?", followUp = d11 } 
    }
    
    d10.text = "We weren't giving you the option."
    d10.onEnd = kothStory7_onPhase4DialogEndBad
    
    d11.text = "Your ships destroyed our fleet - destroyed billions of credits worth of technology. Thousands of our comrades are dead."
    d11.answers = {
        { answer = "This ship is commandeered. ${_PLAYER} is dead." % { _PLAYER = _PlayerName } , followUp = d13 },
        { answer = "Your pirate mercenaries don't care.", followUp = d12 }
    }
    
    d12.text = "I see. We've changed our mind. All ships, engage and destroy the unknown ships."
    d12.onEnd = kothStory7_onPhase4DialogEndBad
    
    d13.text = "I see. I find that hard to believe. We'll be sending a team to inspect your ship. Keep your weapons powered down."
    d13.answers = {
        { answer = "I'm done with you.", followUp = d14 },    
        { answer = "You're welcome for the freighter escort, asshole.", followUp = d15 }
    }
    
    d14.text = "This is our space. You aren't \"done\" with us. All ships, subdue the two unknown vessels."
    d14.onEnd = kothStory7_onPhase4DialogEndBad
    
    d15.text = "<Overheard> We've got to stop hiring such aggressive pirate captains to guard our shipments."
    d15.followUp = d16

    d16.text = "<Overheard> Just let them through. Corporate can deal with them later."
    d16.followUp = d17

    d17.text = "But- Ugh. Fine. ... You are cleared to proceed. The two of you are quite the pair."
    d17.followUp = d18

    d18.text = "<Secure Channel> Phew! I was afraid they would press. We'll send in the freighter now. Take care to stay away from the defenders, and watch that installation!"
    d18.onEnd = kothStory7_onPhase4DialogEndGood
    
    ESCCUtil.setTalkerTextColors({d2, d4, d5, d7, d18}, "Sophie", HorizonUtil.getDialogSophieTalkerColor(), HorizonUtil.getDialogSophieTextColor())

    ScriptUI(outpostID):interactShowDialog(d0, false)
end

--endregion