---Mixin for position and size properties
---@class PositionableMixin
---@field x number X position in pixels
---@field y number Y position in pixels
---@field width number Actual width in pixels
---@field height number Actual height in pixels
local PositionableMixin = {}
local AABB = require("ennui.utils.aabb")

---Initialize positionable fields on an instance
---Call this from the constructor of classes using this mixin
---@param self table The instance to initialize
function PositionableMixin.initPositionable(self)
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
end

---Set position
---@param x number X position
---@param y number Y position
---@return self
function PositionableMixin:setPosition(x, y)
    self.x = x
    self.y = y

    return self
end

---Get position
---@return number x, number y
function PositionableMixin:getPosition()
    return self.x, self.y
end

---Get size
---@return number width, number height
function PositionableMixin:getSize()
    return self.width, self.height
end

---Get bounds
---@return number x, number y, number width, number height
function PositionableMixin:getBounds()
    return self.x, self.y, self.width, self.height
end

---Get width
---@return number width
function PositionableMixin:getWidth()
    return self.width
end

---Get height
---@return number height
function PositionableMixin:getHeight()
    return self.height
end

---Check if point is within bounds
---@param x number Point X
---@param y number Point Y
---@return boolean
function PositionableMixin:containsPoint(x, y)
    return AABB.containsPoint(x, y, self.x, self.y, self.width, self.height)
end

return PositionableMixin
