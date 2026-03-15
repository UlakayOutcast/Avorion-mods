TorpedoAssembly.pta_commandGetTorpDesign = TorpedoAssembly.commandGetTorpDesign
function TorpedoAssembly.commandGetTorpDesign(tRarityIndex, tWarheadIndex, tBodyIndex, tTechLevel)
    tDesignData = TorpedoAssembly.pta_commandGetTorpDesign(tRarityIndex, tWarheadIndex, tBodyIndex, tTechLevel)
    tDesignData.visualSeed = SeedStr(tDesignData.name).int32
    return tDesignData
end
