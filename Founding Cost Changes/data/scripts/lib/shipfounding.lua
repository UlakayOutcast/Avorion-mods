function ShipFounding.getCosts(ships)
    local resources = {}

    -- Инициализируем массив ресурсов нулями
    for i = 0, MaterialType.Avorion do
        resources[i + 1] = 0
    end

    -- Рассчитываем стоимость в кредитах с прогрессивным увеличением
    local costInCredits = 10000 * math.pow(2, ships)  -- Начинаем с 1000 и удваиваем с каждым кораблём

    return resources, ships, costInCredits
end

function ShipFounding.getNextShipCosts(faction)
    if faction.isAlliance then
        faction = Alliance(faction.index)
    elseif faction.isPlayer then
        faction = Player(faction.index)
    end

    -- Считаем количество кораблей
    local ships = 0
    for _, name in pairs({faction:getShipNames()}) do
        if faction:getShipType(name) == EntityType.Ship then
            ships = ships + 1
        end
    end

    -- Возвращаем массив ресурсов, количество кораблей и стоимость в кредитах
    return ShipFounding.getCosts(ships)
end
