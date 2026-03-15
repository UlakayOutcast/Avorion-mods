package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("callable")

-- Если эта функция возвращает false, скрипт не будет отображаться в окне взаимодействия,
-- даже если его интерфейс зарегистрирован
function interactionPossible(playerIndex)
    local player = Player(playerIndex)
    local _Entity = Entity()

    local craft = player.craft
    if craft == nil then return false end

    local dist = craft:getNearestDistance(_Entity)

    local targetplayerid = _Entity:getValue("_llte_optionalwreck_targetplayer")

    if dist < 200 and playerIndex == targetplayerid then
        return true
    end

    return false, "Вы недостаточно близко, чтобы обыскать объект."%_t
end

function initUI()
    ScriptUI():registerInteraction("Обыскать"%_t, "onSearch")
end

function onSearch(entityIndex)
    local ui = ScriptUI(entityIndex)
    if not ui then return end

    local _HasCodes = Entity():getValue("_llte_optionalwreck_hascode")

    if _HasCodes then
        ui:showDialog(foundSomethingDialog())
    else
        ui:showDialog(foundNothingDialog())
    end
end

function foundNothingDialog()
    local d0_NothingFoundHer = {}

    d0_NothingFoundHer.text = "Вы ничего интересного не нашли."%_t
    d0_NothingFoundHer.answers = {
        {answer = "Хорошо"%_t, onSelect = "finishScript"}
    }

    return d0_NothingFoundHer
end

function foundSomethingDialog()
    -- Создание диалога
    local d0_YouFoundSomeInf = {}

    d0_YouFoundSomeInf.text = "В обломках корабля вы находите чёрный ящик. Похоже, он содержит какие-то коммуникационные коды."%_t
    d0_YouFoundSomeInf.answers = {
        {answer = "Хорошо"%_t, onSelect = "onFoundEnd"}
    }

    return d0_YouFoundSomeInf
end

function finishScript()
    terminate()
    return
end

function onFoundEnd()
    Player():invokeFunction("player/missions/empress/side/lltesidemission5.lua", "foundCodes")

    terminate()
    return
end
