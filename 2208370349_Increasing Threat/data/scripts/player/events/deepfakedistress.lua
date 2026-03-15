package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("stringutility")
include ("callable")
include ("galaxy")
include("randomext")

local AsyncPirateGenerator = include ("asyncpirategenerator")
local AsyncShipGenerator = include ("asyncshipgenerator")
local SectorSpecifics = include ("sectorspecifics")
local SpawnUtility = include ("spawnutility")
local ITUtil = include ("increasingthreatutility")

local target = nil
local generated = 0
local pirates = {}
local traders = {}
local participants = {}
local groups_remaining = 4
local timeSinceCall = 0
local piratesGenerated = false
local tradersGenerated = false
local allGenerated = false
local triggeredambush = false
local sentfirsttaunt = false
local sentfirstwavetaunt = false
local traderfaction = nil
local piratefaction = nil
local hatredlevel = 0

local _Debug = 0

local ambush_taunts = {
    "We've got you now! Hope you're ready to die!",
    "Switch our IFF! Power up the turrets now! Fire! Fire! Fire!",
    "You fool! You fell right into our trap.",
    "Send out our coordinates! We're closing the jaws right now!",
    "The target is here! Jump the fleet in NOW!"
}
local firstwave_taunts = {
    "You'll pay for what you did to our friends!",
    "You killed our comrades! Now, we'll kill you!",
    "You're dead! Your pathetic begging won't save you!",
    "Closing the jaws.",
    "You won't make it out of this sector alive!"
}
local playerran_taunts = {
    "Haha, you ran with your tail between your legs.",
    "Really, you're just going to run? We'll get you next time, coward.",
    "Looks like the target escaped. One day, you won't be so lucky.",
    "One day, your luck will run out. When that happens, we'll be waiting."
}

