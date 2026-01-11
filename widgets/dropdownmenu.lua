local Widget = require("ennui.widget")
local Size = require("ennui.size")
local StackPanel = require("widgets.stackpanel")
local TextButton = require("widgets.textbutton")

---@class DropdownMenu : Widget
---@field __itemPanel StackPanel Panel to hold menu items
---@field backgroundColor number[] RGBA color for background
---@field borderColor number[] RGBA color for border
---@field __isSeparator? boolean Flag to identify separator items
local DropdownMenu = {}
DropdownMenu.__index = DropdownMenu
setmetatable(DropdownMenu, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

---Create a new dropdown menu
---@return DropdownMenu
function DropdownMenu.new()
    local self = setmetatable(Widget(), DropdownMenu) ---@cast self DropdownMenu

    self.backgroundColor = {0.15, 0.15, 0.15, 1}
    self.borderColor = {0.3, 0.3, 0.3, 1}

    self.__itemPanel = StackPanel()
        :setSize(Size.fill(), Size.auto())
        :setSpacing(0)
        :setPadding(4, 4, 4, 4)

    self:addChild(self.__itemPanel)

    self:setSize(100, 80)
    self:setHorizontalAlignment("left")
    self:setVerticalAlignment("top")

    self:setVisible(false)

    return self
end

---Add a menu item
---@param label string Item label text
---@return TextButton itemButton The menu item button
function DropdownMenu:addItem(label)
    local itemButton = TextButton()
        :setText(label)
        :setSize(Size.fill(), Size.auto())
        :setPadding(4, 12, 4, 12)

    self.__itemPanel:addChild(itemButton)

    return itemButton
end

---Add a separator item
---@return Widget separator
function DropdownMenu:addSeparator()
    local separator = Widget()
        :setSize(Size.fill(), 1)
        :setHeight(1)

    separator.__isSeparator = true

    self.__itemPanel:addChild(separator)

    return separator
end

---Set background color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return DropdownMenu self
function DropdownMenu:setBackgroundColor(r, g, b, a)
    self.backgroundColor = {r, g, b, a or 1}
    self:invalidateRender()
    return self
end

---Set border color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return DropdownMenu self
function DropdownMenu:setBorderColor(r, g, b, a)
    self.borderColor = {r, g, b, a or 1}
    self:invalidateRender()
    return self
end

---Get the item panel
---@return StackPanel
function DropdownMenu:getItemPanel()
    return self.__itemPanel
end

---Calculate content width (for auto sizing)
---@return number contentWidth
function DropdownMenu:__calculateContentWidth()
    local maxWidth = 0
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            maxWidth = math.max(maxWidth, child.desiredWidth)
        end
    end
    return maxWidth + self.padding.left + self.padding.right
end

---Calculate content height (for auto sizing)
---@return number contentHeight
function DropdownMenu:__calculateContentHeight()
    return self.__itemPanel.desiredHeight + self.padding.top + self.padding.bottom
end

---Render the dropdown menu
function DropdownMenu:onRender()
    if not self:isVisible() then
        return
    end

    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    for _, child in ipairs(self.__itemPanel.children) do
        if child:isVisible() then
            if child:isVisible() and child.height == 1 then
                love.graphics.setColor(self.borderColor)
                love.graphics.line(child.x, child.y + child.height / 2,
                                   child.x + child.width, child.y + child.height / 2)
            else
                child:onRender()
            end
        end
    end
end

return DropdownMenu
