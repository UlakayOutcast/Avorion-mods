package.path = package.path .. ";data/scripts/lib/?.lua"

include("defaultscripts")
include("stringutility")
include("callable")

local _Debug = 0

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex)
    local player = Player(playerIndex)

    local craft = player.craft
    if craft == nil then return false end

    local dist = craft:getNearestDistance(Entity())
    local targetDist = 300
    --if the player has more than one scanner system, idk what happens. why would you have more than one scanner booster
    if craft:hasScript("scannerbooster.lua") or craft:hasScript("superscoutsystem.lua") then
        local scannerRarity = 0
        local scannerBonus = 1
        if craft:hasScript("scannerbooster.lua") then
            local ok, ret = craft:invokeFunction("scannerbooster.lua", "getRarity")
            if ok == 0 then
                scannerRarity = ret.value --Get the rarity tier value rather than the name.
            end
            scannerBonus = scannerBonus + ((5 + scannerRarity) * 0.1) --should give a 40% bonus @ petty, up to a 100% bonus @ legendary
        else
            local ok, ret = craft:invokeFunction("superscoutsystem.lua", "getRarity")
            if ok == 0 then
                scannerRarity = ret.value --Get the rarity tier value rather than the name.
            end
            scannerBonus = scannerBonus + (((5 + scannerRarity) * 0.1) * 0.8) --ITR upgrades are generally worth ~80% a normal upgrade.
        end

        if _Debug == 1 then
            print("Craft has scanner booster - rarity is: " .. tostring(scannerRarity) .. " final bonus is: " .. tostring(scannerBonus))
        end

        targetDist = math.floor(targetDist * scannerBonus)
    end

    if dist < targetDist then
        return true
    end

    return false, "Вы недостаточно близко, чтобы сканировать этого Ксотанца."%_t
end

function initUI()
    ScriptUI():registerInteraction("Сканировать"%_t, "onScan")
end

function onScan()
    ScriptUI():showDialog(makeDialog())
end

function makeDialog()
    local d0_YouFoundSomeInf = {}

    d0_YouFoundSomeInf.text = "Ксотанец успешно отсканирован."
    d0_YouFoundSomeInf.answers = {
        {answer = "OK"%_t, onSelect = "xsoscanned"}
    }

    return d0_YouFoundSomeInf
end

function xsoscanned()
    if onClient() then
        if _Debug == 1 then
            print("Called on Client => Invoking on server")
        end

        invokeServerFunction("xsoscanned")
        return
    end

    if _Debug == 1 then
        print("Called on Server => Sending callback")
    end

    Player(callingPlayer):sendCallback("onMissionXsotanScanned", Entity().id.string)
    terminate()
    return
end
callable(nil, "xsoscanned")
