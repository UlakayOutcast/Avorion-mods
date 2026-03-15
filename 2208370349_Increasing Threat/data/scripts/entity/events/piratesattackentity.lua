local ITUtil = include("increasingthreatutility")
local SpawnUtility = include("spawnutility")

local _UseHatredLevel = 0

local IncreasingThreat_spawnAttackers = PiratesAttackEntity.spawnAttackers
function PiratesAttackEntity.spawnAttackers()

    local generator = AsyncPirateGenerator(PiratesAttackEntity, PiratesAttackEntity.onPiratesGenerated)
    local entity = Entity()
    local pos = entity.translationf

    local _PirateFaction = generator:getPirateFaction()
    local _HatredIndex = "_increasingthreat_hatred_" .. tostring(_PirateFaction.index)
    local owner = Galaxy():findFaction(entity.factionIndex)
    local _Hatred = 0
    if owner.isPlayer then
        _Hatred = owner:getValue(_HatredIndex)
    elseif owner.isAlliance then
        --We have to do some wacky shit with this, since the player isn't technically in the sector. Use the highest hatred value of all online players in the alliance.
        local _Players = {owner:getOnlineMembers()}
        local _Server = Server()
        for _, _Member in pairs(_Players) do
            local _AlliancePlayer = Player(_Member)
            local _AllianceHatred = _AlliancePlayer:getValue(_HatredIndex) or 0
            if _AllianceHatred > _Hatred then
                _Hatred = _AllianceHatred
            end
        end
    end
    _Hatred = _Hatred or 0

    local _Dir = random():getDirection()
    local _Up = vec3(0,1,0)
    local right = cross(_Dir, _Up)

    local _Piratect = 4
    local _Brutish = _PirateFaction:getTrait("brutish")
    if _Brutish and _Brutish >= 0.25 then
        _Piratect = 6
    end

    local _OKTime = owner:getValue("_increastingthreat_next_entityattack") or 0
    local _Time = Server().unpausedRuntime

    if _Time > _OKTime then
        local _Chance = 0
        if _Hatred > 500 then
            _Chance = _Chance + 20
        end
    
        if _Hatred > 800 then
            _Chance = _Chance + 20
        end
    
        local _Chance = 20
        local _Roll = random():getInt(1, 100)
        if _Roll < _Chance then
            _Piratect = _Piratect + 3
            local _TimeToAdd = (120 * 60)

            local _Vengeful = _PirateFaction:getTrait("vengeful")
            if _Vengeful and _Vengeful >= 0.25 then
                local _VengefulFactor = 1.0
                if _Vengeful >= 0.25 then
                    _VengefulFactor = 0.8
                end
                if _Vengeful >= 0.75 then
                    _VengefulFactor = 0.7
                end
                _TimeToAdd = _TimeToAdd * _VengefulFactor
            end

            local _NewTime = _Time + _TimeToAdd --Don't do this for another 2 hours at least.
            owner:setValue("_increastingthreat_next_entityattack", _NewTime)
        end
    end

    local _SpawnTable = ITUtil.getHatredTable(_Hatred)
    _UseHatredLevel = _Hatred --This doesn't feel very robust, but I can't think of a better alternative.

    generator:startBatch()

    for idx = 1, _Piratect do
        local _Matrix = MatrixLookUpPosition(-_Dir, _Up, pos + _Dir * 1800 + right * 350 * idx)
        generator:createScaledPirateByName(randomEntry(_SpawnTable), _Matrix)
    end

    generator:endBatch()

    HyperspaceEngine(entity):exhaust()

    if entity:getNumArmedTurrets() > 0 then
        ShipAI(entity):setAggressive(false, false)
    end
end

local IncreasingThreat_onPiratesGenerated = PiratesAttackEntity.onPiratesGenerated
function PiratesAttackEntity.onPiratesGenerated(_Generated)
    local entity = Entity()
    local owner = Galaxy():findFaction(entity.factionIndex)

    -- apply a damage buff if the captain has the perk for it
    local strength
    local captain = entity:getCaptain()
    if captain then
        if captain:hasPerk(CaptainUtility.PerkType.Cunning) then
            strength = CaptainUtility.getAttackStrengthPerks(captain, CaptainUtility.PerkType.Cunning)
        end

        if captain:hasPerk(CaptainUtility.PerkType.Harmless) then
            strength = CaptainUtility.getAttackStrengthPerks(captain, CaptainUtility.PerkType.Harmless)
        end
    end

    -- make sure that the player isn't abusing the mechanic
    local disableDrops
    if owner and (owner.isAlliance or owner.isPlayer) then
        local now = Server().unpausedRuntime
        local last = owner:getValue("last_bgs_attack")
        if last and now - last < 20 * 60 then
            disableDrops = true
        end

        owner:setValue("last_bgs_attack", now)
    end

    for _, ship in pairs(_Generated) do
        ship:setValue("background_attacker", true)

        if strength then
            ship.damageMultiplier = ship.damageMultiplier * strength
        end

        if disableDrops then
            ship:setDropsLoot(false)
        end
    end

    Placer.resolveIntersections()

    local _PirateFaction = Faction(_Generated[1].factionIndex)
    local _WilyTrait = _PirateFaction:getTrait("wily") or 0

    SpawnUtility.addEnemyBuffs(_Generated)
    SpawnUtility.addITEnemyBuffs(_Generated, _WilyTrait, _UseHatredLevel)
    terminate() -- nothing more to do
end