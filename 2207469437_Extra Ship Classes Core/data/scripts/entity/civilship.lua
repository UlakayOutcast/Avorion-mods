function CivilShip.reinitializeInteractionText(newName, newTitle)
    local entity = Entity()

    if onClient() then
        entity.name = newName
        entity.title = newTitle
        InteractionText(entity.index).text = Dialog.generateShipInteractionText(entity, random())
    else
        broadcastInvokeClientFunction("reinitializeInteractionText", entity.name, entity.title)
    end
end