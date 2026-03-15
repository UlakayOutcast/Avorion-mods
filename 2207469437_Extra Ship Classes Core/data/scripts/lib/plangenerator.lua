function PlanGenerator.makeAsyncCivilTransportPlan(callback, values, faction, volume, styleName, material, sync)
    local seed = math.random(0xffffffff)

    if not material then
        material = PlanGenerator.selectMaterial(faction)
    end

    local code = [[
        package.path = package.path .. ";data/scripts/lib/?.lua"
        package.path = package.path .. ";data/scripts/?.lua"

        local FactionPacks = include ("factionpacks")
        local PlanGenerator = include ("plangenerator")

        function run(styleName, seed, volume, material, factionIndex, ...)

            local faction = Faction(factionIndex)

            if not volume then
                volume = Balancing_GetSectorShipVolume(faction:getHomeSectorCoordinates());
                local deviation = Balancing_GetShipVolumeDeviation();
                volume = volume * deviation
            end

            local plan = FactionPacks.getFreighterPlan(faction, volume, material)
            if plan then return plan, ... end

            local style = PlanGenerator.getFreighterStyle(faction, styleName)
            local plan = GeneratePlanFromStyle(style, Seed(seed), volume, 5000, nil, material)

            -- exchange most cargo blocks to crew quarters and some to generators and engines as housing is a lot denser
            for _, index in pairs({plan:getBlockIndices()}) do
                local blocktype = plan:getBlockType(index)
        
                if blocktype == BlockType.CargoBay then
                    if random():test(0.7) then
                        plan:setBlockType(index, BlockType.Quarters)
                    else
                        if random():test(0.5) then
                            plan:setBlockType(index, BlockType.Generator)
                        else
                            plan:setBlockType(index, BlockType.Engine)
                        end
                    end
                end
            end

            return plan, ...
        end
    ]]

    if sync then
        return execute(code, styleName, seed, volume, material, faction.index)
    else
        values = values or {}
        async(callback, code, styleName, seed, volume, material, faction.index, unpack(values))
    end
end

function PlanGenerator.makeCivilTransportPlan(faction, volume, styleName, material)
    return PlanGenerator.makeAsyncCivilTransportPlan(nil, nil, faction, volume, styleName, material, true)
end