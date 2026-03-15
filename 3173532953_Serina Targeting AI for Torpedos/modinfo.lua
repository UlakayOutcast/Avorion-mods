
meta =
{
    -- ID of your mod; Make sure this is unique!
    -- Will be used for identifying the mod in dependency lists
    -- Will be changed to workshop ID (ensuring uniqueness) when you upload the mod to the workshop
    id = "3173532953",

    -- Name of your mod; You may want this to be unique, but it's not absolutely necessary.
    -- This is an additional helper attribute for you to easily identify your mod in the Mods() list
    name = "Serina: Targeting AI for Torpedos",

    -- Title of your mod that will be displayed to players
    title = "Serina: Targeting AI for Torpedos",

    -- Type of your mod, either "mod" or "factionpack"
    type = "mod",

    -- Description of your mod that will be displayed to players
    description = "Update 3/9/24: added MIRV and misfire chance* \n Torpedoes will spawn between 0 (misfire) and 4 child torpedoes. The misfire chance was added to prevent this from being too overpowered. \n Inspired by 'Torpedo auto-target with spread' by Nirin \n \n The script has been rewritten from the ground up to improve clarity and reduce overhead \n \n  Gone are the days of worrying about where your torpedos are going. Serina takes care of all of that for you! \n \n The Logic: \n When toropedoes are fired, if you have an enemy selected all torpedoes will be sent there. \n In all other instances (i.e. targeting self, ally, nothing), your torpedoes will disperse *'randomly'* (Fisher-Yates Shuffle) to available targets \n\n If you have yourself targeted in a literally blank sector and you (perhaps unwisely) fire the torpedoes... may God have mercy on your soul.\n\n \n Just kidding! That's resolved too, they shoot off like you had nothing selected, they do look a bit janky(i.e. they seem like they're about to circle back, then they zip off away again), depeding on your torp range this may happen a few times: but they don't retrun to sender!\n \n Added Bonus: Torpedoes are silent - because well, there's only so long you can stand that warning siren before you snap \n \n This is my first mod, feedback and suggestions always welcome!",

    -- Insert all authors into this list
    authors = {"Reuivn"},

    -- Version of your mod, should be in format 1.0.0 (major.minor.patch) or 1.0 (major.minor)
    -- This will be used to check for unmet dependencies or incompatibilities, and to check compatibility between clients and dedicated servers with mods.
    -- If a client with an unmatching major or minor mod version wants to log into a server, login is prohibited.
    -- Unmatching patch version still allows logging into a server. This works in both ways (server or client higher or lower version).
    version = "1.0",

    -- If your mod requires dependencies, enter them here. The game will check that all dependencies given here are met.
    -- Possible attributes:
    -- id: The ID of the other mod as stated in its modinfo.lua
    -- min, max, exact: version strings that will determine minimum, maximum or exact version required (exact is only syntactic sugar for min == max)
    -- optional: set to true if this mod is only an optional dependency (will only influence load order, not requirement checks)
    -- incompatible: set to true if your mod is incompatible with the other one
    -- Example:
    -- dependencies = {
    --      {id = "Avorion", min = "0.17", max = "0.21"}, -- we can only work with Avorion between versions 0.17 and 0.21
    --      {id = "SomeModLoader", min = "1.0", max = "2.0"}, -- we require SomeModLoader, and we need its version to be between 1.0 and 2.0
    --      {id = "AnotherMod", max = "2.0"}, -- we require AnotherMod, and we need its version to be 2.0 or lower
    --      {id = "IncompatibleMod", incompatible = true}, -- we're incompatible with IncompatibleMod, regardless of its version
    --      {id = "IncompatibleModB", exact = "2.0", incompatible = true}, -- we're incompatible with IncompatibleModB, but only exactly version 2.0
    --      {id = "OptionalMod", min = "0.2", optional = true}, -- we support OptionalMod optionally, starting at version 0.2
    -- },
    dependencies = {
        {id = "Avorion", min = "2.2", max = "2.*.*"}
    },

    -- Set to true if the mod only has to run on the server. Clients will get notified that the mod is running on the server, but they won't download it to themselves
    serverSideOnly = false,

    -- Set to true if the mod only has to run on the client, such as UI mods
    clientSideOnly = false,

    -- Set to true if the mod changes the savegame in a potentially breaking way, as in it adds scripts or mechanics that get saved into database and no longer work once the mod gets disabled
    -- logically, if a mod is client-side only, it can't alter savegames, but Avorion doesn't check for that at the moment
    saveGameAltering = false,

    -- Contact info for other users to reach you in case they have questions
    contact = "",
}
