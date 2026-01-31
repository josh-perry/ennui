local Widget = require("ennui.widget")
local Size = require("ennui.size")

---@class Slider : Widget
---@field value number Current value
---@field minValue number Minimum value
---@field maxValue number Maximum value
---@field step number Step increment (0 for continuous)
---@field trackHeight number Height of the track in pixels
---@field thumbSize number Size of the thumb in pixels
---@field trackColor number[] RGBA color for the track
---@field fillColor number[] RGBA color for the filled portion
---@field thumbColor number[] RGBA color for the thumb
---@field thumbHoverColor number[] RGBA color for thumb hover state
---@field thumbPressedColor number[] RGBA color for thumb pressed state
---@field __isDragging boolean Whether the slider is being dragged
---@field __dragStartX number X position when drag started
local Slider = {}
Slider.__index = Slider
setmetatable(Slider, {
    __index = Widget,
    __call = function(class, minValue, maxValue, initialValue)
        return class.new(minValue, maxValue, initialValue)
    end,
})

function Slider:__tostring()
    return string.format("Slider(%.1f)", self.props.value or 0)
end

---Create a new slider widget
---@param minValue number? Minimum value (default 0)
---@param maxValue number? Maximum value (default 100)
---@param initialValue number? Initial value (default minValue)
---@return Slider
function Slider.new(minValue, maxValue, initialValue)
    local self = setmetatable(Widget(), Slider) ---@cast self Slider

    minValue = minValue or 0
    maxValue = maxValue or 100
    initialValue = initialValue or minValue

    self:addProperty("value", initialValue)
    self:addProperty("minValue", minValue)
    self:addProperty("maxValue", maxValue)
    self:addProperty("step", 0)
    self:addProperty("trackHeight", 6)
    self:addProperty("thumbSize", 16)
    self:addProperty("trackColor", {0.3, 0.3, 0.3, 1})
    self:addProperty("fillColor", {0.3, 0.7, 1, 1})
    self:addProperty("thumbColor", {0.9, 0.9, 0.9, 1})
    self:addProperty("thumbHoverColor", {1, 1, 1, 1})
    self:addProperty("thumbPressedColor", {0.7, 0.7, 0.7, 1})

    self.__isDragging = false
    self.__dragStartX = 0

    self:setFocusable(true)
    self:setSize(Size.fill(), 24)

    self:on("mousePressed", function(_, event)
        ---@cast event MouseEvent
        if event.button == 1 and not self.state.isDisabled then
            self.__isDragging = true
            self:updateValueFromMouse(event.x)
            return true
        end
    end)

    self:on("mouseReleased", function(_, event)
        ---@cast event MouseEvent
        if event.button == 1 then
            self.__isDragging = false
        end
    end)

    self:on("mouseMoved", function(_, event)
        ---@cast event MouseEvent
        if self.__isDragging and not self.state.isDisabled then
            self:updateValueFromMouse(event.x)
            return true
        end
    end)

    self:on("keyPressed", function(_, event)
        ---@cast event KeyboardEvent
        if self.state.isDisabled then return end

        local step = self.props.step > 0 and self.props.step or (self.props.maxValue - self.props.minValue) / 20
        if event.key == "left" then
            self:setValue(self.props.value - step)
            return true
        elseif event.key == "right" then
            self:setValue(self.props.value + step)
            return true
        elseif event.key == "home" then
            self:setValue(self.props.minValue)
            return true
        elseif event.key == "end" then
            self:setValue(self.props.maxValue)
            return true
        end
    end)

    return self
end

---Update value from mouse position
---@param mouseX number Mouse X position
function Slider:updateValueFromMouse(mouseX)
    local trackX = self.x + self.padding.left + self.props.thumbSize / 2
    local trackWidth = self.width - self.padding.left - self.padding.right - self.props.thumbSize

    local ratio = (mouseX - trackX) / trackWidth
    ratio = math.max(0, math.min(1, ratio))

    local value = self.props.minValue + ratio * (self.props.maxValue - self.props.minValue)

    if self.props.step > 0 then
        value = math.floor(value / self.props.step + 0.5) * self.props.step
    end

    self:setValue(value)
