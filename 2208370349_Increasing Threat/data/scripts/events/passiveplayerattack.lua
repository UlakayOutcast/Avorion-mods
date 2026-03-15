local ITUtil = include("increasingthreatutility")
local EventUT = include ("eventutility")

local _PlayerIndex = 0
local _Debug = 0

if onServer() then

local IncreasingThreat_initialize = initialize
function initialize(playerIndex, entityName)
    if _Debug == 1 then
        print("Initializing")
    end
    _PlayerIndex = playerIndex

    --Check to see if there's no attack events allowed - if that's the case, re-add the starter script and terminate this.
    if not EventUT.OOSattackEventAllowed() then
        local x,y = Sector():getCoordinates()

        if _Debug == 1 then
            print("No attack event allowed in " .. tostring(x) .. "," .. tostring(y) .. " - re-rolling location.")
        end
        
        local _Interdict = { x = x, y = y }

        local _FactionFunction = [[
            function run(...)
                Player():addScriptOnce("events/passiveplayerattackstarter.lua", ...)
            end
        ]]

        runFactionCode(playerIndex, true, _FactionFunction, "run", _Interdict)

        terminate()
        return
    end

    IncreasingThreat_initialize(playerIndex, entityName)
end

local IncreasingThreat_spawnPirates = spawnPirates --No compatibility retention here, sadly.
function spawnPirates(entry)
    if _Debug == 1 then
        print("Running spawnPirates vs Player : " .. tostring(_PlayerIndex))
    end
    if not entry and not _PlayerIndex then
        print("WARNING / ERROR - entry was " .. tostring(entry) .. " and _PlayerIndex is " .. tostring(_PlayerIndex) .. " activating escape clause and terminating - if you can figure out why this happened please post a comment on the mod page @ https://steamcommunity.com/sharedfiles/filedetails/?id=2208370349. Thanks!")
        terminate()
        return
    end
    local _Player = Player(entry.faction)
    local sector = Sector()
    local x, y = sector:getCoordinates()
    
    local _Generator = AsyncPirateGenerator(nil, onPiratesGenerated)

    local _PirateFaction = _Generator:getPirateFaction()
    local _HatredIndex = "_increasingthreat_hatred_" .. tostring(_PirateFaction.index)
    local _Hatred = _Player:getValue(_HatredIndex) or 0

    --If the pirate faction is craven, add a chance to abort the attack if there's AI defenders.
    local _Craven = _PirateFaction:getTrait("craven")
    if _Craven and _Craven >= 0.25 then
        local _Galaxy = Galaxy()
        local _Controller = _Galaxy:getControllingFaction(x, y)
        if _Controller then
            if _Controller.isAIFaction then
                if random():getInt(1,5) == 1 then
                    if _Debug == 1 then
                        print("Pirates decided to abort the attack due to cowardice.")
                    end
                    terminate()
                    return
                end
            end
        end
    end

    if _Debug == 1 then
        print("Hatred level : " .. tostring(_Hatred))
    end

    local _Piratect = 4
    local _Brutish = _PirateFaction:getTrait("brutish")
    if _Brutish and _Brutish >= 0.25 then
        _Piratect = 6
    end

    local _OKTime = _Player:getValue("_increastingthreat_next_passiveattack") or 0
    local _Time = Server().unpausedRuntime
    local _LargeAttack = false

    if _Time > _OKTime then
        local _Chance = 0
        if _Hatred > 500 then
            _Chance = _Chance + 20
        end
    
        if _Hatred > 800 then
            _Chance = _Chance + 20
        end
    
        local _Chance = 20
        local _Roll = random():getInt(1, 100)
        if _Roll < _Chance then
            _LargeAttack = true
            _Piratect = _Piratect + 4
            local _TimeToAdd = 240 * 60 --Don't do this for another 4 hours at least.

            local _Vengeful = _PirateFaction:getTrait("vengeful")
            if _Vengeful and _Vengeful >= 0.25 then
                if _Debug == 1 then
                print("Pirates are Vengeful. Decreasing time until next large oos attack happens.")
                end
                local _VengefulFactor = 1.0
                if _Vengeful >= 0.25 then
                    _VengefulFactor = 0.8
                end
                if _Vengeful >= 0.75 then
                    _VengefulFactor = 0.7
                end
                _TimeToAdd = _TimeToAdd * _VengefulFactor
            end

            local _NewTime = _Time + _TimeToAdd

            _Player:setValue("_increastingthreat_next_passiveattack", _NewTime)
        end
    end

    local _SpawnTable = ITUtil.getHatredTable(_Hatred)

    _Generator:startBatch()

    local _Posidx = 1
    local _Positions = _Generator:getStandardPositions(_Piratect, 350)
    for idx = 1, _Piratect do
        _Generator:createScaledPirateByName(randomEntry(_SpawnTable), _Positions[_Posidx])
        _Posidx = _Posidx + 1
    end

    _Generator:endBatch()

    if entry:getEntityType() == EntityType.Station then
        if _LargeAttack then
            _Player:sendChatMessage(entry.name, ChatMessageType.Warning, "Your station in sector \\s(%1%:%2%) is being raided!"%_T, sector:getCoordinates())
        else
            _Player:sendChatMessage(entry.name, ChatMessageType.Warning, "Your station in sector \\s(%1%:%2%) is under attack!"%_T, sector:getCoordinates())
        end
    else
        if _LargeAttack then
            _Player:sendChatMessage(entry.name, ChatMessageType.Warning, "Your ship in sector \\s(%1%:%2%) is being overrun!"%_T, sector:getCoordinates())
        else
            _Player:sendChatMessage(entry.name, ChatMessageType.Warning, "Your ship in sector \\s(%1%:%2%) is under attack!"%_T, sector:getCoordinates())
        end
    end
end

local IncreasingThreat_onPiratesGenerated = onPiratesGenerated
function onPiratesGenerated(_Generated)
    local _Player = Player(_PlayerIndex)
    local _PirateFaction = Faction(_Generated[1].factionIndex)
    local _HatredIndex = "_increasingthreat_hatred_" .. tostring(_PirateFaction.index)
    local _Hatred = _Player:getValue(_HatredIndex) or 0

    local _WilyTrait = _PirateFaction:getTrait("wily") or 0

    SpawnUtility.addEnemyBuffs(_Generated)
    SpawnUtility.addITEnemyBuffs(_Generated, _WilyTrait, _Hatred)

    for _, ship in pairs(_Generated) do
        ship:setValue("is_passive_attack", true)
    end

    -- resolve intersections between generated ships
    Placer.resolveIntersections(_Generated)

    terminate()
end

end