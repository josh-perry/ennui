local LayoutStrategy = require("ennui.layout.layout_strategy")

---@class OverlayLayoutStrategy : LayoutStrategy
---A layout strategy that allows children to overlap the parent's content.
---Children are positioned based on their alignment and margin properties.
---The parent's size is NOT affected by children (they're absolute overlays).
local OverlayLayoutStrategy = {}
OverlayLayoutStrategy.__index = OverlayLayoutStrategy
setmetatable(OverlayLayoutStrategy, {
    __index = LayoutStrategy,
    __call = function(class, ...)
        return class.new(...)
    end
})

---Creates a new OverlayLayoutstrategy
---@return OverlayLayoutStrategy
function OverlayLayoutStrategy.new()
    local self = setmetatable(LayoutStrategy(), OverlayLayoutStrategy)
    return self
end

---Measures the desired size of a widget with overlay layout
---Note: Overlay children do NOT affect parent sizing
---@param widget Widget The widget being measured
---@param availableWidth number Available width
---@param availableHeight number Available height
---@return number desiredWidth, number desiredHeight
function OverlayLayoutStrategy:measure(widget, availableWidth, availableHeight)
    local contentWidth = availableWidth - widget.padding.left - widget.padding.right
    local contentHeight = availableHeight - widget.padding.top - widget.padding.bottom

    for _, child in ipairs(widget.children) do
        if child.isVisible then
            child:measure(contentWidth, contentHeight)
        end
    end

    local desiredWidth = widget:calculateDesiredWidth(availableWidth)
    local desiredHeight = widget:calculateDesiredHeight(availableHeight)

    if widget.minWidth and widget.minWidth > 0 then
        desiredWidth = math.max(desiredWidth, widget.minWidth)
    end
    if widget.maxWidth and widget.maxWidth > 0 then
        desiredWidth = math.min(desiredWidth, widget.maxWidth)
    end
    if widget.minHeight and widget.minHeight > 0 then
        desiredHeight = math.max(desiredHeight, widget.minHeight)
    end
    if widget.maxHeight and widget.maxHeight > 0 then
        desiredHeight = math.min(desiredHeight, widget.maxHeight)
    end

    return desiredWidth, desiredHeight
end

---Arranges children as overlays using alignment and margin
---@param widget Widget The widget being arranged
---@param contentX number X position of content area (after padding)
---@param contentY number Y position of content area (after padding)
---@param contentWidth number Width of content area (after padding)
---@param contentHeight number Height of content area (after padding)
function OverlayLayoutStrategy:arrangeChildren(widget, contentX, contentY, contentWidth, contentHeight)
    for _, child in ipairs(widget.children) do
        if child.isVisible then
            local childWidth = child.desiredWidth
            local childHeight = child.desiredHeight

            local childX = contentX
            local childY = contentY

            childX = childX + child.margin.left
            childY = childY + child.margin.top

            local availableWidth = contentWidth - child.margin.left - child.margin.right
            local availableHeight = contentHeight - child.margin.top - child.margin.bottom

            if child.horizontalAlignment == "center" then
                childX = contentX + child.margin.left + (availableWidth - childWidth) / 2
            elseif child.horizontalAlignment == "right" then
                childX = contentX + contentWidth - child.margin.right - childWidth
            elseif child.horizontalAlignment == "stretch" then
                childX = contentX + child.margin.left
                childWidth = availableWidth
            end

            if child.verticalAlignment == "center" then
                childY = contentY + child.margin.top + (availableHeight - childHeight) / 2
            elseif child.verticalAlignment == "bottom" then
                childY = contentY + contentHeight - child.margin.bottom - childHeight
            elseif child.verticalAlignment == "stretch" then
                childY = contentY + child.margin.top
                childHeight = availableHeight
            end

            child:arrange(childX, childY, childWidth, childHeight)
        end
    end
end

return OverlayLayoutStrategy
