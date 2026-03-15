
include('UIDragListElement')

DragList = {elements = {}}

function DragList:initialize()
	self.container = self._parent:createContainer(Node(self._parent.rect.size).rect)
end

function DragList:createDragElement(rect, constructor)
	return UIDragListElement(self, rect, constructor)
end

--- Keep in mind, you cannot secure anything that isn't shared between client and server
--- because client doesn't have a secure function
function DragList:secure()
	local data = {}
	for k, v in pairs(self.elements) do
		local element_extra = v.onSecure and v:onSecure()
		table.insert(data, {id = v.id, list_pos = v.list_pos, n_pos = v.container.position - self.container.position, extra = element_extra})
	end
	return data
end

function DragList:restore(data)
	for k, v in pairs(data) do
		if v.pos then return end -- cancel restore if old pos exists
		local element = self.elements[v.id]
		element.list_pos = v.list_pos
		if type(v.n_pos) == 'table' then
			v.n_pos = vec2(v.n_pos.x, v.n_pos.y) -- Weird vec2 being converted to table on secure from disk
		end
		element.container.position = self.container.position + v.n_pos
		if element.onRestore then element:onRestore(v.extra) end
	end
end

function DragList.onDefaultPreRenderHud(...)
	if DragList.elements[1]._window.visible then
		local mouse = Mouse()
		for _, element in pairs(DragList.elements) do
			local self = element.elements[1]
			if self then
				local x, y = mouse.position.x, mouse.position.y
				y = math.min(y, self._parent.container.rect.upper.y - self.container.rect.height*0.5 - 10)
				y = math.max(y, self._parent.container.rect.lower.y + self.container.rect.height*0.5 + 10)
				for _, v in pairs(self._parent.elements) do
					if mouse:mouseDown(1) and Rect_inside(v.dragframe.rect, mouse.position) then
						v.dragging = true
						v:onDown(x, y)
					end
					if v.dragging and mouse:mouseUp(1) then
						v.dragging = false
						v:onUp(x, y)
					end
					if v.dragging then
						v:dragFunc(x, y)
					end
				end
			end
			if element.onPreRenderHud then element:onPreRenderHud(...) end
		end
	end
end

function UIDragList(namespace, window, parent)
	local x = {_namespace = namespace, _window = window, _parent = parent, elements = {}}
	setmetatable(x, {__index = DragList})
	table.insert(DragList.elements, x)
	x:initialize()
	if not DragList.registered then
		DragList.registered = true
		namespace.onPreRenderHud_UIDragList = DragList.onDefaultPreRenderHud
		Player():registerCallback("onPreRenderHud", "onPreRenderHud_UIDragList")
	end
	return x
end

return DragList
