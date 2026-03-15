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

        local notorietyMsg = "They know of you, but you aren't a topic of conversation."
        if notoriety > 40 then notorietyMsg = "There are whispers of your name in their shipyards." end
        if notoriety > 80 then notorietyMsg = "There are mentions of your name in their shipyards." end
        if notoriety > 120 then notorietyMsg = "You are a frequent topic of discussion in their shipyards." end
        if notoriety > 160 then notorietyMsg = "Your name has a high reward attached to it, and is spoken of frequently." end

        local hatredMsg = "They are hostile to any civilization, but they don't feel strongly about you."
        if hatred > 100 then hatredMsg = "You have angered them, but they aren't willing to devote resources to hunting you down." end
        if hatred > 200 then hatredMsg = "They recognize your threat, and are actively making prepations to deal with you." end
        if hatred > 400 then hatredMsg = "They are willing to devote some amount of ships to attacking you." end
        if hatred > 600 then hatredMsg = "They are hostile towards you, and are willing to devote considerable resources to hunting you down." end
        if hatred > 800 then hatredMsg = "They hate you, and will stop at nothing to kill you." end
        if hatred > 1000 then hatredMsg = "Their hatred of you has consumed them, and they are willing to resort to increasingly extreme measures to see you dead." end

        message = "To whom it may concern,\n\nWe have infiltrated '%1%'.\n%2%\n%3%\n\nRegards"%_T
        arguments = {
            --            faction.unformattedName,
            faction.name,
            notorietyMsg,
            hatredMsg
        }

        if hatred > 200 then
            message = "To whom it may concern,\n\nWe have infiltrated '%1%'.\n%2%\n%3%\n%4%\n\nRegards"%_T
            if _TimeUntilDecap > 0 then
                table.insert(arguments, "These pirates may launch a decapitation strike against you! Their preparations will be finished in approximately " .. tostring(_HoursUntilDecap) .. " hours and " .. tostring(_ReportMinutesUntilDecap) .. " minutes." )
            else
                table.insert(arguments, "These pirates may launch a decapitation strike against you! Their preparations are finished and an attack can be launched at any time." )
            end
        end

        if hatred > 600 then
            message = "To whom it may concern,\n\nWe have infiltrated '%1%'.\n%2%\n%3%\n%4%\n%5%\n\nRegards"%_T
            table.insert(arguments, "If you have an energy suppression satellite running when these pirates attack, they may attempt to attack another location.")
        end

        local mail = Mail()
        mail.sender = "Hidden Sender"%_T
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
        local arguments = {
            faction.name,
            _CovetousArg
        }

        local _Mail = Mail()
        _Mail.sender = "Hidden Sender"%_T
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