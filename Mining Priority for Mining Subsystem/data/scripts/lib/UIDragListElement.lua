package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
Node = include("node")

function Rect_inside(rect, vec2)
	local val =   (vec2.x > rect.position.x - rect.size.x * 0.5)
	val = val and (vec2.x < rect.position.x + rect.size.x * 0.5)
	val = val and (vec2.y > rect.position.y - rect.size.y * 0.5)
	val = val and (vec2.y < rect.position.y + rect.size.y * 0.5)
	return val
end

DragListElement = {}

function DragListElement:initialize()
	---@type UIContainer
	self.container = self._parent.container:createContainer(self._rect)
	self.id = #self._parent.elements + 1
	self.list_pos = self.id
	self.old_position = vec2(self.container.position.x+0, self.container.position.y+0)
	self.contents_rect, self.drag_rect = Node(self._rect.size):cols({1, 10}, 10)
	self.dragframe = self.container:createFrame(self.drag_rect.rect)
	self.dragframe:hide()
	self.drag_pictures = {self.drag_rect:rows(3)}
	for k, v in pairs(self.drag_pictures) do
		v.picture = self.container:createPicture(v:centeredrect(_, v.rect.height).rect, "data/textures/star1.bmp")
		v.picture.color = ClientSettings().uiColor
	end

	self:construct_contents()
end

function DragListElement:dragFunc(x, y)
	self.container.center = vec2(self.container.center.x, y)
	if self.onDrag then self:onDrag(x, y) end
end

function DragListElement:onDown(x, y)
	--print("down in", self.id)
	self.old_position = vec2(self.container.position.x+0, self.container.position.y+0)
	if self.onPress then self:onPress(x, y) end
end

function DragListElement:onUp(x, y)
	local swapping = false
	for k, v in pairs(self._parent.elements) do
		if v._parent._window.visible and self._parent == v._parent and v ~= self and Rect_inside(v.container.rect, vec2(x, y)) then
			v.old_position = vec2(v.container.position.x+0, v.container.position.y+0)
			v.container.position = self.old_position -- TODO fix scrollframes somehow on release they go to where they were and that can now be inside something else if you scroll mid drag
			self.container.position = v.old_position
			local temp_pos = v.list_pos
			v.list_pos = self.list_pos
			self.list_pos = temp_pos
			--print(self.id, 'up inside', v.id)
			swapping = true
		end
	end
	if not swapping and not self.allow_drop_anywhere then
		--print('failed on', self.id)
		self.container.position = self.old_position
	end
	if self.onRelease then self:onRelease(x, y) end
end


function UIDragListElement(parent, rect, constructor)
	local x = {_parent = parent, _rect = rect, construct_contents = constructor}
	setmetatable(x, {__index = DragListElement})
	x:initialize()
	table.insert(parent.elements, x)
	return x
end

return DragListElement