package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"

include ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace DPMMinerAI
DPMMinerAI = {}
local self = DPMMinerAI

self._Debug = 0

self._RunningTag = "_disruptpirateminers_minerisfleeing"
self._EscortTag = "_disruptpirateminers_escort"
self._InitialMinerTag = "_disruptpirateminers_initialminer"

local sentMessage = false
local endpoint

function DPMMinerAI.initialize(_Values)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Starting v9 of Disrupt Pirate Miners AI Script.")

    self.jumping = false
    self.hitsTaken = 0
    self.timePassed = 0

    local dir = random():getDirection()
    endpoint = dir * 20000

    if onServer() then
        Entity():registerCallback("onDamaged", "onDamaged")
        Entity():registerCallback("onShieldDamaged", "onShieldDamaged")
    end
end

function DPMMinerAI.getUpdateInterval()
    --Update every 5 seconds.
    return 5
end

--region #SERVER CALLS
function DPMMinerAI.updateServer(timeStep)
    local methodName = "Update Server"

    local pirateMiner = Entity()
    local _sector = Sector()

    self.timePassed = self.timePassed + timeStep

    --Check to see if there are any escorts in the area.
    --Проверить, есть ли эскорты в этом районе.
    local escorts = { _sector:getEntitiesByScriptValue(self._EscortTag) }
    local otherMinerGroup = { _sector:getEntitiesByScriptValue(self._InitialMinerTag) }

    --If no escorts, flee
    --Если нет эскортов, бежать
    if #escorts == 0 then
        if not pirateMiner:getValue(self._RunningTag) then
            self.Log(methodName, "No escorts found. Running.")
            --self.Log(methodName, "Эскорты не найдены. Бежим.")
        end
        pirateMiner:setValue(self._RunningTag, true)
    end

    --If shot, flee - handled by callbacks.
    --Если подстрелили, бежать - обрабатывается колбэками.

    --If the ship is part of the INITIAL miner group - if any flee, all flee.
    --Если корабль является частью ИСХОДНОЙ группы шахтеров - если кто-то убегает, убегают все.
    if #otherMinerGroup > 0 then
        for _, otherMiner in pairs(otherMinerGroup) do
            if otherMiner:getValue(self._RunningTag) then
                if not pirateMiner:getValue(self._RunningTag) then
                    self.Log(methodName, "Other miners in the initial group running. Running.")
                    --self.Log(methodName, "Другие шахтеры в исходной группе убегают. Бежим.")
                end
                pirateMiner:setValue(self._RunningTag, true)
            end
        end
    end

    --Finally, check to see if entity is fleeting - if it is and there's a safe exit, jump out.
    --Наконец, проверьте, убегает ли сущность - если да, и есть безопасный выход, выпрыгивайте.
    if pirateMiner:getValue(self._RunningTag) then
        --send message if applicable
        --отправить сообщение, если применимо
        if not sentMessage then
            local runAwayLines = {
            "We need to get out of here!",
            -- "Нам нужно убираться отсюда!",
            "Set a course out of the belt now! Go go go!",
            -- "Проложите курс из пояса сейчас! Давай, давай, давай!",
            "RUN!",
            -- "БЕЖАТЬ!",
            "Run away! Run away!",
            -- "Бегите! Бегите!",
            "It's not safe here! Move it!",
            -- "Здесь небезопасно! Двигайтесь!",
            "We're not getting paid enough for this!",
            -- "Нам недостаточно за это платят!",
            "It's not worth it! Punch it!"
            -- "Это того не стоит! Дави на газ!"
            }

            if random():test(0.25) then
                Sector():broadcastChatMessage(pirateMiner, ChatMessageType.Chatter, randomEntry(runAwayLines))
            end

            sentMessage = true
        end
        
        --remove mining script if applicable
        --удалить скрипт майнинга, если применимо
        self.Log(methodName, "Removing script")
        --self.Log(methodName, "Удаление скрипта")
        local safetyBreakout = 0
        --Can you tell I've had issues with this script being added multiple times?
        --Разве вы не видите, что у меня были проблемы с добавлением этого скрипта несколько раз?
        while pirateMiner:hasScript("ai/mine.lua") and safetyBreakout < 10 do
            pirateMiner:removeScript("ai/mine.lua")
            safetyBreakout = safetyBreakout + 1
        end

        --set endpoint if applicable
        --установить конечную точку, если применимо
        if not endpoint then
            local dir = random():getDirection()
            endpoint = dir * 20000
        end

        --fly to endpoint
        --летим к конечной точке
        self.Log(methodName, "Setting fly linear")
        --self.Log(methodName, "Установка линейного полета")
        local shipAI = ShipAI()
        shipAI:setFlyLinear(endpoint, 0, false)

        --check if path out of field (no asteroids) if path exists, jump
        --проверить, есть ли путь из поля (нет астероидов), если путь существует, прыгать
        self.checkIfSafeExit()
    end
