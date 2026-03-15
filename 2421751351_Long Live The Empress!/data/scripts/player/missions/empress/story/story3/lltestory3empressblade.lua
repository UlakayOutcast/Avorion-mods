package.path = package.path .. ";data/scripts/lib/?.lua"

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace LLTEStory3EmpressBlade
LLTEStory3EmpressBlade = {}

-- make the NPC talk to players
LLTEStory3EmpressBlade = include("npcapi/singleinteraction")
MissionUT = include("missionutility")

include("stringutility")

local data = LLTEStory3EmpressBlade.data
data.closeableDialog = false

function LLTEStory3EmpressBlade.getDialog()
    --This is the largest dialog tree I have ever built, ever. I actually had to use an external tool to make sure everything was linked correctly.
    local d0 = LLTEStory3EmpressBlade.getStandardDialog()
    local d1 = LLTEStory3EmpressBlade.getStandardDialog()
    local d2 = LLTEStory3EmpressBlade.getStandardDialog()
    local d3 = LLTEStory3EmpressBlade.getStandardDialog()
    local d4 = LLTEStory3EmpressBlade.getStandardDialog()
    local d5 = LLTEStory3EmpressBlade.getStandardDialog()
    local d6 = LLTEStory3EmpressBlade.getStandardDialog()
    local d7 = LLTEStory3EmpressBlade.getStandardDialog()
    local d8 = LLTEStory3EmpressBlade.getStandardDialog()
    local d9 = LLTEStory3EmpressBlade.getStandardDialog()
    local d10 = LLTEStory3EmpressBlade.getStandardDialog()
    local d11 = LLTEStory3EmpressBlade.getStandardDialog()
    local d12 = LLTEStory3EmpressBlade.getStandardDialog()
    local d13 = LLTEStory3EmpressBlade.getStandardDialog()
    local d14 = LLTEStory3EmpressBlade.getStandardDialog()
    local d15 = LLTEStory3EmpressBlade.getStandardDialog()
    local d16 = LLTEStory3EmpressBlade.getStandardDialog()
    local d17 = LLTEStory3EmpressBlade.getStandardDialog()
    local d18 = LLTEStory3EmpressBlade.getStandardDialog()
    local d19 = LLTEStory3EmpressBlade.getStandardDialog()
    local d20 = LLTEStory3EmpressBlade.getStandardDialog() --I accidentally left d20 out of my outline, so it gets left out of the tree below too. Fuck renumbering everything.
    local d21 = LLTEStory3EmpressBlade.getStandardDialog()
    local d22 = LLTEStory3EmpressBlade.getStandardDialog()
    local d23 = LLTEStory3EmpressBlade.getStandardDialog()
    local d24 = LLTEStory3EmpressBlade.getStandardDialog()
    local d25 = LLTEStory3EmpressBlade.getStandardDialog()

    local _Player = Player()

    local _PlayerRank = _Player:getValue("_llte_cavaliers_rank")
    local _PlayerName = _Player.name
    local _VanillaStoryAdvancement = _Player:getValue("story_advance") or 0
    local _PlayerCrossedBarrier = _VanillaStoryAdvancement >= 6
    local _PlayerFoundAvorion = _Player:getValue("encyclopedia_avorion_found")
    
    --d0
    d0.text = "Hello " .. _PlayerRank .. "! It's good to see you again."
    d0.answers = {
        { answer = "What's on your mind?", followUp = d1 },
        { answer = "You wanted to talk?" , followUp = d1 }
    }
    
    --d1
    d1.text = "I wanted to talk to you about the future of The Cavaliers."
    d1.answers = {
        { answer = "What about it?", followUp = d2 }
    }

    --d2
    d2.text = "We can crush pirates forever. We're great at that! But there's the matter of the Xsotan. We can't destroy them like pirates - they come from the center of the galaxy, and there's no way past the barrier."
    d2.answers = {
        { answer = "That's true.", followUp = d3 }
    }
    if _PlayerCrossedBarrier and _PlayerFoundAvorion then
        table.insert(d2.answers, {answer = "Well, about that...", followUp = d4})
    end

    --d3
    d3.text = "We're not the only ones, at least. Nobody else has seen the galactic core for 200 years. I guess the best we can do is continue destroying the pirates as they start to consolidate power, and continue to cleanse Xsotan infestations as they appear."
    d3.answers = {
        { answer = "What would you do if you could get past it?", followUp = d5},
        { answer = "Maybe someone will get past it someday.", followUp = d6 }
    }

    --d4
    d4.text = "What do you mean?"
    d4.answers = {
        { answer = "I've been past the barrier.", followUp = d11 },
        { answer = "Never mind.", followUp = d12 }
    }

    --d5
    d5.text = "We would establish ourselves as the most powerful military in the galactic core, and then destroy any pirates that may be there while researching where the Xsotan come from."
    d5.answers = {
        { answer = "A worthy goal.", onSelect = "onEndNormal" },
        { answer = "What happens when you've destroyed the Xsotan?", followUp = d7 }
    }

    --d6
    d6.text = "Maybe! That would be a day worthy of celebration! Can you imagine what it would be like for the entire galaxy to be reunited?"
    d6.answers = {
        { answer = "Who knows? It has been 200 years.", followUp = d8 },
        { answer = "War, probably.", followUp = d9 },
        { answer = "It would be a glorious day.", followUp = d24 }
    }

    --d7
    d7.text = "There will always be pirates, but we will have achieved our goal of true peace in the galaxy. The factions will recognize us as heroes, and we'll know that those who can't fight for themselves are safe."
    d7.onEnd = "onEndNormal"

    --d8
    d8.text = "Indeed. I suppose the only way to find out is for someone to make it past!"
    d8.answers = {
        { answer = "You're right about that.", onSelect = "onEndNormal" }
    }
    if _PlayerCrossedBarrier and _PlayerFoundAvorion then
        table.insert(d8.answers, {answer = "Well, about that...", followUp = d4})
    end

    --d9
    d9.text = "I wouldn't be so quick to assume that! 200 years is a long time, true, but it isn't quite enough for a faction to forget their own history. Also, there are some longer-lived species that may have a better memory of the events."
    d9.answers = {
        { answer = "That's a good point.", followUp = d10 }
    }

    --d10
    d10.text = "Besdies, if a large war did start... Well, we've got the strongest military in the galaxy! We could easily put a stop to it ourselves."
    d10.onEnd = "onEndNormal"

    --d11
    d11.text = "You... you have?! This changes everything! How did you do it?"
    d11.answers = {
        { answer = "There's a long quest involving 8 artifacts and a portal.", followUp = d13 }
    }

    --d12
    d12.text = "Are you sure? Whatever it is, you can trust me."
    d12.answers = {
        { answer = "I've been past the barrier.", followUp = d11},
        { answer = "It's nothing. Don't worry about it.", onSelect = "onEndNormal" }
    }

    --d13
    d13.text = "That sounds... unnecessarily convoluted. Is there any way we could help?"
    d13.answers = {
        { answer = "No need. There's an easier way.", followUp = d14 },
        { answer = "You already have.", followUp = d15 }
    }

    --d14
    d14.text = "There is? What would that be?"
    d14.answers = {
        { answer = "There is a material that allows you to bypass hyperspace rifts.", followUp = d16 }
    }

    --d15
    d15.text = "I'm glad we could be of assistance!"
    d15.answers = {
        { answer = "I'm glad you could too. Thanks for the help.", onSelect = "onEndNormal" },
        --Yes, this locks you into making the offer. You don't get to be a dick here and rescind it. If you have an issue with that, I'm not sorry. You've had plenty of opportunities to shut down the conversation before now.
        { answer = "Would you like to see the galactic core for yourself?", followUp = d17 } 
    }

    --d16
    d16.text = "There is? I've never heard of such a thing. What can you tell me about it?"
    d16.answers = {
        { answer = "It's called Avorion. It is only available in the core.", followUp = d19 }
    }

    --d17
    d17.text = "Yes! I don't think many would say no to an adventure like that."
    d17.answers = {
        { answer = "There is a material that allows you to bypass hyperspace rifts.", followUp = d18 }
    }

    --d18
    d18.text = "If you've been inside the core yourself, and since you asked if I'd like to see it... I assume you have some?"
    d18.answers = {
        { answer = " I do, and I would be willing to trade.", followUp = d21 }
    }

    --d19
    d19.text = "That would explain why I've never heard of it. I've haven't had the time to go chasing rumors. Would you... be willing to trade with us?"
    d19.answers = {
        { answer = "Yes.", followUp = d21 },
        { answer = "No. It's too risky.", followUp = d22 }
    }

    --d21
    d21.text = "Yes! That would be amazing! Thank you so much, " .. _PlayerName .. "!"
    d21.answers = {
        { answer = "How do I get it to you?", followUp = d23 }
    }

    --d22
    d22.text = "Ah... that is... I... I understand. Agents from The Family or The Commune could potentially get their hands on some, and who knows what would happen then?"
    d22.followUp = d25

    --d23
    d23.text = "We'll set up a way to secure a delivery. With agents from The Family and The Commune still lurking around, though... I think I would only trust someone who works for you, or an ally that you work with closely. Watch for one of our scouts. They'll contact you with the necessary details."
    d23.answers = {
        { answer = "I'll do that.", onSelect = "onEndGood" },
        --You can simp. I thought of making it so you can megasimp, but this is a space game. If you're that thirsty, go play a dating simulator.
        { answer = "I'll do that. Take care, Adriana.", onSelect = "onEndGood" }
    }

    --d24
    d24.text = "It would be! Perhaps someday, we can make it happen."
    d24.onEnd = "onEndNormal"

    --d25
    d25.text = "Well. We'll be here if you change your mind. Take care, " .. _PlayerRank .. "."
    d25.onEnd = "onEndNormal"

    return d0
end

function LLTEStory3EmpressBlade.getStandardDialog()
    local dx = {}

    local _Talker = "Adriana Stahl"
    local _TalkerColor = MissionUT.getDialogTalkerColor1()
    local _TextColor = MissionUT.getDialogTextColor1()

    dx.talker = _Talker
    dx.textColor = _TextColor
    dx.talkerColor = _TalkerColor

    return dx
end

function LLTEStory3EmpressBlade.onEndGood()
    Player():invokeFunction("player/missions/empress/story/lltestorymission3.lua", "goodEnd")
end

function LLTEStory3EmpressBlade.onEndNormal()
    Player():invokeFunction("player/missions/empress/story/lltestorymission3.lua", "normalEnd")
end