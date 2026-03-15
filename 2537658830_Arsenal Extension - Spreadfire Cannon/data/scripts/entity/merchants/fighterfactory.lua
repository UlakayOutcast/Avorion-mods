include ("weapontypeutility")

local spreadfireCannon_onCreatePressed = FighterFactory.onCreatePressed
function FighterFactory.onCreatePressed()
    local inventoryItem = turretSelection.selected
    if inventoryItem then
        local _Buyer
        local _Player = Player()
        local _Ship = Sector():getEntity(_Player.craftIndex)
        if _Ship and _Ship.factionIndex == _Player.allianceIndex then
            _Buyer = _Player.alliance
        else
            _Buyer = _Player
        end

        local idx = inventoryItem.index
        local turret = _Buyer:getInventory():find(idx)
        local tweapontype = legacyDetectWeaponType(turret)

        --0x706C61736D6166756E637461626C657374617274
        if tweapontype == WeaponType.SpreadFire then
            displayChatMessage("This weapon type cannot be used to create fighters.", "Fighter Factory"%_t, 1)
            return
        end
        --0x706C61736D6166756E637461626C65656E64
    end

    spreadfireCannon_onCreatePressed()
end