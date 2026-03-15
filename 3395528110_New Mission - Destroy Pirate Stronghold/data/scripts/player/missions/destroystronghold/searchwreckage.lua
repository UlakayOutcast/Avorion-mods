package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex)
    local player = Player(playerIndex)
    local _Entity = Entity()

    local craft = player.craft
    if craft == nil then return false end

    local dist = craft:getNearestDistance(_Entity)

    local targetplayerid = _Entity:getValue("_destroystronghold_optionalwreck_targetplayer")

    if dist < 200 and playerIndex == targetplayerid then
        return true
    end

    return false, "Вы недостаточно близко, чтобы обыскать объект."%_t
end

function initUI()
    ScriptUI():registerInteraction("Поиск"%_t, "onSearch")
end

function onSearch(entityIndex)
    local ui = ScriptUI(entityIndex)
    if not ui then return end

    local _HasCodes = Entity():getValue("_destroystronghold_optionalwreck_hascode")

    if _HasCodes then
        ui:showDialog(foundSomethingDialog())
    else
        ui:showDialog(foundNothingDialog())
    end
end

function foundNothingDialog()
    local d0_NothingFoundHer = {}

    d0_NothingFoundHer.text = "Вы не находите ничего примечательного."%_t
    d0_NothingFoundHer.answers = {
        {answer = "OK"%_t, onSelect = "finishScript"}
    }

    return d0_NothingFoundHer
end

function foundSomethingDialog()
    -- make dialog
    local d0_YouFoundSomeInf = {}

    d0_YouFoundSomeInf.text = "В руинах корабля вы находите черный ящик. Кажется, он содержит какие-то коды связи."%_t
    d0_YouFoundSomeInf.answers = {
        {answer = "OK"%_t, onSelect = "onFoundEnd"}
    }

    return d0_YouFoundSomeInf
end

function finishScript()
    terminate()
    return
end

function onFoundEnd()
    Player():invokeFunction("player/missions/destroystronghold.lua", "foundCodes")

    terminate()
    return
end
