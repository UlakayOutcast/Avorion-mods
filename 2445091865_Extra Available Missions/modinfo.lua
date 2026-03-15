
meta =
{
    -- ID of your mod; Make sure this is unique!
    -- Will be used for identifying the mod in dependency lists
    -- Will be changed to workshop ID (ensuring uniqueness) when you upload the mod to the workshop
    id = "2445091865",

    -- Name of your mod; You may want this to be unique, but it's not absolutely necessary.
    -- This is an additional helper attribute for you to easily identify your mod in the Mods() list
    name = "ExtraAvailableMissions",

    -- Title of your mod that will be displayed to players
    title = "Extra Available Missions",

    -- Type of your mod, either "mod" or "factionpack"
    type = "mod",

    -- Description of your mod that will be displayed to players
    description = "Quick reimplemnetation of https://steamcommunity.com/sharedfiles/filedetails/?id=2045569194 - I have several serious issues with how FuryOfTheStars implemented of this concept, and they don't seem to be interested in maintaining the mod.\n\nThis mod does NOT add any new missions! However, it should be fully compatible with all of the extra missions that I've added, as well as any other missions that I (or other modders) happen to add in the future.\n\ntl;dr of what this mod does - it adds more missions to mission boards and swaps them out more frequently. You should always have something available to do when using this mod.",

    -- Insert all authors into this list
    authors = {"KnifeHeart"},

    -- Version of your mod, should be in format 1.0.0 (major.minor.patch) or 1.0 (major.minor)
    -- This will be used to check for unmet dependencies or incompatibilities, and to check compatibility between clients and dedicated servers with mods.
    -- If a client with an unmatching major or minor mod version wants to log into a server, login is prohibited.
    -- Unmatching patch version still allows logging into a server. This works in both ways (server or client higher or lower version).
    version = "1.1.6",

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
        {id = "2045569194", exact = "*.*", incompatible = true},
        {id = "2207469437", exact = "*.*", optional = true},
        {id = "2439444436", exact = "*.*", optional = true},
        {id = "2381708468", exact = "*.*", optional = true},
        {id = "2379374382", exact = "*.*", optional = true},
        {id = "2133506910", exact = "*.*", optional = true},
        {id = "2743848682", exact = "*.*", optional = true},
        {id = "2750680477", exact = "*.*", optional = true},
        {id = "2746663587", exact = "*.*", optional = true},
        {id = "2901149152", exact = "*.*", optional = true},
        {id = "3306700477", exact = "*.*", optional = true},
        {id = "3341419631", exact = "*.*", optional = true},
        {id = "Avorion", min = "1.1", max = "*.*"}
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
