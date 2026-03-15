package.path = package.path .. ";data/scripts/lib/?.lua"

include ("galaxy")
include ("stringutility")
include ("randomext")
include ("callable")
include ("relations")
include ("goods")
local Dialog = include ("dialogutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace RescueSlavesControl
RescueSlavesControl = {}

local data = {}
data.controlledByIndices = {}
data._Debug = 0
function RescueSlavesControl.initialize()
    local methodName = "Initialize"

    RescueSlavesControl.Log(methodName, "Running v14")
end

function RescueSlavesControl.interactionPossible(playerIndex)
    local methodName = "Interaction Possible"

    RescueSlavesControl.Log(methodName, "Running.")

    local trader = Entity()
    local isPirate = trader:getValue("is_pirate")

    if isPirate then
        --No need to process anything else.
        return false
    end

    local faction = Faction()
    local player = Player()
    local pindex = trader:getValue("rescueslaves_mission_player")

    if player then player = player.craftFaction end

    if player and faction and playerIndex == pindex then
        local relation = player:getRelation(faction.index)
        if relation.status == RelationStatus.War then 
            return false 
        end
        if relation.level <= -80000 then 
            return false 
        end

        return true
    end

    return false
end

function RescueSlavesControl.initUI()
    ScriptUI():registerInteraction("[Scan for Slaves]"%_t, "onScanSelected");
end

function RescueSlavesControl.getUpdateInterval()
    return 5
end

function RescueSlavesControl.updateServer(_TimeStep)
    if data._Murderous then
        RescueSlavesControl.murderRescuedSlave()
    end
end

function RescueSlavesControl.onScanSelected()
    local player = Player()

    for _, index in pairs(data.controlledByIndices) do
        if player.index == index then
            local traderUI = ScriptUI()
            traderUI:showDialog(Dialog.empty())
            traderUI:interactShowDialog(RescueSlavesControl.makeNotAgainDialog(), true)
            return -- don't allow double control
        end
    end

    local traderUI = ScriptUI()
    traderUI:showDialog(Dialog.empty())
    invokeServerFunction("onScanSelectedServer", player.index)
end

function RescueSlavesControl.onScanSelectedServer(playerIndex)
    local bribe = RescueSlavesControl.calculateBribe()
    local player = Player(playerIndex)

    local craft = player.craft
    if not craft then
        bribe = 0
    end

    data._bribe = bribe

    -- we don't care about the player DPS
    local trader = Entity()
    local traderHasSlaves = trader:getValue("rescueslaves_has_slaves")

    if traderHasSlaves then
        invokeClientFunction(player, "onHitDialog", bribe)
    else
        broadcastInvokeClientFunction("onNoHitDialog")
    end
end
callable(RescueSlavesControl, "onScanSelectedServer")

function RescueSlavesControl.onNoHitDialog()
    local traderUI = ScriptUI()
    traderUI:showDialog(Dialog.empty())
    traderUI:interactShowDialog(RescueSlavesControl.makeControlDialogNoHit(), true)
end

function RescueSlavesControl.onHitDialog(bribe)
    local methodName = "On Hit Dialog"

    RescueSlavesControl.Log(methodName, "Running on hit dialog.")

    local traderUI = ScriptUI()
    traderUI:showDialog(Dialog.empty())
    traderUI:interactShowDialog(RescueSlavesControl.makeControlDialogHit(bribe), true)
end

--region #DIALOG FUNCS

-- Ship has illegal cargo
function RescueSlavesControl.makeControlDialogHit(bribe)
    local methodName = "Make Control Dialog Hit"
    
    local _random = random()

    local d0_dialog = {}
    local d1_bribe = {}
    local d1_comply = {}
    local d1_taunt = {}
    local d1_runaway = {}
    local d1_murder = {}
    local d2_bribe = {}
    local d2_runaway = {}

    local dialogBranch = _random:getInt(1, 4) --Can't code golf this one - we log it below.
    RescueSlavesControl.Log(methodName, "Running dialog branch " .. tostring(dialogBranch))
    --Even split between comply / bribe / taunt / run
    local answerTable1 = { d1_bribe, d1_comply, d1_runaway, d1_taunt }
    local _answer = answerTable1[dialogBranch]

    --If the player threatens on the bribe, even split between run / comply
    local answerTable2 = { d1_comply, d1_runaway }
    local _bribeThreatenAnswer = answerTable2[_random:getInt(1, 2)]

    --If the player threatens on taunt, even split between run / comply / murder
    local answerTable3 = { d1_runaway, d1_comply, d1_murder }
    local _tauntThreatenAnswer = answerTable3[_random:getInt(1, 3)]

    d0_dialog.text = "... What are you doing? This is our territory. We have a right to transport goods here."
    d0_dialog.answers = {{answer = "There are vital signs in your cargo bay. You are carrying slaves.", followUp = _answer}}

    d1_bribe.text = "Ah yes. They're fantastic specimens aren't they? Perhaps if you pay us ${bribe}, we'll transfer them." % {bribe = createMonetaryString(bribe)}
    d1_bribe.answers = {{answer = "That's disgusting. I'd rather kill the lot of you.", followUp = _bribeThreatenAnswer},
                        {answer = "Very well. Here's your blood money.", onSelect = "onControlEndBribe" }}

    local _ComplyMessages = {
        "Okay okay! Holy shit! We'll turn them over! Don't shoot!",
        "Alright! Alright. No need to start shooting. We'll hand the captives over.",
        "Ugh! Fine, we'll let them go. The boss is gonna have our heads for this...",
        "You made your point! Just... take them and go!",
        "It's just a few bodies! Fine, take 'em if they're that important!",
        "Tch. There's plenty of better stock out there to be found - take your scraps and leave us be!"
    }
    shuffle(random(), _ComplyMessages)

    d1_comply.text = _ComplyMessages[1]
    d1_comply.answers = {{answer = "See that you do."}}
    d1_comply.onEnd = "onControlEndComply"

    d1_taunt.text = "Oh yeah? And what are you gonna do about it?"
    d1_taunt.answers = {
        {answer = "I'll kill you!", followUp = _tauntThreatenAnswer},
        {answer = "Let's talk about this calmly. Nobody needs to die today.", followUp = d2_bribe}
    }

    d1_runaway.text = "Shit! We can't stay here! Set the hyperdrive coordinates NOW! Go go go!"
    d1_runaway.onEnd = "onControlEndRunaway"

    local _MurderousMessages = {
        "You fool. You realize we have a ship full of hostages right? We'll kill every last one of them.",
        "They're precious to you, are they? We'll paint the corridors red with their blood.",
        "Haha! Hahaha! HahahaahAHAHAHAAHAAH!!! Kill every last one of those sorry scum, boys!",
        "Big mistake, idiot. You just signed their death warrants.",
        "You want these folks to die that badly? I'll tell them that before we slit their throats.",
        "Set comms to broadcast to the whole damn sector! Everyone gets to hear their dying screams."
    }
    shuffle(random(), _MurderousMessages)

    d1_murder.text = _MurderousMessages[1]
    d1_murder.onEnd = "onControlEndMurder"

    d2_bribe.text = "Oh? Is that so? How about you pay us ${bribe}, and we'll transfer them? Surely their pathetic lives are worth that much to you." % {bribe = createMonetaryString(bribe)}
    d2_bribe.answers = {
        { answer = "... Fine. Here's your blood money.", onSelect = "onControlEndBribe" },
        { answer = "Is there no other way to settle this?", followUp = d2_runaway }
    }

    d2_runaway.text = "Haha. Nope. And you've given our hyperdrives enough time to charge! Helm, set a course out!"
    d2_runaway.onEnd = "onControlEndRunawayNOW"

    return d0_dialog
end

-- ship has no illegal cargo
function RescueSlavesControl.makeControlDialogNoHit()
    local d0_dialog = {}

    d0_dialog.text = "... What are you doing? This is our territory. We have a right to transport goods here."%_t
    d0_dialog.answers = {{answer = "I see. Have a good journey and stay out of trouble."%_t}}
    d0_dialog.onEnd = "onControlEndNoSlaves"

    return d0_dialog
end

-- double control
function RescueSlavesControl.makeNotAgainDialog()
    local _msgs = {
        "You've already scanned our bays. Away with you.",
        "One unwelcome intrusion wasn't enough for you, huh? We won't accept another scan.",
        "Ugh. I knew we should have picked up a Sphinx back at the last system.",
        "You again? That's enough out of you. Comms, cut the channel.",
        "Stop trying to scan our ship, damn you!"
    }
    shuffle(random(), _msgs)
    
    local d0_dialog = {}

    d0_dialog.text = _msgs[1]

    return d0_dialog
end

--endregion

--region #ON CONTROL END

function RescueSlavesControl.onControlEndBribe()
    if onClient() then 
        invokeServerFunction("onControlEndBribe") 
        return 
    end

    local _Trader = Entity()
    local _Player = Player(callingPlayer)
    local _Bribe = data._bribe
    local canPay, msg, args = _Player:canPay(_Bribe)

    if not canPay then
        _Player:sendChatMessage(_Trader, 0, "You wanna play games, huh?! We're out of here!")
    else
        --Transfer slaves to player's cargo hold.
        RescueSlavesControl.turnOverSlaves()

        --Remove all slaves from own hold
        RescueSlavesControl.removeAllSlaves(_Trader)

        _Player:pay("Paid %1% Credits to buy the slaves.", _Bribe)
        _Player:sendChatMessage(_Trader, 0, "Pleasure doing business with you.")
    end

    _Trader:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(2, 3))
