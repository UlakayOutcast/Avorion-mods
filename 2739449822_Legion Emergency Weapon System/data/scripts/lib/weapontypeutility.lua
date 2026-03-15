function legacyDetectWeaponType(item)
    local legacyTypeByIcon = {}
    legacyTypeByIcon["data/textures/icons/Emergency-Gun.png"] = WeaponType.EmergencyWeapon

    local type = legacyTypeByIcon[item.weaponIcon]

    return type
end