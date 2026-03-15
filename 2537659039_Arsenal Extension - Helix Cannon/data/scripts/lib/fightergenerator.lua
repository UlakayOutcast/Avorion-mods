local helixCannon_addWeapons = FighterGenerator.addWeapons
function FighterGenerator.addWeapons(...)
    _args = {...}

    --0x706C61736D6166756E637461626C657374617274
    if _args[2] == WeaponType.HelixCannon then
        --print("helix cannon fighter found - replacing w/ plasma cannon fighter")
        _args[2] = WeaponType.PlasmaGun
    end
    --0x706C61736D6166756E637461626C65656E64

    helixCannon_addWeapons(unpack(_args,1,select("#", ...)))
end