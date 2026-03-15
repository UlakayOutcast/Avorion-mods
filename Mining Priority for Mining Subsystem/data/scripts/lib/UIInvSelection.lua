package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
Node = include("node")

-- namespace InvSelection
InvSelection = {
	--_parent = UIContainer(),
	--_rect = Rect(),
	--_namespace = ""
}

function InvSelection:initialize()
	self.scrollFrame = self._parent:createScrollFrame(self._rect.rect)
	self.root_node = Node(self._rect.rect.size)

	local size = vec2(self._rect.rect.width, 10000)
	local rect = Rect(vec2(), size)
	self.lister = UIVerticalLister(rect, 0, 0)

	self.currentPos = ivec2(-1, 0)
	---@type table<number, Selection>
	self.rows = {}

	---@type table<ivec2 | vec2, Selection>
	self.data = {}

	self.slotSize = 50
	self.slotAmount = math.floor(self._rect.rect.width/self.slotSize)
	self.slotHeight = self._rect.rect.width / self.slotAmount + self.slotSize / self.slotAmount
end

function InvSelection:getNextPos()
	if self.currentPos.x + 1 > self.slotAmount then
		self.currentPos = ivec2(0, self.currentPos.y + 1)
	else
		self.currentPos = ivec2(self.currentPos.x + 1, self.currentPos.y)
	end
	return self.currentPos
end

---@param item SelectionItem | InventorySelectionItem | CraftDesignSelectionItem | InventoryReferenceSelectionItem
---@param pos ivec2 | vec2 | nil -- As long as you use the same key type you should be fine
function InvSelection:add(item, pos)
	if not pos then
		pos = self:getNextPos()
	end
	if pos.y > #self.rows + 1 or pos.x > self.slotAmount - 1 then
		return "Failed due to position being too large."
	end
	if not self.rows[pos.y+1] then
		local newSelection = self.scrollFrame:createSelection(self.lister:nextRect(self.slotHeight), self.slotAmount)
		newSelection.margin = 0
		table.insert(self.rows, newSelection)
	end
	self.data[pos] = item
	self.rows[pos.y+1]:add(item, ivec2(pos.x,0))
end

---@param type InventoryItemType
function InvSelection:fill(type)
	-- TODO pull from inventory to find type and stuff the list
end

function InvSelection:hide()
	for k, v in pairs(self.rows) do
		v:hide()
	end
	self.scrollFrame:hide()
end
function InvSelection:show()
	for k, v in pairs(self.rows) do
		v:show()
	end
	self.scrollFrame:show()
end

---@param pos ivec2
function InvSelection:remove(pos)
	if pos.y > #self.rows or pos.x > self.slotAmount - 1 then
		return "Failed due to position being too large."
	end
	self.rows[pos.y + 1]:remove(ivec2(pos.x, 0))
	table.remove(self.data, pos)
end

---@param pos ivec2
---@return InventorySelection
function InvSelection:getItem(pos)
	if pos.y > #self.rows or pos.x > self.slotAmount - 1 then
		return "Failed due to position being too large."
	end
	return self.data[pos]
end

function InvSelection:getItems()
	return self.data
end

function InvSelection:clear()
	---@param v Selection
	for k, v in pairs(self.rows) do
		v:clear()
	end
	self.data = {}
end


---@param parent UIContainer
function UIInvSelection(parent, rect, namespace) -- namespace for registering functions with callable?
	if rect.__avoriontype == "Rect" then rect = Node(rect) end
	local x = {
		---@type UIContainer
		_parent = parent,
		---@type Rect
		_rect = rect,
		---@type string
		_namespace = namespace}
	setmetatable(x, {__index = InvSelection})
	x:initialize()
	return x
end

return InvSelection