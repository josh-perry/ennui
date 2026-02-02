local Widget = require("ennui.widget")
local Size = require("ennui.size")
local Text = require("ennui.widgets.text")
local AABB = require("ennui.utils.aabb")

---@class MenuItem
---@field label string Display text
---@field value any Associated value
---@field icon string? Optional icon identifier
---@field isSeparator boolean? Whether this is a separator

---@class Menu : Widget
---@field items MenuItem[] List of items
---@field itemHeight number Height of each item
---@field backgroundColor number[] RGBA color for background
---@field hoverColor number[] RGBA color for hover state
---@field selectedColor number[] RGBA color for selected item
---@field textColor number[] RGBA color for text
---@field borderColor number[] RGBA color for border
---@field cornerRadius number Corner radius
---@field maxVisibleItems number Maximum visible items
---@field selectedIndex number Currently selected item index (0 = none)
---@field hoveredIndex number Currently hovered item index
---@field onItemSelected fun(index: number, item: MenuItem)? Callback when item is selected
---@field __textWidget Text Internal text widget for rendering items
local Menu = {}
Menu.__index = Menu
setmetatable(Menu, {
    __index = Widget,
    __call = function(class, items)
        return class.new(items)
    end,
})

function Menu:__tostring()
    return "Menu"
end

---Create a new menu widget
---@param items MenuItem[]? Initial items
---@return Menu
function Menu.new(items)
    local self = setmetatable(Widget(), Menu) ---@cast self Menu

    self:addProperty("items", items or {})
    self:addProperty("itemHeight", 28)
    self:addProperty("backgroundColor", {0.18, 0.18, 0.18, 1})
    self:addProperty("hoverColor", {0.3, 0.3, 0.3, 1})
    self:addProperty("selectedColor", {0.3, 0.5, 0.8, 1})
    self:addProperty("textColor", {1, 1, 1, 1})
    self:addProperty("borderColor", {0.35, 0.35, 0.35, 1})
    self:addProperty("cornerRadius", 4)
    self:addProperty("maxVisibleItems", 8)
    self:addProperty("selectedIndex", 0)
    self:addProperty("hoveredIndex", 0)

    self.__textWidget = Text()
        :setTextVerticalAlignment("center")
        :setSize(Size.auto(), Size.auto())

    self.onItemSelected = nil

    return self
end

---Set items
---@param items MenuItem[]
---@return Menu self
function Menu:setItems(items)
    self.props.items = items
    return self
end

---Get total menu height
---@return number height
function Menu:getMenuHeight()
    local itemCount = 0
    local separatorCount = 0

    for i, item in ipairs(self.props.items) do
        if item.isSeparator then
            separatorCount = separatorCount + 1
        else
            itemCount = itemCount + 1
        end
        if itemCount + separatorCount >= self.props.maxVisibleItems then
            break
        end
    end

    return itemCount * self.props.itemHeight + separatorCount * 9
end

---Get item at Y position
---@param y number Y coordinate (screen space)
---@return number index (0 if none)
function Menu:getItemAtY(y)
    local currentY = self.y

    for i, item in ipairs(self.props.items) do
        local itemHeight = item.isSeparator and 9 or self.props.itemHeight

        if y >= currentY and y < currentY + itemHeight then
            if item.isSeparator then
                return 0
            end
            return i
        end

        currentY = currentY + itemHeight
        if i >= self.props.maxVisibleItems then break end
    end

    return 0
end

---Override hitTest
function Menu:hitTest(x, y)
    if not self:isVisible() then
        return nil
    end

    local menuHeight = self:getMenuHeight()

    if AABB.containsPoint(x, y, self.x, self.y, self.width, menuHeight) then
        return self
    end

    return nil
end

---Handle click
function Menu:onClicked(event)
    local index = self:getItemAtY(event.y)
    if index > 0 then
        self.props.selectedIndex = index
        if self.onItemSelected then
            self.onItemSelected(index, self.props.items[index])
        end
        return true
    end
    return false
end

---Handle mouse moved
function Menu:onMouseMoved(event)
    self.props.hoveredIndex = self:getItemAtY(event.y)
end

---Handle mouse exited
function Menu:onMouseExited(event)
    self.props.hoveredIndex = 0
end

---Override measure
function Menu:measure(availableWidth, availableHeight)
    local height = self:getMenuHeight()
    self.desiredWidth = availableWidth
    self.desiredHeight = height
    return self.desiredWidth, self.desiredHeight
end

---Render the menu
function Menu:onRender()
    local cornerRadius = self.props.cornerRadius
    local menuHeight = self:getMenuHeight()

    -- Draw background
    love.graphics.setColor(self.props.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, menuHeight, cornerRadius, cornerRadius)

    -- Draw border
    love.graphics.setColor(self.props.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, menuHeight, cornerRadius, cornerRadius)

    -- Draw items
    local currentY = self.y
    local visibleCount = 0

    for i, item in ipairs(self.props.items) do
        if visibleCount >= self.props.maxVisibleItems then break end

        if item.isSeparator then
            -- Draw separator
            love.graphics.setColor(self.props.borderColor)
            love.graphics.line(self.x + 8, currentY + 4, self.x + self.width - 8, currentY + 4)
            currentY = currentY + 9
        else
            -- Draw item background
            if i == self.props.selectedIndex then
                love.graphics.setColor(self.props.selectedColor)
                love.graphics.rectangle("fill", self.x + 2, currentY, self.width - 4, self.props.itemHeight)
            elseif i == self.props.hoveredIndex then
                love.graphics.setColor(self.props.hoverColor)
                love.graphics.rectangle("fill", self.x + 2, currentY, self.width - 4, self.props.itemHeight)
            end

            -- Draw item text
            self.__textWidget.props.text = item.label
            self.__textWidget.props.color = self.props.textColor
            self.__textWidget:arrange(
                self.x + self.padding.left + 8,
                currentY,
                self.width - self.padding.left - self.padding.right - 16,
                self.props.itemHeight
            )
            self.__textWidget:onRender()

            currentY = currentY + self.props.itemHeight
        end

        visibleCount = visibleCount + 1
    end
end

return Menu
