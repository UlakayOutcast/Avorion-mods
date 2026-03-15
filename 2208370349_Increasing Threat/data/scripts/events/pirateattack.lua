ESCCUtil = include("esccutil")

local ITUtil = include("increasingthreatutility")

local piratefaction = nil
local shipscalevalue = 0
local mostHatedName = nil
local mostNotoriousName = nil
local pirate_reserves = {}
local hateCountdownTimer = 0
local _HatredLevel = 0

PirateAttack._Debug = 0

local _ActiveMods = Mods()
PirateAttack._HETActive = false

for _, _Xmod in pairs(_ActiveMods) do
	if _Xmod.id == "1821043731" then --HET
		PirateAttack._HETActive = true
	end
end

if onServer() then
    local secure_IncreasingThreat = PirateAttack.secure
    function PirateAttack.secure()
        local _MethodName = "Secure"
        PirateAttack.Log(_MethodName, "Running...")
        local secureResults = secure_IncreasingThreat()

        secureResults.piratefaction = piratefaction.index
        secureResults.shipscalevalue = shipscalevalue
        secureResults.mostHatedName = mostHatedName
        secureResults.mostNotoriousName = mostNotoriousName
        secureResults.hateCountdownTimer = hateCountdownTimer
        secureResults.pirate_reserves = pirate_reserves
        secureResults._HatredLevel = _HatredLevel

        return secureResults
    end

    local restore_IncreasingThreat = PirateAttack.restore
    function PirateAttack.restore(data)
        local _MethodName = "Restore"
        PirateAttack.Log(_MethodName, "Running...")
        restore_IncreasingThreat()

        piratefaction = Faction(data.piratefaction)
        shipscalevalue = data.shipscalevalue
        mostHatedName = data.mostHatedName
        mostNotoriousName = data.mostNotoriousName
        hateCountdownTimer = data.mostHatedName
        pirate_reserves = data.pirate_reserves
        _HatredLevel = data._HatredLevel
    end

    --Can't retain compatibility here. Too bad.
    local initialize_IncreasingThreat = PirateAttack.initialize
    function PirateAttack.initialize()
        local _MethodName = "Initialize"
        PirateAttack.Log(_MethodName, "intializing increasing threat pirate attack", 1)
        local sector = Sector()

        local generator = AsyncPirateGenerator(PirateAttack, PirateAttack.onPiratesGenerated)
        piratefaction = generator:getPirateFaction()

        local notoriousplayers = ITUtil.getSectorPlayersByNotoriety(piratefaction.index)
        local hatedplayers = ITUtil.getSectorPlayersByHatred(piratefaction.index)

        -- no pirate attacks at the very edge of the galaxy
        local x, y = sector:getCoordinates()
        if length(vec2(x, y)) > 560 then
            PirateAttack.Log(_MethodName, "Too far out for pirate attacks.")
            ITUtil.unpauseEvents()
            terminate()
            return
        end

        if not EventUT.attackEventAllowed() then
            PirateAttack.Log(_MethodName, "Attack event not allowed. Terminating event.")
            ITUtil.unpauseEvents()

            --Pick a random player. If that player is hated enough, initiate an attack against them elsewhere.
            if #hatedplayers > 0 then
                local _RandomPlayer = randomEntry(hatedplayers)
                local _xPlayer = _RandomPlayer.player

                if _RandomPlayer.hatred > 600 then
                    --50/50 shot until hatred level 800 - then it's a 70/30 shot in their favor.
                    local _Chance = 50
                    if _RandomPlayer.hatred > 800 then
                        _Chance = _Chance + 20
                    end
    
                    local _Rgen = ESCCUtil.getRand()
                    local _Roll = _Rgen:getInt(1, 100)
    
                    PirateAttack.Log(_MethodName, "maybe attacking elsewhere. Chance is : " .. tostring(_Chance) .. " and roll is : " .. tostring(_Roll))
                    
                    if _Roll < _Chance then
                        PirateAttack.Log(_MethodName, "Attack event not allowed. Attacking the player elsewhere.")
                        local _Interdict = { x = x, y = y }
                        _xPlayer:addScriptOnce("events/passiveplayerattackstarter.lua", _Interdict)
                    end
                end
            else
                --No players in sector - running alt attack method
                PirateAttack.Log(_MethodName, "No players found - running alt attack method.")
                PirateAttack.runAltAttack(piratefaction.index)
            end

            terminate()
            return
        end

        --If the pirate faction is craven, add a chance to abort the attack if there's AI defenders.
        local _Craven = piratefaction:getTrait("craven")
        if _Craven and _Craven >= 0.25 then
            local _Galaxy = Galaxy()
            local _Controller = _Galaxy:getControllingFaction(x, y)
            if _Controller then
                if _Controller.isAIFaction then
                    local _Rgen = ESCCUtil.getRand()
                    if _Rgen:getInt(1, 5) == 1 then
                        PirateAttack.Log(_MethodName, "Pirates decided to abort the attack due to cowardice.")
                        ITUtil.unpauseEvents()
                        terminate()
                        return
                    end
                end
            end
        end

        ships = {}
        participants = {}
        reward = 0
        reputation = 0

        local controller = Galaxy():getControllingFaction(x, y)
        if controller and controller.index == piratefaction.index then
            PirateAttack.Log(_MethodName, "sector controlled by pirate faction. Terminating event.")
            ITUtil.unpauseEvents()
            terminate()
            return
        end

        --Get challenge rating of attack
        --Challenge rating of attack is calculated by adding notoriety + hatred of all players, then averaging it.
        
        local totalNotoriety = 0
        local totalHatred = 0
        local players = {Sector():getPlayers()}

        for _,p in pairs(notoriousplayers) do
            local xhatred = p.hatred or 0
            local xnotoriety = p.notoriety or 0

            totalHatred = totalHatred + xhatred
            totalNotoriety = totalNotoriety + xnotoriety
        end

        local challengeRating = (totalNotoriety + totalHatred) / (#players * 2)

        PirateAttack.Log(_MethodName, "challenge rating of attack is " .. challengeRating)
        PirateAttack.Log(_MethodName, "building attack pattern table")

        local highestHatred = hatedplayers[1].hatred
        _HatredLevel = highestHatred

        PirateAttack.addHatredReserves(hatedplayers)
        
        local highestNotoriety = notoriousplayers[1].notoriety

        PirateAttack.addNotorietyReserves(notoriousplayers)

        local attackType = ITUtil.getFixedStandardTable(challengeRating, highestHatred, highestNotoriety)
        -- create attacking ships
        local distance = attackType.dist or 250 --_#DistADj
        local hasJammer = false
        local attackShipTable = {}
        for _, _Ship in pairs(attackType.shipTable) do
            table.insert(attackShipTable, _Ship)
        end

        if PirateAttack._HETActive then
            --Attacks come with 3x as many base ships.
            distance = distance * 1.5
            for _ = 1, 2 do
                for _, _Ship in pairs(attackType.shipTable) do
                    table.insert(attackShipTable, _Ship)
                end
            end
            shuffle(random(), attackShipTable)
        end

        --If the most hated player in the sector has a hatred rating over 300, we start tossing Jammers into the attack wave. This has some special consequences.
        if highestHatred >= 300 then
            local JammerChance = 20 + math.min(30, (highestHatred - 300) / 23.3) --Start @ 20% chance at 300. Caps at 50% chance at 1000.
            if math.random(100) < JammerChance then
                table.insert(attackShipTable, "Jammer")
                hasJammer = true
            end
        end

        generator:startBatch()

        local posCounter = 1
        local pirate_positions = generator:getStandardPositions(#attackShipTable, distance)
        for _, p in pairs(attackShipTable) do
            generator:createScaledPirateByName(p, pirate_positions[posCounter])
            posCounter = posCounter + 1
        end

        generator:endBatch()
        reward = attackType.reward
        shipscalevalue = attackType.strength

        reputation = reward * 2000
        reward = reward * 10000 * Balancing_GetSectorRewardFactor(sector:getCoordinates())

        --Don't alert anyone of anything if there is a Jammer in play.
        if hasJammer == false then
            sector:broadcastChatMessage("Server"%_t, 2, "Pirates are attacking the sector!"%_t)
            AlertAbsentPlayers(2, "Pirates are attacking sector \\s(%1%:%2%)!"%_t, sector:getCoordinates())
            if #pirate_reserves > 0 then
                sector:broadcastChatMessage("Server"%_t, ChatMessageType.Information, "Additional subspace signals are showing up on your scanner."%_t)
            end
        end
    end

    --Roughly doubles the update intervals of this event.
    local getUpdateInterval_IncreasingThreat = PirateAttack.getUpdateInterval
    function PirateAttack.getUpdateInterval()
        return 7
    end

    --Created callbacks.
    --Generic callback.
    function PirateAttack.utilPiratesGenerated(generated)
        for _, ship in pairs(generated) do
            if valid(ship) then -- this check is necessary because ships could get destroyed before this callback is executed
                ships[ship.index.string] = true
                ship:registerCallback("onDestroyed", "onShipDestroyed")
            end
        end
    
        -- add enemy buffs
        SpawnUtility.addEnemyBuffs(generated) --Covered IT Extra Scripts
        local _WilyTrait = piratefaction:getTrait("wily") or 0
        SpawnUtility.addITEnemyBuffs(generated, _WilyTrait, _HatredLevel)
    
        -- resolve intersections between generated ships
        Placer.resolveIntersections(generated)
    
        PirateAttack.attackersGenerated = true
    end

    --Specific callbacks.    
    function PirateAttack.onPiratesGenerated(generated)
        PirateAttack.utilPiratesGenerated(generated)
    
        broadcastInvokeClientFunction("onPiratesGenerated", generated[1].id.string)
    end

    function PirateAttack.onHatredPiratesGenerated(generated)
        PirateAttack.utilPiratesGenerated(generated)

        local maxchance = 25
        if #generated > 4 then
            maxchance = 100
        elseif #generated <= 2 then
            maxchance = 10
        end
        local chance = math.random(1, 100)
        if chance <= maxchance then
            broadcastInvokeClientFunction("onHatredPiratesGenerated", generated[1].id.string, mostHatedName)
        end
    end

    function PirateAttack.onNotorietyPiratesGenerated(generated)
        PirateAttack.utilPiratesGenerated(generated)

        local chance = math.random(100)
        if #generated > 3 or chance <= 25 then
            broadcastInvokeClientFunction("onNotorietyPiratesGenerated", generated[1].id.string, mostNotoriousName)
        end
    end

    --Update function.
    local update_IncreasingThreat = PirateAttack.update
    function PirateAttack.update(timeStep)
        local _MethodName = "Update"
        if not PirateAttack.attackersGenerated then return end

        --Tick down both the hatred + notoriety timers if applicable.
        local hateCountdownTimerFinishedThisUpdate = false
        if hateCountdownTimer > 0 then
            PirateAttack.Log(_MethodName, "tick down hatred timer. it is at " .. hateCountdownTimer)
            hateCountdownTimer = hateCountdownTimer - timeStep
            if hateCountdownTimer <= 0 then
                hateCountdownTimerFinishedThisUpdate = true
            end
        end

        local _PiratesInSector = {Sector():getEntitiesByFaction(piratefaction)}
        local _PiratesInSectorCt = #_PiratesInSector

        local maxShips = 4
        if hateCountdownTimerFinishedThisUpdate then
            maxShips = 10
        end
        if #pirate_reserves > 0 then
            local noShips = tablelength(ships)
            if noShips < 25 and _PiratesInSectorCt < 40 then
                --start spawning in more ships. Don't spawn them more than 4-5 at a time.
                local shipsToSpawn = 25 - noShips

                if shipsToSpawn > maxShips then
                    shipsToSpawn = math.random(maxShips,maxShips+1)
                end

                local nextPirateBatch = { }
                for _ = 1, shipsToSpawn, 1 do
                    if next(pirate_reserves) ~= nil then
                        if hateCountdownTimer <= 0 or pirate_reserves[1].reason == "notoriety" then
                            local nextReserveShip = table.remove(pirate_reserves)
                            table.insert(nextPirateBatch, nextReserveShip)
                        end
                    end
                end

                local generator = AsyncPirateGenerator(PirateAttack, PirateAttack.onHatredPiratesGenerated)
                if next(nextPirateBatch) ~= nil then
                    if nextPirateBatch[1].reason == "notoriety" then
                        generator = AsyncPirateGenerator(PirateAttack, PirateAttack.onNotorietyPiratesGenerated)
                    end
                end

                piratefaction = generator:getPirateFaction()
                generator:startBatch()

                local pirate_positions = generator:getStandardPositions(shipsToSpawn, 150)
                for posidx = 1, #nextPirateBatch, 1 do
                    if next(nextPirateBatch) ~= nil then
                        local nextReserveShip = table.remove(nextPirateBatch)
                        generator:createScaledPirateByName(nextReserveShip.ship, pirate_positions[posidx])
                    end
                end

                generator:endBatch()
            end
            return
        end

        update_IncreasingThreat(timeStep)
    end

    --Can't retain compatibility here, unfortunately. If we let the damage check run we will have to let the end check run
    --We don't necessarily want that due to the delay on hatred / notoriety-based events.
    local onShipDestroyed_IncreasingThreat = PirateAttack.onShipDestroyed
    function PirateAttack.onShipDestroyed(shipIndex)
        local _MethodName = "On Ship Destroyed"
        ships[shipIndex.string] = nil
        PirateAttack.Log(_MethodName, "Ship index " .. tostring(shipIndex) .. " was destroyed.")

        local ship = Entity(shipIndex)
        local damagers = {ship:getDamageContributors()}
        for _, damager in pairs(damagers) do
            local faction = Faction(damager)
            if faction and (faction.isPlayer or faction.isAlliance) then
                participants[damager] = damager
            end
        end

        -- if they're all destroyed, the event ends
        if tablelength(ships) == 0 and tablelength(pirate_reserves) == 0 then
            PirateAttack.Log(_MethodName, "All ships destroyed and reserves empty - running end event.")
            PirateAttack.endEvent()
        end
    end

    local endEvent_IncreasingThreat = PirateAttack.endEvent
    function PirateAttack.endEvent()
        local _MethodName = "End Event"
        PirateAttack.Log(_MethodName, "running increasing threat endEvent")
        --increase notoriety and hatred for all participants
        local _IncreasedHatredFor = {}
        local players = {Sector():getPlayers()}

        for _, participant in pairs(participants) do
            local participantFaction = Faction(participant)

            if participantFaction then
                if participantFaction.isPlayer and not _IncreasedHatredFor[participantFaction.index] then
                    PirateAttack.Log(_MethodName, "Have not yet increased hatred for faction index " .. tostring(participantFaction.index) .. " - increasing hatred.")
                    PirateAttack.increaseHatred(participantFaction)
                    _IncreasedHatredFor[participantFaction.index] = true
                end
                if participantFaction.isAlliance then
                    local _Alliance = Alliance(participant)
                    for _, _Pl in pairs(players) do
                        if _Alliance:contains(_Pl.index) and not _IncreasedHatredFor[_Pl.index] then
                            PirateAttack.increaseHatred(_Pl)
                            _IncreasedHatredFor[_Pl.index] = true
                        else
                            PirateAttack.Log(_MethodName, "Have either increased hatred for faciton index " .. tostring(_Pl.index) .. " or they are not part of the alliance.")
                        end
                    end
                end
            end
        end

        --run vanilla endEvent
        PirateAttack.Log(_MethodName, "running vanilla endEvent")
        endEvent_IncreasingThreat()
    end
end

if onClient() then

    if PirateAttack.initialize then
        --Error trap for the HarderEnemys mod.
        local PirateAttack_ClientInitialization = PirateAttack.initialize
        function PirateAttack.initialize()
            --Do nothing, since we're on the client.
        end
    end

    function PirateAttack.onPiratesGenerated(id)
        -- these don't have translation markers on purpose
        local lines = {
            "Eject all your cargo and we will spare you - hahaha just kidding. You're as good as dead.",
            "We'll give you fired rounds for your cargo. Sounds like an equivalent exchange to me.",
            "Kill 'em all, let their god sort them out!",
            "Maybe next time, you'll pay our generous fee for protection.",
            "Don't save any ammo! The salvage will pay for it.",
            "Surrender or be destroyed!",
            "Is this really worth our time? It doesn't matter, we'd be idiots to pass up on free loot.",
            "Hah, they won't stand a chance.",
            "Do you think this is a game?",
            "HahahahAHAHAHAHAHA!",
            "Looks like a soft target. Let's take them out quickly.",
            "This is where the fun begins!",
            "You'll be sucking vacuum in a moment!"
        }
    
        displaySpeechBubble(Entity(id), randomEntry(lines))
    end

    function PirateAttack.onHatredPiratesGenerated(id, hatedPlayerName)
        local lines = {
            "This is the end of the line for you, %s!",
            "We're going to kill you, %s!",
            "Hope you're ready to die, %s.",
            "There's %s! Die die die!",
            "You'll pay for what you did to our friends!",
            "You killed our comrades! Now, we'll kill you!",
            "You're dead! Your pathetic begging won't save you!"
        }

        displaySpeechBubble(Entity(id), string.format(randomEntry(lines), hatedPlayerName))
    end

    function PirateAttack.onNotorietyPiratesGenerated(id, notoriousPlayerName)
        local lines = {
            "Look, it's %s! If we kill them, we'll be legends!",
            "%s has a huge bounty! Take them out now!",
            "%s doesn't look anything like the rumors! Vaporizing you is gonna make a great story back at the shipyard!",
            "Well, well, well, it's %s! We'll bring your head to our boss and get a huge reward!",
            "We're missing one last skull to decorate our ship. Yours will do nicely.",
            "I've never understood why we have such a bad reputation with the likes of you out there."
        }

        displaySpeechBubble(Entity(id), string.format(randomEntry(lines), notoriousPlayerName))
    end
    
end

--region #RUN ALT ATTACK CALL

function PirateAttack.runAltAttack(_index)
    local _MethodName = "Run Alt Attack"
    --This can't be done via hated players because of limitations on creating factions OOS, so instead...
    local sector = Sector()
    local _Ships = {sector:getEntitiesByType(EntityType.Ship)}
    local _Stations = {sector:getEntitiesByType(EntityType.Station)}
    local _Factions = {}
    
    for _, _ship in pairs(_Ships) do
        local _fidx = _ship.factionIndex
        local _Faction = Faction(_fidx)
        if _Faction.isPlayer then
            table.insert(_Factions, _fidx)
        end
        if _Faction.isAlliance then
            --As always, we have to do some wacky shit here. Get all online players.
            local _Alliance = Alliance(_fidx)
            local _OnlinePlayers = {_Alliance:getOnlineMembers()}
            for _, _pidx in pairs(_OnlinePlayers) do
                table.insert(_Factions, _pidx)
            end
        end
    end

    for _, _station in pairs(_Stations) do
        local _fidx = _station.factionIndex
        local _Faction = Faction(_fidx)
        if _Faction.isPlayer then
            table.insert(_Factions, _fidx)
        end
        if _Faction.isAlliance then
            --Get all online players
            local _Alliance = Alliance(_fidx)
            local _OnlinePlayers = {_Alliance:getOnlineMembers()}
            for _, _pidx in pairs(_OnlinePlayers) do
                table.insert(_Factions, _pidx)
            end
        end
    end
    local _UniqueFactions = {}
    table.sort(_Factions)
    --Eliminate duplicates.
    for k, v in ipairs(_Factions) do
        if v ~= _Factions[k+1] then
            table.insert(_UniqueFactions, v)
        end
    end
    for k, v in pairs(_UniqueFactions) do
        PirateAttack.Log(_MethodName, "Running alt attack code for " .. tostring(v))
        --Run an attack vs. each player if we hate them enough. Don't interdict this sector since we don't know if OOS attack events are allowed or not
        --It was likely cancelled just due to no players being this sector.
        local _runFunction = [[
            function run(idx)
                local _Player = Player()
                local _HatredIndex = "_increasingthreat_hatred_" .. tostring(idx)
                local _HatredValue = _Player:getValue(_HatredIndex) or 0
                local _Time = Server().unpausedRuntime
                local _NextTime = _Player:getValue("_increasingthreat_alt_oos_attack") or 0

                if _NextTime < _Time then
                    if _HatredValue > 600 then
                        local _Chance = 50
                        if _HatredValue > 800 then
                            _Chance = _Chance + 20
                        end
                        
                        local _Roll = math.random(1, 100)
                        if _Roll < _Chance then
                            _Player:addScriptOnce("events/passiveplayerattackstarter.lua")
                            _Player:setValue("_increasingthreat_alt_oos_attack", _Time + (20*60))
                        end
                    end
                end
            end
        ]]

        runFactionCode(v, true, _runFunction, "run", _index)
    end
end

--endregion

--region #CLIENT / SERVER CALLS

function PirateAttack.addHatredReserves(_HatedPlayers)
    local _MethodName = "Add Hatred Reserves"

    local _MostHatedPlayer = _HatedPlayers[1]
    
    PirateAttack.Log(_MethodName, "highest hatred belongs to " .. _MostHatedPlayer.player.name .. " at " .. _MostHatedPlayer.hatred)

    local triggerHatredAttack = false

    for _, p in pairs(_HatedPlayers) do
        PirateAttack.Log(_MethodName, "evaluating hatred of " .. p.player.name)
        local hatredcdindex = "_increasingthreat_hatred_cooldown_" .. p.player.index
        local xhatredcd = piratefaction:getValue(hatredcdindex) or 0
        PirateAttack.Log(_MethodName, "hatred of " .. p.player.name .. " is " .. p.hatred .. " || cooldown until attack is " .. xhatredcd)
        local newHatredCooldown = 0
        if not triggerHatredAttack and xhatredcd <= 0 and p.hatred >= 300 then
            local chance = 20 + math.min(30, (p.hatred - 300) / 13.3) --Start @ 20% chance at 300. Caps at 50% chance @ 700.
            if math.random(100) < chance then
                PirateAttack.Log(_MethodName, "execute hatred attack vs " .. p.player.name)
                
                local _BaseCooldownComponent = math.ceil(math.min(1000, _MostHatedPlayer.hatred) / 150) --Player hatred up to 1000 divided by 150. (1-7 attacks.)
                local _OvercapHatred = math.max(0, _MostHatedPlayer.hatred - 1000) --Hatred over the "soft cap" of 1000 - beyond 1000 there isn't much planned content.
                local _OvercapCooldownComponent = math.random(_OvercapHatred / 150, math.ceil(_OvercapHatred / 100)) --An extra 1000 hatred should add between 7-10 attacks.

                newHatredCooldown = _BaseCooldownComponent + math.max(1, _OvercapCooldownComponent) --At least 2 attacks,10,000 hatred would result in a cooldown of 67-97 attacks.
                newHatredCooldown = math.min(newHatredCooldown, 96) --Assuming pirate attacks are "every 15 minutes" - this should put a maximum theorietical cap of 24 hours between hatred waves.
                if PirateAttack._HETActive then
                    PirateAttack.Log(_MethodName, "HET is enabled - reducing hatred cooldown.")
                    newHatredCooldown = math.floor(newHatredCooldown * 0.8)
                end
                local _Vengeful = piratefaction:getTrait("vengeful")
                if _Vengeful then
                    PirateAttack.Log(_MethodName, "Pirate faction is vengeful - reducing hatred cooldown. Hatred cooldown is currently " .. tostring(newHatredCooldown))
                    local _VengefulFactor = 1.0
                    if _Vengeful >= 0.25 then
                        _VengefulFactor = 0.8
                    end
                    if _Vengeful >= 0.75 then
                        _VengefulFactor = 0.7
                    end
                    newHatredCooldown = math.floor(newHatredCooldown * _VengefulFactor)
                end

                PirateAttack.Log(_MethodName, "setting hatred cooldown to " .. newHatredCooldown)
                
                local hatredShips = math.floor((math.min(1000, p.hatred) / 50) + (math.max(0, p.hatred - 1000) / 100))
                local _Brutish = piratefaction:getTrait("brutish")
                if _Brutish and _Brutish >= 0.25 then
                    hatredShips = math.floor(hatredShips * 1.3)
                end

                local hatredTable = ITUtil.getHatredTable(p.hatred)
                for _ = 1, hatredShips do
                    table.insert(pirate_reserves, {ship = hatredTable[math.random(1, #hatredTable)], reason = "hate"})
                    PirateAttack.Log(_MethodName, "added " .. #pirate_reserves .. " ships to reserve")
                end

                mostHatedName = p.player.name
                triggerHatredAttack = true
            end
        else
            newHatredCooldown = math.max(xhatredcd - 1, 0)
        end
        piratefaction:setValue(hatredcdindex, newHatredCooldown)
    end
end

function PirateAttack.addNotorietyReserves(_NotoriousPlayers)
    local _MethodName = "Add Notoriety Reserves"

    local _MostNotoriousPlayer = _NotoriousPlayers[1]

    PirateAttack.Log(_MethodName, "highest notoriety belongs to " .. _MostNotoriousPlayer.player.name .. " at " .. _MostNotoriousPlayer.notoriety)

    local triggerNotorietyAttack = false
    for _, p in pairs(_NotoriousPlayers) do
        PirateAttack.Log(_MethodName, "evaluating notoriety of " .. p.player.name)
        local notorietycdindex = "_increasingthreat_notoriety_cooldown_" .. p.player.index
        local xnotorietycd = piratefaction:getValue(notorietycdindex) or 0
        
        PirateAttack.Log(_MethodName, "notoriety of " .. p.player.name .. " is " .. p.notoriety .. " || cooldown until attack is " .. xnotorietycd)
        
        local newNotorietyCooldown = 0
        if not triggerNotorietyAttack and xnotorietycd <= 0 and p.notoriety >= 60 then
            local chance = 20 + math.min(30, (p.notoriety - 60) / 2.6) --Start @ 20% chance at 60. Caps at 50% chance @ 140.
            if math.random(100) < chance then
                PirateAttack.Log(_MethodName, "execute notoriety attack vs " .. p.player.name)
                
                newNotorietyCooldown = 5 + math.random(2, 3)
                if PirateAttack._HETActive then
                    PirateAttack.Log(_MethodName, "HET is enabled - reducing notoriety cooldown.")
                    newNotorietyCooldown = math.floor(newNotorietyCooldown * 0.8)
                end
                local _Vengeful = piratefaction:getTrait("vengeful")
                if _Vengeful then
                    PirateAttack.Log(_MethodName, "Pirate faction is vengeful - reducing notoriety cooldown. Notoriety cooldown is currently " .. tostring(newNotorietyCooldown))
                    local _VengefulFactor = 1.0
                    if _Vengeful >= 0.25 then
                        _VengefulFactor = 0.8
                    end
                    if _Vengeful >= 0.75 then
                        _VengefulFactor = 0.7
                    end
                    newNotorietyCooldown = math.floor(newNotorietyCooldown * _VengefulFactor)
                end

                PirateAttack.Log(_MethodName, "setting notoriety cooldown to " .. newNotorietyCooldown)

                local notorietyShips = math.floor(math.min(10, p.notoriety / 18))
                local notorietyTable = ITUtil.getNotorietyTable(p.notoriety)
                for _ = 1, notorietyShips do
                    table.insert(pirate_reserves, {ship = notorietyTable[math.random(1, #notorietyTable)], reason = "notoriety"})
                    PirateAttack.Log(_MethodName, "added " .. #pirate_reserves .. " ships to reserve")
                end
            end

            mostNotoriousName = p.player.name
            triggerNotorietyAttack = true
        else
            newNotorietyCooldown = math.max(xnotorietycd - 1, 0)
        end
        piratefaction:setValue(notorietycdindex, newNotorietyCooldown)
    end
end

function PirateAttack.increaseHatred(_Faction)
    local _MethodName = "Increase Hatred"
    PirateAttack.Log(_MethodName, "increasing notoriety / hatred for player " .. _Faction.name)
    local notoriety = _Faction:getValue("_increasingthreat_notoriety")
    local xmultiplier = 1
    local _Difficulty = GameSettings().difficulty
    if _Difficulty == Difficulty.Veteran then
        xmultiplier = 1.15
    elseif _Difficulty == Difficulty.Expert then
        xmultiplier = 1.3
    elseif _Difficulty > Difficulty.Expert then
        xmultiplier = 1.5
    end
    if notoriety then
        PirateAttack.Log(_MethodName, "notoriety value is " .. notoriety)
        notoriety = notoriety + (2 * xmultiplier)
    else
        PirateAttack.Log(_MethodName, "notoriety is 0")
        notoriety = (2 * xmultiplier)
    end
    PirateAttack.Log(_MethodName, "new notoriety value is " .. notoriety)
    notoriety = math.min(notoriety, 200) --Notoriety is capped at 200.
    _Faction:setValue("_increasingthreat_notoriety", notoriety)

    local hatredindex = "_increasingthreat_hatred_" .. piratefaction.index
    local hatred = _Faction:getValue(hatredindex)
    local hatredincrement = math.max((shipscalevalue / 3) * xmultiplier, 4)

    local _Tempered = piratefaction:getTrait("tempered")
    if _Tempered then
        local _TemperedFactor = 1.0
        if _Tempered >= 0.25 then
            _TemperedFactor = 0.8
        end
        if _Tempered >= 0.75 then
            _TemperedFactor = 0.7
        end
        PirateAttack.Log(_MethodName, "Faction is tempered - hatred multiplier is (" .. tostring(_TemperedFactor) .. ")")
        hatredincrement = hatredincrement * _TemperedFactor
    end
    hatredincrement = math.ceil(hatredincrement) --.6666667 values are annoying to change, so just round up.

    if hatred then
        PirateAttack.Log(_MethodName, "hatred value is " .. hatred)
        hatred = hatred + hatredincrement
    else
        PirateAttack.Log(_MethodName, "hatred value is 0")
        hatred = hatredincrement
    end
    PirateAttack.Log(_MethodName, "new hatred value is " .. hatred)
    _Faction:setValue(hatredindex, hatred)
    if hatred >= 700 then
        PirateAttack.Log(_MethodName, "Hatred is greater than 700. Setting traits for pirates.")
        ITUtil.setIncreasingThreatTraits(piratefaction)
    end
end

function PirateAttack.Log(_MethodName, _Msg, _OverrideDebug)
    local _UseDebug = _OverrideDebug or PirateAttack._Debug
    if _UseDebug == 1 then
        print("[IT PirateAttack] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion