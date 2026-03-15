package.path = package.path .. ";data/scripts/lib/?.lua"

Dialog = include("dialogutility")
include("stringutility")
include("callable")

function initUI()
    ScriptUI():registerInteraction("У меня есть груз.", "startInteraction")
end

function interactionPossible(_PlayerIndex, _Option)
    local _Player = Player(_PlayerIndex)
    local craft = _Player.craft
    if craft == nil then return false end

    return true
end

function startInteraction()
    local d0 = {}
    local d1 = {}

    d0.text = "Отлично! Передаём груз сейчас."
    d0.onEnd = "handOverShipment"

    d1.text = "Наши сканеры не находят груз на вашем корабле. Вернитесь с грузом, и мы его примем."

    if not hasGoods() then
        d0.followUp = d1
    else
        d0.followUp = Dialog.empty()
    end

    ScriptUI():showDialog(d0, false)
end

function hasGoods()
    local _Ship
    if onClient() then
        _Ship = Player().craft
    else
        local _Player = Player(callingPlayer)
        _Ship = Entity(_Player.craftIndex)
    end

    for good, amount in pairs(_Ship:findCargos("Груз Авориона")) do
        if amount > 0 then
            return true
        end
    end

    return false
end

function handOverShipment()
    if onClient() then
        if hasGoods() then
            invokeServerFunction("handOverShipment")
        end
    else
        local _Player = Player(callingPlayer)

        if hasGoods() then
            local _Ship = Entity(_Player.craftIndex)

            for good, amount in pairs(_Ship:findCargos("Груз Авориона")) do
                if amount > 0 then
                    _Ship:removeCargo(good, 1)
                    break
                end
            end

            invokeClientFunction(_Player, "transactionDone")
        else
            invokeClientFunction(_Player, "noShipment")
        end
    end
end
callable(nil, "handOverShipment")

function noShipment()
    local d0 = {}

    d0.text = "Наши сканеры не находят груз на вашем корабле. Вернитесь с грузом, и мы его примем."

    ScriptUI():showDialog(d0, false)
end

function transactionDone()
    local d0 = {}

    d0.text = "Всё в порядке. Большое спасибо! Мы отправляемся в путь."
    d0.onEnd = "onEnd"

    ScriptUI():showDialog(d0, false)
end

function onEnd()
    Player():invokeFunction("player/missions/empress/side/lltesidemission6.lua", "finishMission")
end
