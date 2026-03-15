package.path = package.path .. ";data/scripts/lib/?.lua"
include("utility")
include("randomext")
include("SDKDebugLogging")

local SDKCargoModifier = {}

local _DebugMode = true

local oreNameByMaterial = {}
oreNameByMaterial[1] = "Iron Ore"
oreNameByMaterial[2] = "Titanium Ore"
oreNameByMaterial[3] = "Naonite Ore"
oreNameByMaterial[4] = "Trinium Ore"
oreNameByMaterial[5] = "Xanion Ore"
oreNameByMaterial[6] = "Ogonite Ore"
oreNameByMaterial[7] = "Avorion Ore"

local scrapNameByMaterial = {}
scrapNameByMaterial[1] = "Scrap Iron"
scrapNameByMaterial[2] = "Scrap Titanium"
scrapNameByMaterial[3] = "Scrap Naonite"
scrapNameByMaterial[4] = "Scrap Trinium"
scrapNameByMaterial[5] = "Scrap Xanion"
scrapNameByMaterial[6] = "Scrap Ogonite"
scrapNameByMaterial[7] = "Scrap Avorion"

--[[
*    Craft: The target craft we are checking.
*    GoodNames: List of goods we want to check
*    StolenMod: 0 = Return All But Stolen Count
*               1 = Return All Goods Count
*               2 = Return Only Stolen Count
*
*    Returns: List Of Amounts On Ship
*             Total Amount Of All Items
*             Boolean Inidicating If List Conatins Stolen Goods
]]
function getAmountsOnShip(craft, goodNames, stolenmod)
    local amountsOnShip = {}
    local totalAmount = 0
    local containsStolen = false
    local ShipCargo = craft:getCargos() 

    for i = 1, NumMaterials() do amountsOnShip[i] = 0 end

    for good, amount in pairs(ShipCargo) do

        --print("Checking:" .. good.name)

        for material, name in pairs(goodNames) do

            -- All But Stolen Goods
            if stolenmod == 0 then

                if good.name == name and not good.stolen then
                    amountsOnShip[material] = amount
                    totalAmount = totalAmount + amount
                end

            -- All Goods
            elseif stolenmod == 1 then

                if good.name == name then
                    amountsOnShip[material] = amountsOnShip[material] + amount
                    totalAmount = totalAmount + amount
                end

            -- Only Stolen
            elseif stolenmod == 2 then

                if good.name == name and good.stolen then
                    amountsOnShip[material] = amount
                    totalAmount = totalAmount + amount
                end
            end

        end
    end

    --print("Returning Table")
    --ToConsoleTable("Get Amount On Ship", "Amount On Ship", amountsOnShip)

    return amountsOnShip, totalAmount, containsStolen

end


function getOreAmountsOnShip(craft)
    return getAmountsOnShip(craft, oreNameByMaterial, 1)
end


function getScrapAmountsOnShip(craft)
    return getAmountsOnShip(craft, scrapNameByMaterial, 1)
end

--[[
    m = (Method Name) The name of the calling method
    e = (Entity) The entity object we are working with
    g = (Good) The name of the good as a string
    a = (Amount) The number of the goods we are removing
]]
function RemoveGoodByName(m, e, g, a)

    if onClient() then
        LogLine(m, "(Remove Good By Name) Tried To Execute On Client, Sending Request To Server...", _Log)
        invokeServerFunction("RemoveGoodByName", g, a)
        return
    end

    for cargo, _ in pairs(e:getCargos()) do
        if cargo.name == g then
            e:removeCargo(cargo, a)
        end    
    end

end

return SDKCargoModifier
