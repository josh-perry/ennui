local Widget = require("ennui.widget")

---@class Button : Widget
---@field backgroundColor number[] RGBA color for normal state
---@field hoverColor number[] RGBA color for hover state
---@field pressedColor number[] RGBA color for pressed state
---@field disabledColor number[] RGBA color for disabled state
---@field cornerRadius number Corner radius for rounded corners
local Button = {}
Button.__index = Button
setmetatable(Button, {
    __index = Widget,
    __call = function(class, content)
        return class.new(content)
    end,
})

---Create a new button widget
---@param content Widget[]? Button content (array of widgets added as children)
---@return Button
function Button.new(content)
    local self = setmetatable(Widget(), Button) ---@cast self Button

    self:addProperty("backgroundColor", {0.2, 0.2, 0.2, 1})
    self:addProperty("hoverColor", {0.3, 0.3, 0.3, 1})
    self:addProperty("pressedColor", {0.15, 0.15, 0.15, 1})
    self:addProperty("disabledColor", {0.1, 0.1, 0.1, 1})
    self:addProperty("cornerRadius", 4)

    self:setFocusable(true)

    if content and type(content) == "table" then
        for _, widget in ipairs(content) do
            self:addChild(widget)
        end
    end

    return self
end

---Set background color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Button self
function Button:setBackgroundColor(r, g, b, a)
    self.props.backgroundColor = {r, g, b, a or 1}
    return self
end

---Set hover color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Button self
function Button:setHoverColor(r, g, b, a)
    self.props.hoverColor = {r, g, b, a or 1}
    return self
end

---Set pressed color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Button self
function Button:setPressedColor(r, g, b, a)
    self.props.pressedColor = {r, g, b, a or 1}
    return self
end

---Set disabled color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Button self
function Button:setDisabledColor(r, g, b, a)
    self.props.disabledColor = {r, g, b, a or 1}
    return self
end

---Set corner radius
---@param radius number Corner radius in pixels
---@return Button self
function Button:setCornerRadius(radius)
    self.props.cornerRadius = radius
    return self
end

---Override hitTest to allow interactive children to receive events
---Hit transparent widgets pass events through to the button, but buttons and other
---interactive widgets should be able to receive their own events
function Button:hitTest(x, y)
    if not self:isVisible() then
        return nil
    end

    if not self:containsPoint(x, y) then
        return nil
    end

    for i = #self.children, 1, -1 do
        local child = self.children[i]
        local hit = child:hitTest(x, y)

        if hit and hit ~= child then
            return hit
        elseif hit and hit == child and not child:isHitTransparent() then
            return hit
        end
    end

    return self
end

---Calculate content width (for auto sizing)
---@return number contentWidth
function Button:__calculateContentWidth()
    local maxChildWidth = 0
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            maxChildWidth = math.max(maxChildWidth, child.desiredWidth)
        end
    end
    return maxChildWidth + self.padding.left + self.padding.right + 20
end

---Calculate content height (for auto sizing)
---@return number contentHeight
function Button:__calculateContentHeight()
    local maxChildHeight = 0
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            maxChildHeight = math.max(maxChildHeight, child.desiredHeight)
        end
    end
    return maxChildHeight + self.padding.top + self.padding.bottom + 10
end

---Render the button
function Button:onRender()
    local bgColor
    if self.state.isDisabled then
        bgColor = self.props.disabledColor
    elseif self.state.isPressed then
        bgColor = self.props.pressedColor
    elseif self.state.isHovered then
        bgColor = self.props.hoverColor
    else
        bgColor = self.props.backgroundColor
    end

    love.graphics.setColor(bgColor)
    love.graphics.rectangle(
        "fill",
        self.x,
        self.y,
        self.width,
        self.height,
        self.props.cornerRadius,
        self.props.cornerRadius
    )

    if self.state.isFocused then
        love.graphics.setColor(0.5, 0.7, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle(
            "line",
            self.x + 1,
            self.y + 1,
            self.width - 2,
            self.height - 2,
            self.props.cornerRadius,
            self.props.cornerRadius
        )
    end

    for _, child in ipairs(self.children) do
        if child:isVisible() then
            child:onRender()
        end
    end
end

return Button
