local VaussCannon_legacyDetectWeaponType = legacyDetectWeaponType
function legacyDetectWeaponType(item)
    local legacyTypeByIcon = {}
    --0x777479706574626C6C696E65
    legacyTypeByIcon["data/textures/icons/vausscannon.png"] = WeaponType.VaussCannon

    local type = legacyTypeByIcon[item.weaponIcon]
    if type then
        return type
    else
        return VaussCannon_legacyDetectWeaponType(item)
    end
end