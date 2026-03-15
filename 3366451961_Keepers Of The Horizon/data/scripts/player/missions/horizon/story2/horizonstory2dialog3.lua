package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")

HorizonUtil = include("horizonutil")

--namespace HorizonStory2Dialog3
HorizonStory2Dialog3 = {}
local self = HorizonStory2Dialog3

self._Debug = 0

self._Data = {}

--region #INIT

function HorizonStory2Dialog3.initialize(_X, _Y)
    local _MethodName = "Initialize"
    self.Log(_MethodName, "Running...")

    --This data is server side and NOT client side, so we need to send it to the client immedaitely.
    self._Data = {}
    self._Data._X = _X
    self._Data._Y = _Y

    HorizonStory2Dialog3.sync()
end

--endregion

--region #CLIENT CALLS

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function HorizonStory2Dialog3.interactionPossible(playerIndex)
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

function HorizonStory2Dialog3.initUI()
    ScriptUI():registerInteraction("Contact the Hacker", "onContact", 99)
    ScriptUI():registerInteraction("Report Lost Satellite Package", "onLostSatellite", 98)
end

function HorizonStory2Dialog3.onContact(_EntityIndex)
    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    _UI:showDialog(self.getDialog())
end

function HorizonStory2Dialog3.onLostSatellite(_EntityIndex)
    local _UI = ScriptUI(_EntityIndex)
    if not _UI then return end

    _UI:showDialog(self.getSatelliteDialog())
end

function HorizonStory2Dialog3.getDialog()
    local _MethodName = "Get Dialogue"
    self.Log(_MethodName, "Beginning...")

    local _Talker = "Hacker"
    local _TalkerColor = HorizonUtil.getDialogMaceTalkerColor()
    local _TextColor = HorizonUtil.getDialogMaceTextColor()

    local d0 = {}

    d0.text = "... Да?"
    d0.talker = _Talker
    d0.textColor = _TextColor
    d0.talkerColor = _TalkerColor

    local _JobsDone = Entity():getValue("horizon2_job_done")

    if _JobsDone then
        local d1 = {}
        local d2 = {}
        local d3 = {}
        local w1_1 = {}
        local w1_2 = {}
        local w1_3 = {}
        local w1_4 = {}
        local d4 = {}
        local d5 = {}
        local w2_1 = {}
        local w2_2 = {}
        local w2_3 = {}
        local w2_4 = {}
        local d6 = {}
        local d7 = {}
        local w3_1 = {}
        local w3_2 = {}
        local w3_3 = {}
        local w3_4 = {}
        local d8 = {}
        local d9 = {}
        local d10 = {}
        local d11 = {}

        d0.answers = {
            { answer = "Можешь расшифровать чип?", followUp = d1 }
        }

        d1.text = "Мне не нравится возиться с такими вещами. Это опасно. Никогда не знаешь, кому принадлежат данные или что они с ними делают."
        d1.followUp = d3

        d2.text = "[Передача внезапно обрывается.]"

        d3.text = "В худшем случае они узнают, что ты взломал их вещи, и придут за тобой."
        d3.answers = {
            { answer = "Я тебя защищу.", followUp = w1_1 },
            { answer = "Нет, не придут.", followUp = w1_2 },
            { answer = "Ты же до сих пор выживал.", followUp = w1_3 },
            { answer = "Мы собьем их со следа.", followUp = d4 },
            { answer = "Снова уйди в подполье.", followUp = w1_4 }
        }

        w1_1.text = "Что, навсегда? Ты же не сможешь постоянно следить за мной... и именно тогда они воткнут мне нож в спину."
        w1_2.text = "Ты этого не знаешь. Откуда тебе это знать? Ты даже не знаешь, что на этом чипе."
        w1_3.text =  "Да, не делая таких безумных вещей!"
        w1_4.text = "И позволить всей моей работе и контактам засохнуть? Забудь об этом - только в экстренных случаях. Я все еще пытаюсь оправиться от последнего раза, когда уходил в подполье."
        w1_1.followUp = d2
        w1_2.followUp = d2
        w1_3.followUp = d2
        w1_4.followUp = d2

        d4.text = "Ладно, это неплохая идея. Ты и Варланс уже напали на одну пиратскую группировку, верно? Может быть, вы могли бы напасть на вторую группировку и подбросить копию чипа в один из обломков..."
        d4.followUp = d5

        d5.text = "Но вот в чем дело. Мы не знаем, что на этом чипе. Это может быть что-то ужасное. Что-то, что мы не можем позволить попасть не в те руки."
        d5.answers = {
            { answer = "Этого не будет.", followUp = w2_1 },
            { answer = "Это не имеет значения.", followUp = w2_2 },
            { answer = "Я сам позабочусь о себе.", followUp = d6 },
            { answer = "Мы саботируем чип.", followUp = w2_3 },
            { answer = "Я буду осторожен.", followUp = w2_4 }
        }

        w2_1.text = "Да ну? Должно быть, приятно быть таким уверенным. Что ж, я не дожил до этих дней, совершая глупые риски... вроде этого."
        w2_2.text = "О чем ты говоришь? Конечно, это имеет значение. Что, если это генетический код какого-то долбанутого супервируса? Что, если это инструкции по созданию ОМП?"
        w2_3.text = "Что ты говоришь? Ты пересмотрел фильмов или что-то в этом роде? Как только ты получил информацию, уничтожение чипа не имеет значения. Когда она вышла, она вышла!"
        w2_4.text = "Это самая общая банальность, которую ты мог предложить."
        w2_1.followUp = d2
        w2_2.followUp = d2
        w2_3.followUp = d2
        w2_4.followUp = d2

        d6.text = "Твой корабль выглядит довольно впечатляюще... если я удалю информацию со своих компьютеров... Хм. Если тебя не захватят, это значит, что это не вернется ко мне."
        d6.followUp = d7

        d7.text = "Я не знаю, однако. Я все еще чувствую себя неловко из-за этого. Ты абсолютно уверен, что это хорошая идея?"
        d7.answers = {
            { answer = "Это отличная идея.", followUp = w3_1 },
            { answer = "Да, это хорошая идея.", followUp = w3_2 },
            { answer = "Нет, я не уверен.", followUp = w3_3 },
            { answer = "Да, все в порядке.", followUp = w3_4 },
            { answer = "Герои умирают однажды.", followUp = d8 }
        }

        w3_1.text = "Да? Если ты так уверен, почему бы тебе не получить технологию для взлома этого шифрования самостоятельно?"
        w3_2.text = "Нет. Нет, нет, нет. Мне все еще это не нравится. Если твои инстинкты ошибочны, я мертв. Я не готов оказывать тебе такое доверие - мы едва знакомы."
        w3_3.text = "... Тогда зачем мы вообще это делаем?"
        w3_4.text = "Не будь таким беспечным по этому поводу! Ты понятия не имеешь, что поставлено на карту!!"
        w3_1.followUp = d2
        w3_2.followUp = d2
        w3_3.followUp = d2
        w3_4.followUp = d2

        d8.text = "Ты! Ты... ты прав. Я не должен позволять страху управлять мной. Я... просто... после последней группы, с которой я имел дело... Я не хочу..."
        d8.followUp = d9

        d9.text = "Может быть, ты сможешь разобраться с ними за меня. Есть группа, которой я согласился передать артефакт, но они до смерти меня напугали. Все они были в корпоративных костюмах, но шрамы на них... то, как они себя вели..."
        d9.followUp = d10

        d10.text = "Не мог бы ты передать им артефакт за меня? Знаешь что. Если ты это сделаешь, я даже не возьму с тебя плату за взлом чипа."
        d10.answers = {
            { answer = "Конечно.", followUp = d11 }
        }

        d11.text = "Еще раз спасибо. Они находятся в (${_X}:${_Y}). Подойди к доку и возьми артефакт. Кстати, можешь называть меня Мейс." % self._Data
        d11.onEnd = "onEnd"

        for _, _d in pairs({ d1, d3, w1_1, w1_2, w1_3, w1_4, d4, d5, w2_1, w2_2, w2_3, w2_4, d6, d7, w3_1, w3_2, w3_3, w3_4, d8, d9, d10, d11 }) do
            _d.talker = _Talker
            _d.textColor = _TextColor
            _d.talkerColor = _TalkerColor
        end

        return d0
    else
        local d1 = {}
    
        d0.answers = {
            { answer = "Можешь расшифровать чип?", followUp = d1 }
        }
    
        d1.text = "Я все еще не думаю, что могу тебе доверять. Почему я должен помогать?"
        d1.talker = _Talker
        d1.textColor = _TextColor
        d1.talkerColor = _TalkerColor
    
        return d0
    end
