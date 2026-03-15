package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")
include("player")

MissionUT = include("missionutility")
HorizonUtil = include("horizonutil")

--namespace HorizonStory2Dialog4
HorizonStory2Dialog4 = {}
local self = HorizonStory2Dialog4

self._Debug = 0

--region #INIT

function HorizonStory2Dialog4.initialize()
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Running...")
end

--endregion

--region #CLIENT CALLS
-- если эта функция возвращает false, скрипт не будет отображаться в окне взаимодействия,
-- даже если его UI зарегистрирован
function HorizonStory2Dialog4.interactionPossible(playerIndex)
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

function HorizonStory2Dialog4.initUI()
    ScriptUI():registerInteraction("Взять артефакт", "onPickup", 99)
end

function HorizonStory2Dialog4.onPickup(_EntityIndex)
    local _MethodName = "On Pickup"
    self.Log(_MethodName, "Начинаем...")
    --Используйте UT миссии для двух диалоговых штук. Один из них должен вызывать серверную функцию для получения товаров.
    local _Condition = function() return true end --Нет условий - как только мы сюда попадем, это всегда должно быть успешно.

    local _Talker = "Мейс"
    local _TalkerColor = HorizonUtil.getDialogMaceTalkerColor()
    local _TextColor = HorizonUtil.getDialogMaceTextColor()

    local _DockedMaker = function()
        local _Docked = {}
        _Docked.text = "Вот артефакт. Еще раз спасибо, что позаботились об этом."
        _Docked.talker = _Talker
        _Docked.textColor = _TextColor
        _Docked.talkerColor = _TalkerColor
        _Docked.onEnd = "onDockedEnd"

        return _Docked
    end

    local _UndockedMaker = function()
        local _Undocked = {}
        _Undocked.text = "Вам нужно пристыковаться, прежде чем я смогу передать артефакт!!"
        _Undocked.talker = _Talker
        _Undocked.textColor = _TextColor
        _Undocked.talkerColor = _TalkerColor

        return _Undocked
    end

    local _FailedMaker = function()
        return {}
    end

    self.Log(_MethodName, "Получение селектора диалога пристыковки.")
    MissionUT.dockedDialogSelector(Entity().index, _Condition(), _FailedMaker, _UndockedMaker, _DockedMaker)    
end

function HorizonStory2Dialog4.onDockedEnd()
    invokeServerFunction("retrieveArtifactServer")
end

--endregion

--region #SERVER CALLS

function HorizonStory2Dialog4.retrieveArtifactServer()
    local _MethodName = "Retrieve Artifact Server"
    self.Log(_MethodName, "Вызов на сервере")

    local _Player = Player(callingPlayer)
    --Получить текущий корабль игрока.
    local _Ship = Entity(_Player.craftIndex)
    local _Cargo = CargoBay(_Ship)

    self.Log(_MethodName, "Проверка свободного места.")
    if _Cargo then
        if _Cargo.freeSpace >= 1 then
            self.Log(_MethodName, "Достаточно места.")
            local _Good = TradingGood("Древний артефакт", plural_t("Древний артефакт", "Древние артефакты", 1), "Загадочный артефакт. Выглядит довольно старым.", "data/textures/icons/metal-scale.png", 0, 1)
            _Good.tags = {mission_relevant = true}
            _Cargo:addCargo(_Good, 1)
            terminate()
            return
        else
            self.Log(_MethodName, "Недостаточно места.")
            --Ошибка: недостаточно места.
            _Player:sendChatMessage(Entity().title, ChatMessageType.Error,  "Вам нужно как минимум 1 место в грузовом отсеке, чтобы забрать артефакт.")
        end
    else
        --Ошибка: нет груза.
        _Player:sendChatMessage(Entity().title, ChatMessageType.Error,  "Вам нужен грузовой отсек с как минимум 1 местом для груза, чтобы забрать артефакт.")
    end

end
callable(HorizonStory2Dialog4, "retrieveArtifactServer")

--endregion

--region #SECURE / RESTORE / LOG CALLS

function HorizonStory2Dialog4.secure()
    return self._Data
end

function HorizonStory2Dialog4.restore(_Values)
    self._Data = _Values
end

function HorizonStory2Dialog4.Log(_MethodName, _Msg)
    if self._Debug and self._Debug == 1 then
        print("[Horizon Story 2 Dialog 4] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion