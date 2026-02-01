local LayoutStrategy = require("ennui.layout.layout_strategy")

---@class HorizontalLayoutStrategy : LayoutStrategy
local HorizontalLayoutStrategy = {}
HorizontalLayoutStrategy.__index = HorizontalLayoutStrategy
setmetatable(HorizontalLayoutStrategy, {
    __index = LayoutStrategy,
    __call = function(class, ...)
        return class.new(...)
    end
})

---Creates a new HorizontalLayoutstrategy
---@return HorizontalLayoutStrategy
function HorizontalLayoutStrategy.new()
    local self = setmetatable(LayoutStrategy(), HorizontalLayoutStrategy) ---@cast self HorizontalLayoutStrategy
    return self
end

---Measures the desired size of a widget with horizontal layout
---@param widget Widget The widget being measured
---@param availableWidth number Available width
---@param availableHeight number Available height
---@return number desiredWidth, number desiredHeight
function HorizontalLayoutStrategy:measure(widget, availableWidth, availableHeight)
    local contentWidth = availableWidth - widget.padding.left - widget.padding.right
    local contentHeight = availableHeight - widget.padding.top - widget.padding.bottom

    local maxChildHeight = 0
    local totalFixedWidth = 0
    local fillCount = 0
    local fillTotalWeight = 0
    local percentTotalRatio = 0

    for i, child in ipairs(widget.children) do
        if child:isVisible() then
            if i > 1 then
                totalFixedWidth = totalFixedWidth + self.spacing
            end

            child:measure(contentWidth, contentHeight)

            maxChildHeight = math.max(maxChildHeight, child.desiredHeight)

            if type(child.preferredWidth) == "number" then
                totalFixedWidth = totalFixedWidth + child.desiredWidth
            else
                if child.preferredWidth.type == "fill" then
                    fillCount = fillCount + 1
                    fillTotalWeight = fillTotalWeight + (child.preferredWidth.weight or 1)
                elseif child.preferredWidth.type == "percent" then
                    percentTotalRatio = percentTotalRatio + child.preferredWidth.value
                else
                    totalFixedWidth = totalFixedWidth + child.desiredWidth
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
            local estimatedFillWidth = fillCount * 20
            local estimatedPercentWidth = percentTotalRatio * contentWidth
            desiredWidth = totalFixedWidth + estimatedFillWidth + estimatedPercentWidth + widget.padding.left + widget.padding.right
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
            desiredHeight = maxChildHeight + widget.padding.top + widget.padding.bottom
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

---Arranges children horizontally with spacing
---@param widget Widget The widget being arranged
---@param contentX number X position of content area (after padding)
---@param contentY number Y position of content area (after padding)
---@param contentWidth number Width of content area (after padding)
---@param contentHeight number Height of content area (after padding)
function HorizontalLayoutStrategy:arrangeChildren(widget, contentX, contentY, contentWidth, contentHeight)
    -- First pass: Calculate fixed widths and identify fill/percent children
    local totalFixedWidth = 0
    local fillTotalWeight = 0
    local percentTotalRatio = 0

    for i, child in ipairs(widget.children) do
        if child:isVisible() then
            if i > 1 then
                totalFixedWidth = totalFixedWidth + self.spacing
            end

            if type(child.preferredWidth) == "number" then
                totalFixedWidth = totalFixedWidth + child.desiredWidth
            elseif child.preferredWidth.type == "fill" then
                fillTotalWeight = fillTotalWeight + (child.preferredWidth.weight or 1)
            elseif child.preferredWidth.type == "percent" then
                percentTotalRatio = percentTotalRatio + child.preferredWidth.value
            else
                totalFixedWidth = totalFixedWidth + child.desiredWidth
            end
        end
    end

    local remainingWidth = math.max(0, contentWidth - totalFixedWidth)

    local clampedPercentRatio = math.min(1.0, percentTotalRatio)

    -- Calculate how much space percent children need
    local percentWidth = remainingWidth * clampedPercentRatio
    local fillWidth = math.max(0, remainingWidth - percentWidth)

    -- Second pass: Arrange children
    local currentX = contentX
    for i, child in ipairs(widget.children) do
        if child:isVisible() then
            if i > 1 then
                currentX = currentX + self.spacing
            end

            local childWidth
            if type(child.preferredWidth) == "number" then
                childWidth = child.desiredWidth
            elseif child.preferredWidth.type == "fill" then
                local weight = child.preferredWidth.weight or 1
                childWidth = fillTotalWeight > 0 and (fillWidth * (weight / fillTotalWeight)) or 0
            elseif child.preferredWidth.type == "percent" then
                -- Calculate percent based on remaining space, not total space
                childWidth = remainingWidth * child.preferredWidth.value
            else
                childWidth = child.desiredWidth
            end

            local childHeight = child.desiredHeight

            local childY = contentY
            if child.verticalAlignment == "center" then
                childY = contentY + (contentHeight - childHeight) / 2
            elseif child.verticalAlignment == "bottom" then
                childY = contentY + contentHeight - childHeight
            elseif child.verticalAlignment == "stretch" then
                childHeight = contentHeight
            end

            child:arrange(currentX, childY, childWidth, childHeight)

            currentX = currentX + childWidth
        end
    end
end

return HorizontalLayoutStrategy
