function BulletinBoard.Log(_MethodName, _Msg, _OverrideDebug)
    local _UseDebug = _OverrideDebug or BulletinBoard._Debug
    if _UseDebug == 1 then
        print("[ESCC BulletinBoard] - [" .. _MethodName .. "] - " .. _Msg)
    end
end