end
callable(RescueSlavesControl, "onControlEndBribe")

function RescueSlavesControl.onControlEndMurder()
    if onClient() then 
        invokeServerFunction("onControlEndMurder") 
        return 
    end

    local _Trader = Entity()
    local _TraderAI = ShipAI()

    --Replace slaves / freed slaves so the player can blow up the ship
    RescueSlavesControl.replaceIllegalSlaves(_Trader)

    --Give ship to local pirate faction
    RescueSlavesControl.turnShipPirate()

    --Remove PassSector and stop.
    _Trader:removeScript("ai/passsector.lua")
    _TraderAI:setIdle()
    _TraderAI:stop()
    _TraderAI:setPassiveShooting(true)

    --Turn it murderous
    data._Murderous = true
end
callable(RescueSlavesControl, "onControlEndMurder")

function RescueSlavesControl.onControlEndComply()
    if onClient() then 
        invokeServerFunction("onControlEndComply") 
        return 
    end
    local _Trader = Entity()

    --Transfer slaves to player's cargo hold.
    RescueSlavesControl.turnOverSlaves()

    --Remove all slaves from own hold
    RescueSlavesControl.removeAllSlaves(_Trader)

    --Set delayed delete script
    _Trader:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(2, 3))
end
callable(RescueSlavesControl, "onControlEndComply")

