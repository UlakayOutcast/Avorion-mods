package.path = package.path .. ";data/scripts/lib/?.lua"

include("randomext")
include ("stringutility")

--namespace LOTWFreighterMission2
LOTWFreighterMission2 = {}

local deleteTime = 30
local runningAway = false
local invokedEscape = false

function LOTWFreighterMission2.initialize()
    if onServer() then
        local _Ship = Entity()

        _Ship:addScriptOnce("data/scripts/entity/deleteonplayersleft.lua")

        local _Lines = LOTWFreighterMission2.getChatterLines()

        _Ship:addScriptOnce("data/scripts/entity/utility/radiochatter.lua", _Lines, 60, 90, random():getInt(10, 20))

        _Ship:registerCallback("onDamaged", "onDamaged")
        _Ship:registerCallback("onDestroyed", "onDestroyed")
    end
end

function LOTWFreighterMission2.getUpdateInterval()
    return 1
end

function LOTWFreighterMission2.onDamaged(_EntityID, _Damage, _Inflictor)
    if not runningAway then
        Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, "Наш груз в опасности! Нам нужно уходить отсюда! Мы будем в безопасности через %1% секунд!"%_t, deleteTime)
        -- remove normal chatter to avoid casual lines while running away
        Entity():removeScript("radiochatter.lua")
        local position = Entity().position
        local shipAI = ShipAI()
        shipAI:setFlyLinear(position.look * 10000, 0)
        runningAway = true
    end
end

function LOTWFreighterMission2.onDestroyed()
    local _Entity = Entity()
    local _Sector = Sector()
    local x, y = _Sector:getCoordinates()
    if _Entity:getValue("_lotw_no_loot_drop") then
        --do nothing
    else
        local money = 10000 * Balancing_GetSectorRewardFactor(x, y)
        _Sector:dropBundle(_Entity.translationf, nil, nil, money)
    end
end

function LOTWFreighterMission2.updateServer(_TimeStep)
    -- delete one minute after getting damage
    if runningAway then
        deleteTime = deleteTime - _TimeStep
    end

    local scriptFuncs = {
        { script = "player/missions/lotw/lotwstory2.lua", func = "lotwStory2_freighterEscaped" },
        { script = "player/missions/lotw/lotwside1.lua", func = "lotwSide1_freighterEscaped" }
    }

    if deleteTime <= 10 and deleteTime + _TimeStep > 10 then
        Sector():broadcastChatMessage(Entity(), ChatMessageType.Chatter, "Вперёд, быстрее! Почти на месте! Скоро выберемся отсюда!"%_t)
    elseif deleteTime <= 4 then
        Entity():addScriptOnce("deletejumped.lua", 5)
    end
    if deleteTime <= 1 then
        local _Players = {Sector():getPlayers()}
        for _, _P in pairs(_Players) do
            if not invokedEscape then
                for _, scriptFunc in pairs(scriptFuncs) do
                    if _P:hasScript(scriptFunc.script) then
                        _P:invokeFunction(scriptFunc.script, scriptFunc.func)
                        invokedEscape = true
                    end
                end
            end
        end
    end
end

function LOTWFreighterMission2.getChatterLines()
    local chatterLines = {
        "Груз в пути — выдвигаемся.",
        "Проходим транзитом. Скоро совершим прыжок.",
        "Гипердвигатели перезаряжаются. Следующий прыжок через 60.",
        "Двигаемся дальше. Товар сам себя не доставит.",
        "Следите за активностью противника."
    }

    return chatterLines
end
