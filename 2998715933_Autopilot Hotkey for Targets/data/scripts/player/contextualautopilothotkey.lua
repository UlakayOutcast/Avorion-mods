package.path = package.path .. ";data/scripts/lib/?.lua"

include ("utility")
include ("callable")

-- namespace ContextualAutopilotHotkey
ContextualAutopilotHotkey = {}

if onClient() then

CustomHotkeys = include("data/scripts/player/client/customhotkeys")
if CustomHotkeys and CustomHotkeys.caph_contextual_autopilot_hotkey_integrated then
print("[CAPH] Bubbet's CustomHotkeys detected, integrating")

function ContextualAutopilotHotkey.initialize()
    Player():registerCallback("CustomHotkeys_caph_autopilot_target_hotkey", "onCustomHotkey")
end

function ContextualAutopilotHotkey.onCustomHotkey(event, state)
    if event == HotkeyEvent.Pressed
        and (state == PlayerStateType.Fly or state == PlayerStateType.Strategy)
    then
        ContextualAutopilotHotkey.doContextualAutopilotHotkey()
    end
end    

else -- end custom hotkey integration section
print("[CAPH] Bubbet's CustomHotkeys not detected, using hard-coded hotkey")

-- The hotkey to use. 53 corresponds to the backtick/backquote/grave/tilde
-- key (`~) but changing this to another code will change the key as needed.
local cap_key_code = 53

-- The amount of time to wait before considering the key being pressed down as a new
-- press.
local cap_key_delay_ms = 250
local cap_key_last_time
    
ContextualAutopilotHotkey.keyboard = Keyboard()

function ContextualAutopilotHotkey.initialize()
    Player():registerCallback("onPostRenderHud", "onPostRenderHud")
end

-- This gets called a LOT and it's a poor substitute for a proper "key pressed" callback
-- like we get for the galaxy map, but it works. Doing as a little work as infrequently
-- as possible is important.
function ContextualAutopilotHotkey.onPostRenderHud(state)
    if ContextualAutopilotHotkey.keyboard:keyPressed(cap_key_code) then
        local nowTime = appTimeMs()
        if (not cap_key_last_time or nowTime - cap_key_delay_ms > cap_key_last_time)
            and (state == PlayerStateType.Fly or state == PlayerStateType.Strategy)
        then
            cap_key_last_time = nowTime
            ContextualAutopilotHotkey.doContextualAutopilotHotkey()
        end
    end
end

end -- end no custom hotkey integration section
end -- end if onClient() section

-- Below is client/server code, the part that's not about hotkeys

function ContextualAutopilotHotkey.doContextualAutopilotHotkey(selectionId)
    if onClient() then
        invokeServerFunction("doContextualAutopilotHotkey", Player().selectedObject)
        return
    end
    local player = Player()
    -- Shouldn't happen, but OK
    if not player then return end
    local ship = player.craft
    -- Drone, etc. abort immediately
    if not ship or ship.isDrone or ship.isFighter then return end

    -- All of this goes through OrderChain
    local doOrder = function(order, feedback)
        player:sendChatMessage("", 3, feedback)
        ship:invokeFunction("data/scripts/entity/orderchain.lua", order, selectionId)
    end
    -- Если автопилот уже активен, рассматриваем контекстную клавишу как выключение
    local controlUnit = ControlUnit(ship)
    if controlUnit and controlUnit.autoPilotEnabled then
        doOrder("onUserPassiveOrder", "Отменяю текущий приказ!"%_t)
        return
    end

    -- Если нет выбора, то нет и контекста для включения
    if not selectionId or selectionId.isNil then return end

    -- Теперь просто выбираем подходящий приказ в зависимости от того, что представляет собой цель

    local selectedEntity = Entity(selectionId)

    if selectedEntity.isAsteroid then
        if selectedEntity.isObviouslyMineable or 
            selectedEntity:getNearestDistance(ship) < 500
        then
            doOrder("onUserMineOrder", "Добывыю этот астероид!"%_t)
        else
            -- Мы ограничиваем расстояние добычи автопилотом по горячей клавише до 5 км, чтобы предотвратить быстрое
            -- использование горячих клавиш в качестве скрытого метода обнаружения ресурсных астероидов
            player:sendChatMessage("", 1, "Отсюда этот астероид выглядит пустым."%_t)
        end
    elseif selectedEntity.isWreckage then
        doOrder("onUserSalvageOrder", "Утилизирую эти обломки!"%_t)
    elseif ShipAI(ship):isEnemy(selectedEntity) then
        doOrder("onUserAttackEntityOrder", "Вступаю в бой с этим врагом!"%_t)
    elseif selectedEntity.isStation then
        doOrder("onUserDockToStationOrder", "Состыкуюсь с этой станцией!"%_t)
    elseif selectedEntity.isShip and selectionId ~= ship.id then
        doOrder("onUserEscortOrder", "Сопровождаю этот корабль!"%_t)
    elseif selectedEntity:hasComponent(ComponentType.WormHole) then
        -- "Червоточины" могут быть вратами ИЛИ настоящими червоточинами
        if selectedEntity:hasComponent(ComponentType.Plan) then
            doOrder("onUserFlyThroughWormholeOrder", "Прохожу через эти врата!"%_t)
        else
            doOrder("onUserFlyThroughWormholeOrder", "Полный вперед через эту червоточину!"%_t)
        end
    else
        -- Не знаю, что делать с этой целью
    end
end
callable(ContextualAutopilotHotkey, "doContextualAutopilotHotkey")
