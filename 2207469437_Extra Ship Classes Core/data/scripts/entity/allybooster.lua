package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("randomext")

--Don't remove the namespace comment!!! The script could break. Also yes, it is required.
--namespace AllyBooster
AllyBooster = {}
local self = AllyBooster

self._Debug = 0

self.data = {}

function AllyBooster.initialize(_Values)
    local methodName = "Initialize"
    self.Log(methodName, "Initializing Ally Booster v19 script on entity.")

    self.data = _Values or {}

    self.data._HealWhenBoosting = self.data._HealWhenBoosting or false
    self.data._HealPctWhenBoosting = self.data._HealPctWhenBoosting or 0
    self.data._BoostCycle = self.data._BoostCycle or 60
    self.data._MaxBoostCharges = self.data._MaxBoostCharges or 3
    self.data._ChargesMultiplier = self.data._ChargesMultiplier or 1
    if self.data._AllowIronCurtain == nil then --Allow by default, but only if the user does not specify - use the user value otherwise.
        --We have to do it this way because value = x or true will always become true.
        self.data._AllowIronCurtain = true
    end

    self.data._BoostTime = 0
    self.data._BoostCharges = 0

    if onServer() then
        local _entity = Entity()

        Boarding(_entity).boardable = false
        _entity.dockable = false
    end

    self.Log(methodName, "Heal when boosting : " .. tostring(self.data._HealWhenBoosting) .. " -- Healing % when boosting : " .. tostring(self.data._HealPctWhenBoosting))
end

function AllyBooster.getUpdateInterval()
    return 5
end

--region #SERVER CALLS

function AllyBooster.updateServer(_TimeStep)
    local methodName = "Update Server"

    local entity = Entity()
    if entity.playerOwned or entity.allianceOwned then
        terminate()
        return
    end

    self.data._BoostTime = self.data._BoostTime + _TimeStep

    if self.data._BoostTime >= self.data._BoostCycle then
        self.data._BoostCharges = self.data._BoostCharges + (1 * self.data._ChargesMultiplier)
        self.data._BoostTime = 0
    end

    self.Log(methodName, "Boost charges : " .. tostring(self.data._BoostCharges))
    if self.data._BoostCharges > 0 then
        self.boost()
    end
end

function AllyBooster.boost()
    local methodName = "Boost"
    local _Scripts = {
        "eternal.lua",
        "phasemode.lua",
        "adaptivedefense.lua",
        "overdrive.lua",
        "afterburn.lua",
        "avenger.lua",
        "frenzy.lua"
    }

    if self.data._AllowIronCurtain then
        table.insert(_Scripts, "ironcurtain.lua")
    end

    local _Entity = Entity()
    local _FactionEntities = {Sector():getEntitiesByFaction(_Entity.factionIndex)}
    local _Allies = {}

    for _, _FEn in pairs(_FactionEntities) do
        if _FEn.id ~= _Entity.id and _FEn.type == EntityType.Ship and not _FEn.playerOrAllianceOwned then
            table.insert(_Allies, _FEn)
        end
    end

    if #_Allies > 0 then
        --Get ally to boost / script to boost with
        local _TargetAlly = randomEntry(_Allies)

         --Make this a bit smarter and don't try to double add a script to an ally.
        local possibleScripts = {}
        for _, script in pairs(_Scripts) do
            if not _TargetAlly:hasScript(script) then
                table.insert(possibleScripts, script)
            end
        end

        local _AllyScript = randomEntry(possibleScripts)

        --Get positions for laser
        local _AllyPosition = _TargetAlly.translationf
        local _MyPosition = _Entity.translationf
    
        self.Log(methodName, "Adding script " .. tostring(_AllyScript) .. " to ally.")
    
        _TargetAlly:addScriptOnce(_AllyScript)
        Boarding(_TargetAlly).boardable = false --Boarding boosted ships can cause bugs.

        --Heal the boosted target if applicable.
        if self.data._HealWhenBoosting then
            self.Log(methodName, "Healing!")
            if not _TargetAlly.invincible then
                self.Log(methodName, "Target ally not invincible!")
                if _TargetAlly.durability < _TargetAlly.maxDurability then
                    local _HealPct = self.data._HealPctWhenBoosting / 100
                    local _AllyMaxHull = _TargetAlly.maxDurability
    
                    self.Log(methodName, "Healing " .. tostring(_HealPct) .. "%!")
    
                    local _HealAmount = _AllyMaxHull * _HealPct
    
                    self.Log(methodName, "Healing " .. tostring(_HealAmount) .. "hp %!")

                    --Don't overcap healing.
                    if _TargetAlly.durability + _HealAmount > _AllyMaxHull then
                        _HealAmount = _AllyMaxHull - _TargetAlly.durability
                    end
    
                    _TargetAlly.durability = _TargetAlly.durability + _HealAmount
                end
            end
        end

        --Update ally title - only allow for this once or we can get weird crap like 'boosted boosted savage devastator'
        if not _TargetAlly:getValue("_increasingthreat_enhanced_title") and not _TargetAlly:getValue("_escc_enhanced_title") then
            _TargetAlly:setValue("_escc_enhanced_title", true)

            local _TitleArgs = _TargetAlly:getTitleArguments()
            _TitleArgs.script = "Boosted "
            local _AppendDirectlyToTitle = _TargetAlly:getValue("_escc_booster_append_title_direct")
            self.Log(methodName, "Title args are " .. tostring(_TitleArgs))
            if _AppendDirectlyToTitle then 
                _TargetAlly.title = "Boosted " .. _TargetAlly.title
            else
                local newTitle = "${script}" .. _TargetAlly.title

                self.Log(methodName, "Title is : " .. tostring(_TargetAlly.title) .. " new title is: " .. tostring(newTitle))

                _TargetAlly:setTitle(newTitle, _TitleArgs)
            end
        end

        --Finally, consume the boost charge and make the laser.
        self.Log(methodName, "Consuming boost charge.")
        self.data._BoostCharges = self.data._BoostCharges - 1
        self.createLaser(_MyPosition, _AllyPosition)
    end

    --Regardless of what happens, if we're over the maximum number of charges, make sure to cull.
    self.Log(methodName, "At " .. tostring(self.data._BoostCharges) .. " out of " .. tostring(self.data._MaxBoostCharges) .. " maximum charges.")
    if self.data._BoostCharges > self.data._MaxBoostCharges then
        self.data._BoostCharges = self.data._MaxBoostCharges
    end
end

--endregion

--region #CLIENT / SERVER functions

function AllyBooster.createLaser(_From, _To)
    if onServer() then
        broadcastInvokeClientFunction("createLaser", _From, _To)
        return
    end

    local _Color = color or ColorRGB(0, 0.8, 0.5)

    local _Sector = Sector()
    local _Laser = _Sector:createLaser(_From, _To, _Color, 16)

    _Laser.maxAliveTime = 1.5
    _Laser.collision = false
end

function AllyBooster.Log(methodName, _Msg)
    if self._Debug == 1 then
        print("[AllyBooster] - [" .. tostring(methodName) .. "] - " .. tostring(_Msg))
    end
end

--endregion

--region #SECURE / RESTORE

function AllyBooster.secure()
    local methodName = "Secure"
    self.Log(methodName, "Securing self.data")
    return self.data
end

function AllyBooster.restore(_Values)
    local methodName = "Restore"
    self.Log(methodName, "Restoring self.data")
    self.data = _Values
end

--endregion