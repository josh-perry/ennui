local Widget = require("ennui.widget")
local Size = require("ennui.size")

---@class Rectangle : Widget
---@field color number[] RGBA color tint
---@field radius number Corner radius
local Rectangle = {}
Rectangle.__index = Rectangle
setmetatable(Rectangle, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

---Create a new rectangle widget
---@return Rectangle
function Rectangle.new()
    local self = setmetatable(Widget(), Rectangle) ---@cast self Rectangle

    self:addProperty("color", {1, 1, 1, 1})
    self:addProperty("borderColour", {1, 1, 1, 1})
    self:addProperty("radius", 0)

    self:setHitTransparent(true)
    return self
end

---Set color tint
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Rectangle self
function Rectangle:setColor(r, g, b, a)
    self.props.color = {r, g, b, a or 1}
    return self
end

function Rectangle:setBorderColor(r, g, b, a)
    self.props.borderColour = {r, g, b, a or 1}
    return self
end

function Rectangle:setRadius(radius)
    self.props.radius = radius
    return self
end

---Render the rectangle
function Rectangle:onRender()
    love.graphics.setColor(self.props.color)
    love.graphics.rectangle(
        "fill",
        self.x,
        self.y,
        self.width,
        self.height,
        self.radius,
        self.radius
    )

    love.graphics.setColor(self.props.borderColour)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle(
        "line",
        self.x,
        self.y,
        self.width,
        self.height,
        self.radius,
        self.radius
    )

    Widget.onRender(self)
end

return Rectangle

