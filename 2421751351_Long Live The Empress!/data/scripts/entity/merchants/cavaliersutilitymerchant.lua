package.path = package.path .. ";data/scripts/lib/?.lua"
include ("utility")
include ("randomext")
include ("faction")
local ShopAPI = include ("shop")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace CavaliersUtilityMerchant
CavaliersUtilityMerchant = {}
CavaliersUtilityMerchant = ShopAPI.CreateNamespace()

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function CavaliersUtilityMerchant.interactionPossible(playerIndex, option)
    local _Player = Player(playerIndex)
    local _Rank = _Player:getValue("_llte_cavaliers_ranklevel")
    if _Rank and _Rank >= 2 then
        return true
    else
        return false
    end
end

local function sortSystems(a, b)
    if a.rarity.value == b.rarity.value then
        return a.price > b.price
    end

    return a.rarity.value > b.rarity.value
end

function CavaliersUtilityMerchant.shop:addItems()
    local _Merchant = Entity()

    local x, y = Sector():getCoordinates()

    local faction = Faction()

    if faction then
        local item = UsableInventoryItem("cavaliersreinforcementtransmitter.lua", Rarity(RarityType.Exceptional), faction.index)
        CavaliersUtilityMerchant.add(item, getInt(1, 2))

        local item = UsableInventoryItem("torpedoloadercaller.lua", Rarity(RarityType.Exceptional), faction.index)
        CavaliersUtilityMerchant.add(item, getInt(2, 5))
    end

    local _satMin = 2
    local _satMax = 3

    if _Merchant:getValue("_llte_PaladinInventory") then
        local item = UsableInventoryItem("cavaliersenergysuppressor.lua", Rarity(RarityType.Exceptional))
        CavaliersUtilityMerchant.add(item, getInt(2, 3))
        _satMin = _satMin + 1
        _satMax = _satMax + 2
    end

    local item = UsableInventoryItem("energysuppressor.lua", Rarity(RarityType.Exceptional))
    CavaliersUtilityMerchant.add(item, getInt(_satMin, _satMax))
end

function CavaliersUtilityMerchant.initialize()
    CavaliersUtilityMerchant.shop:initialize("Utility Merchant"%_t)
end

function CavaliersUtilityMerchant.initUI()
    CavaliersUtilityMerchant.shop:initUI("Trade Equipment"%_t, "Utility Merchant"%_t, "Utilities"%_t, "data/textures/icons/bag_satellite.png", {showSpecialOffer = false})
end
