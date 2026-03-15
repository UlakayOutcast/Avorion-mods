package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

HorizonUtil = include("horizonutil")
MissionUT = include("missionutility")

include("stringutility")
include("randomext")

--For some reason, we can't get to Galaxy() here. I am not sure why. So allyIndex is needed.
function create(item, rarity, allyIndex)

    rarity = Rarity(RarityType.Legendary)
    local rarity2 = Rarity(RarityType.Rare)

    item.stackable = false
    item.depleteOnUse = false
    item.name = "Frostbite Torpedo Loader Beacon"%_t
    item.price = 0
    item.icon = "data/textures/icons/missile-pod.png"
    item.iconColor = rarity2.color
    item.rarity = rarity
    item:setValue("subtype", "TorpedoLoaderCaller")
    item:setValue("factionIndex", allyIndex) 

    local tooltip = Tooltip()
    tooltip.icon = item.icon
    tooltip.rarity = rarity

    local title = "Frostbite Torpedo Loader Beacon"%_t

    local headLineSize = 25
    local headLineFontSize = 15
    local line = TooltipLine(headLineSize, headLineFontSize)
    line.ctext = title
    line.ccolor = item.rarity.color
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 14)
    line.ltext = "Ally"%_t
    line.rtext = "${faction:"..allyIndex.."}"
    line.icon = "data/textures/icons/flying-flag.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 14)
    line.ltext = "Merchant Type"%_t
    line.rtext = "Torpedo Loader"%_t
    line.icon = "data/textures/icons/ship.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 14)
    line.ltext = "Upgrades"%_t
    line.rtext = "No"%_t
    line.rcolor = ColorRGB(1, 0.3, 0.3)
    line.icon = "data/textures/icons/circuitry.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Turrets"%_t
    line.rtext = "No"%_t
    line.rcolor = ColorRGB(1, 0.3, 0.3)
    line.icon = "data/textures/icons/turret.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Utilities"%_t
    line.rtext = "No"%_t
    line.rcolor = ColorRGB(1, 0.3, 0.3)
    line.icon = "data/textures/icons/satellite.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Torpedoes"%_t
    line.rtext = "Yes"%_t
    line.rcolor =  ColorRGB(0.3, 1, 0.3)
    line.icon = "data/textures/icons/missile-pod.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Rare Artifacts"%_t
    line.rtext = "No"%_t
    line.rcolor = ColorRGB(1, 0.3, 0.3)
    line.icon = "data/textures/icons/circuitry.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(18, 14)
    line.ltext = "Cooldown"
    line.rtext = "2h"
    line.icon = "data/textures/icons/recharge-time.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(14, 14))

    local line = TooltipLine(20, 14)
    line.ltext = "Can be activated by the player"%_t
    tooltip:addLine(line)

    local line = TooltipLine(20, 14)
    line.ltext = "Calls in a Frostbite Company Torpedo Loader."%_t
    tooltip:addLine(line)

    item:setTooltip(tooltip)

    return item
end

function activate(item)
    local _Player = Player()
    local allyIndex = item:getValue("factionIndex")
    if not allyIndex then
        _Player:sendChatMessage("", ChatMessageType.Information, "No response."%_T)
        return false
    end

    local faction = Faction(allyIndex)
    if not faction then
        _Player:sendChatMessage("", ChatMessageType.Information, "No response."%_T)
        return false
    end

    if faction.index ~= allyIndex then
        _Player:sendChatMessage("", ChatMessageType.Information, "No response."%_T)
        return false
    end

    local sender = "Frostbite Company"

    local _Sector = Sector()
    local _X, _Y = _Sector:getCoordinates()

    local _Stage = _Player:getValue("_horizonkeepers_story_stage")

    if _Stage < 10 then
        _Player:sendChatMessage(sender, ChatMessageType.Normal, "You are not authorized to use Frostbite Company torpedo loaders.")
        return false
    end

    if MissionUT.checkSectorInsideBarrier(_X, _Y) then
        _Player:sendChatMessage(sender, ChatMessageType.Normal, "We can't send a torpedo loader to you!")
        return false
    end

    if Sector():getEntitiesByScriptValue("is_frostbite_torpedoloader") then
        _Player:sendChatMessage(sender, ChatMessageType.Normal, "There is already a torpedo loader in this sector.")
        return false
    end

    local craft = _Player.craft
    if not craft then
        _Player:sendChatMessage(sender, ChatMessageType.Error, "You must be in a ship to use this.")
        return false
    end

    local key = "torploader_requested_" .. faction.index
    local timeStamp = _Player:getValue(key)
    local now = Server().unpausedRuntime

    if timeStamp then
        local ago = now - timeStamp
        local wait = 60 * 120

        if ago < wait then
            _Player:sendChatMessage(sender, ChatMessageType.Normal, "We can't send another torpedo loader! You'll have to wait another %i minutes!", math.ceil((wait - ago)/60))
            return false
        end
    end

    _Player:setValue(key, now)

    -- create the merchant
    local loader = HorizonUtil.spawnFrostbiteTorpedoLoader(true, false)
    local loaderAI = ShipAI(loader)

    loaderAI:setFlyLinear(craft.translationf, craft.radius, false)

    local _WithdrawData = {
        _Threshold = 0.1,
        _MinTime = 1,
        _MaxTime = 1,
        _Invincibility = 0.02
    }

    loader:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)

    Sector():broadcastChatMessage(loader, 0, "You need torpedoes, Captain? We've got them.", loader.title, loader.name)

    return true
end
