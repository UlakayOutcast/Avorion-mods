local DestroyStronghold_getBulletinMissionModules = getBulletinMissionModules
function getBulletinMissionModules(modTable)
    --0x65736363206465627567206D697373696F6E207461626C65
    table.insert(modTable, { _Caption = "Уничтожить крепость пиратов", _Tooltip = "destroystronghold" })

    return DestroyStronghold_getBulletinMissionModules(modTable)
end