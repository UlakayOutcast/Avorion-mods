local compassLikeGPI_dirs -- client
local compassLikeGPI_updateTooltip -- extended client function
local compassLikeGPI_update -- extended server function


if onClient() then


compassLikeGPI_dirs = {
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

compassLikeGPI_updateTooltip = AncientGate.updateTooltip
function AncientGate.updateTooltip(...)
    compassLikeGPI_updateTooltip(...)

    local surveyed = Entity():getValue("cgpi_surveyed") or "|"
    local player = Player()
    if surveyed:find('|'..player.index..'|', 1, true) or (player.allianceIndex and surveyed:find('|'..player.allianceIndex..'|', 1, true)) then
        local x, y = Sector():getCoordinates()
        local tx, ty = WormHole():getTargetCoordinates()
        local ownAngle = math.atan2(ty - y, tx - x) + math.pi * 2
        if ownAngle > math.pi * 2 then ownAngle = ownAngle - math.pi * 2 end
        if ownAngle < 0 then ownAngle = ownAngle + math.pi * 2 end

        local dirString, iconPath = "", ""
        local min = 3.0
        for _, dir in ipairs(compassLikeGPI_dirs) do
            local d = math.abs(ownAngle - dir.angle)
            if d < min then
                min = d
                iconPath = "data/textures/icons/gatepixelicons/ancientgate"..dir.name..".png"
                dirString = (dir.name .. " /*direction*/")%_t
            end
        end

        EntityIcon().icon = iconPath
        Entity().title = dirString.." ".."Ancient Gate"%_t
    end
end

else


compassLikeGPI_update = AncientGate.update
function AncientGate.update(...)
    compassLikeGPI_update(...)

    if WormHole().enabled then -- mark the gate as surveyed
        local surveyed = Entity():getValue("cgpi_surveyed") or "|"
        local changed = false
        for _, index in ipairs({Sector():getPresentFactions()}) do
            local faction = Faction(index)
            if faction and not faction.isAIFaction and not surveyed:find('|'..index..'|', 1, true) then
                changed = true
                surveyed = surveyed..index..'|'
                if faction.isPlayer then
                    local player = Player(index)
                    if player.allianceIndex and not surveyed:find('|'..player.allianceIndex..'|', 1, true) then -- survey for alliance too
                        surveyed = surveyed..player.allianceIndex..'|'
                    end
                end
            end
        end
        if changed then
            Entity():setValue("cgpi_surveyed", surveyed)
            AncientGate.updateTooltip() -- update title and name
        end
    end
end


end