function RescueSlavesControl.onControlEndRunaway()
    if onClient() then 
        invokeServerFunction("onControlEndRunaway") 
        return 
    end
    
    RescueSlavesControl.onConrolEndRunrunrun(random():getFloat(12, 15))
end
callable(RescueSlavesControl, "onControlEndRunaway")

function RescueSlavesControl.onControlEndRunawayNOW()
    if onClient() then
        invokeServerFunction("onControlEndRunawayNOW")
        return 
    end

    RescueSlavesControl.onConrolEndRunrunrun(random():getFloat(1, 2))
end
callable(RescueSlavesControl, "onControlEndRunawayNOW")

function RescueSlavesControl.onConrolEndRunrunrun(_TimeToRun)
    local methodName = "Control End Run"

    local _Trader = Entity()

    --Replace slaves / freed slaves so the player can blow up the ship
    RescueSlavesControl.replaceIllegalSlaves(_Trader)

    --Give ship to local pirate faction
    RescueSlavesControl.turnShipPirate()

    --Set delayed delete script
    _Trader:addScriptOnce("entity/utility/delayeddelete.lua", _TimeToRun)
end

--Called if the ship does not have any slaves on it. The player loses rep.
function RescueSlavesControl.onControlEndNoSlaves()
    if onClient() then 
        invokeServerFunction("onControlEndNoSlaves") 
        return 
    end

    -- Player loses relation to the controlled faction and the dominating faction
    local playerFaction = Player(callingPlayer)
    local craft = playerFaction.craft
    if craft then
        playerFaction = getInteractingFactionByShip(craft.id, callingPlayer, AlliancePrivilege.AddResources)
    end

    local aiFaction = Entity().factionIndex
    if playerFaction and aiFaction then
        changeRelations(aiFaction, playerFaction, -4000, RelationChangeType.GeneralIllegal, true, true, aiFaction)

        local sectorControllingFaction = Galaxy():getControllingFaction(Sector():getCoordinates())
        if sectorControllingFaction and aiFaction ~= sectorControllingFaction.index then
            -- loose additional relations to residing faction
            changeRelations(sectorControllingFaction, playerFaction, -4000, RelationChangeType.GeneralIllegal, true, true, sectorControllingFaction)
        end
    end

    --Set bribe to 0 - the player wrongly accused a ship of having slaves.
    RescueSlavesControl.sendCallbackAndSnyc(callingPlayer, 0)
end
callable(RescueSlavesControl, "onControlEndNoSlaves")

--endregion

--region #UTIL FUNCS

function RescueSlavesControl.RescuedSlavesGood()
    local good = TradingGood("Rescued Slave"%_T, plural_t("Rescued Slave", "Rescued Slaves", 1), "A now freed life form that was forced to work for almost no food."%_T, "data/textures/icons/slave.png", 0, 1)
    good.tags = {mission_relevant = true}
    return good
end

function RescueSlavesControl.calculateBribe()
    --Somewhat cheaper than the free slaves mission since the player may have to bribe multiple times.
    --Also this mission needs a better reward than that one.
    return 100000  + math.floor(math.random()*10000)
end

--Turn over ship to local pirates.
function RescueSlavesControl.turnShipPirate()
    local _Sector = Sector()
    local x, y = _Sector:getCoordinates()
    local _pLevel = Balancing_GetPirateLevel(x, y)
    local _pFaction = Galaxy():getPirateFaction(_pLevel)

    local _entity = Entity()

    _entity.factionIndex = _pFaction.index
    _entity:setValue("is_pirate", true)
    _entity:setValue("npc_chatter", nil)
    _entity:setValue("passing_ship", nil)
    _entity:setValue("is_civil", nil) --killing this guy is now legal on twitter.
    _entity:removeScript("civilship.lua")
end

--Send a callback that the player is harassing traders and sync.
function RescueSlavesControl.sendCallbackAndSnyc(_PlayerIndex, _Bribe)
    local _Player = Player(_PlayerIndex)
    -- send callback
    _Player:sendCallback("onTraderScanned", Entity().id, _Bribe)

    -- remember player index
    table.insert(data.controlledByIndices, _PlayerIndex)
    RescueSlavesControl.sync()
end

--Drop slaves in player ship's cargo. Remove them from our own.
function RescueSlavesControl.turnOverSlaves()
    local methodName = "Turn Over Slaves"

    local _Trader = Entity()
    local player = Player(callingPlayer)
    local _SlavesInHold = _Trader:getValue("rescueslaves_slave_qty")

    RescueSlavesControl.Log(methodName, "Turning over " .. tostring(_SlavesInHold) .. " slaves.")

    -- add as many slaves as fit - drop the rest
    local ship = player.craft
    local count = 0
    if (not ship) or (ship.freeCargoSpace == nil) then
        -- drop everything
        Sector():dropCargo(ship.translationf, player, nil, RescueSlavesControl.RescuedSlavesGood(), 0, _SlavesInHold)
    elseif ship.freeCargoSpace < _SlavesInHold then
        -- add as many as you can, drop the rest
        while ship.freeCargoSpace >= 1 do
            ship:addCargo(RescueSlavesControl.RescuedSlavesGood(), 1)
            count = count + 1
        end
        local toDrop = _SlavesInHold - count
        Sector():dropCargo(ship.translationf, player, nil, RescueSlavesControl.RescuedSlavesGood(), 0, toDrop)
    else
        -- add all at once
        ship:addCargo(RescueSlavesControl.RescuedSlavesGood(), _SlavesInHold)
    end
end

function RescueSlavesControl.replaceIllegalSlaves(_Trader)
    local methodName = "Replace Illegal Slaves"

    --Remove slaves in cargo hold
    local _SlavesInHold = _Trader:getValue("rescueslaves_slave_qty")

    RescueSlavesControl.Log(methodName, "Replacing " .. tostring(_SlavesInHold) .. " illegal slaves w/ freed slaves.")

    _Trader:removeCargo(goods["Slave"]:good(), _SlavesInHold)

    --Replace w/ freed slaves
    _Trader:addCargo(RescueSlavesControl.RescuedSlavesGood(), _SlavesInHold)
end

function RescueSlavesControl.murderRescuedSlave()
    local methodName = "Murder Rescued Slave"
    local _Trader = Entity()

    local _MurderMessages = {
        "Help us! Help us!",
        "AAAAAHHHHHHH!!",
        "Help! They're killing all of us! Help!",
        "No! Please! Please!",
        "Please! I've got a family! I-",
        "No! Nooooo!",
        "No! Please! I'll do anything! I'll-"
    }
    shuffle(random(), _MurderMessages)

    local _SlavesLeft = _Trader:getCargoAmount(RescueSlavesControl.RescuedSlavesGood())

    if _SlavesLeft > 0 then
        RescueSlavesControl.Log(methodName, tostring(_SlavesLeft) .. " slaves left. Killing one.")

        _Trader:removeCargo(RescueSlavesControl.RescuedSlavesGood(), 1)

        RescueSlavesControl.Log(methodName, "Killed a slave " .. tostring(_Trader:getCargoAmount(RescueSlavesControl.RescuedSlavesGood())) .. " remain")

        Sector():broadcastChatMessage(_Trader, ChatMessageType.Chatter, _MurderMessages[1])
    else
        _Trader:addScriptOnce("entity/utility/delayeddelete.lua", random():getFloat(2,3))
    end
end

function RescueSlavesControl.removeAllSlaves(_Trader)
    local methodName = "Remove All Slaves"

    local _SlavesInHold = _Trader:getValue("rescueslaves_slave_qty")

    RescueSlavesControl.Log(methodName, "Removing " .. tostring(_SlavesInHold) .. " freed / illegal slaves from hold.")

    _Trader:removeCargo(goods["Slave"]:good(), _SlavesInHold)
    _Trader:removeCargo(RescueSlavesControl.RescuedSlavesGood(), _SlavesInHold)
end

--endregion

--region #LOGGING

function RescueSlavesControl.Log(methodName, _Msg)
    if data._Debug == 1 then
        print("[Rescue Slaves Control] - [" .. methodName .. "] - " .. _Msg)
    end
end

--endregion

--region #SYNC / SECURE / RESTORE

function RescueSlavesControl.sync(data_in)
    if onServer() then
        invokeClientFunction(Player(callingPlayer), "sync", data)
        return
    else
        data = data_in
    end
end

function RescueSlavesControl.restore(data_in)
    data = data_in
end

function RescueSlavesControl.secure()
    return data
end

--endregion