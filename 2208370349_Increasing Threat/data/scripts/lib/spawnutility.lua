ESCCUtil = include("esccutil")

local _ScriptValues = {
    { _Script = "eternal.lua", _Arg = "Cauldron-Born" },
    { _Script = "phasemode.lua", _Arg = "Blinking" },
    { _Script = "ironcurtain.lua", _Arg = "Adamant" },
    { _Script = "adaptivedefense.lua", _Arg = "Adaptive" },
    { _Script = "overdrive.lua", _Arg = "Berserk" },
    { _Script = "afterburn.lua", _Arg = "Fleeting" },
    { _Script = "avenger.lua", _Arg = "Avenger" },
    { _Script = "frenzy.lua", _Arg = "Frenzied" }
}

SpawnUtility._Debug = 0

function SpawnUtility.addITEnemyBuffs(_Ships, _WilyTrait, _HatredLevel)
    local _MethodName = "Add IT Enemy Buffs"
    if _WilyTrait < 0.25 or _HatredLevel <= 700 then
        SpawnUtility.Log(_MethodName, "Wily trait (" .. tostring(_WilyTrait) .. ") not a significant value OR pirates don't hate player (" .. tostring(_HatredLevel) .. ") enough... returning.")
        return
    end
    
    local _Rolls = 1
    local _AddScriptDenominator = 3
    local _Denominator = 500
    if _WilyTrait >= 0.75 then
        SpawnUtility.Log(_MethodName, "Pirate wily trait >= 0.75 - setting extra script denominator to 350.")
        _Denominator = 350
    end

    if _HatredLevel >= 1000 then
        _Rolls = _Rolls + 1
        local _ExtraHatred = math.max(0, _HatredLevel - 1000)
        _Rolls = _Rolls + math.floor(_ExtraHatred / _Denominator)
        _AddScriptDenominator = 2
    end

    SpawnUtility.Log(_MethodName, "Accrued " .. tostring(_Rolls) .. " rolls for extra scripts.")
    local _Rgen = ESCCUtil.getRand()
    local _Shipidx = 1
    for _ = 1, _Rolls do
        SpawnUtility.Log(_MethodName, "Doing roll " .. tostring(_) .. " of " .. tostring(_Rolls))
        if _Rgen:getInt(1, _AddScriptDenominator) == 1 then
            local _ScriptToAdd = _ScriptValues[_Rgen:getInt(1, #_ScriptValues)]
            SpawnUtility.Log(_MethodName, "Roll succeeded - adding script " .. tostring(_ScriptToAdd))

            local _Ship = _Ships[_Shipidx]
            _Ship:addScriptOnce(_ScriptToAdd._Script)
            Boarding(_Ship).boardable = false --Make ship unboardable.

            --Add an additional element to the title.
            if not _Ship:getValue("_increasingthreat_enhanced_title") then
                _Ship:setValue("_increasingthreat_enhanced_title", true)

                local _TitleArgs = _Ships[_Shipidx]:getTitleArguments()
                if _TitleArgs then 
                    _Ship:setTitle("${script} ${toughness}${title}", { toughness = _TitleArgs.toughness, script = _ScriptToAdd._Arg, title = _TitleArgs.title })
                else
                    _Ship.title = _ScriptToAdd._Arg .. " " .. _Ship.title
                end
            end

            _Shipidx = _Shipidx + 1
            if _Shipidx > #_Ships then
                _Shipidx = 1
            end
        end
    end
end

function SpawnUtility.Log(_MethodName, _Msg)
    if SpawnUtility._Debug == 1 then
        print("[Spawn Utility] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end