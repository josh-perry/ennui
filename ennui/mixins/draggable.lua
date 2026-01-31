---Mixin for drag interaction functionality
---@class DraggableMixin
---@field isDraggable boolean Whether widget can be dragged
---@field dragMode string Drag mode: "position" or "delta"
---@field dragHandle table? Drag handle rectangle {x, y, width, height} relative to widget
---@field onDragStart function? Drag lifecycle callback
---@field onDrag function? Drag lifecycle callback
---@field onDragEnd function? Drag lifecycle callback
local DraggableMixin = {}
local AABB = require("ennui.utils.aabb")

---Initialize draggable fields on an instance
---Call this from the constructor of classes using this mixin
---@param self table The instance to initialize
function DraggableMixin.initDraggable(self)
    self.isDraggable = false
    self.dragMode = "position" -- "position" or "delta"
    self.dragHandle = nil -- {x, y, width, height} relative to widget
    -- Drag callbacks
    self.onDragStart = nil -- function(event) -> bool (return false to cancel)
    self.onDrag = nil -- function(event, deltaX, deltaY) for delta mode, or function(event) for position mode
    self.onDragEnd = nil -- function(event)
end

---Configure whether this widget is draggable
---@generic T
---@param self T
---@param draggable boolean Whether the widget can be dragged
---@param dragHandle table? Optional drag handle rectangle {x, y, width, height}
---@return T
function DraggableMixin:setDraggable(draggable, dragHandle)
    self.isDraggable = draggable

    if dragHandle then
        self.dragHandle = dragHandle
    end

    return self
end

---Set the drag mode ("position" or "delta")
---@generic T
---@param self T
---@param mode string "position" for position-based dragging, "delta" for delta-based
---@return T
function DraggableMixin:setDragMode(mode)
    assert(mode == "position" or mode == "delta", "dragMode must be 'position' or 'delta'")
    self.dragMode = mode
    return self
end

---Set the drag handle rectangle
---@generic T
---@param self T
---@param rect table? Rectangle {x, y, width, height} relative to widget, or nil to allow drag from anywhere
---@return T
function DraggableMixin:setDragHandle(rect)
    self.dragHandle = rect
    return self
end

---Check if a point is within the drag handle
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean True if point is in drag handle
function DraggableMixin:isInDragHandle(x, y)
    -- Check if point is within widget bounds
    if not AABB.containsPoint(x, y, self.x, self.y, self.width, self.height) then
        return false
    end

    -- If no drag handle specified, entire widget is draggable
    if not self.dragHandle then
        return true
    end

    -- Convert point to local coordinates
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
    local host = self:__getHost()
    return host and host.isWidgetDragged and host:isWidgetDragged(self) or false
end

return DraggableMixin
