package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("stringutility")
include("sync")

-- Не удаляйте и не изменяйте следующий комментарий, он сообщает игре пространство имён, в котором находится этот скрипт. Если вы удалите его, скрипт сломается.
-- namespace CavEnergySuppressor
CavEnergySuppressor = {}
local self = CavEnergySuppressor
self.data = {time = 20 * 60 * 60} -- Работает в два раза дольше.

defineSyncFunction("data", self)

function CavEnergySuppressor.getUpdateInterval()
    return 60
end

function CavEnergySuppressor.interactionPossible()
    return true
end

function CavEnergySuppressor.initialize()
    if onServer() then
        local entity = Entity()
        if entity.title == "" then
            entity.title = "Подавитель энергетической сигнатуры Mk. II"%_T
        end

        entity:setValue("no_attack_events", true)
    else
        self.sync()
    end
end

function CavEnergySuppressor.initUI()
    ScriptUI():registerInteraction("Закрыть"%_t, "")
end

function CavEnergySuppressor.updateServer(timeStep)
    self.data.time = self.data.time - timeStep

    if self.data.time <= 0 then
        local x, y = Sector():getCoordinates()
        getParentFaction():sendChatMessage("Подавитель энергетической сигнатуры"%_T, ChatMessageType.Normal, [[Ваш подавитель энергетической сигнатуры в секторе \s(%1%:%2%) вышел из строя!]]%_T, x, y)
        getParentFaction():sendChatMessage("Подавитель энергетической сигнатуры"%_T, ChatMessageType.Warning, [[Ваш подавитель энергетической сигнатуры в секторе \s(%1%:%2%) вышел из строя!]]%_T, x, y)
        Entity():clearValues()
        terminate()
    end
end

function CavEnergySuppressor.updateClient(timeStep)
    self.data.time = self.data.time - timeStep

    self.sync()
end

function CavEnergySuppressor.secure()
    return self.data
end

function CavEnergySuppressor.restore(data)
    self.data = data
end

function CavEnergySuppressor.onSync()
    local data = {}
    data.hours = math.floor(self.data.time / 3600)
    data.minutes = math.floor((self.data.time - data.hours * 3600) / 60)

    local text = ""
    if data.hours > 0 then
        text = "Время работы: ${hours} часов ${minutes} минут до выхода из строя."%_t % data
    else
        text = "Время работы: ${minutes} минут до выхода из строя."%_t % data
    end

    InteractionText().text = text
end
