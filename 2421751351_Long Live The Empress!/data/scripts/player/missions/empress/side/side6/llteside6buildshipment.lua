package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")

-- namespace LLTESide6BuildShipment
LLTESide6BuildShipment = {}
local self = LLTESide6BuildShipment

self._Data = {}

self._Debug = 0

-- Настройка
function LLTESide6BuildShipment.initialize()
    local _MethodName = "Инициализация"
    if onServer() then
        self.Log(_MethodName, "Вызов на сервере")
    else
        self.Log(_MethodName, "Вызов на клиенте")
    end
end

-- Вызов серверных функций
function LLTESide6BuildShipment.startServerJob()
    local _MethodName = "Запуск серверной задачи"
    self.Log(_MethodName, "Вызов на сервере")

    local _Player = Player(callingPlayer)

    if not self._Data._RunningJob then
        self.Log(_MethodName, "Игрок " .. _Player.name .. " платит 5000 Авориона — запуск серверной/клиентской задачи по созданию груза.")

        if _Player:canPayResource(Material(MaterialType.Avorion), 5000) then
            _Player:payResource("Оплачено 5000 Авориона для создания груза.", Material(MaterialType.Avorion), 5000)
            self._Data._RunningJob = { _Executed = 0, _Duration = 10, _PlayerFor = _Player.index }
            broadcastInvokeClientFunction("startClientJob")
        else
            _Player:sendChatMessage(Entity(), ChatMessageType.Normal, "У вас недостаточно Авориона, чтобы создать груз!")
        end
    else
        _Player:sendChatMessage(Entity(), ChatMessageType.Normal, "Ваш груз Авориона уже создаётся!")
    end
end
callable(LLTESide6BuildShipment, "startServerJob")

-- Вызов клиентских функций
function LLTESide6BuildShipment.interactionPossible(playerIndex)
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

function LLTESide6BuildShipment.initUI()
    ScriptUI():registerInteraction("Создать груз Авориона", "startJob", 99)
end

function LLTESide6BuildShipment.startJob(_EntityIndex)
    local _MethodName = "Запуск задачи"
    if onClient() then
        self.Log(_MethodName, "Вызов серверной функции")
        invokeServerFunction("startServerJob")
    end
end

function LLTESide6BuildShipment.startClientJob()
    self._Data._RunningJob = { _Executed = 0, _Duration = 10 }
end

function LLTESide6BuildShipment.renderUIIndicator(px, py, size)
    local x = px - size / 2
    local y = py + size / 2

    if self._Data._RunningJob then
        local _Executed = self._Data._RunningJob._Executed
        local _Duration = self._Data._RunningJob._Duration

        if _Executed < _Duration then
            -- Внешний прямоугольник
            local dx = x
            local dy = y

            local sx = size + 2
            local sy = 4

            drawRect(Rect(dx, dy, sx + dx, sy + dy), ColorRGB(0, 0, 0))

            -- Внутренний прямоугольник
            sx = sx - 2
            sy = sy - 2

            sx = sx * _Executed / _Duration

            drawRect(Rect(dx + 1, dy + 1, sx + dx + 1, sy + dy + 1), ColorRGB(0.66, 0.66, 1.0))
        end
    end
end

-- Обновление
function LLTESide6BuildShipment.getUpdateInterval()
    return 1.0
end

function LLTESide6BuildShipment.update(_TimeStep)
    local _MethodName = "Обновление создания груза"
    if self._Data._RunningJob then
        self.Log(_MethodName, "Обновление выполняемой задачи.")
        self._Data._RunningJob._Executed = self._Data._RunningJob._Executed + _TimeStep

        local _Executed = self._Data._RunningJob._Executed
        local _Duration = self._Data._RunningJob._Duration

        if _Executed >= _Duration then
            -- Добавление скрипта получения груза к объекту, затем завершение этого скрипта.
            -- Очевидно, это делается только на сервере.
            if onServer() then
                self.Log(_MethodName, "Выполнено " .. tostring(_Executed) .. " равно или превышает длительность " .. tostring(_Duration) .. " — завершение и добавление getShipment")
                local _Entity = Entity()
                local f = Faction(self._Data._RunningJob._PlayerFor)
                if f then
                    f:sendChatMessage(Entity(), ChatMessageType.Normal, "Мы закончили создание груза Авориона. Вы можете забрать его в секторе (%1%:%2%)."%_t, Sector():getCoordinates())
                end
                _Entity:addScriptOnce("player/missions/empress/side/side6/llteside6getshipment.lua")
                terminate()
                return
            end
        end
    end
end

function LLTESide6BuildShipment.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[LLTE Side 6 Build Shipment] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

-- Сохранение и восстановление
function LLTESide6BuildShipment.secure()
    return self._Data
end

function LLTESide6BuildShipment.restore(_Values)
    self._Data = _Values
end

--endregion