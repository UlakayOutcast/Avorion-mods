package.path = package.path .. ";data/scripts/lib/?.lua;"
package.path = package.path .. ";data/scripts/?.lua;"

local StyleGenerator = include ("internal/stylegenerator.lua")
local PlanGenerator = include ("plangenerator")
local Placer = include ("placer")

function make_gate(x, y, factionIndex)
	local local_x, local_y = Sector():getCoordinates()
	local dir = vec3(x - local_x, 0, y - local_y)
	normalize_ip(dir)

	local position = MatrixLookUp(dir, vec3(0, 1, 0))
	position.pos = dir * 2000

    local gateDesc = EntityDescriptor()
	gateDesc:addComponents(
		ComponentType.Plan,
		ComponentType.BspTree,
		ComponentType.Intersection,
		ComponentType.Asleep,
		ComponentType.DamageContributors,
		ComponentType.BoundingSphere,
		ComponentType.PlanMaxDurability,
		ComponentType.Durability,
		ComponentType.BoundingBox,
		ComponentType.Velocity,
		ComponentType.Physics,
		ComponentType.Scripts,
		ComponentType.ScriptCallback,
		ComponentType.Title,
		ComponentType.Owner,
		ComponentType.FactionNotifier,
		ComponentType.WormHole,
		ComponentType.EnergySystem,
		ComponentType.EntityTransferrer
	)
	gateDesc.invincible = true
    gateDesc.factionIndex = factionIndex
    gateDesc.position = position

	local styleGenerator = StyleGenerator(factionIndex)
	local c1 = styleGenerator.factionDetails.baseColor
	local c2 = ColorRGB(0.25, 0.25, 0.25)
	local c3 = styleGenerator.factionDetails.paintColor
	c1 = ColorRGB(c1.r, c1.g, c1.b)
	c3 = ColorRGB(c3.r, c3.g, c3.b)

	local plan = PlanGenerator.makeGatePlan(Seed(factionIndex) + Server().seed, c1, c2, c3)
	gateDesc:setMovePlan(plan)

	local wormhole = gateDesc:getComponent(ComponentType.WormHole)
	wormhole:setTargetCoordinates(x, y)
	wormhole.visible = false
	wormhole.visualSize = 100
	wormhole.passageSize = 200
	wormhole.oneWay = true

	gateDesc:addScript("data/scripts/entity/gate.lua")
    Sector():createEntity(gateDesc)
    Placer.resolveIntersections()
end
