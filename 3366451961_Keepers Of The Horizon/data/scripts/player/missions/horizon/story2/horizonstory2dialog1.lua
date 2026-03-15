package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")

HorizonUtil = include("horizonutil")

--namespace HorizonStory2Dialog1
HorizonStory2Dialog1 = {}
local self = HorizonStory2Dialog1

self._Debug = 0

--region #INIT

function HorizonStory2Dialog1.initialize()
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Running...")
end

--endregion

--region #CLIENT CALLS

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function HorizonStory2Dialog1.interactionPossible(playerIndex)
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

function HorizonStory2Dialog1.initUI()
    ScriptUI():registerInteraction("Contact the Hacker", "onContact", 99)
end

function HorizonStory2Dialog1.onContact(_EntityIndex)
    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    _UI:showDialog(self.getDialog())
end

function HorizonStory2Dialog1.getDialog()
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

    d0.text = "К-кто вы? Почему вы связываетесь со мной?!"
    d0.answers = { 
        { answer = "Я работаю с Варлансом.", followUp = d1},
        { answer = "У меня есть для вас работа.", followUp = d2 }
    }

    d1.text = "Варланс? Мы не разговаривали годами. Сказал ему, что мы закончили после той последней операции. П-почему ему что-то понадобилось сейчас?"
    d1.answers = {
        { answer = "Мы нашли чип с данными.", followUp = d3 }
    }

    d2.text = "Я вас не знаю! Я не могу вам доверять! Почему я должен что-то для вас делать?"
    d2.answers = {
        { answer = "Вы можете мне доверять.", followup = d4 },
        { answer = "Я вам заплачу.", followUp = d8 }
    }

    d3.text = "Чип с данными? Зачем вам моя помощь, чтобы с этим разобраться?"
    d3.answers = {
        { answer = "Он зашифрован.", followUp = d6 }
    }

    d4.text = "Нет, я не могу!! Я ничего о вас не знаю! Ваши заверения могут быть такими же пустыми, как и их!"
    d4.answers = {
        { answer = "Чьи?", followUp = d7 }
    }

    d5.text = "В галактике не хватит денег, чтобы я с этим связывался!"
    d5.onEnd = "onEnd"

    d6.text = "Зашифрован? О нет. О нет, нет, нет. Ох, неееет. Я с этим не связываюсь. Это слишком опасно."
    d6.answers = {
        { answer = "Вы можете мне доверять.", followUp = d4 },
        { answer = "Я вам заплачу.", followUp = d5 }
    }

    d7.text = "[Передача внезапно обрывается.]"
    d7.onEnd = "onEnd"

    d8.text = "Я не знаю, какую работу вы предлагаете, но в галактике не хватит денег, чтобы я с этим связывался! Не после... О нет. Не стоило мне этого говорить-"
    d8.followUp = d7

    for _, _d in pairs({ d0, d1, d2, d3, d4, d5, d6, d8 }) do
        _d.talker = "Хакер"
        _d.textColor = HorizonUtil.getDialogMaceTextColor()
        _d.talkerColor = HorizonUtil.getDialogMaceTalkerColor()
    end

    return d0
end

function HorizonStory2Dialog1.onEnd()
    local _MethodName = "On End"
    self.Log(_MethodName, "Beginning.")

    Player():invokeFunction("player/missions/horizon/horizonstory2.lua", "kothStory2_contactedHacker")
end

--endregion

--region #CLIENT / SERVER CALLS

function HorizonStory2Dialog1.Log(_MethodName, _Msg)
    if self._Debug and self._Debug == 1 then
        print("[Horizon Story 2 Dialog 1] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion
