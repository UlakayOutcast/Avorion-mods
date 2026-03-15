package.path = package.path .. ";data/scripts/lib/?.lua"
include("tooltipmaker")
include("utility")

-- namespace SortList
---@class SortList
SortList = {}
SortList.elements = {} -- used in button functions to find current element(self) also the only thing actually parented to the script

function SortList:cloneInv(in_table)
    self._turrets = {}
    for _, v in pairs(in_table or self._inventory:getItems()) do
        if self._is_turrets and (v.item.__avoriontype == "InventoryTurret" or v.item.__avoriontype == "TurretTemplate") then
            table.insert(self._turrets, {InventoryReference = v, Tooltip = makeTurretTooltip(v.item, nil, 2)})
        end
        if not self._is_turrets and (v.item.__avoriontype == "SystemUpgradeTemplate") then
            table.insert(self._turrets, {InventoryReference = v, Tooltip = v.item.tooltip})
        end
    end
end

function SortList:fillLines()
    self._lines = self._lines or {}
    self._linetypes = {}
    local manufacturingPrice = false
    for _, v in pairs(self._turrets) do
        v.stats = {}
        for _, line in pairs({ v.Tooltip:getLines()}) do
            local text = trim(line.ltext:match("%D+"))
            local rtext = tonumber(trim(line.rtext:match("%d+")))
            if not self._ignorelines[text] and type(rtext) == "number" then
                self._linetypes[text] = text
                if v.stats[text] then -- Adds multiple lines together
                    v.stats[text] = v.stats[text] + rtext
                else
                    v.stats[text] = rtext
                end
            end
        end
        if self._is_turrets then
            if v.manufacturingPrice then
                v.stats["Manufacturing Price"] = v.manufacturingPrice
                manufacturingPrice = true
            end
            v.stats["Damage Type"] = v.InventoryReference.item.damageType
            v.stats.Material = v.InventoryReference.item.material.value
            v.stats.Coaxial = v.InventoryReference.item.coaxial and 1 or 0
        end
        v.stats.Rarity = v.InventoryReference.item.rarity.value
        v.stats.Price = v.Tooltip.price
    end
    if self._is_turrets then
        if manufacturingPrice then
            self._linetypes["Manufacturing Price"] = "Manufacturing Price"
        end
        self._linetypes["Damage Type"] = "Damage Type"
        self._linetypes["Material"] = "Material"
        self._linetypes["Coaxial"] = "Coaxial"
    end
    self._linetypes["Rarity"] = "Rarity"
    self._linetypes["Price"] = "Price"
    local temp = {}
    for _, v in pairs(self._linetypes) do
        table.insert(temp, v)
    end
    self._linetypes = temp
    table.sort(self._linetypes, function(a, b) return a:lower() < b:lower() end)
    for _, v in ipairs(self._linetypes) do
        if not self._lines[v] then
            local line = {}
            line.rect = self._lister:nextRect(20)
            line.vertical_split = UIArbitraryVerticalSplitter(line.rect, 10, 0, 25, line.rect.width/2+15, line.rect.width)

            local i = 0
            line.checkbox = self._scrollframe:createCheckBox(line.vertical_split:partition(i),"",""); i = i + 1
            line.stat_frame = self._scrollframe:createFrame(line.vertical_split:partition(i))
            line.stat_frame.backgroundColor = ColorARGB(0.7,0,0,0)
            line.stat = self._scrollframe:createLabel(line.vertical_split:partition(i).lower+vec2(2.5,2.5), v, 14)
            line.stat.shortenText = true
            line.stat.tooltip = v
            line.stat.size = line.vertical_split:partition(i).size; i = i + 1
            line.text_box = self._scrollframe:createTextBox(line.vertical_split:partition(i),"")
            line.text_box.text = 1
            line.text_box.allowedCharacters = "0123456789.-"; i = i + 1 -- TODO change sorting to actually use this <>

            line.hide = function(this)
                this.checkbox:hide()
                this.stat_frame:hide()
                this.stat:hide()
                this.text_box:hide()
            end

            line.show = function(this)
                this.checkbox:show()
                this.stat_frame:show()
                this.stat:show()
                this.text_box:show()
            end

            self._lines[v] = line
        end
    end
end

function SortList:fillMax()
    self._maxstats = {}
    for _, turret in pairs(self._turrets) do -- fill _maxstats
        for k, stat in pairs(turret.stats) do
            self._maxstats[k] = self._maxstats[k] or 0
            if stat > self._maxstats[k] then self._maxstats[k] = stat end
        end
    end
end

function SortList:fillInventory()
    self._inventory:clear()
    for k, v in ipairs(self._turrets) do
        if self.inventory_limit and k >= self.inventory_limit then return end
        self._inventory:add(v.InventoryReference)
    end
end

function SortList:search()
    if atype(self._inventory.element or self._inventory) == "InventorySelection" then
        self._inventory.sortMode = 0
    end
    for _, turret in pairs(self._turrets) do -- fill turret sum
        turret.sum = 0
        for stat, line in pairs(self._lines) do
            local val = turret.stats[stat] or 0
            local text = line.text_box.text
            local text_number = tonumber(text) or tonumber(text:match("-?%d+"))
            if line.checkbox.checked and self._maxstats[stat] then
                turret.sum = turret.sum + val*text_number/self._maxstats[stat] -- Weighted Average
                --[[
                if (text:find("<") and (val < text_number)) or not text:find("<") and (val > text_number) then -- TODO figure out the fucky shit happening with some stats from previous inventories
                    if text:find("!") then
                        turret.sum = turret.sum - val/self._maxstats[stat]
                    else
                        turret.sum = turret.sum + val/self._maxstats[stat] -- This works pretty good
                    end
                end]]
            end
        end
    end

    table.sort(self._turrets, function(a,b) return a.sum > b.sum end)
    self:fillInventory()
end

function SortList:clear()
    for _, line in pairs(self._lines) do
        line.checkbox.checked = false
        line.text_box.text = 1
    end
end

-- Button related functions --

function SortList.onInvSearch(btn)
    for _, self in pairs(SortList.elements) do
        if self._searchbutton.index == btn.index then
            self:search()
        end
    end
end

function SortList.onInvClear(btn)
    for _, self in pairs(SortList.elements) do
        if self._clearbutton.index == btn.index then
            self:clear()
        end
    end
end

SortList_onInvSearch = SortList.onInvSearch -- failsafes for nil namespace
SortList_onInvClear = SortList.onInvClear

--[[
TRASHED hah because incorporating trashing turrets would mean removing and re-adding the item to the inventory
Which is a serverside function in my otherwise all client code

function SortList:trash()
    for _, turret in pairs(self._turrets) do
        if turret.sum ~= nil then
            if turret.sum < tonumber(self._trashtextbox.text or 0) and turret.sum ~= 0 then
                print("trashed", turret.InventoryReference.item.__avoriontype, turret.InventoryReference.item.trash)
                turret.InventoryReference.item.trash = 1
                print("aaaa", turret.InventoryReference.item.trash)
            end
        end
    end
end -- make sure there is some kind of confirmation for both operations here
function SortList:cleartrash()
    for _, turret in pairs(self._turrets) do
        if turret.sum ~= nil then
            if turret.sum < tonumber(self._trashtextbox.text or 0) and turret.sum ~= 0 then
                turret.InventoryReference.item.trash = 0
            end
        end
    end
end
function SortList.onTrash(btn)
    for _, self in pairs(SortList.elements) do
        if self._trashbutton.index == btn.index then
            self:trash()
        end
    end
end
function SortList.onClearTrash(btn)
    for _, self in pairs(SortList.elements) do
        if self._cleartrashbutton.index == btn.index then
            self:cleartrash()
        end
    end
end
SortList_onTrash = SortList.onTrash
SortList_onClearTrash = SortList.onClearTrash
]]

-- Constructor related functions --

function SortList:updateInfo(in_table) -- to be called after changing the inventory
    self:cloneInv(in_table)
    self:fillLines()
    self:fillMax()
end

function SortList:changeInventory(inventory)
    self._inventory = inventory
    self:updateInfo()
end

function SortList:onShowWindow(index, type) -- Function specifically for inventories
    self._inventory:clear()
    self._inventory:fill(index or Galaxy():getPlayerCraftFaction().index, type or InventoryItemType.Turret)
    self:updateInfo()
end

function SortList:show()
    self._scrollframe:show()
    self._searchbutton:show()
    self._clearbutton:show()
    self._buttonframe:show()
end

function SortList:hide()
    self._scrollframe:hide()
    self._searchbutton:hide()
    self._clearbutton:hide()
    self._buttonframe:hide()
end

function SortList:initialize()
    -- TODO write code to handle rects that arent lower 0,0 (upper is the bottom right)
    self._container = self._parent:createContainer(self._rect)
    self._ahsplitter = UIArbitraryHorizontalSplitter(Rect(self._rect.size), 10, 0, --[[self._rect.height - self._rect.width/6*2,]] self._rect.height - self._rect.width/6)

    self._scrollframe = self._container:createScrollFrame(self._ahsplitter:partition(0))
    self._lister = UIVerticalLister(Rect(vec2(),self._ahsplitter:partition(0).size+vec2(-15,0)),10,10)

    --[[ Trashed for now
    self._container:createFrame(self._ahsplitter:partition(1))
    self._avsplit = UIArbitraryVerticalSplitter(self._ahsplitter:partition(1), 10, 5, self._ahsplitter:partition(1).width/3, self._ahsplitter:partition(1).width/3*2)
    self._trashbutton = self._container:createButton(self._avsplit:partition(0), "Trash", "SortList_onTrash")
    self._trashtextbox = self._container:createTextBox(self._avsplit:partition(1), "")
    self._trashtextbox.text = 0
    self._trashtextbox.allowedCharacters = "0123456789.-"
    self._cleartrashbutton = self._container:createButton(self._avsplit:partition(2), "Clear Trash", "SortList_onClearTrash")
    if self._namespace then
        if not self._namespace.SortList_onTrash then
            self._namespace.SortList_onTrash = self.onTrash -- This is done to allow function overwrites for specific objects without overwriting the function for all
        end
        if not self._namespace.SortList_onClearTrash then
            self._namespace.SortList_onClearTrash = self.onClearTrash
        end
    end
    ]]

    self._buttonframe = self._container:createFrame(self._ahsplitter:partition(1)) -- change partition if trash
    self._hsplit = UIVerticalSplitter(self._ahsplitter:partition(1), 5, 5, 0.5) -- change partition if trash
    self._searchbutton = self._container:createButton(self._hsplit.left, "Search", "SortList_onInvSearch")
    self._clearbutton = self._container:createButton(self._hsplit.right, "Clear", "SortList_onInvClear")
    if self._namespace then
        if not self._namespace.SortList_onInvSearch then
            self._namespace.SortList_onInvSearch = self.onInvSearch
        end
        if not self._namespace.SortList_onInvClear then
            self._namespace.SortList_onInvClear = self.onInvClear
        end
    end

    self._ignorelines = self._ignorelines or {}
    self:updateInfo()
end

---@class UISortList
---@return SortList
---@param namespace table
---@param parent UIElement
---@param rect Rect
---@param inventory Inventory
function UISortList(namespace, parent, rect, inventory, is_turrets)
    local x = {_namespace = namespace, _parent = parent, _rect = rect, _inventory = inventory, _is_turrets = is_turrets}
    setmetatable(x, {__index = SortList})
    x:initialize()
    table.insert(SortList.elements, x)
    return x
end

return SortList