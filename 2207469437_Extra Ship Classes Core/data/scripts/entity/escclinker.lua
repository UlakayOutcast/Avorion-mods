package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

--Don't remove the next line or it will break, blah blah. Also yes, you need the comment.
--namespace ESCCLinker
ESCCLinker = {}
local self = ESCCLinker

self.data = {}

self._Debug = 0

function ESCCLinker.initialize(values)
    local methodName = "Initialize"
    self.Log(methodName, "Initializing Linker v9")

    self.data = values or {}

    self.data.linkCycle = self.data.linkCycle or 10
    if self.data.boostDamageWhenLinking == nil then
        self.data.boostDamageWhenLinking = false
    end
    self.data.damageBoost = self.data.damageBoost or 1.02
    if self.data.healWhenLinking == nil then
        self.data.healWhenLinking = true
    end
    self.data.healPctWhenLinking = self.data.healPctWhenLinking or 5

    --The player can't alter these.
    self.data.linkTimer = 0
end

function ESCCLinker.getUpdateInterval()
    return 2
end

function ESCCLinker.updateServer(timeStep)
    local methodName = "Update Server"
    self.Log(methodName, "Running...")

    local _sector = Sector()
    local _entity = Entity()

    self.data.linkTimer = (self.data.linkTimer or 0) + timeStep

    if self.data.linkTimer >= self.data.linkCycle then
    --Calculate the total HP pool of all friendly units. Exclude invulnerable units.
        local linkAllies = {}

        local allies = {_sector:getEntitiesByFaction(_entity.factionIndex)}
        for _, ally in pairs(allies) do
            if ally.index ~= _entity.index and ally.type == EntityType.Ship and not ally.invincible then
                table.insert(linkAllies, ally)
            end
        end

        --Do this in a differnt order every time to better distribute the HP.
        shuffle(random(), linkAllies)

        self.Log(methodName, "allied entities: " .. tostring(#allies) .. " linkable allies is: " .. tostring(#linkAllies))
    
        --basically, do pokemon's pain split between each ally and self. If excess HP would push an ally above the threshold, just take the remaining bit.
        for _, ally in pairs(linkAllies) do
            self.createLaser(_entity.translationf, ally.translationf)
            if ally.durability < ally.maxDurability or _entity.durability < _entity.maxDurability then
                local healthPool = _entity.durability + ally.durability
                if self.data.healPctWhenLinking then
                    self.Log(methodName, "Healing by " .. tostring(self.data.healPctWhenLinking / 100) .. " factor")
                    healthPool = healthPool * (1 + (self.data.healPctWhenLinking / 100))
                end
                local splitHealth = healthPool / 2
                local excessHealth = 0

                self.Log(methodName, "Pool is " .. tostring(healthPool) .. " split is " .. tostring(splitHealth))

                local highEntity = nil
                local lowEntity = nil
                if ally.maxDurability > _entity.maxDurability then
                    highEntity = ally
                    lowEntity = _entity
                else
                    highEntity = _entity
                    lowEntity = ally
                end

                if splitHealth > lowEntity.maxDurability then
                    excessHealth = splitHealth - lowEntity.maxDurability
                end
                
                self.Log(methodName, "Excess hp from lowEntity is " .. tostring(excessHealth))

                lowEntity.durability = math.min(splitHealth, lowEntity.maxDurability)
                highEntity.durability = splitHealth + excessHealth
            end

            if self.data.boostDamageWhenLinking then
                ally.damageMultiplier = (ally.damageMultiplier or 1) * self.data.damageBoost
            end
        end

        self.data.linkTimer = 0
    end
end

--region #CLIENT FUNCTIONS

function ESCCLinker.createLaser(_From, _To)
    if onServer() then
        broadcastInvokeClientFunction("createLaser", _From, _To)
        return
    end

    local _Color = ColorRGB(0.0, 1.0, 0.25)

    local _Sector = Sector()
    local _Laser = _Sector:createLaser(_From, _To, _Color, 16)

    _Laser.maxAliveTime = 1.5
    _Laser.collision = false
end

--endregion

--region #LOG / SECURE / RESTORE

function ESCCLinker.Log(_MethodName, _Msg)
    if self._Debug == 1 then
        print("[ESCCLinker] - [" .. tostring(_MethodName) .. "] - " .. tostring(_Msg))
    end
end

function ESCCLinker.secure()
    local _MethodName = "Secure"
    self.Log(_MethodName, "Securing self.data")
    return self.data
end

function ESCCLinker.restore(values)
    local _MethodName = "Restore"
    self.Log(_MethodName, "Restoring self.data")
    self.data = values
end

--endregion