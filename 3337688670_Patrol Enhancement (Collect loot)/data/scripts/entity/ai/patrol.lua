-- Spara den ursprungliga updateFlying-funktionen
local oldUpdateFlying = AIPatrol.updateFlying

-- Skugga funktionen updateFlying
function AIPatrol.updateFlying(timeStep)
    local ship = Entity()
    local ai = ShipAI()
    local sector = Sector()

    -- Hämta alla loot i sektorn
	local turretLoots = {sector:getEntitiesByComponent(ComponentType.TurretLoot)}
    local upgradeLoots = {sector:getEntitiesByComponent(ComponentType.SystemUpgradeLoot)}

    -- Kombinera till en enda tabell
    local loots = {}

    for _, loot in pairs(turretLoots) do
        table.insert(loots, loot)
    end

    for _, loot in pairs(upgradeLoots) do
        table.insert(loots, loot)
    end

    if #loots > 0 then
		--print(#loots)
		AIPatrol.SendFighters()
        -- Hitta närmaste o-claimad loot
        local closestLoot
        local closestDistance = math.huge
        local shipPosition = ship.translationf

        for _, loot in pairs(loots) do
            -- Kolla om looten redan är claimad
            if not loot:hasScript("entity/ai/claimedtag.lua") and loot:isCollectable(ship) then
                local distance = distance2(shipPosition, loot.translationf)
                if distance < closestDistance then
                    closestDistance = distance
                    closestLoot = loot
                end
            end
        end

        -- Om vi hittade en o-claimad loot
        if closestLoot then
            -- Markera looten som claimad
            closestLoot:addScript("entity/ai/claimedtag.lua")
            -- Flyg mot looten
			print("Found loot, flying there!!!")
            ai:setFly(closestLoot.translationf, 0)
            return
        end
    end
	AIPatrol.ReturnFighters()
	--print("No loot found!")

    -- Anropa den ursprungliga updateFlying-funktionen för att fortsätta patrullera
    oldUpdateFlying(timeStep)
end

function AIPatrol.SendFighters()
    local hangar = Hangar()
    local fighterController = FighterController()
    local squads = {hangar:getSquads()}

	for _, index in pairs(squads) do
		local category = hangar:getSquadMainWeaponCategory(index)
		fighterController:setSquadOrders(index, FighterOrders.CollectLoot, Uuid())
		--fighterController:setSquadOrders(index, FighterOrders.Return, Uuid())
	end
end

function AIPatrol.ReturnFighters()
    local hangar = Hangar()
    local fighterController = FighterController()
    local squads = {hangar:getSquads()}

	for _, index in pairs(squads) do
		local category = hangar:getSquadMainWeaponCategory(index)
		--fighterController:setSquadOrders(index, FighterOrders.CollectLoot, Uuid())
		fighterController:setSquadOrders(index, FighterOrders.Return, Uuid())
	end
end