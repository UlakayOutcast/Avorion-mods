package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")

-- Попробуем использовать пространство имён. Интересно, что получится.
-- namespace LLTEStory1Dialogue1
LLTEStory1Dialogue1 = {}
local self = LLTEStory1Dialogue1

self._Data = {}

self._Debug = 0

-- Инициализация
function LLTEStory1Dialogue1.initialize(_X, _Y)
    local _MethodName = "Инициализация"
    if onServer() then
        _MethodName = _MethodName .. " СЕРВЕР"
        self.Log(_MethodName, "Вызов на сервере - установка self._Data")

        self._Data._X = _X
        self._Data._Y = _Y
    else
        _MethodName = _MethodName .. " КЛИЕНТ"
        self.Log(_MethodName, "Вызов на клиенте - синхронизация")

        self.sync()
    end
end

-- Вызов клиентских функций
-- если эта функция возвращает false, скрипт не будет отображаться в окне взаимодействия,
-- даже если его интерфейс зарегистрирован
function LLTEStory1Dialogue1.interactionPossible(playerIndex)
    local _MethodName = "Возможно ли взаимодействие"
    self.Log(_MethodName, "Определение возможности взаимодействия с " .. tostring(playerIndex))
    local _Player = Player(playerIndex)

    self._PlayerIndex = playerIndex

    local craft = _Player.craft
    if craft == nil then return false end

    return true
end

function LLTEStory1Dialogue1.initUI()
    ScriptUI():registerInteraction("Связаться с информатором Кавалеров"%_t, "onContact", 99)
end

function LLTEStory1Dialogue1.onContact(_EntityIndex)
    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    _UI:showDialog(self.getDialog())
end

function LLTEStory1Dialogue1.getDialog()
    local _MethodName = "Получение диалога"
    self.Log(_MethodName, "Начало...")

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}

    d0.text = "Алло? Алло? Кто вы?"
    d0.answers = {
        {answer = "Меня послала Императрица. Я здесь от имени Кавалеров.", followUp = d1 }
    }

    d1.text = "Императрица? Хм? Чего надо?"
    d1.answers = {
        {answer = "Я ищу мощную группу пиратов.", followUp = d2 },
        {answer = "... Кто вы такой?", followUp = d3 }
    }

    d2.text = "Те парни? На самом деле они слабаки. Вы найдёте их в секторе (" .. self._Data._X .. ":" .. self._Data._Y .. "). Они должны быть лёгкой добычей."
    d2.answers = {
        { answer = "Понятно.", onSelect = "onEnd" }
    }

    d3.text = "Это не ваше дело. Так что, хотите информацию или нет?"
    d3.answers = {
        { answer = "Да.", followUp = d5 },
        { answer = "... Сначала скажите, кто вы.", followUp = d4 }
    }

    d4.text = "Серьёзно, это не ваше дело. Разве у вас нет ничего получше, чем заниматься? Берите информацию и уходите."
    d4.answers = {
        { answer = "Хорошо, хорошо.", followUp = d5 },
        { answer = "Ладно, как хотите.", followUp = d5 },
    }

    d5.text = "Отлично. Теперь, когда вы перестали тратить моё время... Те, кого вы ищете, не так сильны, как вы думаете. Вы найдёте их в секторе (" .. self._Data._X .. ":" .. self._Data._Y .. "). Держу пари, вы справитесь с ними без проблем."
    d5.onEnd = "onEnd"

    return d0
end

function LLTEStory1Dialogue1.onEnd()
    Player():invokeFunction("player/missions/empress/story/lltestorymission1.lua", "contactedInformant")
    terminate()
    return
end

-- Вызов клиентских/серверных функций
function LLTEStory1Dialogue1.sync(_X, _Y)
    local _MethodName = "Синхронизация"

    if onClient() then
        _MethodName = _MethodName .. " КЛИЕНТ"
        self.Log(_MethodName, "Начало...")
        if _X and _Y then
            self.Log(_MethodName, "Получены координаты. X: " .. tostring(_X) .. ", Y: " .. tostring(_Y))
            self._Data._X = _X
            self._Data._Y = _Y
        else
            invokeServerFunction("sync")
        end
    else
        _MethodName = _MethodName .. " СЕРВЕР"
        self.Log(_MethodName, "Начало...")

        broadcastInvokeClientFunction("sync", self._Data._X, self._Data._Y)
    end
end
callable(LLTEStory1Dialogue1, "sync")

function LLTEStory1Dialogue1.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[LLTE Story 1 Dialog 1] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

-- Сохранение и восстановление
function LLTEStory1Dialogue1.secure()
    return self._Data
end

function LLTEStory1Dialogue1.restore(_Values)
    self._Data = _Values
end

--endregion