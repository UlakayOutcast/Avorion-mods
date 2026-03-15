package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local ShipGenerator = include("shipgenerator")

ESCCUtil = include("esccutil")
LLTEUtil = include("llteutil")
MissionUT = include("missionutility")

include("stringutility")
include("randomext")

function create(item, rarity, allyIndex)

    rarity = Rarity(RarityType.Exceptional)

    item.stackable = false
    item.depleteOnUse = true
    item.name = "Маяк вызова торпедного погрузчика Кавалеров"%_t
    item.price = 1600000
    item.icon = "data/textures/icons/missile-pod.png"
    item.iconColor = rarity.color
    item.rarity = rarity
    item:setValue("subtype", "TorpedoLoaderCaller")
    item:setValue("factionIndex", allyIndex)

    local tooltip = Tooltip()
    tooltip.icon = item.icon
    tooltip.rarity = rarity

    local title = "Маяк вызова торпедного погрузчика Кавалеров"%_t

    local headLineSize = 25
    local headLineFontSize = 15
    local line = TooltipLine(headLineSize, headLineFontSize)
    line.ctext = title
    line.ccolor = item.rarity.color
    tooltip:addLine(line)

    -- пустая строка
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 14)
    line.ltext = "Союзник"%_t
    line.rtext = "${faction:"..allyIndex.."}"
    line.icon = "data/textures/icons/flying-flag.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 14)
    line.ltext = "Тип торговца"%_t
    line.rtext = "Торпедный погрузчик"%_t
    line.icon = "data/textures/icons/ship.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 14)
    line.ltext = "Улучшения"%_t
    line.rtext = "Нет"%_t
    line.rcolor = ColorRGB(1, 0.3, 0.3)
    line.icon = "data/textures/icons/circuitry.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Турели"%_t
    line.rtext = "Нет"%_t
    line.rcolor = ColorRGB(1, 0.3, 0.3)
    line.icon = "data/textures/icons/turret.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Утилиты"%_t
    line.rtext = "Нет"%_t
    line.rcolor = ColorRGB(1, 0.3, 0.3)
    line.icon = "data/textures/icons/satellite.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Торпеды"%_t
    line.rtext = "Да"%_t
    line.rcolor = ColorRGB(0.3, 1, 0.3)
    line.icon = "data/textures/icons/missile-pod.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Редкие артефакты"%_t
    line.rtext = "Нет"%_t
    line.rcolor = ColorRGB(1, 0.3, 0.3)
    line.icon = "data/textures/icons/circuitry.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    -- пустая строка
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 15)
    line.ltext = "Расходуется при использовании"%_t
    line.lcolor = ColorRGB(1.0, 1.0, 0.3)
    tooltip:addLine(line)

    -- пустая строка
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 14)
    line.ltext = "Может быть активирован игроком"%_t
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Вызывает торпедный погрузчик Кавалеров."%_t
    tooltip:addLine(line)

    item:setTooltip(tooltip)

    return item
end

function activate(item)
    local _Player = Player()
    local allyIndex = item:getValue("factionIndex")
    if not allyIndex then
        _Player:sendChatMessage("", ChatMessageType.Information, "Нет ответа."%_T)
        return false
    end

    local allyIndex = item:getValue("factionIndex")
    if not allyIndex then
        _Player:sendChatMessage("", ChatMessageType.Information, "Нет ответа."%_T)
        return false
    end

    local faction = Faction(allyIndex)
    if not faction then
        _Player:sendChatMessage("", ChatMessageType.Information, "Нет ответа."%_T)
        return false
    end

    if faction.index ~= allyIndex then
        _Player:sendChatMessage("", ChatMessageType.Information, "Нет ответа."%_T)
        return false
    end

    local sender = "Кавалеры"

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()

    local _Rank = _Player:getValue("_llte_cavaliers_ranklevel")
    local _PlayerInBarrier = MissionUT.checkSectorInsideBarrier(_X, _Y)
    local _CavsInBarrier = _Player:getValue("_llte_cavaliers_inbarrier")

    local playerFaction = _Player.craftFaction

    if _Rank < 2 then
        _Player:sendChatMessage(sender, ChatMessageType.Normal, "Мы отправляем боевую поддержку только тем, кто доказал свою преданность нам."%_T)
        return false
    end

    if _PlayerInBarrier and not _CavsInBarrier then
        _Player:sendChatMessage(sender, ChatMessageType.Normal, "Мы не можем отправить вам торпедный погрузчик!"%_T)
        return false
    end

    if Sector():getEntitiesByScriptValue("_llte_cavaliers_torpedo_loader") then
        _Player:sendChatMessage(sender, ChatMessageType.Normal, "В этом секторе уже есть торпедный погрузчик."%_T)
        return false
    end

    local craft = _Player.craft
    if not craft then
        _Player:sendChatMessage(sender, ChatMessageType.Error, "Вы должны находиться на корабле, чтобы использовать это."%_T)
        return false
    end

    -- создание торговца
    local pos = random():getDirection() * 1500
    local matrix = MatrixLookUpPosition(normalize(-pos), vec3(0, 1, 0), pos)

    local ship = ShipGenerator.createTradingShip(faction, matrix)

    ship:invokeFunction("icon.lua", "set", "data/textures/icons/pixel/torpedoboat.png")

    ship.title = "Торпедный погрузчик Кавалеров"
    ship:addScriptOnce("data/scripts/entity/merchants/cavalierstorpedoloader.lua")
    ship:addScript("data/scripts/entity/merchants/travellingmerchant.lua")
    ship:addScriptOnce("deleteonplayersleft.lua")

    local _WithdrawData = {
        _Threshold = 0.1,
        _MinTime = 1,
        _MaxTime = 1,
        _Invincibility = 0.02
    }

    ship:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
    ship:setValue("_llte_cavaliers_torpedo_loader", true)
    ship.name = LLTEUtil.getFreighterName()

    Sector():broadcastChatMessage(ship, 0, "Нужны торпеды, Кавалер? У нас они есть.", ship.title, ship.name)

    return true
end
