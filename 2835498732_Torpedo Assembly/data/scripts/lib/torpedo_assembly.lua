-- /run Player():removeScript('lib/torpedo_assembly.lua')
-- /run Player():addScriptOnce('lib/torpedo_assembly.lua')

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace TorpedoAssembly
TorpedoAssembly = {}

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("utility")
include("callable")
include("weapontype")
include("tooltipmaker")
include("damagetypeutility")

local self = TorpedoAssembly
local TorpedoUtility = include("torpedoutility")
local TorpedoGenerator = include("torpedogenerator")
local KnowledgeUtility = include("buildingknowledgeutility")
local WHRef = TorpedoUtility.WarheadType
local BDRef = TorpedoUtility.BodyType
local Warheads = TorpedoUtility.Warheads
local Bodies = TorpedoUtility.Bodies

self.torpWaitQueueEXT = {} --{cIdx, tId, tName, tAmt, tRepeat}
self.torpProdQueueEXT = {} --{cIdx, cProdLine, cProdCap, tName, tWork, tDone, tStatus}
self.torpWaitQueueINT = {} --{cIdx, tId, tName, tRarity, tWarhead, tBody, tAmt, tCost, tRepeat}
self.torpProdQueueINT = {} --{cIdx, cProdLine, cProdCap, cTech, tName, tRarity, tWarhead, tBody, tCost, tWork, tDone, tStatus}
self.torpProdShipsINT = {} --{cIdx}

local boolStr = { 
	[true] = "Yes",
	[false] = "No",
}
local workColor = {
	[0] = ColorRGB(0.8, 0.8, 0.8),
	[1] = ColorRGB(0.0, 0.7, 0.0),
	[2] = ColorRGB(0.7, 0.0, 0.0),
	[3] = ColorRGB(0.8, 0.8, 0.8),
}
local workStatus = {
	[0] = "Idle",
	[1] = "Working",
	[2] = "Jammed",
	[3] = "Finished",
}
local tColor = {
	["Default"] = ColorRGB(0.8, 0.8, 0.8),
	["Positive"] = ColorRGB(0.0, 0.7, 0.0),
	["Negative"] = ColorRGB(0.7, 0.0, 0.0),
	["Inactive"] = ColorRGB(0.4, 0.4, 0.4),
}
local mColor = {
	["Iron"] = ColorRGB(1.0, 0.7, 0.5),
	["Titanium"] = ColorRGB(1.0, 1.0, 1.0),
	["Naonite"] = ColorRGB(0.3, 1.0, 0.3),
	["Trinium"] = ColorRGB(0.3, 0.6, 1.0),
	["Xanion"] = ColorRGB(1.0, 1.0, 0.3),
	["Ogonite"] = ColorRGB(1.0, 0.5, 0.2),
	["Avorion"] = ColorRGB(1.0, 0.15, 0.15),
}
local asmMatLines = {
	{name = "Iron",     lines = 1},
	{name = "Titanium", lines = 2},
	{name = "Naonite",  lines = 2},
	{name = "Trinium",  lines = 3},
	{name = "Xanion",   lines = 3},
	{name = "Ogonite",  lines = 4},
	{name = "Avorion",  lines = 5},
}
local prodCostBodies = {
	{type = BDRef.Orca,       eff = 30,  fe = 60, ti = 0,  na = 0,  tr = 0,  xa = 0,  og = 0,  av = 0},
	{type = BDRef.Hammerhead, eff = 45,  fe = 30, ti = 60, na = 0,  tr = 0,  xa = 0,  og = 0,  av = 0},
	{type = BDRef.Stingray,   eff = 60,  fe = 60, ti = 30, na = 30, tr = 0,  xa = 0,  og = 0,  av = 0},
	{type = BDRef.Ocelot,     eff = 50,  fe = 10, ti = 70, na = 20, tr = 0,  xa = 0,  og = 0,  av = 0},
	{type = BDRef.Lynx,       eff = 70,  fe = 10, ti = 70, na = 20, tr = 40, xa = 0,  og = 0,  av = 0},
	{type = BDRef.Panther,    eff = 90,  fe = 20, ti = 60, na = 30, tr = 70, xa = 0,  og = 0,  av = 0},
	{type = BDRef.Osprey,     eff = 80,  fe = 20, ti = 50, na = 20, tr = 30, xa = 40, og = 0,  av = 0},
	{type = BDRef.Eagle,      eff = 100, fe = 20, ti = 60, na = 10, tr = 30, xa = 20, og = 50, av = 0},
	{type = BDRef.Hawk,       eff = 120, fe = 10, ti = 60, na = 20, tr = 60, xa = 20, og = 30, av = 40},
}
local prodCostWarheads = {
	{type = WHRef.Nuclear,    eff = 20,  fe = 40, ti = 0,  na = 0,  tr = 0,  xa = 0,  og = 0,  av = 0},
	{type = WHRef.Neutron,    eff = 35,  fe = 30, ti = 40, na = 0,  tr = 0,  xa = 0,  og = 0,  av = 0},
	{type = WHRef.Fusion,     eff = 35,  fe = 20, ti = 50, na = 0,  tr = 0,  xa = 0,  og = 0,  av = 0},
	{type = WHRef.Kinetic,    eff = 50,  fe = 20, ti = 35, na = 45, tr = 0,  xa = 0,  og = 0,  av = 0},
	{type = WHRef.Plasma,     eff = 70,  fe = 30, ti = 40, na = 20, tr = 50, xa = 0,  og = 0,  av = 0},
	{type = WHRef.Ion,        eff = 80,  fe = 40, ti = 20, na = 60, tr = 40, xa = 0,  og = 0,  av = 0},
	{type = WHRef.Tandem,     eff = 120, fe = 20, ti = 40, na = 50, tr = 50, xa = 80, og = 0,  av = 0},
	{type = WHRef.EMP,        eff = 120, fe = 80, ti = 20, na = 40, tr = 20, xa = 30, og = 50, av = 0},
	{type = WHRef.Sabot,      eff = 150, fe = 20, ti = 70, na = 20, tr = 60, xa = 40, og = 90, av = 0},
	{type = WHRef.AntiMatter, eff = 200, fe = 10, ti = 60, na = 60, tr = 70, xa = 60, og = 60, av = 80},
}

local debugPrint = true
local filePath = "moddata/torpedo_assembly_designs.txt"
local storedDesigns = {}
local diskPermissions = true
local timerLast = 0
local timerDelta = 0
local countLogic = 60
local limitLogic = 60
local countSync = 900
local limitSync = 900
local countData = 60
local limitData = 60
local countUI = 15
local limitUI = 15
local shipPlan = nil
local blocksAssembly = 0
local blocksTorpStorage = 0
local shipProdCapacity = 0
local shipProdLines = 0
local shipLauncher = nil
local playerResource = nil
local launchersData = {
	storageFree = 0,
	storageNum = 0,
	storageMax = 0,
	torpNum = {},
	torpMax = {},
}

local player = nil
local entity = nil
local tabTorpAsm = nil
local listTorpBody = nil
local listTorpWarhead = nil
local listTorpRarity = nil
local listTorpDesigns = nil
local torpIndexRarity = nil
local torpIndexWarhead = nil
local torpIndexBody = nil
local btnDesignerProto = nil
local btnDesignerSave = nil
local btnDesignerReset = nil
local btnDesignerDelete = nil
local btnDesignerReload = nil
local btnAssemblerAdd = nil
local btnAssemblerRemove = nil
local btnAssemblerStop = nil
local btnAssemblerRepeat = nil
local torpDesign = nil
local torpShafts = {tShaft = {}}
local torpFactorySlot = {}
local torpFactory = {}
local torpStats = {}
local torpCost = {}

function TorpedoAssembly.initialize()
	if onClient() and timerLast == 0 then timerLast = Client().unpausedRuntime end
	if onServer() and timerLast == 0 then timerLast = Server().unpausedRuntime end
	if onClient() then
		player = Player()
		if player then TorpedoAssembly.fetchCoreData() end
		player:registerCallback("onShipChanged", "onShipChanged")
		tabTorpAsm = ShipWindow():createTab("Torpedo Assembly"%_t, "data/textures/icons/torp-assembly.png", "Torpedo Assembly"%_t)
		local secTorpAsmCore = UIVerticalLister(Rect(tabTorpAsm.size), 10, 0)
		local secTorpAsmMain = UIVerticalMultiSplitter(secTorpAsmCore.rect, 10, 0, 1)
		local secTorpAsmConf = UIHorizontalMultiSplitter(secTorpAsmMain:partition(0), 10, 0, 2)
		local secTorpAsmData = UIHorizontalMultiSplitter(secTorpAsmMain:partition(1), 10, 0, 1)
		local wndTorpAsmDesigner = Rect(0, 0, 350, 150)
		local wndTorpAsmBlueprints = TorpedoAssembly.customRectBL(wndTorpAsmDesigner, 350, 395)
		local wndTorpAsmLaunchShaft = TorpedoAssembly.customRectBL(wndTorpAsmBlueprints, 350, 165)
		local wndTorpAsmCraftStats = TorpedoAssembly.customRectTR(wndTorpAsmDesigner, 620, 170)
		local wndTorpAsmCraftManager = TorpedoAssembly.customRectBL(wndTorpAsmCraftStats, 620, 550)
		TorpedoAssembly.initTorpDesigner(tabTorpAsm, wndTorpAsmDesigner)
		TorpedoAssembly.initTorpBlueprints(tabTorpAsm, wndTorpAsmBlueprints)
		TorpedoAssembly.initTorpLaunchShaft(tabTorpAsm, wndTorpAsmLaunchShaft)
		TorpedoAssembly.initTorpCraftStats(tabTorpAsm, wndTorpAsmCraftStats)
		TorpedoAssembly.initTorpCraftManager(tabTorpAsm, wndTorpAsmCraftManager)
	end
end

function TorpedoAssembly.update()
	if onClient() and timerLast == 0 then timerLast = Client().unpausedRuntime end
	if onServer() and timerLast == 0 then timerLast = Server().unpausedRuntime end
	if onClient() then
		if tabTorpAsm and tabTorpAsm.isActiveTab then
			countUI = countUI + 1
			countData = countData + 1
			if countData >= limitData then
				TorpedoAssembly.fetchCoreData()
				TorpedoAssembly.fetchPlayerData()
				TorpedoAssembly.fetchFactoryData()
				TorpedoAssembly.fetchLaunchersData()
				countData = 0
			end
			if countUI >= limitUI then
				TorpedoAssembly.updateTorpedoShafts()
				TorpedoAssembly.updateTorpedoFactory()
				TorpedoAssembly.updateTorpLineButtons()
				TorpedoAssembly.updateTorpedoProdQueue()
				TorpedoAssembly.updateProdDeleteButton()
				local hasRequiredBlocks = blocksAssembly > 0 and blocksTorpStorage > 0
				if shipPlan and hasRequiredBlocks then
					TorpedoAssembly.updateDesignerButtons(true)
					if not torpDesign then 
						btnDesignerSave.active = false
						btnAssemblerAdd.active = false
						btnAssemblerRepeat.active = false
					end
				else TorpedoAssembly.updateDesignerButtons(false) end
				countUI = 0
			end
		end
	end
	if onServer() then
		countSync = countSync + 1
		countLogic = countLogic + 1
		if countLogic >= limitLogic then
			TorpedoAssembly.processFactoryLogic()
			countLogic = 0
		end
		if countSync >= limitSync then
			TorpedoAssembly.commandRefreshShipList()
			TorpedoAssembly.commandRefreshProdPower()
			countSync = 0
		end
	end
end

