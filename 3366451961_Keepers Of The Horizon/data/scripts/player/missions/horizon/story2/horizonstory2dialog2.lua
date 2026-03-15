package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")

HorizonUtil = include("horizonutil")

--namespace HoirzonStory2Dialog2
HoirzonStory2Dialog2 = {}
local self = HoirzonStory2Dialog2

self._Debug = 0

--region #INIT

function HoirzonStory2Dialog2.initialize()
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Running...")
end

--endregion

--region #CLIENT CALLS

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function HoirzonStory2Dialog2.interactionPossible(playerIndex)
    local _MethodName = "Interaction Possible"
    self.Log(_MethodName, "Determining interactability with " .. tostring(playerIndex))
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

function HoirzonStory2Dialog2.initUI()
    ScriptUI():registerInteraction("Contact the Hacker", "onContact", 99)
end

function HoirzonStory2Dialog2.onContact(_EntityIndex)
    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    _UI:showDialog(self.getDialog())
end

function HoirzonStory2Dialog2.getDialog()
    local _MethodName = "Get Dialogue"
    self.Log(_MethodName, "Beginning...")

    local d0 = {}
    local d1 = {}
    local d2 = {}
    local d3 = {}
    local d4 = {}
    local d5 = {}
    local d6 = {}
    local d7 = {}
    local d8 = {}
    local d9 = {}
    local d10 = {}
    local d11 = {}
    local d12 = {}
    local d13 = {}

    d0.text = "Ух! Опять ты? Я думал, я сказал тебе, что не хочу иметь с тобой ничего общего!"
    d0.answers = {
        { answer = "Успокойся.", followUp = d1 },
        { answer = "Подожди! Не заканчивай передачу!", followUp = d2 }
    }

    d1.text = "Нет! Я не хочу с тобой разговаривать! Иди к черту!"
    d1.onEnd = "onEndBad"

    d2.text = "Ладно, но у тебя должна быть чертовски веская причина, чтобы снова связываться со мной!"
    d2.answers = {
        { answer = "Есть что-нибудь, что тебе нужно сделать?", followUp = d3 }
    }

    d3.text = "... Что? Это шутка? Ты пытаешься меня разыграть?"
    d3.answers = {
        { answer = "Нет. Что тебе нужно?", followUp = d4 }, 
        { answer = "Да. Увидимся.", followUp = d6 }        
    }

    d4.text = "... Ты уверен, что не шутишь."
    d4.answers = {
        { answer = "Да. Это не шутка.", followUp = d5 },
        { answer = "Я уже не так уверен.", followUp = d6 }
    }

    d5.text = "Ммм. Ладно. В секторе нужно сделать три вещи."
    d5.followUp = d7

    d6.text = "Идиот! Я не хочу с тобой разговаривать! Иди к черту!"
    d6.onEnd = "onEndBad"

    d7.text = "Во-первых, мне нужно, чтобы один из ящиков перенесли с контейнерного поля на эту станцию. Я воспользуюсь программным обеспечением транспортера станции, чтобы забрать содержимое - я не хочу, чтобы меня видели, когда я получаю к нему доступ."
    d7.followUp = d8

    d8.text = "Далее, мне нужно развернуть спутник для мониторинга некоторых подпространственных возмущений, которые я засек вчера. Он должен находиться на расстоянии не менее 50 км от этой станции."
    d8.followUp = d9
    
    d9.text = "Наконец, мне нужно, чтобы ты уничтожил несколько астероидов здесь. Избавься от нескольких десятков для меня."
    d9.followUp = d10

    d10.text = "Ты можешь со всем этим справиться?"
    d10.answers = {
        { answer = "Да.", onSelect = "onEndGood" },
        { answer = "Зачем тебе уничтожать астероиды?", followUp = d11 }
    }

    d11.text = "Тупые капитаны торговых судов постоянно застревают на них. Я умолял диспетчерскую сектора что-нибудь с этим сделать, но они тянут время, как обычно. Прошли годы, а они до сих пор это не исправили. Можешь в это поверить?"
    d11.answers = {
        { answer = "... Да, да, я могу.", followUp = d12 },
        { answer = "Почему это проблема?", followUp = d13 }
    }

    d12.text = "... Не могу поверить, что я это говорю, но спасибо. Дай мне знать, когда закончишь."
    d12.onEnd = "onEndGood"

    d13.text = "Потому что, если капитан застрял, больше капитанов не будут прыгать в систему. Это останавливает всю экономику станции. Не знаю, как ты, но я хотел бы иметь возможность есть и пить."
    d13.answers = {
        { answer = "Окей, окей. Понял.", onSelect = "onEndGood" }
    }

    for _, _d in pairs({ d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13 }) do
        _d.talker = "Хакер"
        _d.textColor = HorizonUtil.getDialogMaceTextColor()
        _d.talkerColor = HorizonUtil.getDialogMaceTalkerColor()
    end

    return d0
end

function HoirzonStory2Dialog2.onEndBad()
    local _MethodName = "On End"
    self.Log(_MethodName, "Beginning.")

    Player():invokeFunction("player/missions/horizon/horizonstory2.lua", "kothStory2_contactedHacker2", false)
end

function HoirzonStory2Dialog2.onEndGood()
    local _MethodName = "On End"
    self.Log(_MethodName, "Beginning.")

    Player():invokeFunction("player/missions/horizon/horizonstory2.lua", "kothStory2_contactedHacker2", true)
end

--endregion

--region #CLIENT / SERVER CALLS

function HoirzonStory2Dialog2.Log(_MethodName, _Msg)
    if self._Debug and self._Debug == 1 then
        print("[Horizon Story 2 Dialog 2] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion
