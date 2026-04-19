-- Add new perks to Perk table
-- Increases/Decreases Area Size of Map Commands Scout, Mine, Scrap, Refine, Procure, Sell, Trade, Expedition, Maintenance
CaptainUtility.PerkType.Hodophile = 662730600 --Use super unique values for custom perks to reduce chance of incompatibility
CaptainUtility.PerkType.Hodophobic = 662730601
-- Increases/Decreases Local Reputation During Map Commands
CaptainUtility.PerkType.Friendly = 662730602
CaptainUtility.PerkType.Unfriendly = 662730603
-- Increases/Decreases UnarmedTurrets
CaptainUtility.PerkType.UpUnarmedTurrets = 662730604
CaptainUtility.PerkType.DownUnarmedTurrets = 662730605
-- Increases/Decreases ArmedTurrets
CaptainUtility.PerkType.UpArmedTurrets = 662730606
CaptainUtility.PerkType.DownArmedTurrets = 662730607
-- Increases/Decreases PointDefenseTurrets
CaptainUtility.PerkType.UpPointDefenseTurrets = 662730608
CaptainUtility.PerkType.DownPointDefenseTurrets = 662730609
-- Increases/Decreases AutomaticTurrets
CaptainUtility.PerkType.UpAutomaticTurrets = 662730610
CaptainUtility.PerkType.DownAutomaticTurrets = 662730611
-- Increases/Decreases EnergyDamage
CaptainUtility.PerkType.UpEnergyDamage = 662730612
CaptainUtility.PerkType.DownEnergyDamage = 662730613
-- Increases/Decreases ElectricDamage
CaptainUtility.PerkType.UpElectricDamage = 662730614
CaptainUtility.PerkType.DownElectricDamage = 662730615
-- Increases/Decreases PlasmaDamage
CaptainUtility.PerkType.UpPlasmaDamage = 662730616
CaptainUtility.PerkType.DownPlasmaDamage = 662730617
-- Increases/Decreases AntiMatterDamage
CaptainUtility.PerkType.UpAntiMatterDamage = 662730618
CaptainUtility.PerkType.DownAntiMatterDamage = 662730619
-- Increases/Decreases FragmentsDamage
CaptainUtility.PerkType.UpFragmentsDamage = 662730620
CaptainUtility.PerkType.DownFragmentsDamage = 662730621
-- Increases/Decreases PhysicalDamage
CaptainUtility.PerkType.UpPhysicalDamage = 662730622
CaptainUtility.PerkType.DownPhysicalDamage = 662730623

