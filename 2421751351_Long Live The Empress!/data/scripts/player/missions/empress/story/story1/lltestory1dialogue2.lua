package.path = package.path .. ";data/scripts/lib/?.lua"

LLTEUtil = include("llteutil")

include("stringutility")
include("callable")

-- Попробуем использовать пространство имён. Интересно, что получится.
-- namespace LLTEStory1Dialogue2
LLTEStory1Dialogue2 = {}
local self = LLTEStory1Dialogue2

self._Data = {}

self._Debug = 0

function LLTEStory1Dialogue2.initialize()
    self._Data._Traitor = LLTEUtil.getRandomName(true, true)
end

-- если эта функция возвращает false, скрипт не будет отображаться в окне взаимодействия,
-- даже если его интерфейс зарегистрирован
function LLTEStory1Dialogue2.interactionPossible(playerIndex)
    local _MethodName = "Возможно ли взаимодействие"
    self.Log(_MethodName, "Определение возможности взаимодействия с " .. tostring(playerIndex))
    local _Player = Player(playerIndex)

    self._PlayerIndex = playerIndex

    local craft = _Player.craft
    if craft == nil then return false end

    return true
end

function LLTEStory1Dialogue2.initUI()
    ScriptUI():registerInteraction("Связаться с предателем"%_t, "onContact", 99)
end

function LLTEStory1Dialogue2.onContact(_EntityIndex)
    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    _UI:showDialog(self.getDialog())
end

function LLTEStory1Dialogue2.getDialog()
    local _MethodName = "Получение диалога"
    self.Log(_MethodName, "Начало...")

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}
    local d7 = {}
    local d8 = {}

    d0.text = "Алло? Кто там на этот раз? Чего надо?"
    d0.answers = {
        { answer = "Я вернулся.", followUp = d1 },
        { answer = "Сюрприз.", followUp = d1 }
    }

    d1.text = "Э-э... я... я... э... п-привет."
    d1.answers = {
        {answer = "Ты пытался меня убить.", followUp = d2 }
    }

    d2.text = "Н-ну, послушай. Когда ты... ЭЙ! ПОДОЖДИ! НЕТ! [БАХ-БАХ-БАХ-БАХ-БАХ] ААААААААААА-"
    d2.answers = {
        { answer = "... Алло?", followUp = d3 }
    }

    local _Name = self._Data._Traitor.name
    local _Pn1 = self._Data._Traitor.pn1
    local _Pn2 = self._Data._Traitor.pn2
    local _Tense = self._Data._Traitor.ptense

    d3.text = "Здравствуйте! Приносим извинения за " .. _Name .. ". Если бы мы знали, что " .. _Pn1 .. " " .. _Tense .. " крот, мы бы разобрались с " .. _Pn2 .. " раньше. Что вам нужно?"
    d3.answers = {
        { answer = "Вы что-нибудь знаете о мощной группе пиратов?", followUp = d8 }
    }

    d8.text = "... Возможно. Кто спрашивает?"
    d8.answers = {
        { answer = "Кавалеры.", followUp = d4 }
    }

    d4.text = "Кавалеры, да? Как поживает Адриана?"
    d4.answers = {
        { answer = "Теперь она Императрица.", followUp = d5 }
    }

    d5.text = "Она действительно сделала это? Удивительно. Мы с ней давно знакомы. Если ей нужна услуга, я помогу. Я знаю группу, о которой вы говорите. Они мерзкие и сильные. Я могу указать вам на них, но сначала лучше ослабить их."
    d5.answers = {
        { answer = "Я слушаю.", followUp = d6 }
    }

    d6.text = "У меня есть информация о нескольких грузовых отправках, которые они организуют. Если вы сможете их уничтожить, это подкосит их. Я загружаю данные в ваш компьютер. Когда найдёте их, грузовые корабли, несомненно, попытаются сбежать. Не позволяйте им прыгать слишком много раз, иначе вы можете потерять их след."
    d6.answers = {
        { answer = "Понял. Спасибо.", onSelect = "onEnd" },
        { answer = "Как я могу быть уверен, что тебе можно доверять?", followUp = d7 }
    }

    d7.text = "Не можете. Извините. Ничего не могу с этим поделать. Но позвольте сказать так: даже если я веду вас в другую засаду, вы сможете убить больше пиратов. Это само по себе награда, не так ли?"
    d7.answers = {
        { answer = "Хех. Это хороший аргумент.", onSelect = "onEnd" },
        { answer = "Довольно убедительно. Спасибо.", onSelect = "onEnd" }
    }

    return d0
end

function LLTEStory1Dialogue2.onEnd()
    Player():invokeFunction("player/missions/empress/story/lltestorymission1.lua", "contactedTraitor")
    terminate()
    return
end

-- Вызов клиентских/серверных функций
function LLTEStory1Dialogue2.Log(_MethodName, _Msg, _OverrideDebug)
    local _TempDebug = self._Debug
    if _OverrideDebug then self._Debug = _OverrideDebug end
    if self._Debug and self._Debug == 1 then
        print("[LLTE Story 1 Dialog 2] - [" .. _MethodName .. "] - " .. _Msg)
    end
    if _OverrideDebug then self._Debug = _TempDebug end
end

--endregion