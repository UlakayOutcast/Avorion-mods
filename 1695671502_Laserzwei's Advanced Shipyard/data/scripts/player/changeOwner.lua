function initialize(index)
    if onClient() then

    else
        local entity = Player().craft
        local target = entity.selectedObject
        target.factionIndex = index or Player().index
        target.invincible = false
        print("new faction", index or Player().index, "invincible: ", target.invincible)
        terminate()
    end
end
