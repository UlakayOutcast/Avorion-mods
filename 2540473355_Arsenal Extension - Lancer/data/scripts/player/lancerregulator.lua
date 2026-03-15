package.path = package.path .. ";data/scripts/lib/?.lua"

include("weapontypeutility")

--namespace LancerRegulator
LancerRegulator = {}

function LancerRegulator.initialize()
    local player = Player()
    player:registerCallback("onItemAdded", "onItemAdded")
end

--Fixes a bug where the player could get non-coaxial lancers. I don't really like having to resort to this but oh well.
function LancerRegulator.onItemAdded(_Index, _Amount, _AmountBefore)
    local _Player = Player()
    local _Inventory = _Player:getInventory()
    local _Item = _Inventory:find(_Index)

    if not _Item then
        return
    end

    if _Item.itemType == InventoryItemType.Turret then
        local _WType = WeaponTypes.getTypeOfItem(_Item)

        --0x696666756E637374617274
        if _WType == WeaponType.LancerLaser and _Item.coaxial ~= true then
            _Item.coaxial = true
            local _Difference = _Amount - _AmountBefore

            for i = 1, _Difference do
                _Inventory:remove(_Index)                
            end
            for i = 1, _Difference do
                _Inventory:add(_Item, true)
            end      
        end
        --0x696666756E63656E64
    end
end