local Widget = require("ennui.widget")
local Size = require("ennui.size")
local Text = require("widgets.text")
local HorizontalStackPanel = require("widgets.horizontalstackpanel")
local Rectangle = require("widgets.rectangle")

---@class Checkbox : Widget
---@field checked boolean Whether the checkbox is checked
---@field boxSize number Size of the checkbox box in pixels
---@field boxColor number[] RGBA color for the box border
---@field checkColor number[] RGBA color for the check mark
---@field backgroundColor number[] RGBA color for the box background
---@field hoverColor number[] RGBA color for hover state
---@field textColor number[] RGBA color for the label text
---@field spacing number Spacing between box and label
---@field __textWidget Text Internal Text widget reference
---@field __layoutContainer HorizontalStackPanel Internal layout container
---@field __indicatorPlaceholder Rectangle Internal placeholder for checkbox indicator
local Checkbox = {}
Checkbox.__index = Checkbox
setmetatable(Checkbox, {
    __index = Widget,
    __call = function(class, label)
        return class.new(label)
    end,
})

---Create a new checkbox widget
---@param label string? Checkbox label text (optional)
---@return Checkbox
function Checkbox.new(label)
    local self = setmetatable(Widget(), Checkbox) ---@cast self Checkbox

    self:addProperty("checked", false)
    self:addProperty("boxSize", 18)
    self:addProperty("boxColor", {0.5, 0.5, 0.5, 1})
    self:addProperty("checkColor", {0.3, 0.7, 1, 1})
    self:addProperty("backgroundColor", {0.15, 0.15, 0.15, 1})
    self:addProperty("hoverColor", {0.2, 0.2, 0.2, 1})
    self:addProperty("textColor", {1, 1, 1, 1})
    self:addProperty("spacing", 8)
    self:addProperty("label", label or "")

    self.__layoutContainer = HorizontalStackPanel()
        :setSpacing(self.props.spacing)
        :setSize(Size.auto(), Size.auto())
        :setHitTransparent(true)

    -- Create indicator placeholder (invisible, just for layout)
    self.__indicatorPlaceholder = Rectangle()
        :setSize(self.props.boxSize, self.props.boxSize)
        :setColor(0, 0, 0, 0) -- Invisible

    self.__textWidget = Text()
        :setTextVerticalAlignment("center")
        :setSize(Size.auto(), Size.auto())

    self.__layoutContainer:addChild(self.__indicatorPlaceholder)
    self.__layoutContainer:addChild(self.__textWidget)
    self:addChild(self.__layoutContainer)

    self:watch("label", function(newLabel)
        self.__textWidget.props.text = newLabel
        self:invalidateLayout()
    end, { immediate = true })

    self:watch("textColor", function(newColor)
        self.__textWidget.props.color = newColor
        self:invalidateRender()
    end, { immediate = true })

    self:watch("spacing", function(newSpacing)
        self.__layoutContainer:setSpacing(newSpacing)
        self:invalidateLayout()
    end)

    self:watch("boxSize", function(newSize)
        self.__indicatorPlaceholder:setSize(newSize, newSize)
        self:invalidateLayout()
    end)

    self:setFocusable(true)

    self:on("clicked", function()
        if not self.state.isDisabled then
            self.props.checked = not self.props.checked
        end
    end)

    self:on("keyPressed", function(_, event)
        if event.key == "space" or event.key == "return" then
            if not self.state.isDisabled then
                self.props.checked = not self.props.checked
            end
            return true
        end
    end)

    return self
end

---Set the checked state
---@param checked boolean Whether the checkbox is checked
---@return Checkbox self
function Checkbox:setChecked(checked)
    self.props.checked = checked
    return self
end

---Get the checked state
---@return boolean checked
function Checkbox:isChecked()
    return self.props.checked
end

---Toggle the checked state
---@return Checkbox self
function Checkbox:toggle()
    self.props.checked = not self.props.checked
    return self
end

---Set the label text
---@param label string Label text
---@return Checkbox self
function Checkbox:setLabel(label)
    self.props.label = label
    return self
end

---Get the label text
---@return string label
function Checkbox:getLabel()
    return self.props.label
end

---Set text color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Checkbox self
function Checkbox:setTextColor(r, g, b, a)
    self.props.textColor = {r, g, b, a or 1}
    return self
end

---Set box color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Checkbox self
function Checkbox:setBoxColor(r, g, b, a)
    self.props.boxColor = {r, g, b, a or 1}
    return self
end

---Set check color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Checkbox self
function Checkbox:setCheckColor(r, g, b, a)
    self.props.checkColor = {r, g, b, a or 1}
    return self
end

---Set box size
---@param size number Size in pixels
---@return Checkbox self
function Checkbox:setBoxSize(size)
    self.props.boxSize = size
    return self
end

---Override hitTest to ensure checkbox receives events
function Checkbox:hitTest(x, y)
    if not self:isVisible() then
        return nil
    end

    if not self:containsPoint(x, y) then
        return nil
    end

    return self
end

---Calculate content width (for auto sizing)
---@return number contentWidth
function Checkbox:__calculateContentWidth()
    return self.__layoutContainer.desiredWidth + self.padding.left + self.padding.right
end

---Calculate content height (for auto sizing)
---@return number contentHeight
function Checkbox:__calculateContentHeight()
    return self.__layoutContainer.desiredHeight + self.padding.top + self.padding.bottom
end

---Render the checkbox
function Checkbox:onRender()
    local boxSize = self.props.boxSize
    local boxX = self.__indicatorPlaceholder.x
    local boxY = self:__centerVertically(boxSize)

    -- Draw background
    local bgColor = self.state.isHovered and self.props.hoverColor or self.props.backgroundColor
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", boxX, boxY, boxSize, boxSize, 3, 3)

    -- Draw border
    love.graphics.setColor(self.props.boxColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", boxX, boxY, boxSize, boxSize, 3, 3)

    -- Draw check mark if checked
    if self.props.checked then
        love.graphics.setColor(self.props.checkColor)
        love.graphics.setLineWidth(2)

        local padding = 4
        local x1 = boxX + padding
        local y1 = boxY + boxSize / 2
        local x2 = boxX + boxSize / 3
        local y2 = boxY + boxSize - padding
        local x3 = boxX + boxSize - padding
        local y3 = boxY + padding

        love.graphics.line(x1, y1, x2, y2, x3, y3)
        love.graphics.setLineWidth(1)
    end

    if self.state.isFocused then
        love.graphics.setColor(0.5, 0.7, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", boxX - 2, boxY - 2, boxSize + 4, boxSize + 4, 4, 4)
        love.graphics.setLineWidth(1)
    end

    if self.__textWidget:isVisible() then
        self.__textWidget:onRender()
    end
end

return Checkbox