end

function HorizonStory2Dialog3.getSatelliteDialog()
    local _MethodName = "Get Satellite Dialogue"
    self.Log(_MethodName, "Beginning...")

    local _PlayerHasSatellite = false
    local items = Player():getInventory():getItemsByType(InventoryItemType.UsableItem)
    for _, slot in pairs(items) do
        local item = slot.item

        -- we assume they're stackable, so we return here
        if item:getValue("subtype") == "HorizonStory2ResearchSatellite" then
            _PlayerHasSatellite = true
            break
        end
    end

    if Entity():getValue("horizon2_satellitejob_done") then
        _PlayerHasSatellite = true
    end

    local _Talker = "Hacker"
	local _TalkerColor = HorizonUtil.getDialogMaceTalkerColor()
	local _TextColor = HorizonUtil.getDialogMaceTextColor()

    local d0 = {}
    d0.talker = _Talker
    d0.textColor = _TextColor
    d0.talkerColor = _TalkerColor

    if _PlayerHasSatellite then
        d0.text = "... Это не смешно. Хватит тратить мое время."
    else
        d0.text = "Серьезно? Ты его потерял? Будь немного осторожнее. Они дорогие!"
        d0.onEnd = "onEndGiveSat"
    end

    return d0
end

function HorizonStory2Dialog3.onEnd()
    local _MethodName = "On End"
    self.Log(_MethodName, "Beginning.")

    Player():invokeFunction("player/missions/horizon/horizonstory2.lua", "kothStory2_contactedHacker3")
end

function HorizonStory2Dialog3.onEndGiveSat()
    local _MethodName = "On End Give Sat"
    self.Log(_MethodName, "Beginning.")

    Player():invokeFunction("player/missions/horizon/horizonstory2.lua", "kothStory2_contactedHackerGiveSat")
end

--endregion

--region #SECURE / RESTORE / LOG / SYNC CALLS

function HorizonStory2Dialog3.sync(_Data_In)
    if onServer() then
        broadcastInvokeClientFunction("sync", self._Data)
    else
        if _Data_In then
            self._Data = _Data_In
        else
            invokeServerFunction("sync")
        end
    end
end
callable(HorizonStory2Dialog3, "sync")

function HorizonStory2Dialog3.secure()
    return self._Data
end

function HorizonStory2Dialog3.restore(_Values)
    self._Data = _Values
end

function HorizonStory2Dialog3.Log(_MethodName, _Msg)
    if self._Debug and self._Debug == 1 then
        print("[Horizon Story 2 Dialog 3] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion
