dirs = -- overridden
{
	{name = "E",    angle = math.pi * 2 * 0 / 16},
	{name = "ENE",  angle = math.pi * 2 * 1 / 16},
	{name = "NE",   angle = math.pi * 2 * 2 / 16},
	{name = "NNE",  angle = math.pi * 2 * 3 / 16},
	{name = "N",    angle = math.pi * 2 * 4 / 16},
	{name = "NNW",  angle = math.pi * 2 * 5 / 16},
	{name = "NW",   angle = math.pi * 2 * 6 / 16},
	{name = "WNW",  angle = math.pi * 2 * 7 / 16},
	{name = "W",    angle = math.pi * 2 * 8 / 16},
	{name = "WSW",  angle = math.pi * 2 * 9 / 16},
	{name = "SW",   angle = math.pi * 2 * 10 / 16},
	{name = "SSW",  angle = math.pi * 2 * 11 / 16},
	{name = "S",    angle = math.pi * 2 * 12 / 16},
	{name = "SSE",  angle = math.pi * 2 * 13 / 16},
	{name = "SE",   angle = math.pi * 2 * 14 / 16},
	{name = "ESE",  angle = math.pi * 2 * 15 / 16},
	{name = "E",    angle = math.pi * 2 * 16 / 16}
}

local compassLikeGPI_disabled = false -- client/server
local compassLikeGPI_secure, compassLikeGPI_restore -- overridden server functions

function Gate.getGateName(isDisabled) -- overridden
    local x, y = Sector():getCoordinates()
    local tx, ty = WormHole():getTargetCoordinates()
    local specs = SectorSpecifics(tx, ty, GameSeed())

    -- find "sky" direction to name the gate
    local ownAngle = math.atan2(ty - y, tx - x) + math.pi * 2
    if ownAngle > math.pi * 2 then ownAngle = ownAngle - math.pi * 2 end
    if ownAngle < 0 then ownAngle = ownAngle + math.pi * 2 end

    local dirString, iconPath = "", ""
    local min = 3.0
    for _, dir in ipairs(dirs) do
        local d = math.abs(ownAngle - dir.angle)
        if d < min then
            min = d
            iconPath = "data/textures/icons/gatepixelicons/gate"..dir.name..".png"
            dirString = (dir.name .. " /*direction*/")%_t
        end
    end

    if isDisabled then -- Integration: Gate Founder
        iconPath = "data/textures/icons/gatepixelicons/gateNA.png"
        if Gate.compassLikeGPI_disableMeshes then
            Gate.compassLikeGPI_disableMeshes() -- disable portal render
        end
    elseif Gate.compassLikeGPI_enableMeshes then
        Gate.compassLikeGPI_enableMeshes() -- re-enable portal render
    end

    return iconPath, "${dir} Gate to ${sector}"%_t % {dir = dirString, sector = specs.name}
end

function Gate.initialize() -- overridden
    local entity = Entity()
    local wormhole = WormHole()

    local tx, ty = wormhole:getTargetCoordinates()
    local x, y = Sector():getCoordinates()

    local d = distance(vec2(x, y), vec2(tx, ty))

    local cx = (x + tx) / 2
    local cy = (y + ty) / 2

    base = math.ceil(d * 30 * Balancing_GetSectorRichnessFactor(cx, cy))

    if onServer() then
        -- get callbacks for sector readiness
        entity:registerCallback("destinationSectorReady", "updateTooltip")
        if GameVersion() >= Version(1, 3, 5) then
            if GameVersion() >= Version(2, 0) then
                entity.dockable = not GameSettings().dockingRestrictions
            else
                entity.dockable = Scenario().isCreative
            end
        end
        Gate.updateTooltip()
    else
        EntityIcon().icon, Entity().title = Gate.getGateName()

        invokeServerFunction("updateTooltip")
        entity:registerCallback("onSelected", "updateTooltip")
        
        if GameVersion() >= Version(0, 30, 0) then -- gate sound
            Gate.soundSource = SoundSource("ambiences/gate1", entity.translationf, 300)
            Gate.soundSource.minRadius = 15
            Gate.soundSource.maxRadius = 300
            Gate.soundSource.volume = 1.0
            Gate.soundSource:play()
        end
    end
end

function Gate.updateTooltip(ready, isPowerDisabled) -- overridden
    if onServer() then
        -- on the server, check if the sector is ready,
        -- then invoke client sided tooltip update with the ready variable
        local entity = Entity()
        local transferrer = EntityTransferrer(entity.index)

        ready = transferrer.sectorReady

        if not callingPlayer then
            broadcastInvokeClientFunction("updateTooltip", ready, compassLikeGPI_disabled)
        else
            invokeClientFunction(Player(callingPlayer), "updateTooltip", ready, compassLikeGPI_disabled)
        end
    else
        if type(ready) == "boolean" then
            gateReady = ready
        end

        -- on the client, calculate the fee and update the tooltip
        local user = Player()
        local ship = Sector():getEntity(user.craftIndex)

        -- during login/loading screen it's possible that the player still has to be placed in his drone, so ship is nil
        if not ship then return end

        local shipFaction = Faction(ship.factionIndex)
        if shipFaction then
            user = shipFaction
        end

        local fee = math.ceil(base * Gate.factor(Faction(), user))
        local tooltip = EntityTooltip(Entity().index)

        tooltip:setDisplayTooltip(0, "Fee"%_t, "¢${fee}"%_t % {fee = tostring(fee)})

        if GameVersion() >= Version(1, 1, 2) and Hud().tutorialActive then
             gateReady = false -- always show not ready if tutorial is active, as player can't travel via gate
        end
        if not gateReady then
            tooltip:setDisplayTooltip(1, "Status"%_t, "Not Ready"%_t)
        else
            tooltip:setDisplayTooltip(1, "Status"%_t, "Ready"%_t)
        end

        if type(isPowerDisabled) == "boolean" then
            compassLikeGPI_disabled = isPowerDisabled
            EntityIcon().icon = Gate.getGateName(isPowerDisabled)
        end
    end
end

function Gate.getPower()
    return not compassLikeGPI_disabled
end


if onServer() then


function Gate.setPower(value)
    compassLikeGPI_disabled = not value
    local t = callingPlayer
    callingPlayer = nil -- we need 'updateTooltip' to broadcast the changes so callingPlayer should be nil
    Gate.updateTooltip(nil, true)
    callingPlayer = t
end

compassLikeGPI_secure = Gate.secure
function Gate.secure()
    local data = {}
    if compassLikeGPI_secure then
        data = compassLikeGPI_secure()
    end
    data.disabled = compassLikeGPI_disabled
    return data
end

compassLikeGPI_restore = Gate.restore
function Gate.restore(data)
    Gate.setPower(not data.disabled)
    if compassLikeGPI_restore then
        compassLikeGPI_restore(data)
    end
end


else -- onClient


function Gate.compassLikeGPI_disableMeshes()
    local mesh = PlanMesh()

    mesh:disableMesh(BlockShading.WormHole, MaterialType.Iron)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Titanium)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Naonite)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Trinium)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Xanion)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Ogonite)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Avorion)
end

function Gate.compassLikeGPI_enableMeshes()
    local mesh = PlanMesh()
    mesh:enableAll()
end



end
