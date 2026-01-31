---@class LayoutStrategy
---@field spacing number Gap between children in pixels
local LayoutStrategy = {}
LayoutStrategy.__index = LayoutStrategy
setmetatable(LayoutStrategy, {
    __call = function(class, ...)
        return class.new(...)
    end
})

---Creates a new Layoutstrategy
---@return LayoutStrategy
function LayoutStrategy.new()
    local self = setmetatable({}, LayoutStrategy) ---@cast self LayoutStrategy
    self.spacing = 0

    return self
end

---@param widget Widget The widget being measured
---@param availableWidth number Available width
---@param availableHeight number Available height
---@return number desiredWidth, number desiredHeight
function LayoutStrategy:measure(widget, availableWidth, availableHeight)
    return widget.desiredWidth or 0, widget.desiredHeight or 0
end

---@param widget Widget The widget being arranged
---@param contentX number X position of content area (after padding)
---@param contentY number Y position of content area (after padding)
---@param contentWidth number Width of content area (after padding)
---@param contentHeight number Height of content area (after padding)
function LayoutStrategy:arrangeChildren(widget, contentX, contentY, contentWidth, contentHeight)
end

---@param spacing number Gap between children in pixels
---@return LayoutStrategy self for method chaining
function LayoutStrategy:setSpacing(spacing)
    if type(spacing) ~= "number" then
        error(("spacing must be a number, got %s"):format(type(spacing)))
    end
    if spacing ~= spacing then
        error("spacing must not be NaN")
    end
    if spacing < 0 then
        error(("spacing must be non-negative, got %s"):format(tostring(spacing)))
    end
    self.spacing = spacing
    return self
end

---@return number spacing Gap between children in pixels
function LayoutStrategy:getSpacing()
    return self.spacing
end

return LayoutStrategy