-- Hijack current Class Properties function and append our own classes
local ExtCapts_CaptainUtility_ClassProperties = CaptainUtility.ClassProperties --Save whatever this function is
function CaptainUtility.ClassProperties() --Create new function in its place
	local properties = {}
	
    if ExtCapts_CaptainUtility_ClassProperties then
        properties = ExtCapts_CaptainUtility_ClassProperties() --Run original function, then append result as necessary
    end
	
    properties[CaptainUtility.ClassType.SquadLeader] =
    {
        displayName = "Командир отряда /* Капитанский класс мужчины-капитана */"%_t,
        displayNameFemale = "Командир отряда /* Капитанский класс женщины-капитана*/"%_t,
        untranslatedName = "Командир отряда /* Капитанский класс мужчины-капитана */"%_T,
        untranslatedNameFemale = "Командир отряда /* Капитанский класс женщины-капитана*/"%_T,
        description = "Этот капитан имеет большой опыт командования взводами истребителей. Его опыт позволит выжать максимум эффективности из пилотных отрядов. /* sentence referring to a male captain */"%_t,
        descriptionFemale = "Этот капитан имеет большой опыт командования взводами истребителей. Ее опыт позволит выжать максимум эффективности из пилотных отрядов. /* sentence referring to a female captain */"%_t,

        icon = "data/textures/ui/captain/symbol-squadleader.png",
        tooltipIcon = "data/textures/ui/captain/symbol-squadleader-black-bg.png",
        center = "data/textures/ui/captain/center-gold-shaded.png",
        ring = "data/textures/ui/captain/ring-gold-shaded.png",

        centerColor = ColorRGB(1.0, 1.0, 1.0),
        ringColor = ColorRGB(1.0, 1.0, 1.0),
        primaryColor = ColorRGB(0.85, 0.6, 0.1),
        secondaryColor = ColorRGB(0.85, 0.6, 0.1),
    }
    properties[CaptainUtility.ClassType.ShieldMaster] =
    {
        displayName = "Мастер щита /* Капитанский класс мужчины-капитана */"%_t,
        displayNameFemale = "Повелительница щита /* Капитанский класс женщины-капитана*/"%_t,
        untranslatedName = "Мастер щита /* Капитанский класс мужчины-капитана */"%_T,
        untranslatedNameFemale = "Повелительница щита /* Капитанский класс женщины-капитана*/"%_T,
        description = "Этот капитан овладел искусством защитных щитов. Он может максимизировать свои собственные щиты, нанося при этом больший урон другим. /* sentence referring to a male captain */"%_t,
        descriptionFemale = "Этот капитан овладел искусством защитных щитов. Она может максимизировать свои собственные щиты, нанося при этом больший урон другим. /* sentence referring to a female captain */"%_t,

        icon = "data/textures/ui/captain/symbol-generic-captain.png",
        tooltipIcon = "data/textures/ui/captain/symbol-generic-captain-black-bg.png",
        center = "data/textures/ui/captain/center-white-shaded.png",
        ring = "data/textures/ui/captain/ring-white-shaded.png",

        centerColor = ColorRGB(0.4, 0.4, 1.0),
        ringColor = ColorRGB(0.4, 0.4, 1.0),
        primaryColor = ColorRGB(0.4, 0.4, 1.0),
        secondaryColor = ColorRGB(0.4, 0.4, 1.0),
    }
    properties[CaptainUtility.ClassType.AICaptain] =
    {
        displayName = "AI Капитан /* Капитанский класс мужчины-капитана */"%_t,
        displayNameFemale = "AI Капитан /* Капитанский класс женщины-капитана*/"%_t,
        untranslatedName = "AI Капитан /* Капитанский класс мужчины-капитана */"%_T,
        untranslatedNameFemale = "AI Капитан /* Капитанский класс женщины-капитана*/"%_T,
        description = "Вся команда распущена. Ваши биологические зависимости - всего лишь слабость. /* sentence referring to a male captain */"%_t,
        descriptionFemale = "Вся команда распущена. Ваши биологические зависимости - всего лишь слабость. /* sentence referring to a female captain */"%_t,

        icon = "data/textures/ui/captain/symbol-generic-captain.png",
        tooltipIcon = "data/textures/ui/captain/symbol-generic-captain-black-bg.png",
        center = "data/textures/ui/captain/center-white-shaded.png",
        ring = "data/textures/ui/captain/ring-white-shaded.png",

        centerColor = ColorRGB(0.0, 0.5, 1.0),
        ringColor = ColorRGB(0.0, 0.5, 1.0),
        primaryColor = ColorRGB(0.0, 0.5, 1.0),
        secondaryColor = ColorRGB(0.0, 0.5, 1.0),
    }
    properties[CaptainUtility.ClassType.LimitBreaker] =
    {
        displayName = "Разрушитель границ /* Капитанский класс мужчины-капитана */"%_t,
        displayNameFemale = "Разрушительница границ /* Капитанский класс женщины-капитана*/"%_t,
        untranslatedName = "Разрушитель границ /* Капитанский класс мужчины-капитана */"%_T,
        untranslatedNameFemale = "Разрушительница границ /* Капитанский класс женщины-капитана*/"%_T,
        description = "Этот капитан живет на грани возможностей кораблестроения, позволяя строить свои корабли за пределами их лимитов. Требуется 15 подсистем для вступления в силу. /* sentence referring to a male captain */"%_t,
        descriptionFemale = "Этот капитан живет на грани возможностей кораблестроения, позволяя строить свои корабли за пределами их лимитов. Требуется 15 подсистем для вступления в силу. /* sentence referring to a female captain */"%_t,

        icon = "data/textures/ui/captain/symbol-generic-captain.png",
        tooltipIcon = "data/textures/ui/captain/symbol-generic-captain-black-bg.png",
        center = "data/textures/ui/captain/center-white-shaded.png",
        ring = "data/textures/ui/captain/ring-white-shaded.png",

        centerColor = ColorRGB(0.8, 0.3, 0.3),
        ringColor = ColorRGB(0.8, 0.3, 0.3),
        primaryColor = ColorRGB(0.8, 0.3, 0.3),
        secondaryColor = ColorRGB(0.8, 0.3, 0.3),
    }
    properties[CaptainUtility.ClassType.StarSurfer] =
    {
        displayName = "Звездный серфер /* Капитанский класс мужчины-капитана */"%_t,
        displayNameFemale = "Звездная серферша /* Капитанский класс женщины-капитана*/"%_t,
        untranslatedName = "Звездный серфер /* Капитанский класс мужчины-капитана */"%_T,
        untranslatedNameFemale = "Звездная серферша /* Капитанский класс женщины-капитана*/"%_T,
        description = "Этому капитану нужна скорость, бешеная скорость. /* sentence referring to a male captain */"%_t,
        descriptionFemale = "Этому капитану нужна скорость, бешеная скорость. /* sentence referring to a female captain */"%_t,

        icon = "data/textures/ui/captain/symbol-generic-captain.png",
        tooltipIcon = "data/textures/ui/captain/symbol-generic-captain-black-bg.png",
        center = "data/textures/ui/captain/center-white-shaded.png",
        ring = "data/textures/ui/captain/ring-white-shaded.png",

        centerColor = ColorRGB(0.7, 0.3, 0.7),
        ringColor = ColorRGB(0.7, 0.3, 0.7),
        primaryColor = ColorRGB(0.7, 0.3, 0.7),
        secondaryColor = ColorRGB(0.7, 0.3, 0.7),
    }
    properties[CaptainUtility.ClassType.LootGoblin] =
    {
        displayName = "Лут Гоблин /* Капитанский класс мужчины-капитана */"%_t,
        displayNameFemale = "Лут Гоблин /* Капитанский класс женщины-капитана*/"%_t,
        untranslatedName = "Лут Гоблин /* Капитанский класс мужчины-капитана */"%_T,
        untranslatedNameFemale = "Лут Гоблинша /* Капитанский класс женщины-капитана*/"%_T,
        description = "Жадность этого капитана не знает границ, он позаботился о том, чтобы получить свою добычу и иметь место для ее хранения. /* sentence referring to a male captain */"%_t,
        descriptionFemale = "Жадность этого капитана не знает границ, она позаботилась о том, чтобы получить свою добычу и иметь место для ее хранения. /* sentence referring to a female captain */"%_t,

        icon = "data/textures/ui/captain/symbol-generic-captain.png",
        tooltipIcon = "data/textures/ui/captain/symbol-generic-captain-black-bg.png",
        center = "data/textures/ui/captain/center-white-shaded.png",
        ring = "data/textures/ui/captain/ring-white-shaded.png",

        centerColor = ColorRGB(0.1, 0.8, 0.1),
        ringColor = ColorRGB(0.1, 0.8, 0.1),
        primaryColor = ColorRGB(0.1, 0.8, 0.1),
        secondaryColor = ColorRGB(0.1, 0.8, 0.1),
    }
	return properties --Return adjusted result
end

-- Hijack current Class Tooltip function and append our own classes' tool tips
local ExtCapts_CaptainUtility_makeTooltip = CaptainUtility.makeTooltip
function CaptainUtility.makeTooltip(captain, commandType)
    local iconColor = ColorRGB(0.5, 0.5, 0.5)

    local headLineSize = 25
    local headLineFont = 15

    local tooltip = Tooltip() -- our reconstructed tooltip
    local originalTooltip = Tooltip()
	
    if ExtCapts_CaptainUtility_makeTooltip then
        originalTooltip = ExtCapts_CaptainUtility_makeTooltip(captain, commandType) -- copy the original tooltip
    end
	
	
    local fontSize = 13;
    local lineHeight = 16;
	
	local hookLine = 0
	local lastLine=nil
	
	--- Dissect original tooltip, copy over the first portion ---
	for i, lineGrab in pairs({originalTooltip:getLines()}) do
		if lineGrab.ltext == "Level" 
		or lineGrab.ltext == "Level"  
		or lineGrab.ltext == "Nivel"  
		or lineGrab.ltext == "Niveau"  
		or lineGrab.ltext == "レベル"  
		or lineGrab.ltext == "Уровень"  
		or lineGrab.ltext == "级别" then -- I've found that the 'Level' line always takes place after the class information and/or a blank line
			hookLine=i
			break
		end
		if(lastLine)then tooltip:addLine(lastLine) end
		lastLine=lineGrab
	end
	
    local classLinesAdded
	if originalTooltip:getLine(hookLine-2).ltext == "Tier" 
	or originalTooltip:getLine(hookLine-2).ltext == "Stufe" 
	or originalTooltip:getLine(hookLine-2).ltext == "Grado" 
	or originalTooltip:getLine(hookLine-2).ltext == "Rang" 
	or originalTooltip:getLine(hookLine-2).ltext == "ティア" 
	or originalTooltip:getLine(hookLine-2).ltext == "Ранг" 
	or originalTooltip:getLine(hookLine-2).ltext == "等级" then -- If this line is 'Tier' then that means no other class information has been added yet
		classLinesAdded=false
		tooltip:addLine(lastLine)-- additional empty line added by class break
	else
		classLinesAdded=true
	end
	
	
	--- Add custom Captain Class tooltips here ---
    -- Squad Leaders boost fighter squad efficiency
    if captain:hasClass(CaptainClass.SquadLeader) then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Эскадрильи истребителей"%_t
        line.rtext = "+1"%_t
        line.icon = "data/textures/icons/hangar.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Производственная мощность"%_t
        line.rtext = "+10%"%_t
        line.icon = "data/textures/icons/production-capacity.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        classLinesAdded = true
    end
    -- Shield Masters boost shield stats and plasma damage
    if captain:hasClass(CaptainClass.ShieldMaster) then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Все характеристики щита"%_t
        line.rtext = "+10%"%_t
        line.icon = "data/textures/icons/shield.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Плазменный урон"%_t
        line.rtext = "+10%"%_t
        line.icon = "data/textures/icons/plasma-gun.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        classLinesAdded = true
    end
    -- AI Captains remove add 10k AI crew, adds auto turret slots, and cost 1TW energy
    if captain:hasClass(CaptainClass.AICaptain) then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Экипаж AI инженереров"%_t
        line.rtext = "+300"%_t
        line.icon = "data/textures/icons/crew.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
		
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Экипаж AI механиков"%_t
        line.rtext = "+300"%_t
        line.icon = "data/textures/icons/crew.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Автоматические турели"%_t
        line.rtext = "+20"%_t
        line.icon = "data/textures/icons/auto-targeting.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Производство энергии"%_t
		line.rcolor = ColorRGB(0.9, 0.3, 0.3)
        line.rtext = "-1GW"%_t
        line.icon = "data/textures/icons/electric.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        classLinesAdded = true
    end
    -- Limit Breaker increase processing power to next step and adds 2 arbitrary turrets
    if captain:hasClass(CaptainClass.LimitBreaker) then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Лимит обработки"%_t
        line.rtext = "+2 Шага"%_t
        line.icon = "data/textures/icons/processor.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Уневерсальние ячейки для турелей"%_t
        line.rtext = "+4"%_t
        line.icon = "data/textures/icons/turret.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        classLinesAdded = true
    end
    -- Star Surfer increases Hyperspace and Speed stats
    if captain:hasClass(CaptainClass.StarSurfer) then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Перезарядка гиперпространства"%_t
        line.rtext = "-20%"%_t
        line.icon = "data/textures/icons/vortex.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Скорость"%_t
        line.rtext = "+10%"%_t
        line.icon = "data/textures/icons/speedometer.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Ускорение"%_t
        line.rtext = "+10%"%_t
        line.icon = "data/textures/icons/acceleration.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        classLinesAdded = true
    end
    -- Loot Goblin adds cargo space and significant loot item pickup range
    if captain:hasClass(CaptainClass.LootGoblin) then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Диапазон сбора добычи"%_t
        line.rtext = "+3 км"%_t
        line.icon = "data/textures/icons/horizontal-flip.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Грузовой отсек"%_t
        line.rtext = "+10%"%_t
        line.icon = "data/textures/icons/cargo-hold.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        classLinesAdded = true
    end
	
	
	--- Add remaining lines from the original tooltip to finish our reconstructed tooltip ---
	if classLinesAdded then
		hookLine=hookLine-1 -- reset to the empty line added by class break if necessary
	end
	for i, lineGrab in pairs({originalTooltip:getLines()}) do
		if(i>=hookLine) then
			tooltip:addLine(lineGrab)
		end
	end
	
	return tooltip
end
-- Перехватываем текущую функцию свойств перков и добавляем наши собственные перки
local ExtCapts_CaptainUtility_PerkProperties = CaptainUtility.PerkProperties
function CaptainUtility.PerkProperties()
	local properties = {}
	
    if ExtCapts_CaptainUtility_PerkProperties then
        properties = ExtCapts_CaptainUtility_PerkProperties()
    end
    properties[CaptainUtility.PerkType.Hodophile] =
    {
        displayName = "Ходофил /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Ходофил /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан любит путешествовать и расширит свои параметры, чтобы сделать это. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан любит путешествовать и расширит свои параметры, чтобы сделать это. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Увеличенная рабочая область с командами"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.Hodophobic] =
    {
        displayName = "Годофоб /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Годофоб /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан ненавидит путешествовать, предпочитая держаться поближе к тому месту, где он находится. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан ненавидит путешествовать, предпочитая держаться поближе к тому месту, где она находится. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Уменьшенная рабочая область с командами"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.Friendly] =
    {
        displayName = "Дружелюбный /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Дружелюбная /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан хорошо работает с другими, получая репутацию у близлежащих фракций. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан хорошо работает с другими, получая репутацию у близлежащих фракций. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Вероятно, получит репутацию от выполнения команд"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.Unfriendly] =
    {
        displayName = "Недружелюбный /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Недружелюбная /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан является антагонистом, иногда теряя репутацию у близлежащих фракций. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан является антагонистом, иногда теряя репутацию у близлежащих фракций. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Вероятно, потеряет репутацию от выполнения команд"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.UpUnarmedTurrets] =
    {
        displayName = "Увеличение число небоевых турелей /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Увеличение число небоевых турелей /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан добавляет ячейки для небоевых турелей на корабль. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан добавляет ячейки для небоевых турелей на корабль. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Добавляет ячейки для небоевых турелей на корабль"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.UpArmedTurrets] =
    {
        displayName = "Увеличение число боевых турелей /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Увеличение число боевых турелей /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан добавляет ячейки для боевых турелей на корабль. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан добавляет ячейки для боевых турелей на корабль. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Добавляет ячейки для боевых турелей на корабль"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.UpPointDefenseTurrets] =
    {
        displayName = "Увеличение число оборонительных турелей /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Увеличение число оборонительных турелей /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан добавляет ячейки для оборонительных турелей на корабль. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан добавляет ячейки для оборонительных турелей на корабль. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Добавляет ячейки для оборонительных турелей на корабль"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.UpAutomaticTurrets] =
    {
        displayName = "Увеличение число автоматических турелей /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Увеличение число автоматических турелей /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан добавляет ячейки для автоматических турелей на корабль. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан добавляет ячейки для автоматических турелей на корабль. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Добавляет ячейки для автоматических турелей на корабль"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.UpEnergyDamage] =
    {
        displayName = "Увеличение энергетического урона /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Увеличение энергетического урона /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан добавляет дополнительный энергетический урон пушкам корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан добавляет дополнительный энергетический урон пушкам корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Добавляет дополнительный энергетический урон пушкам корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.UpElectricDamage] =
    {
        displayName = "Увеличение электрического урона /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Увеличение электрического урона /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан добавляет дополнительный электрический урон пушкам корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан добавляет дополнительный электрический урон пушкам корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Добавляет дополнительный электрический урон пушкам корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.UpPlasmaDamage] =
    {
        displayName = "Увеличение плазменного урона /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Увеличение плазменного урона /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан добавляет дополнительный плазменный урон пушкам корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан добавляет дополнительный плазменный урон пушкам корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Добавляет дополнительный плазменный урон пушкам корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.UpAntiMatterDamage] =
    {
        displayName = "Увеличение урона антиматерией /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Увеличение урона антиматерией /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан добавляет дополнительный урон антиматерией пушкам корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан добавляет дополнительный урон антиматерией пушкам корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Добавляет дополнительный урон антиматерией пушкам корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.UpFragmentsDamage] =
    {
        displayName = "Увеличение урона осколками /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Увеличение урона осколками /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан добавляет дополнительный урон осколками пушкам корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан добавляет дополнительный урон осколками пушкам корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Добавляет дополнительный урон осколками пушкам корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.UpPhysicalDamage] =
    {
        displayName = "Увеличение физического урона /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Увеличение физического урона /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан добавляет дополнительный физический урон пушкам корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан добавляет дополнительный физический урон пушкам корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Добавляет дополнительный физический урон пушкам корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.DownUnarmedTurrets] =
    {
        displayName = "Уменьшение число небоевых турелей /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Уменьшение число небоевых турелей /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан убирает ячейки для небоевых турелей с корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан убирает ячейки для небоевых турелей с корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Убирает ячейки для небоевых турелей с корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.DownArmedTurrets] =
    {
        displayName = "Уменьшение число боевых турелей /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Уменьшение число боевых турелей /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан убирает ячейки для боевых турелей с корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан убирает ячейки для боевых турелей с корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Убирает ячейки для боевых турелей с корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.DownPointDefenseTurrets] =
    {
        displayName = "Уменьшение число оборонительных турелей /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Уменьшение число оборонительных турелей /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан убирает ячейки для оборонительных турелей с корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан убирает ячейки для оборонительных турелей с корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Убирает ячейки для оборонительных турелей с корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.DownAutomaticTurrets] =
    {
        displayName = "Уменьшение число автоматических турелей /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Уменьшение число автоматических турелей /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан убирает ячейки для автоматических турелей с корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан убирает ячейки для автоматических турелей с корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Убирает ячейки для автоматических турелей с корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.DownEnergyDamage] =
    {
        displayName = "Уменьшение энергетического урона /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Уменьшение энергетического урона /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан уменьшает выход энергетического урона из пушек корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан уменьшает выход энергетического урона из пушек корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Уменьшает выход энергетического урона из пушек корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.DownElectricDamage] =
    {
        displayName = "Уменьшение электрического урона /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Уменьшение электрического урона /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан уменьшает выход электрического урона из пушек корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан уменьшает выход электрического урона из пушек корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Уменьшает выход электрического урона из пушек корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.DownPlasmaDamage] =
    {
        displayName = "Уменьшение плазменного урона /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Уменьшение плазменного урона /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан уменьшает выход плазменного урона из пушек корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан уменьшает выход плазменного урона из пушек корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Уменьшает выход плазменного урона из пушек корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.DownAntiMatterDamage] =
    {
        displayName = "Уменьшение урона антиматерией /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Уменьшение урона антиматерией /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан уменьшает выход урона антиматерией из пушек корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан уменьшает выход урона антиматерией из пушек корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Уменьшает выход урона антиматерией из пушек корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.DownFragmentsDamage] =
    {
        displayName = "Уменьшение урона осколками /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Уменьшение урона осколками /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан уменьшает выход урона осколками из пушек корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан уменьшает выход урона осколками из пушек корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Уменьшает выход урона осколками из пушек корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
    properties[CaptainUtility.PerkType.DownPhysicalDamage] =
    {
        displayName = "Уменьшение физического урона /* Тип перка капитана-мужчины */"%_t,
        displayNameFemale = "Уменьшение физического урона /* Тип перка капитана-женщины */"%_t,
        description = "Этот капитан уменьшает выход физического урона из пушек корабля. /* предложение, относящееся к капитану-мужчине */"%_t,
        descriptionFemale = "Этот капитан уменьшает выход физического урона из пушек корабля. /* предложение, относящееся к капитану-женщине */"%_t,
        summary = "Уменьшает выход физического урона из пушек корабля"%_t,
        color = ColorRGB(0.9, 0.9, 0.9)
    }
	
	return properties
end

-- Perk Impacts, designed to be infinitely scalable without error or generic error fallback
function CaptainUtility.getAreaPerkImpact(captain, perk)

	if perk == CaptainUtility.PerkType.Hodophile then
		return math.floor((captain.level+1)/2) -- increase area by 1 for every 2 levels
		
	elseif perk == CaptainUtility.PerkType.Hodophobic then
		return -math.max(0,3 - math.floor((captain.level+1)/2)) -- decrease area by 3, softening by 1 every 2 levels until 0 reduction
		
	else return 0
	end
end

function CaptainUtility.getRelationshipPerkImpact(captain, perk)

	if perk == CaptainUtility.PerkType.Friendly then
		return (captain.level+1)*100 -- increase by 100 for every level
		
	elseif perk == CaptainUtility.PerkType.Unfriendly then
		return -math.max(0,500+(captain.level*100)) -- decrease by 500, soften by 100 for every level, cap 0
		
	else return 0 -- fallback
	end
end

function CaptainUtility.getShipBonusPerkImpact(captain, perk)

	if perk == CaptainUtility.PerkType.UpUnarmedTurrets
		or perk == CaptainUtility.PerkType.UpArmedTurrets
		or perk == CaptainUtility.PerkType.UpPointDefenseTurrets
		or perk == CaptainUtility.PerkType.UpAutomaticTurrets then
		return math.floor((captain.level+1)/2) -- increase perk by 1 for every 2 levels
		
	elseif perk == CaptainUtility.PerkType.UpEnergyDamage
		or perk == CaptainUtility.PerkType.UpElectricDamage
		or perk == CaptainUtility.PerkType.UpPlasmaDamage
		or perk == CaptainUtility.PerkType.UpAntiMatterDamage
		or perk == CaptainUtility.PerkType.UpFragmentsDamage
		or perk == CaptainUtility.PerkType.UpPhysicalDamage then
		return 0.01*captain.level -- increase perk by .01 for every level
		
	elseif perk == CaptainUtility.PerkType.DownUnarmedTurrets
		or perk == CaptainUtility.PerkType.DownArmedTurrets
		or perk == CaptainUtility.PerkType.DownPointDefenseTurrets
		or perk == CaptainUtility.PerkType.DownAutomaticTurrets then
		return -math.max(0,3 - math.floor((captain.level+1)/2)) -- decrease perk by 3, softening by 1 every 2 levels until 0 reduction
		
	elseif perk == CaptainUtility.PerkType.DownEnergyDamage
		or perk == CaptainUtility.PerkType.DownElectricDamage
		or perk == CaptainUtility.PerkType.DownPlasmaDamage
		or perk == CaptainUtility.PerkType.DownAntiMatterDamage
		or perk == CaptainUtility.PerkType.DownFragmentsDamage
		or perk == CaptainUtility.PerkType.DownPhysicalDamage then
		return -math.max(0,0.05 - (captain.level*0.01)) -- decrease perk by 0.05, soften by 0.01 every level until 0
		
	else return 0 -- fallback
	
	end
	
end

-- this is a custom function that gets called from the simulation.lua because Galaxy() cannot be rendered there due to poor coding.
-- meant to be used in conjuction with the 'friendly' and 'unfriendly' perks.
function CaptainUtility.applyLocalRelationshipChange(faction, shipDatabaseEntry, impact)

	local x, y = shipDatabaseEntry:getCoordinates()
    local localFaction = Galaxy():getNearestFaction(x,y)
	
	changeRelations(faction, localFaction, impact, nil, nil, nil, localFaction)
end

-- Per Command / Perk Summaries
-- My summaries will be the same across all commands, so just going to make a single function for each one to call
local PerkSummary = {}
function PerkSummary.Hodophile(line, captain, perk, properties, isValid)
	if perk == CaptainUtility.PerkType.Hodophile then
		isPerk=true
		if CaptainUtility.getAreaPerkImpact(captain, perk) > 0 and isValid then
			line.ltext = "${var1}x${var1} увеличенная командная область"%_t % {var1 = CaptainUtility.getAreaPerkImpact(captain, perk)}
			line.lcolor = ColorRGB(0.6, 0.9, 0.6)
		else
			line.ltext = "не влияет на командную зону"%_t
			line.lcolor = ColorRGB(0.7, 0.7, 0.7)
		end
		eprint("Recognized as Extra Crew n Captains Perk")
    end
end
function PerkSummary.Hodophobic(line, captain, perk, properties, isValid)
	if perk == CaptainUtility.PerkType.Hodophobic then
		isPerk=true
		if CaptainUtility.getAreaPerkImpact(captain, perk) < 0 and isValid then
			line.ltext = "${var1}x${var1} умененная командная область"%_t % {var1 = math.abs(CaptainUtility.getAreaPerkImpact(captain, perk))}
			line.lcolor = ColorRGB(0.6, 0.9, 0.6)
		else
			line.ltext = "не влияет на командную зону"%_t
			line.lcolor = ColorRGB(0.7, 0.7, 0.7)
		end
		eprint("Recognized as Extra Crew n Captains Perk")
    end
end
function PerkSummary.Friendly(line, captain, perk, properties, isValid)
	if perk == CaptainUtility.PerkType.Friendly then
		isPerk=true
		if CaptainUtility.getRelationshipPerkImpact(captain, perk) > 0 and isValid then
			line.ltext = "Улучшает отношения с местной фракцией"%_t
			line.lcolor = ColorRGB(0.6, 0.9, 0.6)
		else
			line.ltext = "Не повлияет на отношения с местной фракцией"%_t
			line.lcolor = ColorRGB(0.7, 0.7, 0.7)
		end
		eprint("Recognized as Extra Crew n Captains Perk")
    end
end
function PerkSummary.Unfriendly(line, captain, perk, properties, isValid)
	if perk == CaptainUtility.PerkType.Unfriendly then
		isPerk=true
		if CaptainUtility.getRelationshipPerkImpact(captain, perk) < 0 and isValid then
			line.ltext = "Ухудшает отношения с местной фракцией"%_t
			line.lcolor = ColorRGB(0.9, 0.6, 0.6)
		else
			line.ltext = "Не повлияет на отношения с местной фракцией"%_t
			line.lcolor = ColorRGB(0.7, 0.7, 0.7)
		end
		eprint("Recognized as Extra Crew n Captains Perk")
    end
end
function PerkSummary.ShipBonus(line, captain, perk, properties)
	if perk == CaptainUtility.PerkType.UpUnarmedTurrets
		or perk == CaptainUtility.PerkType.UpArmedTurrets
		or perk == CaptainUtility.PerkType.UpPointDefenseTurrets
		or perk == CaptainUtility.PerkType.UpAutomaticTurrets
		or perk == CaptainUtility.PerkType.UpEnergyDamage
		or perk == CaptainUtility.PerkType.UpElectricDamage
		or perk == CaptainUtility.PerkType.UpPlasmaDamage
		or perk == CaptainUtility.PerkType.UpAntiMatterDamage
		or perk == CaptainUtility.PerkType.UpFragmentsDamage
		or perk == CaptainUtility.PerkType.UpPhysicalDamage
		or perk == CaptainUtility.PerkType.DownUnarmedTurrets
		or perk == CaptainUtility.PerkType.DownArmedTurrets
		or perk == CaptainUtility.PerkType.DownPointDefenseTurrets
		or perk == CaptainUtility.PerkType.DownAutomaticTurrets
		or perk == CaptainUtility.PerkType.DownEnergyDamage
		or perk == CaptainUtility.PerkType.DownElectricDamage
		or perk == CaptainUtility.PerkType.DownPlasmaDamage
		or perk == CaptainUtility.PerkType.DownAntiMatterDamage
		or perk == CaptainUtility.PerkType.DownFragmentsDamage
		or perk == CaptainUtility.PerkType.DownPhysicalDamage then
			isPerk=true
			line.ltext = "Не повлияет на эту команду"%_t
			line.lcolor = ColorRGB(0.6, 0.6, 0.6)
			eprint("Recognized as Extra Crew n Captains Perk")
    end
end


-- hijacking the various map command calls
local ExtCapts_CaptainUtility_insertMiningPerkSummaries = CaptainUtility.insertMiningPerkSummaries
function CaptainUtility.insertMiningPerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertMiningPerkSummaries then
        ExtCapts_CaptainUtility_insertMiningPerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, true)
	PerkSummary.Hodophobic(line, captain, perk, properties, true)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end

local ExtCapts_CaptainUtility_insertSalvagingPerkSummaries = CaptainUtility.insertSalvagingPerkSummaries
function CaptainUtility.insertSalvagingPerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertSalvagingPerkSummaries then
        ExtCapts_CaptainUtility_insertSalvagingPerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, true)
	PerkSummary.Hodophobic(line, captain, perk, properties, true)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end

local ExtCapts_CaptainUtility_insertProcurePerkSummaries = CaptainUtility.insertProcurePerkSummaries
function CaptainUtility.insertProcurePerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertProcurePerkSummaries then
        ExtCapts_CaptainUtility_insertProcurePerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, true)
	PerkSummary.Hodophobic(line, captain, perk, properties, true)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end

local ExtCapts_CaptainUtility_insertSellPerkSummaries = CaptainUtility.insertSellPerkSummaries
function CaptainUtility.insertSellPerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertSellPerkSummaries then
        ExtCapts_CaptainUtility_insertSellPerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, true)
	PerkSummary.Hodophobic(line, captain, perk, properties, true)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end

local ExtCapts_CaptainUtility_insertTradePerkSummaries = CaptainUtility.insertTradePerkSummaries
function CaptainUtility.insertTradePerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertTradePerkSummaries then
        ExtCapts_CaptainUtility_insertTradePerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, true)
	PerkSummary.Hodophobic(line, captain, perk, properties, true)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end

local ExtCapts_CaptainUtility_insertTravelPerkSummaries = CaptainUtility.insertTravelPerkSummaries
function CaptainUtility.insertTravelPerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertTravelPerkSummaries then
        ExtCapts_CaptainUtility_insertTravelPerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, false)
	PerkSummary.Hodophobic(line, captain, perk, properties, false)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end

local ExtCapts_CaptainUtility_insertSupplyPerkSummaries = CaptainUtility.insertSupplyPerkSummaries
function CaptainUtility.insertSupplyPerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertSupplyPerkSummaries then
        ExtCapts_CaptainUtility_insertSupplyPerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, false)
	PerkSummary.Hodophobic(line, captain, perk, properties, false)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end

local ExtCapts_CaptainUtility_insertRefinePerkSummaries = CaptainUtility.insertRefinePerkSummaries
function CaptainUtility.insertRefinePerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertRefinePerkSummaries then
        ExtCapts_CaptainUtility_insertRefinePerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, false)
	PerkSummary.Hodophobic(line, captain, perk, properties, false)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end

local ExtCapts_CaptainUtility_insertScoutPerkSummaries = CaptainUtility.insertScoutPerkSummaries
function CaptainUtility.insertScoutPerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertScoutPerkSummaries then
        ExtCapts_CaptainUtility_insertScoutPerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, true)
	PerkSummary.Hodophobic(line, captain, perk, properties, true)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end

local ExtCapts_CaptainUtility_insertMaintenancePerkSummaries = CaptainUtility.insertMaintenancePerkSummaries
function CaptainUtility.insertMaintenancePerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertMaintenancePerkSummaries then
        ExtCapts_CaptainUtility_insertMaintenancePerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, true)
	PerkSummary.Hodophobic(line, captain, perk, properties, true)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end

local ExtCapts_CaptainUtility_insertExpeditionPerkSummaries = CaptainUtility.insertExpeditionPerkSummaries
function CaptainUtility.insertExpeditionPerkSummaries(line, captain, perk, properties)
	local isPerk=false
    if ExtCapts_CaptainUtility_insertExpeditionPerkSummaries then
        ExtCapts_CaptainUtility_insertExpeditionPerkSummaries(line, captain, perk, properties)
    end
	PerkSummary.Hodophile(line, captain, perk, properties, true)
	PerkSummary.Hodophobic(line, captain, perk, properties, true)
	PerkSummary.Friendly(line, captain, perk, properties, true)
	PerkSummary.Unfriendly(line, captain, perk, properties, true)
	PerkSummary.ShipBonus(line, captain, perk, properties)
end