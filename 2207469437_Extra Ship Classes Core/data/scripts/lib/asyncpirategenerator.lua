--GET _AMP
local _ActiveMods = Mods()
local _Amp = 1.0
local _HighAmp = 1.0

for _, _Xmod in pairs(_ActiveMods) do
	if _Xmod.id == "2191291553" then --HarderEnemys
		_Amp = _Amp + 2
        _HighAmp = _HighAmp * 2
	end
	if _Xmod.id == "1821043731" then --HET
		_Amp = _Amp + 0.5
        _HighAmp = _HighAmp * 2
	end
end

--region #POSITION FUNCTIONS

--Get a number of positions for spawning pirates, so we don't need to do it in our missions / events.
function AsyncPirateGenerator:getStandardPositions(positionCT, distance)
    local _MethodName = "[ESCC] Get Standard Positions"
    PirateGenerator.Log(_MethodName, "Running pass-through function...")

    return PirateGenerator.getStandardPositions(positionCT, distance)
end

function AsyncPirateGenerator:getGenericPosition()
    local _MethodName = "[ESCC] Get Generic Position"
    PirateGenerator.Log(_MethodName, "Running pass-through function...")

    return PirateGenerator.getGenericPosition()
end

--endregion

--See pirategenerator.lua for a better description of exactly what these ships do.
--region #CREATE SCALED

function AsyncPirateGenerator:createScaledJammer(position)
    local _MethodName = "[ESCC] Create Scaled Jammer"
    PirateGenerator.Log(_MethodName, "Beginning...")
    
    local scaling = self:getScaling()
    return self:create(position, 1.0 * _Amp * scaling, "Jammer"%_T)
end

function AsyncPirateGenerator:createScaledStinger(position)
    local _MethodName = "[ESCC] Create Scaled Stinger"
    PirateGenerator.Log(_MethodName, "Beginning...")
    
    local scaling = self:getScaling()
    return self:create(position, 1.25 * _Amp * scaling, "Stinger"%_T)
end

function AsyncPirateGenerator:createScaledScorcher(position)
    local _MethodName = "[ESCC] Create Scaled Scorcher"
    PirateGenerator.Log(_MethodName, "Beginning...")
    
    local scaling = self:getScaling()
    return self:create(position, 6.0 * _Amp * scaling, "Scorcher"%_T)
end

function AsyncPirateGenerator:createScaledBomber(position)
    local _MethodName = "[ESCC] Create Scaled Bomber"
    PirateGenerator.Log(_MethodName, "Beginning...")
    
    local scaling = self:getScaling()
    return self:create(position, 6.0 * _Amp * scaling, "Bomber"%_T)
end

function AsyncPirateGenerator:createScaledSinner(position)
    local _MethodName = "[ESCC] Create Scaled Sinner"
    PirateGenerator.Log(_MethodName, "Beginning...")
    
    local scaling = self:getScaling()
    return self:create(position, 10.0 * _Amp * scaling, "Sinner"%_T)
end

function AsyncPirateGenerator:createScaledProwler(position)
    local _MethodName = "[ESCC] Create Scaled Prowler"
    PirateGenerator.Log(_MethodName, "Beginning...")
    
    local scaling = self:getScaling()
    return self:create(position, 12.0 * _Amp * scaling, "Prowler"%_T)
end

function AsyncPirateGenerator:createScaledPillager(position)
    local _MethodName = "[ESCC] Create Scaled Pillager"
    PirateGenerator.Log(_MethodName, "Beginning...")
    
    local scaling = self:getScaling()
    return self:create(position, 18.0 * _Amp * scaling, "Pillager"%_T)
end

function AsyncPirateGenerator:createScaledDevastator(position)
    local _MethodName = "[ESCC] Create Scaled Devastator"
    PirateGenerator.Log(_MethodName, "Beginning...")
    
    local scaling = self:getScaling()
    return self:create(position, 28.0 * _Amp * scaling, "Devastator"%_T)
end

function AsyncPirateGenerator:createScaledFlagship(position)
    local methodName = "[ESCC] Create Flagship"
    PirateGenerator.Log(methodName, "Beginning...")

    local scaling = self:getScaling()
    return self:create(position, 25 * _Amp * scaling, "Pirate Flagship"%_T)
end

function AsyncPirateGenerator:createScaledDemolisher(position)
    local _MethodName = "[ESCC] Create Scaled Demolisher (Devastator)"
    PirateGenerator.Log(_MethodName, "DEMOLISHER COMPATIBILITY CALL - Beginning...")
    
    local scaling = self:getScaling()
    return self:create(position, 28.0 * _Amp * scaling, "Devastator"%_T)
end

function AsyncPirateGenerator:createScaledExecutioner(position, specialScale)
    local _MethodName = "[ESCC] Create Scaled Executioner"

    specialScale = specialScale or 100

    PirateGenerator.Log(_MethodName, "Beginning... Special scale value is " .. tostring(specialScale))

    local specialShipScale = 20 + math.min(30, (math.max(0, specialScale - 200) / 10)) * _Amp
    local scaling = self:getScaling()
    PirateGenerator["_ESCC_executioner_specialscale"] = specialScale
    return self:create(position, specialShipScale * scaling, "Executioner"%_T)
end

function AsyncPirateGenerator:createScaledPirateByName(name, position)
    local _MethodName = "[ESCC] Create Scaled Pirate By Name"
    PirateGenerator.Log(_MethodName, "Creating Pirate - name: " .. tostring(name))
    
    return self["createScaled" .. name](self, position)
end

--endregion

--region #CREATE

function AsyncPirateGenerator:createJammer(position)
    local _MethodName = "[ESCC] Create Jammer"
    PirateGenerator.Log(_MethodName, "Beginning...")
    
    return self:create(position, 1.0 * _Amp, "Jammer"%_T)
end

function AsyncPirateGenerator:createStinger(position)
    local _MethodName = "[ESCC] Create Stinger"
	PirateGenerator.Log(_MethodName, "Beginning...")

    return self:create(position, 1.25 * _Amp, "Stinger"%_T)
end

function AsyncPirateGenerator:createScorcher(position)
    local _MethodName = "[ESCC] Create Scorcher"
	PirateGenerator.Log(_MethodName, "Beginning...")

    return self:create(position, 6.0 * _Amp, "Scorcher"%_T)
end

function AsyncPirateGenerator:createBomber(position)
    local _MethodName = "[ESCC] Create Bomber"
    PirateGenerator.Log(_MethodName, "Beginning...")

    return self:create(position, 6.0 * _Amp, "Bomber"%_T)
end

function AsyncPirateGenerator:createSinner(position)
    local _MethodName = "[ESCC] Create Sinner"
	PirateGenerator.Log(_MethodName, "Beginning...")

    return self:create(position, 10.0 * _Amp, "Sinner"%_T)
end

function AsyncPirateGenerator:createProwler(position)
    local _MethodName = "[ESCC] Create Prowler"
	PirateGenerator.Log(_MethodName, "Beginning...")

    return self:create(position, 12.0 * _Amp, "Prowler"%_T)
end

function AsyncPirateGenerator:createPillager(position)
    local _MethodName = "[ESCC] Create Pillager"
	PirateGenerator.Log(_MethodName, "Beginning...")

    return self:create(position, 18.0 * _Amp, "Pillager"%_T)
end

function AsyncPirateGenerator:createDevastator(position)
    local _MethodName = "[ESCC] Create Devastator"
	PirateGenerator.Log(_MethodName, "Beginning...")

    return self:create(position, 28.0 * _Amp, "Devastator"%_T)
end

function AsyncPirateGenerator:createFlagship(position)
    local methodName = "[ESCC] Create Flagship"
    PirateGenerator.Log(methodName, "Beginning...")

    return self:create(position, 25 * _Amp, "Pirate Flagship"%_T)
end

function AsyncPirateGenerator:createDemolisher(position)
    local _MethodName = "[ESCC] Create Demolisher (Devastator)"
    PirateGenerator.Log(_MethodName, "DEMOLISHER COMPATIBILITY CALL - Beginning...")
    
    return self:create(position, 28.0 * _Amp, "Devastator"%_T)
end

function AsyncPirateGenerator:createExecutioner(position, specialScale)
    local _MethodName = "[ESCC] Create Executioner"

    specialScale = specialScale or 100

    PirateGenerator.Log(_MethodName, "Beginning... Special scale value is " .. tostring(specialScale))

    local specialShipScale = 20 + math.min(30, (math.max(0, specialScale - 200) / 10)) * _Amp
    PirateGenerator["_ESCC_executioner_specialscale"] = specialScale
    return self:create(position, specialShipScale, "Executioner"%_T)
end

function AsyncPirateGenerator:createPirateByName(name, position)
    local _MethodName = "[ESCC] Create Pirate By Name"
    PirateGenerator.Log(_MethodName, "Creating Pirate - name: " .. tostring(name))
    
    return self["create" .. name](self, position)
end

--endregion