if onServer() then

    function getUpdateInterval()
        if not triggeredambush then
            --Update more frequently before the big ambush is triggered.
            return 1
        else
            return 5
        end
    end

    function secure()
        return {
            _GroupsRemaining = groups_remaining,
            _PirateFaction = piratefaction.index,
            _HatredLevel = hatredlevel,
            _TriggeredAmbush = triggeredambush,
            _SentFirstTaunt = sentfirsttaunt,
            _SentFirstWaveTaunt = sentfirstwavetaunt
        }
    end

    function restore(_Data)
        groups_remaining = _Data._GroupsRemaining
        piratefaction = Faction(_Data._PirateFaction)
        hatredlevel = _Data._HatredLevel
        triggeredambush = _Data._TriggeredAmbush
        sentfirsttaunt = _Data._SentFirstTaunt
        sentfirstwavetaunt = _Data._SentFirstWaveTaunt
    end

    function initialize(firstInitialization)
        local _MethodName = "Initialize"

        local specs = SectorSpecifics()
        local x, y = Sector():getCoordinates()
        local coords = specs.getShuffledCoordinates(random(), x, y, 7, 12)

        target = nil

        for _, coord in pairs(coords) do
            local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, Server().seed)

            if not regular and not offgrid and not blocked and not home then
                target = {x=coord.x, y=coord.y}
                break
            end
        end

        -- if no empty sector could be found, exit silently
        if not target then
            ITUtil.unpauseEvents()
            terminate()
            return
        end

        local pirateGenerator = AsyncPirateGenerator(nil, onPiratesFinished)
        local player = Player()

        piratefaction = pirateGenerator:getPirateFaction()

        --These start showing up with a 20% chance @ 300 hatred. This caps at 50% at 1000.
        local hatredindex = "_increasingthreat_hatred_" .. piratefaction.index
        hatredlevel = player:getValue(hatredindex) or 0
        if hatredlevel >= 300 then
            local chance = 20 + math.min(30, math.max(0, hatredlevel - 200) / 23)
            if math.random(100) > chance then
                Log(_MethodName, "rolled higher than " .. tostring(chance) .. " - terminating the event.")
                ITUtil.unpauseEvents()
                terminate()
                return
            end
        else
            Log(_MethodName, "pirate faction " .. piratefaction.name .. " does not hate " .. player.name .. " enough to do a deepfake.")
            ITUtil.unpauseEvents()
            terminate()
            return
        end

        if hatredlevel >= 1000 then
            groups_remaining = groups_remaining + 1
        end

        local _Brutish = piratefaction:getTrait("brutish")
        if _Brutish and _Brutish >= 0.25 then
            groups_remaining = groups_remaining + 1
        end

        player:registerCallback("onSectorEntered", "onSectorEntered")
        player:registerCallback("onSectorLeft", "onSectorLeft")

        if firstInitialization then
            local messages =
            {
                "Mayday! Mayday! We are under attack by pirates! Our position is \\s(%1%:%2%), someone help, please!"%_t,
                "Mayday! CHRRK ... under attack CHRRK ... pirates ... CHRRK ... position \\s(%1%:%2%) ... help!"%_t,
                "Can anybody hear us? We have been ambushed by pirates! Our position is \\s(%1%:%2%) Help!"%_t,
                "This is a distress call! Our position is \\s(%1%:%2%) We are under attack by pirates, please help!"%_t,
            }

            player:sendChatMessage("Unknown"%_t, 0, messages[random():getInt(1, #messages)], target.x, target.y)
            player:sendChatMessage("", 3, "You have received a distress signal from an unknown source."%_t)
        end
    end

    function updateServer(timeStep)

        local _Sector = Sector()

        local x, y = _Sector:getCoordinates()
        if x == target.x and y == target.y then
            if allGenerated then
                updatePresentShips()

                local piratesLeft = tablelength(pirates)
                local tradersLeft = tablelength(traders)

                local _PiratesInSector = {Sector():getEntitiesByFaction(piratefaction)}
                local _PiratesInSectorCt = #_PiratesInSector

                if triggeredambush and groups_remaining > 0 and _PiratesInSectorCt < 40 then
                    --Spawn another 4-5 ships in. Use the hatred table that the player has accrued.
                    local hatredTable = ITUtil.getHatredTable(hatredlevel)
                    local hatredShips = math.random(4, 5)
                    local pirateBatch = {}
                    local pirateGenerator = AsyncPirateGenerator(nil, onPiratesFinished)
                    local _Distance = 250 --_#DistAdj

                    --Figure out if HET is enabled.
                    local _ActiveMods = Mods()
                    local _HETActive = false

                    for _, _Xmod in pairs(_ActiveMods) do
                    	if _Xmod.id == "1821043731" then --HET
                    		_HETActive = true
                    	end
                    end

                    for _ = 1, hatredShips do
                        table.insert(pirateBatch, hatredTable[math.random(1, #hatredTable)])
                    end
                    table.insert(pirateBatch, "Jammer")
                    if _HETActive then
                        _Distance = 400
                        table.insert(pirateBatch, "Executioner")
                    end

                    local piratePositions = pirateGenerator:getStandardPositions(#pirateBatch, _Distance)
                    local posidx = 1

                    pirateGenerator:startBatch()

                    for _, p in pairs(pirateBatch) do
                        if p == "Executioner" then
                            pirateGenerator:createScaledExecutioner(piratePositions[posidx], hatredlevel)
                        else
                            pirateGenerator:createScaledPirateByName(p, piratePositions[posidx])
                        end
                        posidx = posidx + 1
                    end

                    pirateGenerator:endBatch()

                    groups_remaining = groups_remaining - 1
                end

                if tradersLeft == 0 and piratesLeft == 0 then
                    endEvent()
                end
            end
        elseif generated == 0 then
            timeSinceCall = timeSinceCall + timeStep

            if timeSinceCall > 10 * 60 then
                terminate()
            end
        end
    end

    function updatePresentShips()
        for i, pirate in pairs(pirates) do
            if not valid(pirate) then
                pirates[i] = nil
            else
                --Check distance to all enemies. If anything is less than 5km away that is NOT the trader faction, power weapons back up.
                local pirateai = ShipAI(pirate)
                local ships = {Sector():getEntitiesByType(EntityType.Ship)}
                for _, s in pairs(ships) do
                    if pirateai:isEnemy(s) and s.factionIndex ~= traderfaction.index then
                        local threshold = 500
                        if pirate.damageMultiplier < 1 and distance(pirate.translationf, s.translationf) <= threshold then
                            local powerupval = pirate:getValue("_increasingthreat_deepfake_powerup")
                            if powerupval then
                                print(s.name .. "is close - returning pirate " .. pirate.name .. " to original firepower multiplier of " .. powerupval)
                                pirate.damageMultiplier = powerupval
                            end
                        end
                    end
                end
            end
        end

        for i, trader in pairs(traders) do
            if not valid(trader) then
                traders[i] = nil
            else
                --Check distance to all player / alliance ships. If anything is less than 0.5km away, power weapons back up and trigger ambush.
                local ships = {Sector():getEntitiesByType(EntityType.Ship)}
                for _, s in pairs(ships) do
                    local sfaction = Faction(s.factionIndex)
                    if sfaction.isPlayer or sfaction.isAlliance then
                        local threshold = 200
                        if distance(trader.translationf, s.translationf) <= threshold and not triggeredambush then
                            sentfirsttaunt = true
                            Sector():broadcastChatMessage(trader, ChatMessageType.Chatter, ambush_taunts[math.random(#ambush_taunts)])
                            startAmbush()
                            break
                        end
                    end
                end
            end
        end

        if tablelength(pirates) == 0 and not triggeredambush then
            startAmbush()
        end
    end

    function startAmbush()
        --print("starting pirate ambush")
        --Power all ship weapons back up.
        local ships = {Sector():getEntitiesByType(EntityType.Ship)}
        for _, ship in pairs(ships) do
            --Only do this for pirate or trader ships.
            if ship.factionIndex == piratefaction.index or ship.factionIndex == traderfaction.index then
                --Bump damage multiplier back up again
                if ship.damageMultiplier < 1 then
                    local powerupval = ship:getValue("_increasingthreat_deepfake_powerup")
                    if powerupval then
                        ship.damageMultiplier = powerupval
                    end
                end
            end

            --If it is a pirate, unregister all traders as enemies.
            if ship.factionIndex == piratefaction.index then
                local pirateai = ShipAI(ship)
                pirateai:registerFriendFaction(traderfaction.index)
                for _, tship in pairs(traders) do
                    pirateai:registerFriendEntity(tship.id)
                end
                pirateai:stop()
                pirateai:setAggressive(1)
            end
            --If it is a trader, unregister all pirates as enemies and swap to pirate faction.
            if ship.factionIndex == traderfaction.index then
                if not sentfirsttaunt then
                    Sector():broadcastChatMessage(ship, ChatMessageType.Chatter, ambush_taunts[math.random(#ambush_taunts)])
                    sentfirsttaunt = true
                end
                ship:removeScript("civilship.lua")
                ship:removeScript("dialogs/storyhints.lua")
                ship:setValue("is_civil", nil)
                ship:setValue("npc_chatter", false)
                ship.factionIndex = piratefaction.index
                local traderai = ShipAI(ship)
                traderai:registerFriendFaction(piratefaction.index)
                for _, pship in pairs(pirates) do
                    traderai:registerFriendEntity(pship.id)
                end
                traderai:stop()
                traderai:setAggressive(1)
            end
        end
        --Start spawning enemies.
        triggeredambush = true
    end

    function onSectorLeft(player, x, y, switchType)
        -- only react when the player left the correct Sector
        if x ~= target.x or y ~= target.y then return end

        updatePresentShips()

        if tablelength(pirates) > 0 or tablelength(traders) > 0 then
            local deleteEnemyShips = false
            if switchType == sectorChangeType.Jump then
                local sender = piratefaction.name
                Player():sendChatMessage(sender, 0, playerran_taunts[math.random(#playerran_taunts)])
                deleteEnemyShips = true
            elseif switchType == sectorChangeType.Forced then
                deleteEnemyShips = true
            end

            if deleteEnemyShips then
                for _, pirate in pairs(pirates) do
                    Sector():deleteEntity(pirate)
                end
                for _, trader in pairs(traders) do
                    Sector():deleteEntity(trader)
                end

                ITUtil.unpauseEvents()
                terminate()
            end
        end

        if tablelength(pirates) == 0 and tablelength(traders) == 0 then
            endEvent()
        end
    end

    function onSectorEntered(player, x, y)

        if x ~= target.x or y ~= target.y then return end

        generated = 1

        -- spawn 3 ships and 10 pirates
        traderfaction = Galaxy():getNearestFaction(x, y)
        local volume = Balancing_GetSectorShipVolume(x, y) * 2

        local look = vec3(1, 0, 0)
        local up = vec3(0, 1, 0)

        local onShipsFinished = function (ships)
            for _, ship in pairs(ships) do
                table.insert(traders, ship)
                ShipAI(ship.index):setPassiveShooting(true)
                ship:setValue("_increasingthreat_deepfake_powerup", 6)
                ship.damageMultiplier = 0.05
            end

            tradersGenerated = true
            allGenerated = piratesGenerated and tradersGenerated
        end

        local shipGenerator = AsyncShipGenerator(nil, onShipsFinished)

        shipGenerator:startBatch()
        shipGenerator:createFreighterShip(traderfaction, MatrixLookUpPosition(look, up, vec3(100, 50, 50)), volume)
        shipGenerator:createFreighterShip(traderfaction, MatrixLookUpPosition(look, up, vec3(0, -50, 0)), volume)
        shipGenerator:createTradingShip(traderfaction, MatrixLookUpPosition(look, up, vec3(-100, -50, -50)), volume)
        shipGenerator:createFreighterShip(traderfaction, MatrixLookUpPosition(look, up, vec3(-200, 50, -50)), volume)
        shipGenerator:createFreighterShip(traderfaction, MatrixLookUpPosition(look, up, vec3(-300, -50, 50)), volume)
        shipGenerator:endBatch()

        local pirateBatch = { "Marauder", "Marauder", "Marauder", "Pirate", "Pirate", "Pirate", "Bandit", "Bandit", "Bandit" }

        local pirateGenerator = AsyncPirateGenerator(nil, onPiratesFinished)

        pirateGenerator:startBatch()

        for _, p in pairs(pirateBatch) do
            pirateGenerator:createPirateByName(p, pirateGenerator:getStandardPositions(1)[1])
        end

        pirateGenerator:endBatch()
    end

    function onPiratesFinished(ships)
        for _, ship in pairs(ships) do
            table.insert(pirates, ship)
            ship:registerCallback("onDestroyed", "onPirateDestroyed")
        end

        piratesGenerated = true

        -- add enemy buffs
        SpawnUtility.addEnemyBuffs(ships) --Covered IT Extra Scripts
        local _WilyTrait = piratefaction:getTrait("wily") or 0
        SpawnUtility.addITEnemyBuffs(ships, _WilyTrait, hatredlevel)

        for _, ship in pairs(ships) do
            ship:setValue("_increasingthreat_deepfake_powerup", ship.damageMultiplier)
            ship.damageMultiplier = 0.05
        end

        allGenerated = piratesGenerated and tradersGenerated
    end

    function onPirateDestroyed(shipIndex)
        local ship = Entity(shipIndex)
        local damagers = {ship:getDamageContributors()}
        for _, damager in pairs(damagers) do
            local faction = Faction(damager)
            if faction and (faction.isPlayer or faction.isAlliance) then
                participants[damager] = damager
            end
        end
    end

    function endEvent()
        local _MethodName = "End Event"
        Log(_MethodName, "ending deepfake distress - increasing hatred for all participants")

        local _IncreasedHatredFor = {}
        local players = {Sector():getPlayers()}

        for _, participant in pairs(participants) do
            local participantFaction = Faction(participant)

            if participantFaction then
                if participantFaction.isPlayer and not _IncreasedHatredFor[participantFaction.index] then
                    Log(_MethodName, "Have not yet increased hatred for faction index " .. tostring(participantFaction.index) .. " - increasing hatred.")
                    increaseHatred(participantFaction)
                    _IncreasedHatredFor[participantFaction.index] = true
                end
                if participantFaction.isAlliance then
                    local _Alliance = Alliance(participant)
                    for _, _Pl in pairs(players) do
                        if _Alliance:contains(_Pl.index) and not _IncreasedHatredFor[_Pl.index] then
                            increaseHatred(_Pl)
                            _IncreasedHatredFor[_Pl.index] = true
                        else
                            Log(_MethodName, "Have either increased hatred for faciton index " .. tostring(_Pl.index) .. " or they are not part of the alliance.")
                        end
                    end
                end
            end
        end

        terminate()
    end

    function sendCoordinates()
        invokeClientFunction(Player(callingPlayer), "receiveCoordinates", target)
    end
    callable(nil, "sendCoordinates")
    
end

function abandon()
    if onClient() then
        invokeServerFunction("abandon")
        return
    end

    terminate()
end
callable(nil, "abandon")

if onClient() then

    function initialize()
        invokeServerFunction("sendCoordinates")
        target = {x=0, y=0}
    end

    function receiveCoordinates(target_in)
        target = target_in
    end

    function getMissionBrief()
        return "Distress Signal"%_t
    end

    function getMissionDescription()
        if not target then return "" end

        return "You have received a distress call from an unknown source. Their last reported position was (${xCoord}, ${yCoord})."%_t % {xCoord = target.x, yCoord = target.y}
    end

    function getMissionLocation()
        if not target then return 0, 0 end

        return target.x, target.y
    end

end

--region #SERVER / CLIENT CALLS

function increaseHatred(_Faction)
    local _MethodName = "Increase Hatred"
    local hatredindex = "_increasingthreat_hatred_" .. piratefaction.index
    local hatred = _Faction:getValue(hatredindex)
    local xmultiplier = 1
    local _Difficulty = GameSettings().difficulty
    if _Difficulty == Difficulty.Veteran then
        xmultiplier = 1.15
    elseif _Difficulty == Difficulty.Expert then
        xmultiplier = 1.3
    elseif _Difficulty > Difficulty.Expert then
        xmultiplier = 1.5
    end
    local hatredincrement = 15 * xmultiplier

    local _Tempered = piratefaction:getTrait("tempered")
    if _Tempered then
        local _TemperedFactor = 1.0
        if _Tempered >= 0.25 then
            _TemperedFactor = 0.8
        end
        if _Tempered >= 0.75 then
            _TemperedFactor = 0.7
        end
        Log(_MethodName, "Faction is tempered - hatred multiplier is (" .. tostring(_TemperedFactor) .. ")")
        hatredincrement = hatredincrement * _TemperedFactor
    end
    hatredincrement = math.ceil(hatredincrement)

    if hatred then
        Log(_MethodName, "hatred value is " .. hatred)
        hatred = hatred + hatredincrement
    else
        Log(_MethodName, "hatred value is 0")
        hatred = hatredincrement
    end
    Log(_MethodName, "new hatred value is " .. hatred)
    _Faction:setValue(hatredindex, hatred)
    if hatred >= 700 then
        Log(_MethodName, "Hatred is greater than 700. Setting traits for pirates.")
        ITUtil.setIncreasingThreatTraits(piratefaction)
    end
end

function Log(_MethodName, _Msg)
    if _Debug == 1 then
        print("[IT Deepfake Distress Signal] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion