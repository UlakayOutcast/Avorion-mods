function execute(sender, commandName, pIndex, ...)
    local player = Player(sender)
    player:addScriptOnce("data/scripts/player/changeOwner.lua", pIndex)

    return 0, "", ""
end

function getDescription()
    return "Transfers ownership of the currently targeted Ship to the sender"
end

function getHelp()
    return "A shorter way to get entitydbg"
end
