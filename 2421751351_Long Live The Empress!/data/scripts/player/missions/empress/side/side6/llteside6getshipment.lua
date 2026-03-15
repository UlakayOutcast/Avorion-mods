package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")
include("player")

MissionUT = include("missionutility")

-- namespace LLTESide6GetShipment
LLTESide6GetShipment = {}
local self = LLTESide6GetShipment

self._Data = {}

self._Debug = 0

-- Настройка
function LLTESide6GetShipment.initialize()
    local _MethodName = "Инициализация"
    if onServer() then
        self.Log(_MethodName, "Вызов на сервере")
    else
        self.Log(_MethodName, "Вызов на клиенте")
    end
end

-- Вызов серверных функций
function LLTESide6GetShipment.retrieveShipmentServer()
    local _MethodName = "Получение груза (сервер)"
    self.Log(_MethodName, "Вызов на сервере")

    local _Player = Player(callingPlayer)
    -- Получаем текущий корабль игрока.
    local _Ship = Entity(_Player.craftIndex)
    local _Cargo = CargoBay(_Ship)

    self.Log(_MethodName, "Проверка свободного места.")
    if _Cargo then
        if _Cargo.freeSpace >= 75 then
            self.Log(_MethodName, "Достаточно места.")
            local _Good = TradingGood("Груз Авориона", plural_t("Груз Авориона", "Грузы Авориона", 1), "Ящик, полный Авориона", "data/textures/icons/lead.png", 358000, 75)
            _Cargo:addCargo(_Good, 1)
            terminate()
            return
        else
            self.Log(_MethodName, "Недостаточно места.")
            -- Ошибка: недостаточно места.
            _Player:sendChatMessage(Entity().title, ChatMessageType.Error, "Вам нужно как минимум 75 единиц грузового пространства, чтобы забрать груз.")
        end
    else
        -- Ошибка: нет грузового отсека.
        _Player:sendChatMessage(Entity().title, ChatMessageType.Error, "Вам нужен грузовой отсек с как минимум 75 единицами грузового пространства, чтобы забрать груз.")
    end
end
callable(LLTESide6GetShipment, "retrieveShipmentServer")

-- Вызов клиентских функций
function LLTESide6GetShipment.interactionPossible(playerIndex)
    local _MethodName = "Возможно ли взаимодействие"
    self.Log(_MethodName, "Определение возможности взаимодействия с " .. tostring(playerIndex))
    local _Player = Player(playerIndex)

    self._PlayerIndex = playerIndex

    -- Если у игрока нет скрипта побочной миссии 6, просто завершаем.
    if not _Player:hasScript("lltesidemission6.lua") then
        terminate()
        return
    end

    local craft = _Player.craft
    if craft == nil then return false end

    return true
end

function LLTESide6GetShipment.initUI()
    ScriptUI():registerInteraction("Забрать груз Авориона", "onRetrieve", 99)
end

function LLTESide6GetShipment.onRetrieve(_EntityIndex)
    local _MethodName = "Забрать груз"
    self.Log(_MethodName, "Начало...")
    -- Используем MissionUT для двух диалогов. Один из них должен вызвать серверную функцию для получения товара.
    local _Condition = function() return true end -- Нет условий — как только мы сюда попали, это должно всегда сработать.

    local _DockedMaker = function()
        local _Docked = {}
        _Docked.text = "Сейчас передам груз."
        _Docked.onEnd = "onDockedEnd"

        return _Docked
    end

    local _UndockedMaker = function()
        local _Undocked = {}
        _Undocked.text = "Вам нужно пристыковаться, чтобы мы могли передать груз. Подойдите к ближайшему док-порту, и мы передадим его в кратчайшие сроки."

        return _Undocked
    end

    local _FailedMaker = function()
        return {}
    end

    self.Log(_MethodName, "Получение диалога выбора стыковки.")
    MissionUT.dockedDialogSelector(Entity().index, _Condition(), _FailedMaker, _UndockedMaker, _DockedMaker)
end

function LLTESide6GetShipment.onDockedEnd()
    invokeServerFunction("retrieveShipmentServer")
end

-- Логирование
function LLTESide6GetShipment.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[LLTE Side 6 Get Shipment] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

-- Сохранение и восстановление
function LLTESide6GetShipment.secure()
    return self._Data
end

function LLTESide6GetShipment.restore(_Values)
    self._Data = _Values
end

--endregion