end

function DPMMinerAI.onDamaged(objectIndex, amount, inflictor, damageSource, damageType)
    self.onPirateMinerDamaged()
end

function DPMMinerAI.onShieldDamaged(enityID, amount, damageType, inflictor)
    self.onPirateMinerDamaged()
end

function DPMMinerAI.onPirateMinerDamaged()
    local methodName = "On Pirate Miner damaged"
    --local methodName = "Пиратский шахтер поврежден"

    local pirateMiner = Entity()
    local startRunning = false

    self.hitsTaken = (self.hitsTaken or 0) + 1
    if self.hitsTaken >= 3 then --Don't start running just becaues you bumped an asteroid.
    --if self.hitsTaken >= 3 then --Не начинайте бежать только потому, что вы столкнулись с астероидом.
        if not Entity():getValue(self._RunningTag) then
            self.Log(methodName, "Pirate miner getting shot at - running.")
            --self.Log(methodName, "В пиратского шахтера стреляют - бежим.")
        end
        startRunning = true
    end

    local shieldRatio = pirateMiner.shieldDurability / pirateMiner.shieldMaxDurability
    local hpRatio = pirateMiner.durability / pirateMiner.maxDurability

    if (pirateMiner.shieldMaxDurability > 0 and shieldRatio < 0.95) or hpRatio < 0.95 then
        if not Entity():getValue(self._RunningTag) then
            self.Log(methodName, "Pirate miner hp ratio is " .. tostring(hpRatio) .. " or shield max durability is " .. tostring(pirateMiner.shieldMaxDurability) .. " and shield ratio is " .. tostring(shieldRatio) .. ". Running.")
            --self.Log(methodName, "Соотношение здоровья пиратского шахтера " .. tostring(hpRatio) .. " или максимальная прочность щита " .. tostring(pirateMiner.shieldMaxDurability) .. " и соотношение щита " .. tostring(shieldRatio) .. ". Бежим.")
        end
        startRunning = true
    end    

    if startRunning then
        pirateMiner:setValue(self._RunningTag, true)
    end
end

function DPMMinerAI.checkIfSafeExit()
    local methodName = "Check If Safe Exit"
    --local methodName = "Проверить безопасный выход"

    local pirateMiner = Entity()

    --Check for nearby asteroids. If there are none, jump out.
    --Проверьте наличие ближайших астероидов. Если их нет, выпрыгивайте.
    local _EntitySphere = pirateMiner:getBoundingSphere()
    local _AsteroidCheckSphere = Sphere(_EntitySphere.center, _EntitySphere.radius * 10)
    local _NearbyEntities = {Sector():getEntitiesByLocation(_AsteroidCheckSphere)}
    local _NearbyAsteroids = 0

    for _, nearbyEntity in pairs(_NearbyEntities) do
        if nearbyEntity.type == EntityType.Asteroid then
            _NearbyAsteroids = _NearbyAsteroids + 1
        end
    end

    self.Log(methodName, "Withdrawing. Asteroids nearby: " .. tostring(_NearbyAsteroids))
    --self.Log(methodName, "Отступаем. Астероидов поблизости: " .. tostring(_NearbyAsteroids))

    if _NearbyAsteroids == 0 and self.timePassed >= 30 and not self.jumping then
        local jumpTime = random():getFloat(3, 8)
        pirateMiner:addScript("utility/delayeddelete.lua", jumpTime)
        self.jumping = true
        deferredCallback(jumpTime - 0.25, "sendEscapedCallback")
    end
end

function DPMMinerAI.sendEscapedCallback()
    Sector():sendCallback("disruptPirateMiners_pirateMinerEscaped")
end

--endregion

--region #SECURE / RESTORE / LOG / SYNC CALLS

function DPMMinerAI.Log(_MethodName, _Msg)
    if self._Debug and self._Debug == 1 then
        print("[Disrupt Pirte Miners Miner AI] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion
