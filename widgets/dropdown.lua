local Widget = require("ennui.widget")
local Size = require("ennui.size")
local Text = require("widgets.text")
local Menu = require("widgets.menu")

---@class DropdownItem
---@field label string Display text
---@field value any Associated value
---@field icon string? Optional icon identifier

---@class Dropdown : Widget
---@field items DropdownItem[] List of items
---@field selectedIndex number Currently selected item index (0 = none)
---@field isOpen boolean Whether dropdown is open
---@field direction "down"|"up" Direction dropdown opens
---@field maxVisibleItems number Maximum visible items
---@field itemHeight number Height of each item
---@field backgroundColor number[] RGBA color for background
---@field hoverColor number[] RGBA color for hover state
---@field selectedColor number[] RGBA color for selected item
---@field menuColor number[] RGBA color for menu background
---@field textColor number[] RGBA color for text
---@field borderColor number[] RGBA color for border
---@field cornerRadius number Corner radius
---@field __textWidget Text Internal Text widget
---@field __menu Menu Internal Menu widget
local Dropdown = {}
Dropdown.__index = Dropdown
setmetatable(Dropdown, {
    __index = Widget,
    __call = function(class, items)
        return class.new(items)
    end,
})

---Create a new dropdown widget
---@param items DropdownItem[]? Initial items (optional)
---@return Dropdown
function Dropdown.new(items)
    local self = setmetatable(Widget(), Dropdown) ---@cast self Dropdown

    self:addProperty("items", items or {})
    self:addProperty("selectedIndex", 0)
    self:addProperty("isOpen", false)
    self:addProperty("direction", "down")
    self:addProperty("maxVisibleItems", 8)
    self:addProperty("itemHeight", 28)
    self:addProperty("backgroundColor", {0.2, 0.2, 0.2, 1})
    self:addProperty("hoverColor", {0.3, 0.3, 0.3, 1})
    self:addProperty("selectedColor", {0.3, 0.5, 0.8, 1})
    self:addProperty("menuColor", {0.18, 0.18, 0.18, 1})
    self:addProperty("textColor", {1, 1, 1, 1})
    self:addProperty("borderColor", {0.35, 0.35, 0.35, 1})
    self:addProperty("cornerRadius", 4)

    self.__textWidget = Text()
        :setTextVerticalAlignment("center")
        :setSize(Size.auto(), Size.auto())

    self.__menu = Menu(items)
    self.__menu:setVisible(false)
    self.__menu.onItemSelected = function(index, item)
        self.props.selectedIndex = index
        self:close()
    end

    self.__menu:bindFrom(self, {
        "selectedColor",
        "textColor",
        "backgroundColor"
    })

    self:watch("items", function(items)
        self.__menu:setItems(items)
    end, { immediate = true })

    self:setFocusable(true)
    self:setSize(Size.fill(), 32)

    return self
end

---Add an item to the dropdown
---@param label string Display text
---@param value any? Associated value (defaults to label)
---@param icon string? Optional icon identifier
---@return Dropdown self
function Dropdown:addItem(label, value, icon)
    table.insert(self.props.items, { label = label, value = value or label, icon = icon })
    self.__menu:setItems(self.props.items)
    return self
end

---Add a separator
---@return Dropdown self
function Dropdown:addSeparator()
    table.insert(self.props.items, { label = "---", value = nil, isSeparator = true })
    self.__menu:setItems(self.props.items)
    return self
end

---Remove an item by index
---@param index number Item index to remove
---@return Dropdown self
function Dropdown:removeItem(index)
    table.remove(self.props.items, index)
    if self.props.selectedIndex == index then
        self.props.selectedIndex = 0
    elseif self.props.selectedIndex > index then
        self.props.selectedIndex = self.props.selectedIndex - 1
    end
    self.__menu:setItems(self.props.items)
    return self
end

---Clear all items
---@return Dropdown self
function Dropdown:clearItems()
    self.props.items = {}
    self.props.selectedIndex = 0
    self.__menu:setItems({})
    return self
end

---Set selected index
---@param index number Item index to select (0 for none)
---@return Dropdown self
function Dropdown:setSelectedIndex(index)
    if index >= 0 and index <= #self.props.items then
        local item = self.props.items[index]
        if not item or not item.isSeparator then
            self.props.selectedIndex = index
        end
    end
    return self
end

---Get selected index
---@return number index
function Dropdown:getSelectedIndex()
    return self.props.selectedIndex
end

---Get selected item
---@return DropdownItem? item
function Dropdown:getSelectedItem()
    if self.props.selectedIndex > 0 then
        return self.props.items[self.props.selectedIndex]
    end
    return nil
end

---Get selected value
---@return any? value
function Dropdown:getSelectedValue()
    local item = self:getSelectedItem()
    return item and item.value
end

---Set selected value
---@param value any Value to select
---@return Dropdown self
function Dropdown:setSelectedValue(value)
    for i, item in ipairs(self.props.items) do
        if item.value == value then
            self.props.selectedIndex = i
            break
        end
    end
    return self
end

---Toggle dropdown open state
---@return Dropdown self
function Dropdown:toggle()
    if self.props.isOpen then
        self:close()
    else
        self:open()
    end
    return self
end

---Open the dropdown
---@return Dropdown self
function Dropdown:open()
    if self.props.isOpen then
        return self
    end

    self.props.isOpen = true

    self:__positionMenu()
    self.__menu:setVisible(true)

    -- Register menu as overlay
    local host = self:__getHost()

    if host and host.registerOverlay then
        host:registerOverlay(self.__menu)
    end

    return self
end

---Close the dropdown
---@return Dropdown self
function Dropdown:close()
    if not self.props.isOpen then return self end
    self.props.isOpen = false

    -- Hide menu and unregister overlay
    self.__menu:setVisible(false)
    local host = self:__getHost()
    if host and host.unregisterOverlay then
        host:unregisterOverlay(self.__menu)
    end
    return self
end

---Position the menu relative to the dropdown
---@private
function Dropdown:__positionMenu()
    local menuY
    if self.props.direction == "up" then
        menuY = self.y - self.__menu:getMenuHeight()
    else
        menuY = self.y + self.height
    end
    self.__menu.x = self.x
    self.__menu.y = menuY
    self.__menu.width = self.width
end

---Set dropdown direction
---@param direction "down"|"up" Direction to open
---@return Dropdown self
function Dropdown:setDirection(direction)
    self.props.direction = direction
    return self
end

---Set background color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Dropdown self
function Dropdown:setBackgroundColor(r, g, b, a)
    self.props.backgroundColor = {r, g, b, a or 1}
    return self
end

---Set text color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Dropdown self
function Dropdown:setTextColor(r, g, b, a)
    self.props.textColor = {r, g, b, a or 1}
    return self
end

---Calculate content height
function Dropdown:__calculateContentHeight()
    return 32 + self.padding.top + self.padding.bottom
end

---Override arrange to keep menu positioned
function Dropdown:arrange(x, y, width, height)
    Widget.arrange(self, x, y, width, height)
    if self.props.isOpen then
        self:__positionMenu()
    end
end

function Dropdown:onClicked(event)
    self:toggle()
    return true
end

function Dropdown:onFocusLost(event)
    self:close()
end

function Dropdown:onKeyPressed(event)
    if event.key == "space" or event.key == "return" then
        if self.props.isOpen and self.__menu.props.hoveredIndex > 0 then
            self.props.selectedIndex = self.__menu.props.hoveredIndex
            self:close()
        else
            self:toggle()
        end
        return true
    elseif event.key == "escape" then
        self:close()
        return true
    elseif event.key == "up" then
        if self.props.isOpen then
            local idx = self.__menu.props.hoveredIndex - 1
            while idx >= 1 do
                if not self.props.items[idx].isSeparator then
                    self.__menu.props.hoveredIndex = idx
                    break
                end
                idx = idx - 1
            end
        end
        return true
    elseif event.key == "down" then
        if self.props.isOpen then
            local idx = self.__menu.props.hoveredIndex + 1
            while idx <= #self.props.items do
                if not self.props.items[idx].isSeparator then
                    self.__menu.props.hoveredIndex = idx
                    break
                end
                idx = idx + 1
            end
        else
            self:open()
            for i, item in ipairs(self.props.items) do
                if not item.isSeparator then
                    self.__menu.props.hoveredIndex = i
                    break
                end
            end
        end
        return true
    end
end

---Render the dropdown button
function Dropdown:onRender()
    local cornerRadius = self.props.cornerRadius

    -- Draw button background
    local bgColor = self.state.isHovered and self.props.hoverColor or self.props.backgroundColor
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, cornerRadius, cornerRadius)

    -- Draw border
    love.graphics.setColor(self.props.borderColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, cornerRadius, cornerRadius)

    -- Draw selected text
    local displayText = "Select..."
    if self.props.selectedIndex > 0 then
        local item = self.props.items[self.props.selectedIndex]
        if item then
            displayText = item.label
        end
    end

    self.__textWidget.props.text = displayText
    self.__textWidget.props.color = self.props.textColor
    self.__textWidget:arrange(
        self.x + self.padding.left + 8,
        self.y,
        self.width - self.padding.left - self.padding.right - 28,
        self.height
    )
    self.__textWidget:onRender()

    -- Draw dropdown arrow
    local iconSize = 8
    local iconX = self.x + self.width - self.padding.right - 16
    local iconY = self.y + (self.height - iconSize) / 2

    love.graphics.setColor(self.props.textColor[1], self.props.textColor[2], self.props.textColor[3], 0.6)
    if self.props.isOpen then
        love.graphics.polygon("fill",
            iconX, iconY + iconSize,
            iconX + iconSize, iconY + iconSize,
            iconX + iconSize / 2, iconY
        )
    else
        love.graphics.polygon("fill",
            iconX, iconY,
            iconX + iconSize, iconY,
            iconX + iconSize / 2, iconY + iconSize
        )
    end

    -- Draw focus indicator
    if self.state.isFocused then
        love.graphics.setColor(0.5, 0.7, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", self.x + 1, self.y + 1, self.width - 2, self.height - 2,
            cornerRadius, cornerRadius)
        love.graphics.setLineWidth(1)
    end
end

return Dropdown
