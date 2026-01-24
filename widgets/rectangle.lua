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

function Rectangle:__tostring()
    return "Rectangle"
end

---Create a new rectangle widget
---@return Rectangle
function Rectangle.new()
    local self = setmetatable(Widget(), Rectangle) ---@cast self Rectangle

    self:addProperty("color", {1, 1, 1, 1})
    self:addProperty("borderColor", {1, 1, 1, 1})
    self:addProperty("radius", 0)
    self:setSize(Size.fill(), Size.fill())

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
    self.props.borderColor = {r, g, b, a or 1}
    return self
end

function Rectangle:setRadius(radius)
    self.props.radius = radius
    return self
end

function Rectangle:setBorderWidth(width)
    self.props.borderWidth = width
    return self
end

---Render the rectangle
function Rectangle:onRender()
    love.graphics.setColor(self.props.color)
    love.graphics.rectangle(
        "fill",
        self.x + 0.5,
        self.y + 0.5,
        self.width - 0.5,
        self.height - 0.5,
        self.radius,
        self.radius
    )

    love.graphics.setColor(self.props.borderColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle(
        "line",
        self.x + 0.5,
        self.y + 0.5,
        self.width - 0.5,
        self.height - 0.5,
        self.radius,
        self.radius
    )

    Widget.onRender(self)
end

return Rectangle