function TorpedoAssembly.secure()
	print("Torpedo Assembly: Saving Server-Side Data.")
	print("torpWaitQueueEXT <- "..#self.torpWaitQueueEXT)
	print("torpProdQueueEXT <- "..#self.torpProdQueueEXT)
	print("torpWaitQueueINT <- "..#self.torpWaitQueueINT)
	print("torpProdQueueINT <- "..#self.torpProdQueueINT)
	print("torpProdShipsINT <- "..#self.torpProdShipsINT)
	return {
		dWaitQueueEXT = self.torpWaitQueueEXT,
		dProdQueueEXT = self.torpProdQueueEXT,
		dWaitQueueINT = self.torpWaitQueueINT,
		dProdQueueINT = self.torpProdQueueINT,
		dProdShipsINT = self.torpProdShipsINT
	}
end

function TorpedoAssembly.restore(data)
	if data then
		print("Torpedo Assembly: Loading Server-Side Data.")
		print("torpWaitQueueEXT -> "..#data.dWaitQueueEXT)
		print("torpProdQueueEXT -> "..#data.dProdQueueEXT)
		print("torpWaitQueueINT -> "..#data.dWaitQueueINT)
		print("torpProdQueueINT -> "..#data.dProdQueueINT)
		print("torpProdShipsINT -> "..#data.dProdShipsINT)
		self.torpWaitQueueEXT = data.dWaitQueueEXT or {}
		self.torpProdQueueEXT = data.dProdQueueEXT or {}
		self.torpWaitQueueINT = data.dWaitQueueINT or {}
		self.torpProdQueueINT = data.dProdQueueINT or {}
		self.torpProdShipsINT = data.dProdShipsINT or {}
	end
end

function TorpedoAssembly.onShipChanged(playerIndex, craftId, previousId)
	if onClient() then
		countData = 0
		TorpedoAssembly.fetchCoreData()
		TorpedoAssembly.fetchPlayerData()
		TorpedoAssembly.fetchFactoryData()
		TorpedoAssembly.fetchLaunchersData()
		TorpedoAssembly.updateTorpedoWaitQueue()
		TorpedoAssembly.updateTorpedoProdQueue()
		TorpedoAssembly.updateAvailableConfigs()
		if torpIndexRarity and torpIndexWarhead and torpIndexBody then
			invokeServerFunction("commandGenerateDesign", torpIndexRarity, torpIndexWarhead, torpIndexBody)
		end
	end
end

function TorpedoAssembly.onMaxBuildableMaterialChanged(material)
	if onClient() then TorpedoAssembly.updateAvailableConfigs() end
end

function TorpedoAssembly.initTorpDesigner(tab, section)
	TorpedoAssembly.customFrame(tab, section)
	TorpedoAssembly.customLabel(tab, section, "НАСТРОЙКИ СБОРКИ ТОРПЕДЫ")
	TorpedoAssembly.customText(tab, section, 16, 27, 125, 23, "Корпус торпеды", 13)
	TorpedoAssembly.customText(tab, section, 16, 53, 125, 23, "Боевая часть торпеды", 13)
	TorpedoAssembly.customText(tab, section, 16, 79, 125, 23, "Редкость торпеды", 13)
	listTorpBody = TorpedoAssembly.customDropdown(tab, section, 155, 26, 180, 23)
	listTorpWarhead = TorpedoAssembly.customDropdown(tab, section, 155, 52, 180, 23)
	listTorpRarity = TorpedoAssembly.customDropdown(tab, section, 155, 78, 180, 23)
	btnDesignerProto = TorpedoAssembly.customButton(tab, section, 16, 110, 110, 25, "СОЗДАТЬ", "actionValidateDesign")
	btnDesignerSave = TorpedoAssembly.customButton(tab, section, 136, 110, 80, 25, "СОХРАНИТЬ", "actionSaveDesign")
	btnDesignerReset = TorpedoAssembly.customButton(tab, section, 226, 110, 110, 25, "СБРОСИТЬ", "actionResetDesign")
	btnDesignerProto.tooltip = "Генерирует проект торпеды с использованием выбранных параметров. Будет отключена, если на вашем корабле отсутствуют блоки сборки или хранения торпед."%_t
	btnDesignerSave.tooltip = "Сохраняет текущий проект торпеды на диск. Будет отключена, если нет сгенерированного проекта торпеды или если на вашем корабле отсутствуют блоки сборки или хранения торпед."%_t
	btnDesignerReset.tooltip = "Сбрасывает проект торпеды и всю статистику, отображаемую в интерфейсе. Будет отключена, если на вашем корабле отсутствуют блоки сборки или хранения торпед."%_t
	TorpedoAssembly.updateAvailableConfigs()
end
function TorpedoAssembly.initTorpBlueprints(tab, section)
	TorpedoAssembly.checkDiskPermissions()
	TorpedoAssembly.customFrame(tab, section)
	TorpedoAssembly.customLabel(tab, section, "СОХРАНЕННЫЕ ПРОЕКТЫ ТОРПЕД")
	listTorpDesigns = TorpedoAssembly.customListBox(tab, section, 16, 26, 319, 317)
	btnDesignerDelete = TorpedoAssembly.customButton(tab, section, 60, 356, 110, 25, "УДАЛИТЬ", "actionDeleteDesign")
	btnDesignerReload = TorpedoAssembly.customButton(tab, section, 180, 356, 110, 25, "ПЕРЕЗАГРУЗИТЬ", "actionReloadDesigns", true)
	btnDesignerDelete.tooltip = "Удаляет выбранный сохраненный проект. Будет отключена, если у вас больше нет сохраненных проектов."%_t
	btnDesignerReload.tooltip = "Перезагружает сохраненные проекты с диска. Подходит, если вы добавляете их вручную во время игры."%_t
	listTorpDesigns.onSelectFunction = "actionLoadSelected"
end

function TorpedoAssembly.initTorpLaunchShaft(tab, section)
	TorpedoAssembly.customFrame(tab, section)
	TorpedoAssembly.customLabel(tab, section, "ОБЗОР ВМЕСТИМОСТИ ТОРПЕДНЫХ ШАХТ")
	torpShafts.tShaft[1] = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customText(tab, section, 15, 23, 75, 20, "Шахта #01:", 13).localRect, 75, 20, "", 13, true, -1)
	torpShafts.tShaft[2] = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customText(tab, section, 15, 45, 75, 20, "Шахта #02:", 13).localRect, 75, 20, "", 13, true, -1)
	torpShafts.tShaft[3] = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customText(tab, section, 15, 67, 75, 20, "Шахта #03:", 13).localRect, 75, 20, "", 13, true, -1)
	torpShafts.tShaft[4] = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customText(tab, section, 15, 89, 75, 20, "Шахта #04:", 13).localRect, 75, 20, "", 13, true, -1)
	torpShafts.tShaft[5] = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customText(tab, section, 15, 111, 75, 20, "Шахта #05:", 13).localRect, 75, 20, "", 13, true, -1)
	torpShafts.tShaft[6] = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextSt(tab, torpShafts.tShaft[1].localRect, 15, 0, 75, 20, "Шахта #06:", 13).localRect, 75, 20, "", 13, true, -1)
	torpShafts.tShaft[7] = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextSt(tab, torpShafts.tShaft[2].localRect, 15, 0, 75, 20, "Шахта #07:", 13).localRect, 75, 20, "", 13, true, -1)
	torpShafts.tShaft[8] = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextSt(tab, torpShafts.tShaft[3].localRect, 15, 0, 75, 20, "Шахта #08:", 13).localRect, 75, 20, "", 13, true, -1)
	torpShafts.tShaft[9] = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextSt(tab, torpShafts.tShaft[4].localRect, 15, 0, 75, 20, "Шахта #09:", 13).localRect, 75, 20, "", 13, true, -1)
	torpShafts.tShaft[10] = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextSt(tab, torpShafts.tShaft[5].localRect, 15, 0, 75, 20, "Шахта #10:", 13).localRect, 75, 20, "", 13, true, -1)
	torpShafts.tStorage = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customText(tab, section, 15, 133, 120, 20, "Хранилище торпед:", 13).localRect, 195, 20, "", 13, true, -1)
end

function TorpedoAssembly.initTorpCraftStats(tab, section)
	TorpedoAssembly.customFrame(tab, section)
	TorpedoAssembly.customLabel(tab, section, "ХАРАКТЕРИСТИКИ СБОРКИ ТОРПЕД")
	torpStats.tName = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customText(tab, section, 15, 24, 50, 20, "Название:", 12).localRect, 300, 20, "", 12, true)
	torpStats.tRarity = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customText(tab, section, 15, 46, 105, 20, "Редкость/Класс:", 12).localRect, 80, 20, "", 12, true)
	torpStats.tDamageType = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customText(tab, section, 15, 68, 105, 20, "Тип урона:", 12).localRect, 80, 20, "", 12, true)
	torpStats.tDamageHull = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customText(tab, section, 15, 90, 105, 20, "Урон по корпусу:", 12).localRect, 80, 20, "", 12, true)
	torpStats.tDamageShield = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customText(tab, section, 15, 112, 105, 20, "Урон по щитам:", 12).localRect, 80, 20, "", 12, true)
	torpStats.tVelFactor = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customText(tab, section, 15, 134, 105, 20, "Фактор скорости:", 12).localRect, 80, 20, "", 12, true)
	torpStats.tSize = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tName.localRect, 20, 0, 40, 20, "Размер:", 12).localRect, 40, 20, "", 12, true)
	torpStats.tTech = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tSize.localRect, 20, 0, 75, 20, "Уровень тех.:", 12).localRect, 40, 20, "", 12, true)
	torpStats.tDurability = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tRarity.localRect, 20, 0, 105, 20, "Прочность:", 12).localRect, 75, 20, "", 12, true)
	torpStats.tAcceleration = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tDamageType.localRect, 20, 0, 105, 20, "Ускорение:", 12).localRect, 75, 20, "", 12, true)
	torpStats.tTurnSpeed = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tDamageHull.localRect, 20, 0, 105, 20, "Маневренность:", 12).localRect, 75, 20, "", 12, true)
	torpStats.tMaxVelocity = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tDamageShield.localRect, 20, 0, 105, 20, "Макс. скорость:", 12).localRect, 75, 20, "", 12, true)
	torpStats.tMaxRange = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tVelFactor.localRect, 20, 0, 105, 20, "Макс. дальность:", 12).localRect, 75, 20, "", 12, true)
	torpStats.tPenetrator = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tDurability.localRect, 20, 0, 140, 20, "Пробивает щиты:", 12).localRect, 40, 20, "", 12, true)
	torpStats.tDeactivator = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tAcceleration.localRect, 20, 0, 140, 20, "Деактивирует щиты:", 12).localRect, 40, 20, "", 12, true)
	torpStats.tDamageCombo = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tTurnSpeed.localRect, 20, 0, 140, 20, "Урон по щитам/корпусу:", 12).localRect, 40, 20, "", 12, true)
	torpStats.tEnergyDrain = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tMaxVelocity.localRect, 20, 0, 140, 20, "Поглощает энергию:", 12).localRect, 40, 20, "", 12, true)
	torpStats.tEnergyUse = TorpedoAssembly.customTextRt(tab, TorpedoAssembly.customTextSt(tab, torpStats.tMaxRange.localRect, 20, 0, 105, 20, "Расход энергии:", 12).localRect, 75, 20, "", 12, true)
	TorpedoAssembly.commandLoadTorpDesigns()
	TorpedoAssembly.resetTorpedoStats()
end

function TorpedoAssembly.initTorpCraftManager(tab, section)
	TorpedoAssembly.customFrame(tab, section)
	TorpedoAssembly.customLabel(tab, section, "УПРАВЛЕНИЕ СБОРКОЙ ТОРПЕД")
	btnAssemblerAdd = TorpedoAssembly.customButton(tab, section, 206, 26, 110, 25, "ДОБАВИТЬ", "actionProdAdd", false)
	btnAssemblerRemove = TorpedoAssembly.customButton(tab, section, 206, 62, 110, 25, "УДАЛИТЬ", "actionProdRemove", false)
	btnAssemblerStop = TorpedoAssembly.customButton(tab, section, 206, 98, 110, 25, "СТОП", "actionProdStop", false)
	btnAssemblerRepeat = TorpedoAssembly.customButton(tab, section, 206, 134, 110, 25, "ПОВТОРИТЬ", "actionProdRepeat", false)
	btnAssemblerAdd.tooltip = "Добавляет выбранное количество торпед в очередь производства. Будет отключена, если нет сгенерированного проекта торпеды или если на вашем корабле отсутствуют блоки сборки или хранилища торпед."%_t
	btnAssemblerRemove.tooltip = "Удаляет выбранный запрос на производство торпед из очереди. Будет отключена, если в очереди ничего нет."%_t
	btnAssemblerStop.tooltip = "Полностью останавливает все производство, очищает очередь производства и возвращает материалы для всех торпед в процессе. Будет отключена, если ничего не производится."%_t
	btnAssemblerRepeat.tooltip = "Автоматически продолжает производить выбранный проект торпеды. Будет отключена, если нет сгенерированного проекта торпеды или если на вашем корабле отсутствуют блоки сборки или хранилища торпед."%_t
	torpFactory.pProdCap = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customText(tab, section, 15, 25, 125, 20, "Скорость производства:", 13).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pProdLines = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customText(tab, section, 15, 47, 125, 20, "Линии производства:", 13).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pProdEff = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customText(tab, section, 15, 69, 125, 20, "Требуемые усилия:", 13).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pProdTime = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customText(tab, section, 15, 91, 125, 20, "Время производства:", 13).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pOrderAmount = TorpedoAssembly.customSlider(tab, section, 16, 113, 178, 20, "", "")
	torpFactory.pOrderAmount.tooltip = "Количество спроектированных торпед для постановки в очередь на производство. Ограничения зависят от доступных материалов. До 100 торпед на очередь. Торпеды, которым не хватает места в хранилище, остановят очередь производства, если их не хранить или не вернуть."%_t
	torpFactory.pCostFe = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextClr(tab, section, 16, 147, 85, 20, "Стоимость железа:", 13, mColor.Iron).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pCostTi = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextClr(tab, section, 16, 169, 85, 20, "Стоимость титана:", 13, mColor.Titanium).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pCostTr = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextClr(tab, section, 16, 191, 85, 20, "Стоимость триния:", 13, mColor.Trinium).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pCostOg = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextClr(tab, section, 16, 213, 85, 20, "Стоимость огонита:", 13, mColor.Ogonite).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pCostNa = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextClr(tab, section, 176, 169, 85, 20, "Стоимость наонита:", 13, mColor.Naonite).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pCostXa = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextClr(tab, section, 176, 191, 85, 20, "Стоимость ксаниона:", 13, mColor.Xanion).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pCostAv = TorpedoAssembly.customTextRc(tab, TorpedoAssembly.customTextClr(tab, section, 176, 213, 85, 20, "Стоимость авориона:", 13, mColor.Avorion).localRect, 50, 20, "", 13, true, -1)
	torpFactory.pProdQueue = TorpedoAssembly.customListBox(tab, section, 331, 26, 274, 509)
	torpFactorySlot[1] = TorpedoAssembly.customQueueEntry(tab, section, 16, 246, "actionProdRefund1")
	torpFactorySlot[2] = TorpedoAssembly.customQueueEntry(tab, section, 16, 306, "actionProdRefund2")
	torpFactorySlot[3] = TorpedoAssembly.customQueueEntry(tab, section, 16, 366, "actionProdRefund3")
	torpFactorySlot[4] = TorpedoAssembly.customQueueEntry(tab, section, 16, 426, "actionProdRefund4")
	torpFactorySlot[5] = TorpedoAssembly.customQueueEntry(tab, section, 16, 486, "actionProdRefund5")
	torpFactory.pProdQueue.onSelectFunction = "actionQueueSelect"
	TorpedoAssembly.resetFactoryStats()
	TorpedoAssembly.fetchFactoryData()
	TorpedoAssembly.updateTorpedoFactory()
	TorpedoAssembly.updateProductionData()
	TorpedoAssembly.updateTorpedoWaitQueue()
	TorpedoAssembly.updateTorpedoProdQueue()
end

function TorpedoAssembly.processFactoryLogic()
	local somethingHasChanged = false
	local changeStore, mustClean = TorpedoAssembly.processStoreLogic()
	local changeQueue = TorpedoAssembly.processQueueLogic()
	local changeClean = TorpedoAssembly.processCleanLogic()
	TorpedoAssembly.processWorkLogic()
	somethingHasChanged = changeStore or changeQueue or changeClean or mustClean
    if onServer() and somethingHasChanged then
		if mustClean then TorpedoAssembly.commandCleanShipList() end
		self.torpProdQueueEXT = TorpedoAssembly.reloadExtProdTable(self.torpProdQueueINT)
		self.torpWaitQueueEXT = TorpedoAssembly.reloadExtWaitTable(self.torpWaitQueueINT)
		invokeClientFunction(Player(callingPlayer), "commandLoadClientData", self.torpWaitQueueEXT, self.torpProdQueueEXT)
	end
end

function TorpedoAssembly.processCleanLogic()
	local somethingHasChanged = false
	if #self.torpWaitQueueINT > 0 then
		for pQueue = 1, #self.torpWaitQueueINT do
			if self.torpWaitQueueINT[pQueue] and self.torpWaitQueueINT[pQueue].tAmt <= 0 then
				--TorpedoAssembly.dPrint("processCleanLogic() -> Cleaning Void Entry #"..pQueue)
				table.remove(self.torpWaitQueueINT, pQueue)
				somethingHasChanged = true
			end
		end
	end
	return somethingHasChanged
end
function TorpedoAssembly.processStoreLogic()
	local somethingHasChanged = false
	local emergencyCleanNeeded = false
	if #self.torpProdQueueINT > 0 then
		for pLine = 1, #self.torpProdQueueINT do
			if self.torpProdQueueINT[pLine].tStatus == 2 or 
				self.torpProdQueueINT[pLine].tDone >= self.torpProdQueueINT[pLine].tWork then
				local newTorp = TorpedoAssembly.commandGetTorpDesign(self.torpProdQueueINT[pLine].tRarity, 
					self.torpProdQueueINT[pLine].tWarhead, 
					self.torpProdQueueINT[pLine].tBody, 
					self.torpProdQueueINT[pLine].cTech)
				local newStatus = TorpedoAssembly.commandSafeSendToStorage(newTorp, self.torpProdQueueINT[pLine].cIdx)
				if newStatus == 4 then 
					self.torpProdQueueINT[pLine].tStatus = 2
					emergencyCleanNeeded = true
				else self.torpProdQueueINT[pLine].tStatus = newStatus end
				--TorpedoAssembly.dPrint("processStoreLogic() -> Deposit Status for Line #"..pLine..": "..newStatus)
				somethingHasChanged = true
			end
		end
	end
	return somethingHasChanged, emergencyCleanNeeded
end

function TorpedoAssembly.processQueueLogic()
	local somethingHasChanged = false
	if #self.torpProdQueueINT > 0 then
		for pLine = 1, #self.torpProdQueueINT do
			if self.torpProdQueueINT[pLine].tStatus == 3 or
				self.torpProdQueueINT[pLine].tStatus == 0 then
				local foundNewEntry = false
				if #self.torpWaitQueueINT > 0 then
					for pQueue = 1, #self.torpWaitQueueINT do
						if self.torpProdQueueINT[pLine].cIdx == self.torpWaitQueueINT[pQueue].cIdx then
							if self.torpWaitQueueINT[pQueue].tAmt > 0 then
								if self.torpWaitQueueINT[pQueue].tRepeat then
									local repeatAmount = TorpedoAssembly.checkResources({Player(callingPlayer):getResources()}, self.torpWaitQueueINT[pQueue].tCost)
									if repeatAmount > 0 then
										--TorpedoAssembly.dPrint("processQueueLogic() -> Found repeating Entry for Line #"..pLine.." from Queue #"..pQueue)
										TorpedoAssembly.commandWithdrawCost(self.torpWaitQueueINT[pQueue].tCost, 1)
										self.torpProdQueueINT[pLine].tName = self.torpWaitQueueINT[pQueue].tName
										self.torpProdQueueINT[pLine].tRarity = self.torpWaitQueueINT[pQueue].tRarity
										self.torpProdQueueINT[pLine].tWarhead = self.torpWaitQueueINT[pQueue].tWarhead
										self.torpProdQueueINT[pLine].tBody = self.torpWaitQueueINT[pQueue].tBody
										self.torpProdQueueINT[pLine].tCost = self.torpWaitQueueINT[pQueue].tCost
										self.torpProdQueueINT[pLine].tWork = self.torpProdQueueINT[pLine].tCost[0]
										self.torpProdQueueINT[pLine].tDone = 0
										self.torpProdQueueINT[pLine].tStatus = 1
										somethingHasChanged = true
										foundNewEntry = true
										break
									end
								else 
									--TorpedoAssembly.dPrint("processQueueLogic() -> Found new Entry for Line #"..pLine.." from Queue #"..pQueue)
									self.torpWaitQueueINT[pQueue].tAmt = self.torpWaitQueueINT[pQueue].tAmt - 1
									self.torpProdQueueINT[pLine].tName = self.torpWaitQueueINT[pQueue].tName
									self.torpProdQueueINT[pLine].tRarity = self.torpWaitQueueINT[pQueue].tRarity
									self.torpProdQueueINT[pLine].tWarhead = self.torpWaitQueueINT[pQueue].tWarhead
									self.torpProdQueueINT[pLine].tBody = self.torpWaitQueueINT[pQueue].tBody
									self.torpProdQueueINT[pLine].tCost = self.torpWaitQueueINT[pQueue].tCost
									self.torpProdQueueINT[pLine].tWork = self.torpProdQueueINT[pLine].tCost[0]
									self.torpProdQueueINT[pLine].tDone = 0
									self.torpProdQueueINT[pLine].tStatus = 1
									somethingHasChanged = true
									foundNewEntry = true
									break
								end
							end
						end
					end
				end
				if not foundNewEntry then
					--TorpedoAssembly.dPrint("processQueueLogic() -> No Entries. Idling Line #"..pLine)
					self.torpProdQueueINT[pLine].tName = "N/A"
					self.torpProdQueueINT[pLine].tRarity = -1
					self.torpProdQueueINT[pLine].tWarhead = -1
					self.torpProdQueueINT[pLine].tBody = -1
					self.torpProdQueueINT[pLine].tCost = {}
					self.torpProdQueueINT[pLine].tWork = 1
					self.torpProdQueueINT[pLine].tDone = 0
					self.torpProdQueueINT[pLine].tStatus = 0
					somethingHasChanged = true
				end
			end
		end
	end
	return somethingHasChanged
end

function TorpedoAssembly.processWorkLogic()
	timerDelta = Server().unpausedRuntime - timerLast
	timerLast = Server().unpausedRuntime
	if #self.torpProdQueueINT > 0 then
		for pLine = 1, #self.torpProdQueueINT do
			if self.torpProdQueueINT[pLine].tStatus == 1 and 
				self.torpProdQueueINT[pLine].tDone < self.torpProdQueueINT[pLine].tWork then
				self.torpProdQueueINT[pLine].tDone = self.torpProdQueueINT[pLine].tDone + self.torpProdQueueINT[pLine].cProdCap * timerDelta
				if self.torpProdQueueINT[pLine].tDone > self.torpProdQueueINT[pLine].tWork then
					self.torpProdQueueINT[pLine].tDone = self.torpProdQueueINT[pLine].tWork
				end
				--TorpedoAssembly.dPrint("processWorkLogic() -> Active Line#"..pLine.." Found. Work Status: "..self.torpProdQueueINT[pLine].tDone.."/"..self.torpProdQueueINT[pLine].tWork)
			end
		end
	end
end

function TorpedoAssembly.fetchCoreData()
	player = Player()
	if player then entity = Entity(player.craftIndex) end
	if entity then shipPlan = Plan(entity) end
	if shipPlan then shipLauncher = TorpedoLauncher(entity) end
end

function TorpedoAssembly.fetchFactoryData()
	if valid(entity) and shipPlan then
		shipProdLines = 0
		blocksAssembly = shipPlan:getNumBlocks(BlockType.Assembly)
		blocksTorpStorage = shipPlan:getNumBlocks(BlockType.TorpedoStorage)
		shipProdCapacity = shipPlan:getStats().productionCapacity
		local tempBlocks = shipPlan:getBlocksByType(BlockType.Assembly)
		for _, blockIndex in pairs(tempBlocks) do
			local tempBlock = shipPlan:getBlock(blockIndex)
			if tempBlock then
				shipProdLines = asmMatLines[tempBlock.material.value + 1].lines
				break
			end
		end
	end
end

function TorpedoAssembly.fetchProdLines(refShipPlan)
	local refProdLines, refProdCapacity = 0, 0
	if refShipPlan then
		refProdLines = refShipPlan:getStats().productionCapacity
		local tempBlocks = refShipPlan:getBlocksByType(BlockType.Assembly)
		for _, blockIndex in pairs(tempBlocks) do
			local tempBlock = refShipPlan:getBlock(blockIndex)
			if tempBlock then
				refProdCapacity = asmMatLines[tempBlock.material.value + 1].lines
				break
			end
		end
	end
	return refProdCapacity, refProdLines
end

function TorpedoAssembly.fetchLaunchersData()
	if shipLauncher then
		local torpBlocks = {}
		local foundShafts = {}
		local shipShafts = {shipLauncher:getShafts()}
		if shipPlan then
			local torpBlocksNormal = shipPlan:getBlocksByType(BlockType.TorpedoLauncher)
			local torpBlocksFront = shipPlan:getBlocksByType(BlockType.FrontTorpedoLauncher)
			for _, block in pairs(torpBlocksNormal) do torpBlocks[#torpBlocks + 1] = block end
			for _, block in pairs(torpBlocksFront) do torpBlocks[#torpBlocks + 1] = block end
		end
		for num, shaft in pairs(shipShafts) do foundShafts[num] = shaft end
		for sNum = 1, 10 do
			if foundShafts[sNum] and sNum <= #torpBlocks then
				launchersData.torpNum[sNum] = shipLauncher:getNumTorpedoes(foundShafts[sNum])
				launchersData.torpMax[sNum] = shipLauncher:getMaxTorpedoes(foundShafts[sNum])
			else
				launchersData.torpNum[sNum] = 0
				launchersData.torpMax[sNum] = 0
			end
		end
		launchersData.storageFree = shipLauncher.freeStorage
		launchersData.storageNum = shipLauncher.occupiedStorage
		launchersData.storageMax = shipLauncher.occupiedStorage + shipLauncher.freeStorage
	end
end

function TorpedoAssembly.fetchPlayerData()
	if player then
		playerResource = {player:getResources()}
		if player.infiniteResources then
			playerResource[1] = 1000000000
			playerResource[2] = 1000000000
			playerResource[3] = 1000000000
			playerResource[4] = 1000000000
			playerResource[5] = 1000000000
			playerResource[6] = 1000000000
			playerResource[7] = 1000000000
		end
	end
end

function TorpedoAssembly.checkDiskPermissions()
	if not onClient() then return end
	local fExist = io.open(filePath, "a")
	if not fExist then
		if pcall(io.open(filePath, "w")) == false then
			diskPermissions = false
			print("Warning! Torpedo Assembler is missing disk read/write permissions!")
			return
		end
		local fNew = io.output(io.open(filePath, "w"))
		fNew:close()
	end
end

function TorpedoAssembly.checkResources(pResource, tCost)
	if onServer() and Player(callingPlayer).infiniteResources then return 100 end
	local tAmount = 100
	for mType = 1, 7 do
		local pLimit = math.min(math.floor(pResource[mType] / tCost[mType]), 100)
		if pLimit < tAmount then tAmount = pLimit end
	end
	return tAmount
end

function TorpedoAssembly.checkKnowledge(idxRarity, idxWarhead, idxBody)
	local matPlayer = Player(callingPlayer)
	local matRarity, matWarhead, matBody = TorpedoAssembly.getMaterialFromIndex(idxRarity, idxWarhead, idxBody)
	local matRarityKnw = KnowledgeUtility.hasKnowledge(matPlayer, Material(matRarity))
	local matWarheadKnw = KnowledgeUtility.hasKnowledge(matPlayer, Material(matWarhead))
	local matBodyKnw = KnowledgeUtility.hasKnowledge(matPlayer, Material(matBody))
	local matKnowledge = matRarityKnw and matWarheadKnw and matBodyKnw
	return matKnowledge
end

function TorpedoAssembly.calculateTorpedoCost(idxRarity, idxWarhead, idxBody, tTech)
	local rarityVal = Rarity(idxRarity).value
	local warheadCost = prodCostWarheads[idxWarhead + 1]
	local bodyCost = prodCostBodies[idxBody + 1]
	local tBiasEff = lerp(tTech, 1, 52, 0, 200)
	local tBiasCost = lerp(tTech, 1, 52, 0, 300)
	local costEff = round((100 * warheadCost.eff * bodyCost.eff * (1 + rarityVal) * (1 + tBiasEff / 100)) / 60)
	local costFe = round((warheadCost.fe + bodyCost.fe) * (1 + rarityVal * 0.35) * (1 + tBiasCost / 100))
	local costTi = round((warheadCost.ti + bodyCost.ti) * (1 + rarityVal * 0.35) * (1 + tBiasCost / 100))
	local costNa = round((warheadCost.na + bodyCost.na) * (1 + rarityVal * 0.35) * (1 + tBiasCost / 100))
	local costTr = round((warheadCost.tr + bodyCost.tr) * (1 + rarityVal * 0.35) * (1 + tBiasCost / 100))
	local costXa = round((warheadCost.xa + bodyCost.xa) * (1 + rarityVal * 0.35) * (1 + tBiasCost / 100))
	local costOg = round((warheadCost.og + bodyCost.og) * (1 + rarityVal * 0.35) * (1 + tBiasCost / 100))
	local costAv = round((warheadCost.av + bodyCost.av) * (1 + rarityVal * 0.35) * (1 + tBiasCost / 100))
	return {[0] = costEff, [1] = costFe, [2] = costTi, [3] = costNa, [4] = costTr, [5] = costXa, [6] = costOg, [7] = costAv}
end

function TorpedoAssembly.updateDesignerButtons(bool)
	btnDesignerProto.active = bool
	btnDesignerSave.active = bool
	btnDesignerReset.active = bool
	btnAssemblerAdd.active = bool
	btnAssemblerRepeat.active = bool
end

function TorpedoAssembly.updateProdDeleteButton()
	local allowDelete = false
	allowDelete = allowDelete or (torpFactory.pProdQueue.rows > 0)
	for tSlot = 1, 5 do
		if allowDelete then break end
		allowDelete = allowDelete or (torpFactorySlot[tSlot].prodStatus.progress > 0)
	end
	btnAssemblerStop.active = allowDelete
end

function TorpedoAssembly.updateAvailableConfigs()
	if listTorpBody then
		listTorpBody:clear()
		listTorpBody:addEntry(Bodies[BDRef.Orca].name%_t, mColor.Iron)
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Titanium)) then listTorpBody:addEntry(Bodies[BDRef.Hammerhead].name%_t, mColor.Titanium) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Naonite)) then listTorpBody:addEntry(Bodies[BDRef.Stingray].name%_t, mColor.Naonite) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Naonite)) then listTorpBody:addEntry(Bodies[BDRef.Ocelot].name%_t, mColor.Naonite) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Trinium)) then listTorpBody:addEntry(Bodies[BDRef.Lynx].name%_t, mColor.Trinium) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Trinium)) then listTorpBody:addEntry(Bodies[BDRef.Panther].name%_t, mColor.Trinium) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Xanion)) then listTorpBody:addEntry(Bodies[BDRef.Osprey].name%_t, mColor.Xanion) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Ogonite)) then listTorpBody:addEntry(Bodies[BDRef.Eagle].name%_t, mColor.Ogonite) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Avorion)) then listTorpBody:addEntry(Bodies[BDRef.Hawk].name%_t, mColor.Avorion) end
	end
	if listTorpWarhead then
		listTorpWarhead:clear()
		listTorpWarhead:addEntry(Warheads[WHRef.Nuclear].name%_t, mColor.Iron)
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Titanium)) then listTorpWarhead:addEntry(Warheads[WHRef.Neutron].name%_t, mColor.Titanium) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Titanium)) then listTorpWarhead:addEntry(Warheads[WHRef.Fusion].name%_t, mColor.Titanium) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Naonite)) then listTorpWarhead:addEntry(Warheads[WHRef.Kinetic].name%_t, mColor.Naonite) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Trinium)) then listTorpWarhead:addEntry(Warheads[WHRef.Plasma].name%_t, mColor.Trinium) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Trinium)) then listTorpWarhead:addEntry(Warheads[WHRef.Ion].name%_t, mColor.Trinium) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Xanion)) then listTorpWarhead:addEntry(Warheads[WHRef.Tandem].name%_t, mColor.Xanion) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Ogonite)) then listTorpWarhead:addEntry(Warheads[WHRef.EMP].name%_t, mColor.Ogonite) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Ogonite)) then listTorpWarhead:addEntry(Warheads[WHRef.Sabot].name%_t, mColor.Ogonite) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Avorion)) then listTorpWarhead:addEntry(Warheads[WHRef.AntiMatter].name%_t, mColor.Avorion) end
	end
	if listTorpRarity then
		listTorpRarity:clear()
		listTorpRarity:addEntry(Rarity(RarityType.Common).name, TorpedoAssembly.getRarityColor(RarityType.Common))
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Naonite)) then listTorpRarity:addEntry(Rarity(RarityType.Uncommon).name, TorpedoAssembly.getRarityColor(RarityType.Uncommon)) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Trinium)) then listTorpRarity:addEntry(Rarity(RarityType.Rare).name, TorpedoAssembly.getRarityColor(RarityType.Rare)) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Xanion)) then listTorpRarity:addEntry(Rarity(RarityType.Exceptional).name, TorpedoAssembly.getRarityColor(RarityType.Exceptional)) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Ogonite)) then listTorpRarity:addEntry(Rarity(RarityType.Exotic).name, TorpedoAssembly.getRarityColor(RarityType.Exotic)) end
		if KnowledgeUtility.hasKnowledge(player, Material(MaterialType.Avorion)) then listTorpRarity:addEntry(Rarity(RarityType.Legendary).name, TorpedoAssembly.getRarityColor(RarityType.Legendary)) end
	end
end

function TorpedoAssembly.updateTorpedoStats()
	torpStats.tName.caption = torpDesign.name
	torpStats.tSize.caption = torpDesign.size
	torpStats.tTech.caption = torpDesign.tech
	torpStats.tRarity.caption = torpDesign.rarity.name
	torpStats.tRarity.color = TorpedoAssembly.getRarityColor(torpDesign.rarity.value)
	torpStats.tDamageType.caption = getDamageTypeName(torpDesign.damageType)
	torpStats.tDamageType.color = getDamageTypeColor(torpDesign.damageType)
	torpStats.tDamageHull.caption = string.format("%.1f", torpDesign.hullDamage)
	torpStats.tDamageShield.caption = string.format("%.1f", torpDesign.shieldDamage)
	torpStats.tAcceleration.caption = string.format("%.1f m/s²", torpDesign.acceleration * 10)
	torpStats.tVelFactor.caption = string.format("%.1f %%", torpDesign.damageVelocityFactor * 100)
	torpStats.tDurability.caption = string.format("%.1f", torpDesign.durability)
	torpStats.tTurnSpeed.caption = string.format("%.1f rad/s", torpDesign.turningSpeed)
	torpStats.tMaxVelocity.caption = string.format("%.0f m/s", torpDesign.maxVelocity * 10)
	torpStats.tMaxRange.caption = string.format("%.1f km", torpDesign.reach / 100)
	torpStats.tEnergyUse.caption = string.format("%.0f MW", torpDesign.storageEnergyDrain / 1000000)
	TorpedoAssembly.setYesNo(torpStats.tPenetrator, torpDesign.shieldPenetration)
	TorpedoAssembly.setYesNo(torpStats.tDeactivator, torpDesign.shieldDeactivation)
	TorpedoAssembly.setYesNo(torpStats.tDamageCombo, torpDesign.shieldAndHullDamage)
	TorpedoAssembly.setYesNo(torpStats.tEnergyDrain, torpDesign.energyDrain)
	torpCost = TorpedoAssembly.calculateTorpedoCost(torpIndexRarity, torpIndexWarhead, torpIndexBody, torpDesign.tech)
	if shipProdCapacity > 0 then torpFactory.pProdTime.caption = TorpedoAssembly.timerNum(torpCost[0] / shipProdCapacity)
	else torpFactory.pProdTime.caption = "-" end
	torpFactory.pProdEff.caption = TorpedoAssembly.shortNum(torpCost[0])
	torpFactory.pCostFe.caption = TorpedoAssembly.shortNum(torpCost[1])
	torpFactory.pCostTi.caption = TorpedoAssembly.shortNum(torpCost[2])
	torpFactory.pCostNa.caption = TorpedoAssembly.shortNum(torpCost[3])
	torpFactory.pCostTr.caption = TorpedoAssembly.shortNum(torpCost[4])
	torpFactory.pCostXa.caption = TorpedoAssembly.shortNum(torpCost[5])
	torpFactory.pCostOg.caption = TorpedoAssembly.shortNum(torpCost[6])
	torpFactory.pCostAv.caption = TorpedoAssembly.shortNum(torpCost[7])
end

function TorpedoAssembly.updateTorpedoShafts()
	if launchersData.storageNum and launchersData.storageMax then
		if launchersData.storageNum > 0 or launchersData.storageMax > 0 then
			torpShafts.tStorage.caption = TorpedoAssembly.deterNum(launchersData.storageNum).."/"..TorpedoAssembly.deterNum(launchersData.storageMax)
		else torpShafts.tStorage.caption = "-/-" end
	else torpShafts.tStorage.caption = "-/-" end
	for sNum = 1, 10 do
		if launchersData.torpNum and launchersData.torpMax and launchersData.torpNum[sNum] and launchersData.torpMax[sNum] then
			if launchersData.torpNum[sNum] > 0 or launchersData.torpMax[sNum] > 0 then
				torpShafts.tShaft[sNum].caption = TorpedoAssembly.deterNum(launchersData.torpNum[sNum]).."/"..TorpedoAssembly.deterNum(launchersData.torpMax[sNum])
			else torpShafts.tShaft[sNum].caption = "-/-" end
		else torpShafts.tShaft[sNum].caption = "-/-" end
	end
end

function TorpedoAssembly.updateTorpedoFactory()
	if shipProdCapacity > 0 then torpFactory.pProdCap.caption = TorpedoAssembly.roundNum(shipProdCapacity).."/s"
	else torpFactory.pProdCap.caption = "-/s" end
	if shipProdLines > 0 then 
		torpFactory.pProdLines.caption = string.format("%.0f", shipProdLines)
		for tSlot = 1, 5 do
			if tSlot <= shipProdLines then
				torpFactorySlot[tSlot].iconNum.color = tColor.Default
				torpFactorySlot[tSlot].iconNum.caption = tSlot
				torpFactorySlot[tSlot].iconNum.tooltip = "Idle"%_t
			else
				torpFactorySlot[tSlot].iconNum.color = tColor.Inactive
				torpFactorySlot[tSlot].iconNum.caption = "X"
				torpFactorySlot[tSlot].iconNum.tooltip = "Inactive"%_t
				torpFactorySlot[tSlot].prodStatus.progress = 0
				torpFactorySlot[tSlot].prodStatus.color = ColorRGB(0.9, 0.9, 0.9)
				torpFactorySlot[tSlot].torpName.caption = "N/A"
			end
		end
	else 
		torpFactory.pProdLines.caption = "?"
		for tSlot = 1, 5 do
			torpFactorySlot[tSlot].iconNum.color = tColor.Inactive
			torpFactorySlot[tSlot].iconNum.caption = "X"
			torpFactorySlot[tSlot].iconNum.tooltip = "Inactive"%_t
			torpFactorySlot[tSlot].prodStatus.progress = 0
			torpFactorySlot[tSlot].prodStatus.color = ColorRGB(0.9, 0.9, 0.9)
			torpFactorySlot[tSlot].torpName.caption = "N/A"
		end
	end
	if torpDesign then
		local maxNewTorps = TorpedoAssembly.checkResources(playerResource, torpCost)
		if maxNewTorps > 1 then
			torpFactory.pOrderAmount.segments = maxNewTorps - 1
			torpFactory.pOrderAmount.max = maxNewTorps
			torpFactory.pOrderAmount.min = 1
		elseif maxNewTorps == 1 then
			torpFactory.pOrderAmount.segments = 0
			torpFactory.pOrderAmount.max = 1
			torpFactory.pOrderAmount.min = 1
		else
			torpFactory.pOrderAmount.segments = 0
			torpFactory.pOrderAmount.max = 0
			torpFactory.pOrderAmount.min = 0
		end
	else
		torpFactory.pOrderAmount.segments = 0
		torpFactory.pOrderAmount.max = 0
		torpFactory.pOrderAmount.min = 0
	end
end

function TorpedoAssembly.updateTorpLineButtons()
	for tSlot = 1, 5 do
		if torpFactorySlot[tSlot] then
			if torpFactorySlot[tSlot].prodStatus.progress > 0 then
				torpFactorySlot[tSlot].refundBt.active = true
			else torpFactorySlot[tSlot].refundBt.active = false end
		end
	end
end

function TorpedoAssembly.updateTorpedoWaitQueue()
	torpFactory.pProdQueue:clear()
	if player and #self.torpWaitQueueEXT > 0 then
		for pQueue = 1, #self.torpWaitQueueEXT do
			if self.torpWaitQueueEXT[pQueue].cIdx == player.craftIndex.value then
				if self.torpWaitQueueEXT[pQueue].tRepeat then torpFactory.pProdQueue:addEntry("[R] "..self.torpWaitQueueEXT[pQueue].tName, self.torpWaitQueueEXT[pQueue].tId)
				elseif self.torpWaitQueueEXT[pQueue].tAmt == 1 then torpFactory.pProdQueue:addEntry(self.torpWaitQueueEXT[pQueue].tName, self.torpWaitQueueEXT[pQueue].tId)
				else torpFactory.pProdQueue:addEntry(self.torpWaitQueueEXT[pQueue].tAmt.."x "..self.torpWaitQueueEXT[pQueue].tName, self.torpWaitQueueEXT[pQueue].tId) end
			end
		end
	end
end

function TorpedoAssembly.updateTorpedoProdQueue()
	timerDelta = Client().unpausedRuntime - timerLast
	timerLast = Client().unpausedRuntime
	if player and #self.torpProdQueueEXT > 0 then
		for pLine = 1, #self.torpProdQueueEXT do
			if self.torpProdQueueEXT[pLine].tStatus == 1 and 
				self.torpProdQueueEXT[pLine].tDone < self.torpProdQueueEXT[pLine].tWork then
				self.torpProdQueueEXT[pLine].tDone = self.torpProdQueueEXT[pLine].tDone + self.torpProdQueueEXT[pLine].cProdCap * timerDelta
				if self.torpProdQueueEXT[pLine].tDone > self.torpProdQueueEXT[pLine].tWork then
					self.torpProdQueueEXT[pLine].tDone = self.torpProdQueueEXT[pLine].tWork
				end
			end
			if  self.torpProdQueueEXT[pLine].cIdx == player.craftIndex.value then
				torpFactorySlot[self.torpProdQueueEXT[pLine].cProdLine].iconNum.color = workColor[self.torpProdQueueEXT[pLine].tStatus]
				torpFactorySlot[self.torpProdQueueEXT[pLine].cProdLine].iconNum.tooltip = workStatus[self.torpProdQueueEXT[pLine].tStatus]
				torpFactorySlot[self.torpProdQueueEXT[pLine].cProdLine].torpName.caption = TorpedoAssembly.trimTrName(self.torpProdQueueEXT[pLine].tName)
				torpFactorySlot[self.torpProdQueueEXT[pLine].cProdLine].prodStatus.progress = self.torpProdQueueEXT[pLine].tDone / self.torpProdQueueEXT[pLine].tWork
				torpFactorySlot[self.torpProdQueueEXT[pLine].cProdLine].prodStatus.color = ColorHSV(torpFactorySlot[self.torpProdQueueEXT[pLine].cProdLine].prodStatus.progress * 120, 1.0, 0.8)
			end
		end
	end
end

function TorpedoAssembly.updateTorpedoDesigns()
	listTorpDesigns:clear()
	if #storedDesigns > 0 then
		btnDesignerDelete.active = true
		for dNum = 1, #storedDesigns do
			listTorpDesigns:addEntry(storedDesigns[dNum].name)
		end
	else btnDesignerDelete.active = false end
end

function TorpedoAssembly.updateProductionData()
	if onClient() then invokeServerFunction("commandSendClientData") end
end

function TorpedoAssembly.resetTorpedoStats()
	torpDesign = nil
	torpStats.tName.caption = "?"
	torpStats.tSize.caption = "0"
	torpStats.tTech.caption = "0"
	torpStats.tRarity.caption = "?"
	torpStats.tRarity.color = tColor.Default
	torpStats.tDamageType.caption = "?"
	torpStats.tDamageType.color = tColor.Default
	torpStats.tDamageHull.caption = "0"
	torpStats.tDamageShield.caption = "0"
	torpStats.tAcceleration.caption = "0 m/s²"
	torpStats.tVelFactor.caption = "0 %"
	torpStats.tDurability.caption = "0"
	torpStats.tTurnSpeed.caption = "0 rad/s"
	torpStats.tMaxVelocity.caption = "0 m/s"
	torpStats.tMaxRange.caption = "0 km"
	torpStats.tEnergyUse.caption = "0 MW"
	torpStats.tPenetrator.caption = "?"
	torpStats.tDeactivator.caption = "?"
	torpStats.tDamageCombo.caption = "?"
	torpStats.tEnergyDrain.caption = "?"
	torpStats.tPenetrator.color = tColor.Default
	torpStats.tDeactivator.color = tColor.Default
	torpStats.tDamageCombo.color = tColor.Default
	torpStats.tEnergyDrain.color = tColor.Default
end

function TorpedoAssembly.resetFactoryStats()
	torpDesign = nil
	torpFactory.pProdEff.caption = "?"
	torpFactory.pProdTime.caption = "?"
	torpFactory.pCostFe.caption = "-"
	torpFactory.pCostTi.caption = "-"
	torpFactory.pCostNa.caption = "-"
	torpFactory.pCostTr.caption = "-"
	torpFactory.pCostXa.caption = "-"
	torpFactory.pCostOg.caption = "-"
	torpFactory.pCostAv.caption = "-"
	torpFactory.pCostFe.color = mColor.Iron
	torpFactory.pCostTi.color = mColor.Titanium
	torpFactory.pCostNa.color = mColor.Naonite
	torpFactory.pCostTr.color = mColor.Trinium
	torpFactory.pCostXa.color = mColor.Xanion
	torpFactory.pCostOg.color = mColor.Ogonite
	torpFactory.pCostAv.color = mColor.Avorion
	torpFactory.pOrderAmount.sliderPosition = 0
	torpFactory.pOrderAmount.segments = 0
	torpFactory.pOrderAmount.max = 0
	torpFactory.pOrderAmount.min = 0
	for t = 1, 8 do torpCost[t - 1] = 1 end
end

function TorpedoAssembly.actionValidateDesign()
	if onClient() then
		torpIndexRarity = listTorpRarity.selectedIndex
		torpIndexWarhead = listTorpWarhead.selectedIndex
		torpIndexBody = listTorpBody.selectedIndex
		invokeServerFunction("commandGenerateDesign", torpIndexRarity, torpIndexWarhead, torpIndexBody)
		countUI = limitUI
	end
end
callable(TorpedoAssembly, "actionValidateDesign")

function TorpedoAssembly.actionResetDesign()
	TorpedoAssembly.resetTorpedoStats()
	TorpedoAssembly.resetFactoryStats()
end
callable(TorpedoAssembly, "actionResetDesign")

function TorpedoAssembly.actionSaveDesign()
	if not onClient() then return end
	if not torpDesign then return end
	if not diskPermissions then
		print("Warning! Torpedo Assembler is missing disk read/write permissions!")
		return
	end
	local dataEntry ='{["name"]="'..torpDesign.name..'"'
	dataEntry = dataEntry..',["rarityIndex"]='..torpIndexRarity
	dataEntry = dataEntry..',["warheadIndex"]='..torpIndexWarhead
	dataEntry = dataEntry..',["bodyIndex"]='..torpIndexBody
	dataEntry = dataEntry..'}\n'
	local fStream = io.input(io.open(filePath, "a"))
	fStream:write(dataEntry)
	fStream:close()
	TorpedoAssembly.commandLoadTorpDesigns()
end
callable(TorpedoAssembly, "actionSaveDesign")

function TorpedoAssembly.actionDeleteDesign()
	if not onClient() then return end
	if not diskPermissions then
		print("Warning! Torpedo Assembler is missing disk read/write permissions!")
		return
	end
	local tempStrStorage = {}
	local refLine = listTorpDesigns.selected + 1
	local fStream = io.output(io.open(filePath, "r"))
	for rLine in io.lines(filePath) do table.insert(tempStrStorage, rLine) end
	fStream:close()
	fStream = io.output(io.open(filePath, "w"))
	for sLine = 1, #tempStrStorage do
		if sLine ~= refLine then 
			fStream:write(tempStrStorage[sLine].."\n")
		end
	end
	fStream:close()
	TorpedoAssembly.commandLoadTorpDesigns()
end
callable(TorpedoAssembly, "actionDeleteDesign")

function TorpedoAssembly.actionReloadDesigns()
	TorpedoAssembly.commandLoadTorpDesigns()
end
callable(TorpedoAssembly, "actionReloadDesigns")

function TorpedoAssembly.actionLoadSelected()
	local refLine = listTorpDesigns.selected + 1
	if storedDesigns[refLine] then
		torpIndexRarity = storedDesigns[refLine].rarityIndex
		torpIndexWarhead = storedDesigns[refLine].warheadIndex
		torpIndexBody = storedDesigns[refLine].bodyIndex
		if onClient() then
			invokeServerFunction("commandGenerateDesign", torpIndexRarity, torpIndexWarhead, torpIndexBody)
		end
	end
end
callable(TorpedoAssembly, "actionLoadSelected")

function TorpedoAssembly.actionProdAdd()
	if onClient() and torpDesign and torpFactory.pOrderAmount.value > 0 then
		invokeServerFunction("commandAddToQueue", torpIndexRarity, torpIndexWarhead, torpIndexBody, player.craftIndex.value, torpFactory.pOrderAmount.value, false)
	end
end
callable(TorpedoAssembly, "actionProdAdd")

function TorpedoAssembly.actionProdRemove()
	if onClient() and torpFactory.pProdQueue.selectedValue then
		invokeServerFunction("commandRemoveFromQueue", torpFactory.pProdQueue.selectedValue)
	end
end
callable(TorpedoAssembly, "actionProdRemove")

function TorpedoAssembly.actionProdStop()
	if onClient() then
		invokeServerFunction("commandStopFactory", player.craftIndex.value)
	end
end
callable(TorpedoAssembly, "actionProdStop")

function TorpedoAssembly.actionProdRepeat()
	if onClient() and torpDesign and torpFactory.pOrderAmount.value > 0 then
		invokeServerFunction("commandAddToQueue", torpIndexRarity, torpIndexWarhead, torpIndexBody, player.craftIndex.value, 1, true)
	end
end
callable(TorpedoAssembly, "actionProdRepeat")

function TorpedoAssembly.actionQueueSelect()
	if torpFactory.pProdQueue.selectedValue then btnAssemblerRemove.active = true
	else btnAssemblerRemove.active = false end
end
callable(TorpedoAssembly, "actionQueueSelect")

function TorpedoAssembly.actionProdRefund1()
	if onClient() and torpFactorySlot[1].prodStatus.progress > 0 then
		torpFactorySlot[1].refundBt.active = false
		invokeServerFunction("commandRemoveFromLine", player.craftIndex.value, 1)
	end
end
callable(TorpedoAssembly, "actionProdRefund1")

function TorpedoAssembly.actionProdRefund2()
	if onClient() and torpFactorySlot[2].prodStatus.progress > 0 then
		torpFactorySlot[2].refundBt.active = false
		invokeServerFunction("commandRemoveFromLine", player.craftIndex.value, 2)
	end
end
callable(TorpedoAssembly, "actionProdRefund2")

function TorpedoAssembly.actionProdRefund3()
	if onClient() and torpFactorySlot[3].prodStatus.progress > 0 then
		torpFactorySlot[3].refundBt.active = false
		invokeServerFunction("commandRemoveFromLine", player.craftIndex.value, 3)
	end
end
callable(TorpedoAssembly, "actionProdRefund3")

function TorpedoAssembly.actionProdRefund4()
	if onClient() and torpFactorySlot[4].prodStatus.progress > 0 then
		torpFactorySlot[4].refundBt.active = false
		invokeServerFunction("commandRemoveFromLine", player.craftIndex.value, 4)
	end
end
callable(TorpedoAssembly, "actionProdRefund4")

function TorpedoAssembly.actionProdRefund5()
	if onClient() and torpFactorySlot[5].prodStatus.progress > 0 then
		torpFactorySlot[5].refundBt.active = false
		invokeServerFunction("commandRemoveFromLine", player.craftIndex.value, 5)
	end
end
callable(TorpedoAssembly, "actionProdRefund5")

function TorpedoAssembly.reloadExtProdTable(intProd)
	local extProd = {}
	if #intProd > 0 then
		for pLine = 1, #intProd do
			table.insert(extProd,{cIdx = intProd[pLine].cIdx, cProdLine = intProd[pLine].cProdLine,
			cProdCap = intProd[pLine].cProdCap, tName = intProd[pLine].tName, tWork = intProd[pLine].tWork,
			tDone = intProd[pLine].tDone, tStatus = intProd[pLine].tStatus})
		end
	end
	return extProd
end

function TorpedoAssembly.reloadExtWaitTable(intWait)
	local extWait = {}
	if #intWait > 0 then
		for pLine = 1, #intWait do
			table.insert(extWait,{cIdx = intWait[pLine].cIdx, tId = intWait[pLine].tId,
			tName = intWait[pLine].tName, tAmt = intWait[pLine].tAmt,
			tRepeat = intWait[pLine].tRepeat})
		end
	end
	return extWait
end

function TorpedoAssembly.commandStopFactory(craftIdx)
	local refreshExt = false
	if #self.torpWaitQueueINT > 0 then
		for pQueue = 1, #self.torpWaitQueueINT do
			if self.torpWaitQueueINT[pQueue] then
				if self.torpWaitQueueINT[pQueue].cIdx == craftIdx then
					if not self.torpWaitQueueINT[pQueue].tRepeat then TorpedoAssembly.commandRefundCost(self.torpWaitQueueINT[pQueue].tCost, self.torpWaitQueueINT[pQueue].tAmt) end
					table.remove(self.torpWaitQueueINT, pQueue)
					refreshExt = true
				end
			end
		end
	end
	if #self.torpProdQueueINT > 0 then
		for pLine = 1, #self.torpProdQueueINT do
			if self.torpProdQueueINT[pLine].cIdx == craftIdx then
				TorpedoAssembly.commandRefundCost(self.torpProdQueueINT[pLine].tCost, 1)
				self.torpProdQueueINT[pLine].tName = "N/A"
				self.torpProdQueueINT[pLine].tRarity = -1
				self.torpProdQueueINT[pLine].tWarhead = -1
				self.torpProdQueueINT[pLine].tBody = -1
				self.torpProdQueueINT[pLine].tCost = {}
				self.torpProdQueueINT[pLine].tWork = 1
				self.torpProdQueueINT[pLine].tDone = 0
				self.torpProdQueueINT[pLine].tStatus = 0
				refreshExt = true
			end
		end
	end
	if refreshExt and onServer() then 
		self.torpProdQueueEXT = TorpedoAssembly.reloadExtProdTable(self.torpProdQueueINT)
		self.torpWaitQueueEXT = TorpedoAssembly.reloadExtWaitTable(self.torpWaitQueueINT)
		invokeClientFunction(Player(callingPlayer), "commandPushProdData", self.torpProdQueueEXT)
		invokeClientFunction(Player(callingPlayer), "commandPushWaitData", self.torpWaitQueueEXT)
	end
end
callable(TorpedoAssembly, "commandStopFactory")

function TorpedoAssembly.commandRemoveFromLine(craftIdx, numLine)
	local refreshExt = false
	if #self.torpProdQueueINT > 0 then
		for pLine = 1, #self.torpProdQueueINT do
			if self.torpProdQueueINT[pLine].cIdx == craftIdx and
				self.torpProdQueueINT[pLine].cProdLine == numLine then
				TorpedoAssembly.commandRefundCost(self.torpProdQueueINT[pLine].tCost, 1)
				self.torpProdQueueINT[pLine].tName = "N/A"
				self.torpProdQueueINT[pLine].tRarity = -1
				self.torpProdQueueINT[pLine].tWarhead = -1
				self.torpProdQueueINT[pLine].tBody = -1
				self.torpProdQueueINT[pLine].tCost = {}
				self.torpProdQueueINT[pLine].tWork = 1
				self.torpProdQueueINT[pLine].tDone = 0
				self.torpProdQueueINT[pLine].tStatus = 0
				refreshExt = true
			end
		end
	end
	if refreshExt and onServer() then 
		self.torpProdQueueEXT = TorpedoAssembly.reloadExtProdTable(self.torpProdQueueINT)
		invokeClientFunction(Player(callingPlayer), "commandPushProdData", self.torpProdQueueEXT)
	end
end
callable(TorpedoAssembly, "commandRemoveFromLine")

function TorpedoAssembly.commandRemoveFromQueue(entryId)
	local refreshExt = false
	if #self.torpWaitQueueINT > 0 then
		for pQueue = 1, #self.torpWaitQueueINT do
			if self.torpWaitQueueINT[pQueue].tId == entryId then
				if not self.torpWaitQueueINT[pQueue].tRepeat then TorpedoAssembly.commandRefundCost(self.torpWaitQueueINT[pQueue].tCost, self.torpWaitQueueINT[pQueue].tAmt) end
				table.remove(self.torpWaitQueueINT, pQueue)
				refreshExt = true
				break
			end
		end
	end
	if refreshExt and onServer() then 
		self.torpWaitQueueEXT = TorpedoAssembly.reloadExtWaitTable(self.torpWaitQueueINT)
		invokeClientFunction(Player(callingPlayer), "commandPushWaitData", self.torpWaitQueueEXT)
	end
end
callable(TorpedoAssembly, "commandRemoveFromQueue")

function TorpedoAssembly.commandAddToQueue(rarityIdx, warheadIdx, bodyIdx, craftIdx, tAmount, setRepeat)
	if torpDesign then
		TorpedoAssembly.fetchPlayerData()
		newTorpId = TorpedoAssembly.genNewId()
		torpCost = TorpedoAssembly.calculateTorpedoCost(rarityIdx, warheadIdx, bodyIdx, torpDesign.tech)
		tAmount = math.min(TorpedoAssembly.checkResources(playerResource, torpCost), tAmount)
		local meetsReqs = TorpedoAssembly.checkKnowledge(rarityIdx, warheadIdx, bodyIdx)
		if meetsReqs and tAmount > 0 then
			if not setRepeat then TorpedoAssembly.commandWithdrawCost(torpCost, tAmount) end
			table.insert(self.torpWaitQueueINT,{cIdx = craftIdx, tId = newTorpId,
			tName = torpDesign.name, tRarity = rarityIdx, tWarhead = warheadIdx,
			tBody = bodyIdx, tAmt = tAmount, tCost = torpCost, tRepeat = setRepeat})
			if onServer() then
				self.torpWaitQueueEXT = TorpedoAssembly.reloadExtWaitTable(self.torpWaitQueueINT)
				invokeClientFunction(Player(callingPlayer), "commandPushWaitData", self.torpWaitQueueEXT)
			end
		end
	end
end
callable(TorpedoAssembly, "commandAddToQueue")

function TorpedoAssembly.commandPushWaitData(serverData)
	self.torpWaitQueueEXT = serverData
	TorpedoAssembly.updateTorpedoWaitQueue()
end
callable(TorpedoAssembly, "commandPushWaitData")

function TorpedoAssembly.commandPushProdData(serverData)
	self.torpProdQueueEXT = serverData
	TorpedoAssembly.updateTorpedoProdQueue()
end
callable(TorpedoAssembly, "commandPushProdData")

function TorpedoAssembly.commandSendClientData()
	if onServer() then
		self.torpProdQueueEXT = TorpedoAssembly.reloadExtProdTable(self.torpProdQueueINT)
		self.torpWaitQueueEXT = TorpedoAssembly.reloadExtWaitTable(self.torpWaitQueueINT)
		invokeClientFunction(Player(callingPlayer), "commandLoadClientData", self.torpWaitQueueEXT, self.torpProdQueueEXT)
	end
end
callable(TorpedoAssembly, "commandSendClientData")

function TorpedoAssembly.commandLoadClientData(waitQueue, prodQueue)
	self.torpWaitQueueEXT = waitQueue
	self.torpProdQueueEXT = prodQueue
	TorpedoAssembly.updateTorpedoWaitQueue()
	TorpedoAssembly.updateTorpedoProdQueue()
end
callable(TorpedoAssembly, "commandLoadClientData")

function TorpedoAssembly.commandWithdrawCost(tCost, tAmt)
	local refPlayer = Player(callingPlayer)
	if refPlayer and tAmt and tCost then
		if tCost[1] and tCost[2] and tCost[3] and tCost[4] and tCost[5] and tCost[6] and tCost[7] then
			refPlayer:pay("", 0, tCost[1] * tAmt, tCost[2] * tAmt, tCost[3] * tAmt,
			tCost[4] * tAmt, tCost[5] * tAmt, tCost[6] * tAmt, tCost[7] * tAmt)
		end
	end
end

function TorpedoAssembly.commandRefundCost(tCost, tAmt)
	local refPlayer = Player(callingPlayer)
	if refPlayer and tAmt and tCost then
		if tCost[1] and tCost[2] and tCost[3] and tCost[4] and tCost[5] and tCost[6] and tCost[7] then
			refPlayer:receive("", 0, tCost[1] * tAmt, tCost[2] * tAmt, tCost[3] * tAmt,
			tCost[4] * tAmt, tCost[5] * tAmt, tCost[6] * tAmt, tCost[7] * tAmt)
		end
	end
end

function TorpedoAssembly.commandSyncProdShips(entityIdx)
	local refEntity = Entity(entityIdx)
	if refEntity then
		local foundShip = false
		if #self.torpProdShipsINT > 0 then
			for iShip = 1, #self.torpProdShipsINT do
				if self.torpProdShipsINT[iShip].cIdx == refEntity.index.value then
					foundShip = true
					break
				end
			end
		elseif not foundShip then
			table.insert(self.torpProdShipsINT, {cIdx = refEntity.index.value})
		end
	end
end

function TorpedoAssembly.commandSyncProdPower(entityIdx, techLevel)
	local refEntity = Entity(entityIdx)
	local refShipPlan = Plan(refEntity)
	local refTech = techLevel or TorpedoAssembly.commandGetTechLevel(entityIdx)
	if refEntity and refShipPlan then
		local sProdLines, sProdCap = TorpedoAssembly.fetchProdLines(refShipPlan)
		if sProdLines > 0 then
			for pLine = 1, sProdLines do
				local foundLine = false
				if #self.torpProdQueueINT > 0 then
					for pEntry = 1, #self.torpProdQueueINT do
						if self.torpProdQueueINT[pEntry].cIdx == refEntity.index.value and 
							self.torpProdQueueINT[pEntry].cProdLine == pLine then
							self.torpProdQueueINT[pEntry].cProdCap = sProdCap
							self.torpProdQueueINT[pEntry].cTech = refTech
							foundLine = true
							break
						end
					end
				end
				if not foundLine then
					table.insert(self.torpProdQueueINT,{
					cIdx = refEntity.index.value, cProdLine = pLine, cProdCap = sProdCap,
					cTech = refTech, tName = "N/A", tRarity = -1, tWarhead = -1, tBody = -1,
					tCost = {}, tWork = 1, tDone = 0, tStatus = 0})
					table.insert(self.torpProdQueueEXT,{
					cIdx = refEntity.index.value, cProdLine = pLine, cProdCap = sProdCap,
					tName = "N/A", tWork = 1, tDone = 0, tStatus = 0})
				end
			end
		end
		if #self.torpProdQueueINT > 0 then
			for pDel = 1, #self.torpProdQueueINT do
				if self.torpProdQueueINT[pDel] then 
					if self.torpProdQueueINT[pDel].cIdx == refEntity.index.value and 
						self.torpProdQueueINT[pDel].cProdLine > sProdLines then
						table.remove(self.torpProdQueueINT, pDel)
					end
				end
			end
		end
	end
end

function TorpedoAssembly.commandRefreshProdPower()
	if #self.torpProdShipsINT > 0 then
		for iShip = 1, #self.torpProdShipsINT do
			if self.torpProdShipsINT[iShip] and self.torpProdShipsINT[iShip].cIdx then
				TorpedoAssembly.commandSyncProdPower(self.torpProdShipsINT[iShip].cIdx)
			end
		end
	end
end

function TorpedoAssembly.commandCleanShipList()
	local dataChanged = false
	if #self.torpProdShipsINT > 0 then
		for iShip = 1, #self.torpProdShipsINT do
			if self.torpProdShipsINT[iShip] and self.torpProdShipsINT[iShip].cIdx then
				local refShip = Entity(self.torpProdShipsINT[iShip].cIdx)
				if not refShip then
					for iQueue = 1, #self.torpWaitQueueINT do
						if self.torpWaitQueueINT[iQueue] and self.torpWaitQueueINT[iQueue].cIdx == self.torpProdShipsINT[iShip].cIdx then
							if not self.torpWaitQueueINT[iQueue].tRepeat then TorpedoAssembly.commandRefundCost(self.torpWaitQueueINT[iQueue].tCost, self.torpWaitQueueINT[iQueue].tAmt) end
							table.remove(self.torpWaitQueueINT, iQueue)
							dataChanged = true
						end
					end
					for iProd = 1, #self.torpProdQueueINT do
						if self.torpProdQueueINT[iProd] and self.torpProdQueueINT[iProd].cIdx == self.torpProdShipsINT[iShip].cIdx then
							TorpedoAssembly.commandRefundCost(self.torpProdQueueINT[iProd].tCost, 1)
							table.remove(self.torpProdQueueINT, iProd)
							dataChanged = true
						end
					end
					table.remove(self.torpProdShipsINT, iShip)
				end
			end
		end
	end
    return dataChanged
end

function TorpedoAssembly.commandRefreshShipList()
	local dataChanged = TorpedoAssembly.commandCleanShipList()
    if onServer() and dataChanged then
		self.torpProdQueueEXT = TorpedoAssembly.reloadExtProdTable(self.torpProdQueueINT)
		self.torpWaitQueueEXT = TorpedoAssembly.reloadExtWaitTable(self.torpWaitQueueINT)
		invokeClientFunction(Player(callingPlayer), "commandLoadClientData", self.torpWaitQueueEXT, self.torpProdQueueEXT)
	end
end

function TorpedoAssembly.commandGenerateDesign(rarityIdx, warheadIdx, bodyIdx)
	torpIndexRarity = rarityIdx
	torpIndexWarhead = warheadIdx
	torpIndexBody = bodyIdx
	player = Player(callingPlayer)
	TorpedoAssembly.commandSyncProdShips(player.craftIndex)
	TorpedoAssembly.commandSyncProdPower(player.craftIndex)
	shipTechLevel = TorpedoAssembly.commandGetTechLevel(player.craftIndex)
	local torpData = TorpedoAssembly.commandGetTorpDesign(torpIndexRarity, torpIndexWarhead, torpIndexBody, shipTechLevel)
	if onServer() then invokeClientFunction(Player(callingPlayer), "commandUpdateStatsData", torpData) end
	torpDesign = torpData
end
callable(TorpedoAssembly, "commandGenerateDesign")

function TorpedoAssembly.commandAddStoreTorpedo()
	player = Player(callingPlayer)
	if torpDesign and player then
		TorpedoAssembly.commandSafeSendToStorage(torpDesign, player.craftIndex.value)
	end
end
callable(TorpedoAssembly, "commandAddStoreTorpedo")

function TorpedoAssembly.commandGetTechLevel(entityIdx)
	local refTechLevel = 1
	local refEntity = Entity(entityIdx)
	local shipTurrets = {refEntity:getTurrets()}
	if shipTurrets and TorpedoAssembly.getTableSize(shipTurrets) > 0 then
		for _, turret in pairs(shipTurrets) do
			local weapon = Weapons(turret)
			if weapon.averageTech > refTechLevel then 
			refTechLevel = weapon.averageTech end
		end
	end
	return refTechLevel
end

function TorpedoAssembly.commandGetTorpDesign(tRarityIndex, tWarheadIndex, tBodyIndex, tTechLevel)
	local refDistFromTech = lerp(tTechLevel, 1, 52, 500, 0)
	local refPosFromDist = math.sqrt(math.pow(refDistFromTech, 2) / 2)
	local tRarity, tWarhead, tBody = TorpedoAssembly.getEntryFromIndex(tRarityIndex, tWarheadIndex, tBodyIndex)
	local tDesignData = TorpedoGenerator():generate(refPosFromDist, refPosFromDist, nil, Rarity(tRarity), Warheads[tWarhead].type, Bodies[tBody].type)
	tDesignData.name = "${speed}-Тип ${warhead} Торпеда "%_t % {speed = tDesignData.bodyClass%_t, warhead = tDesignData.warheadClass%_t} .. " " .. TorpedoAssembly.getMarkFromRarity(tDesignData.rarity.value)
	return tDesignData
end

function TorpedoAssembly.commandSafeSendToStorage(refTorpData, craftIndex)
	local targetRefShip = Entity(craftIndex)
	if not targetRefShip then return 4 end
	local targetShipLauncher = TorpedoLauncher(targetRefShip)
	if targetShipLauncher.freeStorage > refTorpData.size then
		targetShipLauncher:addTorpedo(refTorpData)
		return 3
	else return 2 end
end

function TorpedoAssembly.commandUpdateStatsData(torpData)
	torpDesign = torpData
	TorpedoAssembly.updateTorpedoStats()
end
callable(TorpedoAssembly, "commandUpdateStatsData")

function TorpedoAssembly.commandLoadTorpDesigns()
	if not onClient() then return end
	storedDesigns = {}
	if not diskPermissions then
		print("Warning! Torpedo Assembler is missing disk read/write permissions!")
		return
	end
	local fStream = io.output(io.open(filePath, "r"))
	for fLine in io.lines(filePath) do
		if string.len(fLine) > 20 and string.sub(fLine,1,10) == "{[\"name\"]=" then
			fLine = fLine:gsub('(".-"):(.-),','[%1]=%2,\n')
			local tData = loadstring("return "..fLine)()
			table.insert(storedDesigns, tData)
		end
	end
	fStream:close()
	TorpedoAssembly.updateTorpedoDesigns()
end

function TorpedoAssembly.getRarityColor(rarityIdx)
	local rarityColor = {
		[0] = RarityType.Common,
		[1] = RarityType.Uncommon,
		[2] = RarityType.Rare,
		[3] = RarityType.Exceptional,
		[4] = RarityType.Exotic,
		[5] = RarityType.Legendary}
	return Rarity(rarityColor[rarityIdx]).color
end

function TorpedoAssembly.getEntryFromIndex(rarityIdx, warheadIdx, bodyIdx)
	local rarityId = {
		[0] = RarityType.Common,
		[1] = RarityType.Uncommon,
		[2] = RarityType.Rare,
		[3] = RarityType.Exceptional,
		[4] = RarityType.Exotic,
		[5] = RarityType.Legendary}
	local warheadId = {
		[0] = WHRef.Nuclear,
		[1] = WHRef.Neutron,
		[2] = WHRef.Fusion,
		[3] = WHRef.Kinetic,
		[4] = WHRef.Plasma,
		[5] = WHRef.Ion,
		[6] = WHRef.Tandem,
		[7] = WHRef.EMP,
		[8] = WHRef.Sabot,
		[9] = WHRef.AntiMatter}
	local bodyId = {
		[0] = BDRef.Orca,
		[1] = BDRef.Hammerhead,
		[2] = BDRef.Stingray,
		[3] = BDRef.Ocelot,
		[4] = BDRef.Lynx,
		[5] = BDRef.Panther,
		[6] = BDRef.Osprey,
		[7] = BDRef.Eagle,
		[8] = BDRef.Hawk}
	return rarityId[rarityIdx], warheadId[warheadIdx], bodyId[bodyIdx]
end

function TorpedoAssembly.getMaterialFromIndex(rarityIdx, warheadIdx, bodyIdx)
	local rarityMat = {
		[0] = MaterialType.Iron,
		[1] = MaterialType.Naonite,
		[2] = MaterialType.Trinium,
		[3] = MaterialType.Xanion,
		[4] = MaterialType.Ogonite,
		[5] = MaterialType.Avorion}
	local warheadMat = {
		[0] = MaterialType.Iron,
		[1] = MaterialType.Titanium,
		[2] = MaterialType.Titanium,
		[3] = MaterialType.Naonite,
		[4] = MaterialType.Trinium,
		[5] = MaterialType.Trinium,
		[6] = MaterialType.Xanion,
		[7] = MaterialType.Ogonite,
		[8] = MaterialType.Ogonite,
		[9] = MaterialType.Avorion}
	local bodyMat = {
		[0] = MaterialType.Iron,
		[1] = MaterialType.Titanium,
		[2] = MaterialType.Naonite,
		[3] = MaterialType.Naonite,
		[4] = MaterialType.Trinium,
		[5] = MaterialType.Trinium,
		[6] = MaterialType.Xanion,
		[7] = MaterialType.Ogonite,
		[8] = MaterialType.Avorion}
	return rarityMat[rarityIdx], warheadMat[warheadIdx], bodyMat[bodyIdx]
end

function TorpedoAssembly.getMarkFromRarity(rarityVal)
	local rarityMark = {
		[0] = "Mk. I"%_t,
		[1] = "Mk. II"%_t,
		[2] = "Mk. III"%_t,
		[3] = "Mk. V"%_t,
		[4] = "Mk. VII"%_t,
		[5] = "Mk. X"%_t,
		[-1] = "Prototype"%_t
	}
	return rarityMark[rarityVal]
end

function TorpedoAssembly.customRectBL(section, width, height)
	return Rect(section.bottomLeft.x, section.bottomLeft.y + 10, section.bottomLeft.x + width, section.bottomLeft.y + 10 + height)
end

function TorpedoAssembly.customRectTR(section, width, height)
	return Rect(section.topRight.x + 10, section.topRight.y, section.topRight.x + 10 + width, section.topRight.y + height)
end

function TorpedoAssembly.customFrame(tab, section)
	local cFrame = {}
	cFrame.box = tab:createFrame(section)
	cFrame.top = tab:createLine(section.topLeft, section.topRight)
	cFrame.left = tab:createLine(section.topLeft, section.bottomLeft)
	cFrame.right = tab:createLine(section.topRight, section.bottomRight)
	cFrame.bottom = tab:createLine(section.bottomLeft, vec2(section.bottomRight.x + 1, section.bottomRight.y))
	return cFrame
end

function TorpedoAssembly.customSubFrame(tab, section, x, y, w, h)
	local cSubFrame = {}
	local rSubFrame = Rect(section.topLeft.x + x, section.topLeft.y + y, section.topLeft.x + x + w, section.topLeft.y + y + h)
	cSubFrame.box = tab:createFrame(rSubFrame)
	cSubFrame.top = tab:createLine(rSubFrame.topLeft, rSubFrame.topRight)
	cSubFrame.left = tab:createLine(rSubFrame.topLeft, rSubFrame.bottomLeft)
	cSubFrame.right = tab:createLine(rSubFrame.topRight, rSubFrame.bottomRight)
	cSubFrame.bottom = tab:createLine(rSubFrame.bottomLeft, vec2(rSubFrame.bottomRight.x + 1, rSubFrame.bottomRight.y))
	return cSubFrame
end

function TorpedoAssembly.customLabel(tab, section, text)
	local cLabel
	local rLabel = Rect(section.topLeft.x, section.topLeft.y, section.topRight.x, section.topRight.y + 26)
	cLabel = tab:createLabel(rLabel, text%_t, 14)
	cLabel.color = tColor.Default
	cLabel:setCenterAligned()
	return cLabel
end

function TorpedoAssembly.customText(tab, section, x, y, w, h, text, font)
	local cText
	local rText = Rect(section.topLeft.x + x, section.topLeft.y + y, section.topLeft.x + x + w, section.topLeft.y + y + h)
	cText = tab:createLabel(rText, text%_t, font)
	cText.color = tColor.Default
	cText:setLeftAligned()
	return cText
end

function TorpedoAssembly.customTextClr(tab, section, x, y, w, h, text, font, color)
	local cText
	local rText = Rect(section.topLeft.x + x, section.topLeft.y + y, section.topLeft.x + x + w, section.topLeft.y + y + h)
	cText = tab:createLabel(rText, text%_t, font)
	cText.color = color
	cText:setLeftAligned()
	return cText
end

function TorpedoAssembly.customTextBlr(tab, section, x, y, w, h, text, font, background, offset)
	local cTextBlr
	if not offset then offset = 0 end
	if not background then background = false end
	local rTextBlr = Rect(section.topLeft.x + x, section.topLeft.y + y, section.topLeft.x + x + w, section.topLeft.y + y + h)
	if background then TorpedoAssembly.customTextBg(tab, rTextBlr, offset) end
	cTextBlr = tab:createLabel(rTextBlr, text%_t, font)
	cTextBlr.color = tColor.Default
	cTextBlr:setLeftAligned()
	return cTextBlr
end

function TorpedoAssembly.customTextRt(tab, section, w, h, text, font, background, offset)
	local cTextRt
	if not offset then offset = 0 end
	if not background then background = false end
	local rTextRt = Rect(section.topRight.x, section.topRight.y, section.topRight.x + w, section.topRight.y + h)
	if background then TorpedoAssembly.customTextBg(tab, rTextRt, offset) end
	cTextRt = tab:createLabel(rTextRt, text%_t, font)
	cTextRt.color = tColor.Default
	cTextRt:setLeftAligned()
	return cTextRt
end

function TorpedoAssembly.customTextRc(tab, section, w, h, text, font, background, offset)
	local cTextRc
	if not offset then offset = 0 end
	if not background then background = false end
	local rTextRc = Rect(section.topRight.x, section.topRight.y, section.topRight.x + w, section.topRight.y + h)
	if background then TorpedoAssembly.customTextBg(tab, rTextRc, offset) end
	cTextRc = tab:createLabel(rTextRc, text%_t, font)
	cTextRc.color = tColor.Default
	cTextRc:setCenterAligned()
	return cTextRc
end

function TorpedoAssembly.customTextSt(tab, section, x, y, w, h, text, font, background, offset)
	local cTextSt
	if not offset then offset = 0 end
	if not background then background = false end
	local rTextSt = Rect(section.topRight.x + x, section.topRight.y + y, section.topRight.x + x + w, section.topRight.y + y + h)
	if background then TorpedoAssembly.customTextBg(tab, rTextSt, offset) end
	cTextSt = tab:createLabel(rTextSt, text%_t, font)
	cTextSt.color = tColor.Default
	cTextSt:setLeftAligned()
	return cTextSt
end

function TorpedoAssembly.customTextDt(tab, section, x, y, w, h, text, font, background, offset)
	local cTextDt
	if not offset then offset = 0 end
	if not background then background = false end
	local rTextDt = Rect(section.bottomLeft.x + x, section.bottomLeft.y + y, section.bottomLeft.x + x + w, section.bottomLeft.y + y + h)
	if background then TorpedoAssembly.customTextBg(tab, rTextDt, offset) end
	cTextDt = tab:createLabel(rTextDt, text%_t, font)
	cTextDt.color = tColor.Default
	cTextDt:setLeftAligned()
	return cTextDt
end

function TorpedoAssembly.customTextBg(tab, section, offset)
	local cTextBg
	if not offset then offset = 0 end
	local rTextBg = Rect(section.topLeft.x - 5, section.topLeft.y + 2 + offset, section.bottomRight.x + 5, section.bottomRight.y - 1 + offset)
	cTextBg = tab:createFrame(rTextBg)
	return cTextBg
end

function TorpedoAssembly.customDropdown(tab, section, x, y, w, h)
	local cDropdown
	local rDropdown = Rect(section.topLeft.x + x, section.topLeft.y + y, section.topLeft.x + x + w, section.topLeft.y + y + h)
	cDropdown = tab:createComboBox(rDropdown, "")
	return cDropdown
end

function TorpedoAssembly.customButton(tab, section, x, y, w, h, text, command, state)
	local cButton
	if not state then state = false end
	local rButton = Rect(section.topLeft.x + x, section.topLeft.y + y, section.topLeft.x + x + w, section.topLeft.y + y + h)
	cButton = tab:createButton(rButton, text%_t, command)
	cButton.active = state
	return cButton
end

function TorpedoAssembly.customListBox(tab, section, x, y, w, h)
	local cListBox
	local rListBox = Rect(section.topLeft.x + x, section.topLeft.y + y, section.topLeft.x + x + w, section.topLeft.y + y + h)
	cListBox = tab:createListBox(rListBox)
	return cListBox
end

function TorpedoAssembly.customSlider(tab, section, x, y, w, h, text, command)
	local cSlider
	local rSlider = Rect(section.topLeft.x + x, section.topLeft.y + y, section.topLeft.x + x + w, section.topLeft.y + y + h)
	cSlider = tab:createSlider(rSlider, 0, 0, 0, text, command)
	return cSlider
end

function TorpedoAssembly.customQueueEntry(tab, section, x, y, command)
	local cQueueEntry = {}
	local rQueueIcon = Rect(section.topLeft.x + x, section.topLeft.y + y, section.topLeft.x + x + 48, section.topLeft.y + y + 48)
	local rQueueText = Rect(section.topLeft.x + x + 1, section.topLeft.y + y - 2, section.topLeft.x + x + 48 + 1, section.topLeft.y + y + 48 - 2)
	local rQueueProd = Rect(section.topLeft.x + x + 55, section.topLeft.y + y + 24, section.topLeft.x + x + 269, section.topLeft.y + y + 47)
	local rQueuePrbg = Rect(section.topLeft.x + x + 55, section.topLeft.y + y + 24, section.topLeft.x + x + 269, section.topLeft.y + y + 46)
	local rQueueDump = Rect(section.topLeft.x + x + 277, section.topLeft.y + y + 26, section.topLeft.x + x + 298, section.topLeft.y + y + 44)
	local rQueueBtbg = Rect(section.topLeft.x + x + 275, section.topLeft.y + y + 24, section.topLeft.x + x + 299, section.topLeft.y + y + 46)
	cQueueEntry.iconBg = TorpedoAssembly.customFrame(tab, rQueueIcon)
	cQueueEntry.iconNum = tab:createLabel(rQueueText, "", 46)
	cQueueEntry.iconNum.color = tColor.Inactive
	cQueueEntry.iconNum:setCenterAligned()
	cQueueEntry.iconNum.bold = true
	cQueueEntry.torpName = TorpedoAssembly.customTextBlr(tab, rQueueIcon, 60, 1, 235, 20, "N/A", 13, true, -1)
	cQueueEntry.prodStatusBg = TorpedoAssembly.customFrame(tab, rQueuePrbg)
	cQueueEntry.prodStatus = tab:createProgressBar(rQueueProd, ColorRGB(0.9, 0.9, 0.9))
	cQueueEntry.prodStatus.progress = 0.0
	cQueueEntry.refundBtBg = TorpedoAssembly.customFrame(tab, rQueueBtbg)
	cQueueEntry.refundBt = tab:createButton(rQueueDump, "", command)
	cQueueEntry.refundBt.icon = "data/textures/icons/trash-can.png"
	cQueueEntry.refundBt.tooltip = "Возврат торпеды с этой линии производства."%_t
	cQueueEntry.refundBt.active = false
	return cQueueEntry
end

function TorpedoAssembly.setYesNo(textEntry, bool)
	if bool then
		textEntry.color = tColor.Positive
		textEntry.caption = "Yes"%_t
	else
		textEntry.color = tColor.Negative
		textEntry.caption = "No"%_t
	end
end

function TorpedoAssembly.roundNum(number)
	if not number then return "-" end
	if number >= 10000000 then return string.format("%.0fM", number / 1000000)
	elseif number >= 1000000 then return string.format("%.1fM", number / 1000000)
	elseif number >= 10000 then return string.format("%.0fK", number / 1000)
	elseif number >= 1000 then return string.format("%.1fK", number / 1000)
	elseif number >= 100 then return string.format("%.0f", number)
	elseif number >= 10 then return string.format("%.1f", number)
	else return string.format("%.2f", number) end
end

function TorpedoAssembly.shortNum(number)
	if not number then return "-" end
	if number >= 10000000 then return string.format("%.0fM", number / 1000000)
	elseif number >= 1000000 then return string.format("%.1fM", number / 1000000)
	elseif number >= 10000 then return string.format("%.0fK", number / 1000)
	elseif number >= 1000 then return string.format("%.1fK", number / 1000)
	else return string.format("%.0f", number) end
end

function TorpedoAssembly.deterNum(number)
	if not number then return "-" end
	if number - math.floor(number) > 0 then return string.format("%.1f", number)
	else return string.format("%.0f", number) end
end

function TorpedoAssembly.timerNum(number)
	local rHours = math.floor(number / 3600)
	local rMinutes = math.floor((number - 3600 * rHours) / 60)
	local rSeconds = math.fmod(number, 60)
	if rHours > 0 then return string.format("%d:%02d:%02d", rHours, rMinutes, rSeconds)
	elseif rMinutes > 0 then return string.format("%d:%02d", rMinutes, rSeconds)
	else return string.format("%ds", rSeconds) end
end

function TorpedoAssembly.trimTrName(text)
	return text:gsub("Торпеда ", ""):gsub("-Тип ", " / ")
end

function TorpedoAssembly.getTableSize(t)
    local count = 0
    for _, __ in pairs(t) do count = count + 1 end
    return count
end

function TorpedoAssembly.genNewId()
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 9)))
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

function TorpedoAssembly.printSoMuch(text)
	print(text)
	print(text)
	print(text)
	print(text)
	print(text)
end

function TorpedoAssembly.dPrint(text)
	if debugPrint then print(text) end
end