package.path = package.path .. ";data/scripts/lib/?.lua"
include ("galaxy")
include ("utility")
include ("stringutility")
include ("faction")
include ("callable")

local active = false

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)
    if Entity().factionIndex == playerIndex then
        return true
    end

    return false
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function initialize(active_in)
    active = active_in or 0
end

function initUI()

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(0, 0, 0, 0))
    menu:registerWindow(window, "Activate"%_t)

end

--Updates half as often as the normal blocker because the range on this one is massive.
function getUpdateInterval()
    return 10
end

function updateServer(timeStep)

    local _Entity = Entity()
    local _Owner = Faction(_Entity.factionIndex)
    if _Owner.isPlayer or _Owner.isAlliance then
        terminate()
        return
    end

    if active then
        -- block all hyperspace engines in the sector.
        local position = Entity().translationf
        local threshold = 50000 -- 500 km. Let the player believe that escape isn't possible.

        local entities = {Sector():getEntitiesByComponent(ComponentType.HyperspaceEngine)}

        for _, entity in pairs(entities) do
            local d = distance(position, entity.translationf)

            if d <= threshold then
                entity:blockHyperspace(11)
                HyperspaceEngine(entity):exhaust()
            end
        end
    end
end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
function onShowWindow()
    invokeServerFunction("toggleActive")
    ScriptUI():stopInteraction()
end

function toggleActive()
    if callingPlayer then
        if callingPlayer ~= Entity().factionIndex then
            return
        end
    end

    if not active then
        active = true
    else
        active = false
    end
end
callable(nil, "toggleActive")

function activate()
    active = true
end

function deactivate()
    active = false
end