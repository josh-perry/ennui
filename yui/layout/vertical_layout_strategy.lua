local LayoutStrategy = require("yui.layout.layout_strategy")

---@class VerticalLayoutStrategy : LayoutStrategy
local VerticalLayoutStrategy = {}
VerticalLayoutStrategy.__index = VerticalLayoutStrategy
setmetatable(VerticalLayoutStrategy, {
    __index = LayoutStrategy,
    __call = function(class, ...)
        return class.new(...)
    end
})

---Creates a new VerticalLayoutstrategy
---@return VerticalLayoutStrategy
function VerticalLayoutStrategy.new()
    local self = setmetatable(LayoutStrategy(), VerticalLayoutStrategy) ---@cast self VerticalLayoutStrategy
    return self
end

---@param widget Widget The widget being measured
---@param availableWidth number Available width
---@param availableHeight number Available height
---@return number desiredWidth, number desiredHeight
function VerticalLayoutStrategy:measure(widget, availableWidth, availableHeight)
    local contentWidth = availableWidth - widget.padding.left - widget.padding.right
    local contentHeight = availableHeight - widget.padding.top - widget.padding.bottom

    local maxChildWidth = 0
    local totalFixedHeight = 0
    local fillCount = 0
    local fillTotalWeight = 0

    for i, child in ipairs(widget.children) do
        if child:isVisible() then
            if i > 1 then
                totalFixedHeight = totalFixedHeight + self.spacing
            end

            child:measure(contentWidth, contentHeight)

            maxChildWidth = math.max(maxChildWidth, child.desiredWidth)

            if type(child.preferredHeight) == "number" then
                totalFixedHeight = totalFixedHeight + child.desiredHeight
            else
                if child.preferredHeight.type == "fill" then
                    fillCount = fillCount + 1
                    fillTotalWeight = fillTotalWeight + (child.preferredHeight.weight or 1)
                else
                    totalFixedHeight = totalFixedHeight + child.desiredHeight
                end
            end
        end
    end

    local desiredWidth
    local preferredWidth = widget.preferredWidth

    if type(preferredWidth) == "number" then
        desiredWidth = preferredWidth
    else
        if preferredWidth.type == "fixed" then
            desiredWidth = preferredWidth.value
        elseif preferredWidth.type == "percent" then
            desiredWidth = availableWidth * preferredWidth.value
        elseif preferredWidth.type == "auto" then
            desiredWidth = maxChildWidth + widget.padding.left + widget.padding.right
        elseif preferredWidth.type == "fill" then
            desiredWidth = availableWidth
        else
            desiredWidth = 100
        end
    end

    local desiredHeight
    local preferredHeight = widget.preferredHeight

    if type(preferredHeight) == "number" then
        desiredHeight = preferredHeight
    else
        if preferredHeight.type == "fixed" then
            desiredHeight = preferredHeight.value
        elseif preferredHeight.type == "percent" then
            desiredHeight = availableHeight * preferredHeight.value
        elseif preferredHeight.type == "auto" then
            local estimatedFillHeight = fillCount * 20
            desiredHeight = totalFixedHeight + estimatedFillHeight + widget.padding.top + widget.padding.bottom
        elseif preferredHeight.type == "fill" then
            desiredHeight = availableHeight
        else
            desiredHeight = 100
        end
    end

    if widget.minWidth and widget.minWidth > 0 then
        ---@diagnostic disable-next-line: param-type-mismatch
        desiredWidth = math.max(desiredWidth, widget.minWidth)
    end
    if widget.maxWidth and widget.maxWidth > 0 then
        ---@diagnostic disable-next-line: param-type-mismatch
        desiredWidth = math.min(desiredWidth, widget.maxWidth)
    end
    if widget.minHeight and widget.minHeight > 0 then
        ---@diagnostic disable-next-line: param-type-mismatch
        desiredHeight = math.max(desiredHeight, widget.minHeight)
    end
    if widget.maxHeight and widget.maxHeight > 0 then
        ---@diagnostic disable-next-line: param-type-mismatch
        desiredHeight = math.min(desiredHeight, widget.maxHeight)
    end

    assert(desiredWidth, "desiredWidth should be defined")
    assert(desiredHeight, "desiredHeight should be defined")
    return desiredWidth, desiredHeight
end

---@param widget Widget The widget being arranged
---@param contentX number X position of content area (after padding)
---@param contentY number Y position of content area (after padding)
---@param contentWidth number Width of content area (after padding)
---@param contentHeight number Height of content area (after padding)
function VerticalLayoutStrategy:arrangeChildren(widget, contentX, contentY, contentWidth, contentHeight)
    local totalFixedHeight = 0
    local fillTotalWeight = 0

    for i, child in ipairs(widget.children) do
        if child:isVisible() then
            if i > 1 then
                totalFixedHeight = totalFixedHeight + self.spacing
            end

            if type(child.preferredHeight) == "number" then
                totalFixedHeight = totalFixedHeight + child.desiredHeight
            elseif child.preferredHeight.type == "fill" then
                fillTotalWeight = fillTotalWeight + (child.preferredHeight.weight or 1)
            else
                totalFixedHeight = totalFixedHeight + child.desiredHeight
            end
        end
    end

    local remainingHeight = contentHeight - totalFixedHeight

    local currentY = contentY
    for i, child in ipairs(widget.children) do
        if child:isVisible() then
            if i > 1 then
                currentY = currentY + self.spacing
            end

            local childHeight
            if type(child.preferredHeight) == "number" then
                childHeight = child.desiredHeight
            elseif child.preferredHeight.type == "fill" then
                local weight = child.preferredHeight.weight or 1
                childHeight = remainingHeight * (weight / fillTotalWeight)
            else
                childHeight = child.desiredHeight
            end

            local childWidth = child.desiredWidth

            local childX = contentX
            if child.horizontalAlignment == "center" then
                childX = contentX + (contentWidth - childWidth) / 2
            elseif child.horizontalAlignment == "right" then
                childX = contentX + contentWidth - childWidth
            elseif child.horizontalAlignment == "stretch" then
                childWidth = contentWidth
            end

            child:arrange(childX, currentY, childWidth, childHeight)

            currentY = currentY + childHeight
        end
    end
end

return VerticalLayoutStrategy
