local SpreadFire_legacyDetectWeaponType = legacyDetectWeaponType
function legacyDetectWeaponType(item)
    local legacyTypeByIcon = {}
    --0x777479706574626C6C696E65
    legacyTypeByIcon["data/textures/icons/spreadfire.png"] = WeaponType.SpreadFire

    local type = legacyTypeByIcon[item.weaponIcon]
    if type then
        return type
    else
        return SpreadFire_legacyDetectWeaponType(item)
    end
end