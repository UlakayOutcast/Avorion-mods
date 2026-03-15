---@return boolean
local CaptainUtility = include ("captainutility")
function MineAI.instance:findObject(ship, sector, harvestMaterial, depth)
	if type(self) ~= "table" then
		depth = harvestMaterial
		harvestMaterial = sector
		sector = ship
		ship = self
		self = MineAI.instance
	end
	local objectToHarvest
	local higherMaterialPresent
	depth = depth or 1

	local mineables = {sector:getEntitiesByComponent(ComponentType.MineableMaterial)}
	local nearest = math.huge
	
	local _, temp, ignoreOrder = ship:invokeFunction("entity/miningpriority.lua", "getMiningList")
	MineAI.instance.resource_list = temp or MineAI.instance.resource_list
	if not MineAI.instance.resource_list then
		MineAI.instance.resource_list = {}
		for i = 1, 7 do
			-- Проверяем, что материал существует и не nil
			local material = Material(ship.aiOwned and (i-1) or (7-i))
			if material then
				table.insert(MineAI.instance.resource_list, material)
			end
		end
	end

	for _, a in pairs(mineables) do
        if a.type == EntityType.Asteroid and a.isObviouslyMineable then
            local material = a:getLowestMineableMaterial()
			local resources = a:getMineableResources()
			--елси порядок не игнорируется
			if not ignoreOrder then
				if material == MineAI.instance.resource_list[depth] then
					if resources ~= nil and resources > 0 and material ~= nil then
						-- only try to mine objects that are mineable by the available mining lasers
						if material.value <= harvestMaterial + 1 then
							local dist = distance2(a.translationf, ship.translationf)
							if dist < nearest then
								nearest = dist
								objectToHarvest = a
							end
						else
							higherMaterialPresent = true
						end
					end
				end
			else
				local included = false
				for _, v in pairs(MineAI.instance.resource_list) do
					if v == material then included = true end
				end
				if included then
					if resources ~= nil and resources > 0 and material ~= nil then
						-- only try to mine objects that are mineable by the available mining lasers
						if material.value <= harvestMaterial + 1 then
							local dist = distance2(a.translationf, ship.translationf)
							if dist < nearest then
								nearest = dist
								objectToHarvest = a
							end
						else
							higherMaterialPresent = true
						end
					end
				end
			end
		end
	end

	if not objectToHarvest and depth < 7 and not ignoreOrder then
		--print('going deeper, nothing found', depth)
		depth = depth + 1
		objectToHarvest, higherMaterialPresent = MineAI.instance:findObject(ship, sector, harvestMaterial, depth)
	end

	return objectToHarvest, higherMaterialPresent
end