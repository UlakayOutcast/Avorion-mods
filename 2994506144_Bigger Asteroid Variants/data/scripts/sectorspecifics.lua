SectorSpecifics.RichAsteroidsSector_addTemplatesOld = SectorSpecifics.addMoreTemplates
function SectorSpecifics:addMoreTemplates()
    self:RichAsteroidsSector_addTemplatesOld()

    self:addTemplate("sectors/normalRichAsteroidFields");
    self:addTemplate("sectors/hugeAsteroidFields");
    self:addTemplate("sectors/bigAsteroidFields");
end
