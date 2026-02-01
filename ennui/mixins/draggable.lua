---Mixin for drag interaction functionality
---@class DraggableMixin
---@field isDraggable boolean Whether widget can be dragged
---@field dragMode dragMode Drag mode: "position" or "delta"
---@field dragHandle table? Drag handle rectangle {x, y, width, height} relative to widget
---@field onDragStart function? Drag lifecycle callback
---@field onDrag function? Drag lifecycle callback
---@field onDragEnd function? Drag lifecycle callback
local DraggableMixin = {}
local AABB = require("ennui.utils.aabb")
local Mixin = require("ennui.utils.mixin")
local PositionableMixin = require("ennui.mixins.positionable")
local ParentableMixin = require("ennui.mixins.parentable")

---@alias dragMode "position"|"delta"

---Initialize draggable fields on an instance
---Call this from the constructor of classes using this mixin
---@param self table The instance to initialize
function DraggableMixin.initDraggable(self)
    self.isDraggable = false
    self.dragMode = "position"
    self.dragHandle = nil

    self.onDragStart = nil
    self.onDrag = nil
    self.onDragEnd = nil
end

---Configure whether this widget is draggable
---@param draggable boolean Whether the widget can be dragged
---@param dragHandle table? Optional drag handle rectangle {x, y, width, height}
---@return self
function DraggableMixin:setDraggable(draggable, dragHandle)
    self.isDraggable = draggable

    if dragHandle then
        self.dragHandle = dragHandle
    end

    return self
end

---Set the drag mode ("position" or "delta")
---@param mode dragMode "position" for position-based dragging, "delta" for delta-based
---@return self
function DraggableMixin:setDragMode(mode)
    assert(mode == "position" or mode == "delta", "dragMode must be 'position' or 'delta'")
    self.dragMode = mode
    return self
end

---Set the drag handle rectangle
---@param rect table? Rectangle {x, y, width, height} relative to widget, or nil to allow drag from anywhere
---@return self
function DraggableMixin:setDragHandle(rect)
    self.dragHandle = rect
    return self
end

---Check if a point is within the drag handle
---Requires PositionableMixin
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean True if point is in drag handle
function DraggableMixin:isInDragHandle(x, y)
    if not Mixin.hasMixin(self, PositionableMixin) then
        error("DraggableMixin:isInDragHandle requires PositionableMixin")
    end

    ---@cast self PositionableMixin | DraggableMixin
    if not AABB.containsPoint(x, y, self.x, self.y, self.width, self.height) then
        return false
    end

    -- If no drag handle specified, entire widget is draggable
    if not self.dragHandle then
        return true
    end

    local localX = x - self.x
    local localY = y - self.y

    local handleX = self.dragHandle.x or 0
    local handleY = self.dragHandle.y or 0

    -- width/height of 0 means full widget dimension
    local handleWidth = self.dragHandle.width == 0 and self.width or (self.dragHandle.width or self.width)
    local handleHeight = self.dragHandle.height == 0 and self.height or (self.dragHandle.height or self.height)

    return AABB.containsPoint(localX, localY, handleX, handleY, handleWidth, handleHeight)
end

---Check if this widget is currently being dragged
---@return boolean True if widget is currently being dragged
function DraggableMixin:isDragging()
    if not Mixin.hasMixin(self, ParentableMixin) then
        error("DraggableMixin:isDragging requires ParentableMixin")
    end

    ---@cast self ParentableMixin | DraggableMixin
    local host = self:getHost()
    return host and host.isWidgetDragged and host:isWidgetDragged(self) or false
end

return DraggableMixin