end

---Set the current value
---@param value number New value
---@return Slider self
function Slider:setValue(value)
    value = math.max(self.props.minValue, math.min(self.props.maxValue, value))
    self.props.value = value
    return self
end

---Get the current value
---@return number value
function Slider:getValue()
    return self.props.value
end

---Set the minimum value
---@param minValue number Minimum value
---@return Slider self
function Slider:setMinValue(minValue)
    self.props.minValue = minValue
    if self.props.value < minValue then
        self.props.value = minValue
    end
    return self
end

---Set the maximum value
---@param maxValue number Maximum value
---@return Slider self
function Slider:setMaxValue(maxValue)
    self.props.maxValue = maxValue
    if self.props.value > maxValue then
        self.props.value = maxValue
    end
    return self
end

---Set the step increment
---@param step number Step increment (0 for continuous)
---@return Slider self
function Slider:setStep(step)
    self.props.step = step
    return self
end

---Set track color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Slider self
function Slider:setTrackColor(r, g, b, a)
    self.props.trackColor = {r, g, b, a or 1}
    return self
end

---Set fill color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Slider self
function Slider:setFillColor(r, g, b, a)
    self.props.fillColor = {r, g, b, a or 1}
    return self
end

---Set thumb color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Slider self
function Slider:setThumbColor(r, g, b, a)
    self.props.thumbColor = {r, g, b, a or 1}
    return self
end

---Override hitTest
function Slider:hitTest(x, y)
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
function Slider:__calculateContentWidth()
    return 100 + self.padding.left + self.padding.right
end

---Calculate content height (for auto sizing)
---@return number contentHeight
function Slider:__calculateContentHeight()
    return math.max(self.props.thumbSize, self.props.trackHeight) + self.padding.top + self.padding.bottom
end

---Render the slider
function Slider:onRender()
    local trackHeight = self.props.trackHeight
    local thumbSize = self.props.thumbSize

    local trackX = self.x + self.padding.left + thumbSize / 2
    local trackY = self.y + self.padding.top + (self.height - self.padding.top - self.padding.bottom - trackHeight) / 2
    local trackWidth = self.width - self.padding.left - self.padding.right - thumbSize

    -- Calculate thumb position
    local ratio = (self.props.value - self.props.minValue) / (self.props.maxValue - self.props.minValue)
    local thumbX = trackX + ratio * trackWidth - thumbSize / 2

    -- Draw track background
    love.graphics.setColor(self.props.trackColor)
    love.graphics.rectangle("fill", trackX, trackY, trackWidth, trackHeight, trackHeight / 2, trackHeight / 2)

    -- Draw filled portion
    local fillWidth = ratio * trackWidth
    if fillWidth > 0 then
        love.graphics.setColor(self.props.fillColor)
        love.graphics.rectangle("fill", trackX, trackY, fillWidth, trackHeight, trackHeight / 2, trackHeight / 2)
    end

    -- Draw thumb
    local thumbColor
    if self.__isDragging or self.state.isPressed then
        thumbColor = self.props.thumbPressedColor
    elseif self.state.isHovered then
        thumbColor = self.props.thumbHoverColor
    else
        thumbColor = self.props.thumbColor
    end

    local thumbY = self.y + self.padding.top + (self.height - self.padding.top - self.padding.bottom - thumbSize) / 2
    love.graphics.setColor(thumbColor)
    love.graphics.circle("fill", thumbX + thumbSize / 2, thumbY + thumbSize / 2, thumbSize / 2)

    -- Draw focus indicator
    if self.state.isFocused then
        love.graphics.setColor(0.5, 0.7, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", thumbX + thumbSize / 2, thumbY + thumbSize / 2, thumbSize / 2 + 2)
        love.graphics.setLineWidth(1)
    end
end

return Slider
