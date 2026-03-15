package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")

HorizonUtil = include("horizonutil")

--namespace HorizonStory2Dialog5
HorizonStory2Dialog5 = {}
local self = HorizonStory2Dialog5

self._Debug = 0

--region #INIT

--Holy fuck am I finally done with these??? Really wish there was some better documentation on addDialogInteraction.
--Or that it allowed for setting of priority.
function HorizonStory2Dialog5.initialize()
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Running...")
end

--endregion

--region #CLIENT CALLS

-- если эта функция возвращает false, скрипт не будет отображаться в окне взаимодействия,
-- даже если его UI может быть зарегистрирован
function HorizonStory2Dialog5.interactionPossible(playerIndex)
    local _MethodName = "Interaction Possible"
    self.Log(_MethodName, "Определение возможности взаимодействия с " .. tostring(playerIndex))
    local _Player = Player(playerIndex)
    local _Entity = Entity()

    local craft = _Player.craft
    if craft == nil then return false end

    local dist = craft:getNearestDistance(_Entity)

    local targetplayerid = _Entity:getValue("horizon_story_player")

    if dist < 1000 and playerIndex == targetplayerid then
        return true
    end

    return false
end

function HorizonStory2Dialog5.initUI()
    ScriptUI():registerInteraction("Contact Mace", "onContact", 99)
end

function HorizonStory2Dialog5.onContact(_EntityIndex)
    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    _UI:showDialog(self.getDialog())
end

function HorizonStory2Dialog5.getDialog()
    local _MethodName = "Get Dialogue"
    self.Log(_MethodName, "Начало...")

    local _PlayerHasChip = false
    local items = Player():getInventory():getItemsByType(InventoryItemType.VanillaItem)
    for _, slot in pairs(items) do
        local item = slot.item

        --Not stackable but the player should only have one.
        if item:getValue("subtype") == "HorizonStoryDataChip" then
            _PlayerHasChip = true
            break
        end
    end

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4_chip = {}
    local d4_nochip = {}

    d0.text = "... Да?"
    d0.answers = {
        { answer = "Эти пираты пытались меня убить.", followUp = d1 }
    }

    d1.text = "ОНИ ЧТО????"
    d1.followUp = d2

    d2.text = "О нет. О боже. Я чувствовал, что они собираются это сделать. Я. Черт возьми. Я бы никак не смог противостоять им на своем крошечном корабле. Прости, что втянул тебя в это, но ты спас мне жизнь. Спасибо."
    d2.followUp = d3

    d3.text = "Я в долгу перед тобой. Ладно. Где этот чип?"
    if _PlayerHasChip then
        d3.answers = {
            { answer = "Вот он.", followUp = d4_chip, onSelect = "removeChip" }
        }
    else
        d3.answers = {
            { answer = "... Я потерял его.", followUp = d4_nochip }
        }
    end

    d4_chip.text = "Отлично. Я взломаю его в мгновение ока. Просто убедись, что сохранишь эту информацию в безопасном месте. Как только я закончу, я удалю все следы этого из моих систем!"
    d4_chip.onEnd = "onEnd"

    d4_nochip.text = "Правда. И после всего этого ты потерял чип? Хорошо, что я нашел еще один, когда убирал за пиратами на днях."
    d4_nochip.talker = "Varlance"
    d4_nochip.textColor = HorizonUtil.getDialogVarlanceTextColor()
    d4_nochip.talkerColor = HorizonUtil.getDialogVarlanceTalkerColor()
    d4_nochip.followUp = d4_chip

    for _, _d in pairs({ d0, d1, d2, d3, d4_chip }) do
        _d.talker = "Mace"
        _d.textColor = HorizonUtil.getDialogMaceTextColor()
        _d.talkerColor = HorizonUtil.getDialogMaceTalkerColor()
    end

    return d0
end

function HorizonStory2Dialog5.onEnd()
    local _MethodName = "On End"
    self.Log(_MethodName, "Начало.")

    Player():invokeFunction("player/missions/horizon/horizonstory2.lua", "kothStory2_contactedHacker4")
end

--endregion

--region #SERVER CALLS

--Starts as a client call and apparently it works??? You can actually remove something from a player's inventory clientside. Shit is wack as hell.
--It comes back when the server is reloaded and the player's inventory is refreshed, though, so it does nothing.
--I can't believe that it doesn't error out in the first place, lmaoooooo.
function HorizonStory2Dialog5.removeChip()
    local methodName = "Remove Chip"

    if onClient() then
        self.Log(methodName, "Вызов на клиенте => вызов на сервере.")
        --have to invoke this on server.
        invokeServerFunction("removeChip")
        return
    end

    self.Log(methodName, "Вызвано на сервере.")

    local _Player = Player(callingPlayer)
    local _Inventory = _Player:getInventory()
    local items = _Inventory:getItemsByType(InventoryItemType.VanillaItem)
    for idx, slot in pairs(items) do
        local item = slot.item

        --Not stackable but the player should only have one.
        if item:getValue("subtype") == "HorizonStoryDataChip" then
            self.Log(methodName, "Чип найден - удаляем его.")
            _Inventory:removeAll(idx)
            break
        end
    end
end
callable(HorizonStory2Dialog5, "removeChip")

--endregion

--region #SECURE / RESTORE / LOG CALLS

function HorizonStory2Dialog5.secure()
    return self._Data
end

function HorizonStory2Dialog5.restore(_Values)
    self._Data = _Values
end

function HorizonStory2Dialog5.Log(_MethodName, _Msg)
    if self._Debug and self._Debug == 1 then
        print("[Horizon Story 2 Dialog 5] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion