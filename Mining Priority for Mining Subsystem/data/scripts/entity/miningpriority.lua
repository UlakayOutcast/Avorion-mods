package.path = package.path .. ";data/scripts/lib/?.lua"
include('callable')
include("UIDragList")
local CaptainUtility = include ("captainutility")


-- namespace MiningPriority

MiningPriority = {}

local function getMaxMineableMaterial()
    local ship = Entity()
    local captain = ship:getCaptain()
    local maxMaterialLevel = 0
	local maxRange = 0

    -- Проверяем наличие капитана-шахтёра
    if captain and captain:hasClass(CaptainUtility.ClassType.Miner) then
        maxMaterialLevel = captain.tier + captain.level
		maxRange = maxRange + captain.tier * 300 + captain.level * 150
	else
		maxRange = maxRange + captain.tier * 150 + captain.level * 87.5
		captain = false
    end
	-- Проверяем наличие подсистемы
	local system = ShipSystem(ship)
	if system then
		for upgrade, _ in pairs(system:getUpgrades()) do
			if string.find(upgrade.script, "miningsystem") or string.find(upgrade.script, "miningcarrierhybrid") then
				-- Получаем материал из системы напрямую
				local ret, materialLevel, range = ship:invokeFunction(upgrade.script, "getBonuses", upgrade.seed, upgrade.rarity)
				if ret == 0 and materialLevel then
					if maxMaterialLevel == nil or materialLevel > maxMaterialLevel then
						maxMaterialLevel = materialLevel
					end
					maxRange = maxRange + range
				end
			end
		end
	end
    return maxMaterialLevel, range
end

function MiningPriority.updateUI()
    if not dragList or not ignoreOrderCheckbox then return end

    -- Получаем текущий максимальный уровень материала
    local maxMaterialLevel = getMaxMineableMaterial()

    -- Обновляем чекбокс "Игнорировать порядок"
    if maxMaterialLevel > 0 then
        ignoreOrderCheckbox.checked = false
        ignoreOrderCheckbox.active = true
    else
        ignoreOrderCheckbox.checked = true
        ignoreOrderCheckbox.active = false
    end

    -- Обновляем элементы dragList
    for _, element in pairs(dragList.elements) do
        if element.material then
            if element.material.value > maxMaterialLevel then
                -- element.label.text = element.material.name .. " (НЕДОСТУПНО)"
                element.label.color = ColorRGB(0.5, 0.5, 0.5)
                element.check_box.checked = false
                element.check_box.active = false
            else
                -- element.label.text = element.material.name
                element.label.color = element.material.color  -- Возвращаем исходный цвет
                element.check_box.checked = true
                element.check_box.active = true
            end
        end
    end
end

function MiningPriority.interactionPossible(playerIndex, option)
	callingPlayer = Player().index
	if not checkEntityInteractionPermissions(Entity(), AlliancePrivilege.FlyCrafts) then
		return false
	end
	
	local maxMaterialLevel = getMaxMineableMaterial()
    if maxMaterialLevel > 0 then return true else return false end
end


function MiningPriority.getMiningList() -- invoked via mineAI
	return MiningPriority.material_list, MiningPriority.ignoreOrder
end

function MiningPriority.getMaterialList()
    MiningPriority.material_list = {}
    local temp = {}

    -- Собираем только включённые материалы
    for k, v in pairs(dragList.elements) do
        if v.check_box and v.check_box.checked and v.material then
            table.insert(temp, v.material)
        end
    end

    -- Копируем в final список
    for k, v in pairs(temp) do
        table.insert(MiningPriority.material_list, v)
    end
	-- print("Material list for AI:")
	-- for k, v in pairs(MiningPriority.material_list) do
		-- print(k, v and v.name or "nil")
	-- end

    return MiningPriority.material_list
end



function MiningPriority.secure()
    local sec_mat_list = {}
    for k, v in pairs(MiningPriority.material_list or {}) do
        if v then -- Проверяем, что материал существует
            table.insert(sec_mat_list, v.value)
        end
    end
    return {
        ignoreOrder = MiningPriority.ignoreOrder,
        dragList = MiningPriority.dragList,
        material_list = sec_mat_list
    }
end


function MiningPriority.restore(data)
    MiningPriority.ignoreOrder = data.ignoreOrder
    MiningPriority.dragList = data.dragList
    MiningPriority.material_list = {}
    for k, v in pairs(data.material_list or {}) do
        if v then -- Проверяем, что значение существует
            table.insert(MiningPriority.material_list, Material(v))
        end
    end
    if not MiningPriority.dragList or not MiningPriority.material_list then
        MiningPriority.fetch()
    end
end


function MiningPriority.fetch(data) -- from client to server
	if onServer() then
		if data then
			MiningPriority.ignoreOrder = data.ignoreOrder
			MiningPriority.dragList = data.dragList
			MiningPriority.material_list = data.material_list
		else
			broadcastInvokeClientFunction('fetch')
		end
	else
		if onClient() then
			if ignoreOrderCheckbox and dragList then
				invokeServerFunction('fetch', {
					ignoreOrder = ignoreOrderCheckbox.checked,
					dragList = dragList:secure(),
					material_list = MiningPriority.getMaterialList() -- Используем getMaterialList, который фильтрует отключённые материалы
				})
			end
		end
	end
end
callable(MiningPriority, 'fetch')

function MiningPriority.sync(data) -- from server to client
	if onClient() then
		local i = 0 -- stupid workaround be cause 'if data then' was passing on a empty table
		for _,_ in pairs(data or {}) do
			i = i + 1
		end
		if i>0 then
			dragList.check_box_initialized = false
			ignoreOrderCheckbox.checked = data.ignoreOrder
			dragList.check_box_initialized = true
			dragList:restore(data.dragList)
		else
			invokeServerFunction('sync')
		end
	else
		if not MiningPriority.dragList then
			MiningPriority.fetch()
		end
		invokeClientFunction(Player(callingPlayer), 'sync', {ignoreOrder = MiningPriority.ignoreOrder, dragList = MiningPriority.dragList})
	end
end
callable(MiningPriority, 'sync')

function MiningPriority.onShowWindow()
    -- MiningPriority.updateUI()
	MiningPriority.sync()
end

function MiningPriority.onCloseWindow()
	if dragList.check_box_initialized then
		MiningPriority.fetch() -- stripping all the checkbox params out
	end
end

function MiningPriority.initUI()
	local res = getResolution()
	local size = vec2(300, 230 + 30)

	local menu = ScriptUI()
	local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	menu:registerWindow(window, "Приаритет добычи")

	window.caption = "Приаритет добычи"
	window.showCloseButton = true
	window.moveable = true

    local ignoreOrderNode, dragNode = Node(size):rows({30, 1}, 10)
	dragNode = window:createContainer(dragNode.rect)

	dragList = UIDragList(MiningPriority, window, dragNode)

	ignoreOrderCheckbox = window:createCheckBox(ignoreOrderNode:pad(10, 10, 10, 0).rect, 'Игнорировать порядок', 'onCloseWindow')
	ignoreOrderCheckbox.tooltip = 'Установите флажок, чтобы использовать поведение, максимально приближенное к стандартному, игнорируя порядок в списке и проверяя только, включен ли ресурс.'
	ignoreOrderCheckbox.checked = false

	for k, v in pairs({Node(window.size):pad(10):rows({20,20,20,20,20,20,20}, 10, 10)}) do
		dragList:createDragElement(v.rect, function(this)
			local checkbox_rect, contents_rect = this.contents_rect:cols({20, 1}, 10)
			this.check_box = this.container:createCheckBox(checkbox_rect:centeredrect(20).rect, "", "onCloseWindow")
			this.check_box.checked = true
			this.material = Material(this.id < 8 and 7 - this.id or 0)
			this.label = this.container:createLabel(vec2(contents_rect.rect.lower.x, contents_rect.rect.center.y - 10), this.material.name, 16)
			this.label.color = this.material.color
			this.label_frame = this.container:createFrame(contents_rect:pad(-5,0,-5,0).rect)
			this.onRelease = MiningPriority.onCloseWindow
			this.onSecure = function(self) -- defining onSecure and restore for custom contents of element
				return self.check_box.checked -- only need info related to the contents defined above
			end
			this.onRestore = function(self, data) -- don't need to set pos because the draglist does it for us
				self._parent.check_box_initialized = false
				self.check_box.checked = data
				self._parent.check_box_initialized = true
			end
		end)
	end

    dragList.check_box_initialized = true
    MiningPriority.sync()
    -- MiningPriority.updateUI()
end




return MiningPriority
