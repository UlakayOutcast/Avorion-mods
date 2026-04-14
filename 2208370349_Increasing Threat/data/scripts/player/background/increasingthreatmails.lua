package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace IncreasingThreatMails
IncreasingThreatMails = {}

IncreasingThreatMails._Debug = 0

if onServer() then

    function IncreasingThreatMails.onInformantHired(factionIndex)
        IncreasingThreatMails.sendUpdateMail(factionIndex)
    end

    function IncreasingThreatMails.sendUpdateMail(factionIndex)
        local faction = Faction(factionIndex)
        if not faction then return end

        local player = Player()
        local _Time = Server().unpausedRuntime
        local _DecapTime = player:getValue("_increasingthreat_next_decap")
        local _TimeUntilDecap = 0
        if _DecapTime then
            _TimeUntilDecap = _DecapTime - _Time
        end
        --Don't give the player an exact number - fudge by +/- 20 minutes.
        local _FudgeTime = 1200 - random():getInt(0, 2400)
        local _ReportTimeUntilDecap = _TimeUntilDecap + _FudgeTime
        local _MinutesUntilDecap = math.floor(_ReportTimeUntilDecap / 60)
        local _HoursUntilDecap = math.floor(_MinutesUntilDecap / 60)
        local _ReportMinutesUntilDecap = _MinutesUntilDecap - (_HoursUntilDecap * 60)

        -- faction name
        -- notoriety
        local notoriety = player:getValue("_increasingthreat_notoriety") or 0
        local hatredindex = "_increasingthreat_hatred_" .. factionIndex
        local hatred = player:getValue(hatredindex) or 0
        -- hatred
        -- traits

        local message
        local arguments = {}

        local notorietyMsg = "Они знают о тебе, но ты не являешься темой для разговоров."
        if notoriety > 40 then notorietyMsg = "На их верфях шепотом произносят твое имя." end
        if notoriety > 80 then notorietyMsg = "На их верфях есть упоминания вашего имени." end
        if notoriety > 120 then notorietyMsg = "Ты - частая тема для обсуждения на их верфях." end
        if notoriety > 160 then notorietyMsg = "С твоим именем связана высокая награда, и о нем часто говорят." end

        local hatredMsg = "Они враждебны к любой цивилизации, но не питают к тебе особых чувств."
        if hatred > 100 then hatredMsg = "Ты разозлил их, но они не хотят тратить ресурсы на то, чтобы выслеживать тебя." end
        if hatred > 200 then hatredMsg = "Они распознают твою угрозу и активно готовятся к тому, чтобы расправиться с тобой." end
        if hatred > 400 then hatredMsg = "Они готовы выделить некоторое количество кораблей для нападения на тебя." end
        if hatred > 600 then hatredMsg = "Они настроены по отношению к тебе враждебно и готовы потратить значительные ресурсы на то, чтобы выследить тебя." end
        if hatred > 800 then hatredMsg = "Они ненавидят тебя и не остановятся ни перед чем, чтобы убить." end
        if hatred > 1000 then hatredMsg = "Их поглотила ненависть к тебе, и они готовы прибегнуть ко все более крайним мерам, чтобы увидеть тебя мертвым." end

        message = "Для тех, кого это может касаться,\n\nмы внедрились в '%1%'.\n%2%\n%3%\n\nRegards"%_T
        arguments = {
            --            faction.unformattedName,
            faction.name,
            notorietyMsg,
            hatredMsg
        }

        if hatred > 200 then
            message = "К тем, кого это может касаться,\n\nмы проникли '%1%'.\n%2%\n%3%\n%4%\n\nRegards"%_T
            if _TimeUntilDecap > 0 then
                table.insert(arguments, "Эти пираты могут нанести вам сокрушительный удар! Их приготовления будут завершены примерно через " .. tostring(_HoursUntilDecap) .. " hours and " .. tostring(_ReportMinutesUntilDecap) .. " minutes." )
            else
                table.insert(arguments, "Эти пираты могут нанести вам сокрушительный удар! Они закончили подготовку и могут начать атаку в любой момент." )
            end
        end

        if hatred > 600 then
            message = "К тем, кого это может касаться,\n\nмы проникли '%1%'.\n%2%\n%3%\n%4%\n%5%\n\nRegards"%_T
            table.insert(arguments, "Если у вас работает спутник энергетического подавления, то во время нападения этих пиратов они могут попытаться атаковать другое место.")
        end

        local mail = Mail()
        mail.sender = "Скрытый отправитель"%_T
        mail.receiver = player.id
        --    mail.header = Format("Surveillance Report of Faction '%1%'"%_T, faction.unformattedName)
        mail.header = Format("Infiltration Report, '%1%'"%_T, faction.name)
        mail.text = Format(message, unpack(arguments))

        player:addMail(mail)
    end

    function IncreasingThreatMails.onBriberHired(factionIndex)
        local _MethodName = "On Briber Hired"
        local faction = Faction(factionIndex)
        if not faction then return end

        local player = Player()

        local hatredindex = "_increasingthreat_hatred_" .. factionIndex
        local hatred = player:getValue(hatredindex) or 0

        local _Covetous = faction:getTrait("covetous")
        local _ReductionFactor = 0.2
        local _CovetousArg = ""
        if _Covetous and _Covetous >= 0.25 then
            IncreasingThreatMails.Log(_MethodName, "Pirates are covetous. Bribes are more effective.")
            _ReductionFactor = _ReductionFactor * 1.5
            _CovetousArg = "eagerly "
        end

        local _NewHatred = math.ceil(hatred * (1.0 - _ReductionFactor))
        player:setValue(hatredindex, _NewHatred)

        IncreasingThreatMails.Log(_MethodName, "Hatred value is " .. tostring(hatred) .. " new hatred value is " .. tostring(_NewHatred))

        local message = "To whom it may concern,\n\n'%1%' have %2%accepted your bribe. They will feel slightly more amicably towards in the immediate future.\n\nRegards"%_T
        local message = "Для тех, кого это может касаться,\n\n'%1%' уже '%2%' приняли вашу взятку. В ближайшем будущем они будут относиться к вам немного дружелюбнее.\n\nRegards"%_T
        local arguments = {
            faction.name,
            _CovetousArg
        }

        local _Mail = Mail()
        _Mail.sender = "Скрытый отправитель"%_T
        _Mail.receiver = player.id
        _Mail.header = Format("Bribery Report, '%1%'"%_T, faction.name)
        _Mail.text = Format(message, unpack(arguments))

        player:addMail(_Mail)
    end

end

function IncreasingThreatMails.Log(_MethodName, _Msg)
    if IncreasingThreatMails._Debug == 1 then
        print("[IT Mails] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end