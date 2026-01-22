local LayoutStrategy = require("ennui.layout.layout_strategy")

---@class GridLayoutStrategy : LayoutStrategy
---@field columns number? Number of columns in the grid (nil = auto-calculate)
---@field rows number? Number of rows in the grid (nil = auto-calculate)
---@field rowSpacing number Vertical spacing between rows
---@field columnSpacing number Horizontal spacing between columns
local GridLayoutStrategy = {}
GridLayoutStrategy.__index = GridLayoutStrategy
setmetatable(GridLayoutStrategy, {
    __index = LayoutStrategy,
    __call = function(class, ...)
        return class.new(...)
    end
})

---Creates a new GridLayoutstrategy
---@param columns number? Number of columns (default: auto-calculate based on rows, or 1 if rows not set)
---@param rows number? Number of rows (default: auto-calculate based on columns and child count)
---@return GridLayoutStrategy
function GridLayoutStrategy.new(columns, rows)
    local self = setmetatable(LayoutStrategy(), GridLayoutStrategy) ---@cast self GridLayoutStrategy
    self.columns = columns
    self.rows = rows
    self.rowSpacing = 0
    self.columnSpacing = 0
    return self
end

---Set the number of columns
---@param columns number? Number of columns (nil = auto-calculate)
---@return GridLayoutStrategy self
function GridLayoutStrategy:setColumns(columns)
    self.columns = columns
    return self
end

---Set the number of rows
---@param rows number? Number of rows (nil = auto-calculate)
---@return GridLayoutStrategy self
function GridLayoutStrategy:setRows(rows)
    self.rows = rows
    return self
end

---Set row spacing
---@param spacing number Vertical spacing between rows
---@return GridLayoutStrategy self
function GridLayoutStrategy:setRowSpacing(spacing)
    if type(spacing) ~= "number" then
        error(("row spacing must be a number, got %s"):format(type(spacing)))
    end
    if spacing ~= spacing then
        error("row spacing must not be NaN")
    end
    if spacing < 0 then
        error(("row spacing must be non-negative, got %s"):format(tostring(spacing)))
    end
    self.rowSpacing = spacing
    return self
end

---Set column spacing
---@param spacing number Horizontal spacing between columns
---@return GridLayoutStrategy self
function GridLayoutStrategy:setColumnSpacing(spacing)
    if type(spacing) ~= "number" then
        error(("column spacing must be a number, got %s"):format(type(spacing)))
    end
    if spacing ~= spacing then
        error("column spacing must not be NaN")
    end
    if spacing < 0 then
        error(("column spacing must be non-negative, got %s"):format(tostring(spacing)))
    end
    self.columnSpacing = spacing
    return self
end

---Set both row and column spacing
---@param spacing number Spacing for both rows and columns
---@return GridLayoutStrategy self
function GridLayoutStrategy:setSpacing(spacing)
    self.rowSpacing = spacing
    self.columnSpacing = spacing
    return self
end

---Measures the desired size of a widget with grid layout
---@param widget Widget The widget being measured
---@param availableWidth number Available width
---@param availableHeight number Available height
---@return number desiredWidth, number desiredHeight
function GridLayoutStrategy:measure(widget, availableWidth, availableHeight)
    local contentWidth = availableWidth - widget.padding.left - widget.padding.right
    local contentHeight = availableHeight - widget.padding.top - widget.padding.bottom

    local visibleChildren = {}
    for _, child in ipairs(widget.children) do
        if child:isVisible() then
            table.insert(visibleChildren, child)
        end
    end

    local childCount = #visibleChildren
    if childCount == 0 then
        return widget:calculateDesiredWidth(availableWidth),
               widget:calculateDesiredHeight(availableHeight)
    end

    local numColumns, numRows
    if self.rows then
        numRows = self.rows
        numColumns = math.ceil(childCount / numRows)
    else
        numColumns = self.columns or 1
        numRows = math.ceil(childCount / numColumns)
    end

    local totalColumnSpacing = (numColumns - 1) * self.columnSpacing
    local totalRowSpacing = (numRows - 1) * self.rowSpacing

    local availableCellWidth = (contentWidth - totalColumnSpacing) / numColumns
    local availableCellHeight = contentHeight / numRows

    local columnWidths = {}
    local rowHeights = {}

    for i = 1, numColumns do
        columnWidths[i] = 0
    end

    for i = 1, numRows do
        rowHeights[i] = 0
    end

    for i, child in ipairs(visibleChildren) do
        local row = math.floor((i - 1) / numColumns) + 1
        local col = ((i - 1) % numColumns) + 1

        child:measure(availableCellWidth, availableCellHeight)

        columnWidths[col] = math.max(columnWidths[col], child.desiredWidth)
        rowHeights[row] = math.max(rowHeights[row], child.desiredHeight)
    end

    local totalWidth = 0
    for _, width in ipairs(columnWidths) do
        totalWidth = totalWidth + width
    end
    totalWidth = totalWidth + totalColumnSpacing

    local totalHeight = 0
    for _, height in ipairs(rowHeights) do
        totalHeight = totalHeight + height
    end
    totalHeight = totalHeight + totalRowSpacing

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
            desiredWidth = totalWidth + widget.padding.left + widget.padding.right
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
            desiredHeight = totalHeight + widget.padding.top + widget.padding.bottom
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

---Arranges children in a grid layout
---@param widget Widget The widget being arranged
---@param contentX number X position of content area (after padding)
---@param contentY number Y position of content area (after padding)
---@param contentWidth number Width of content area (after padding)
---@param contentHeight number Height of content area (after padding)
function GridLayoutStrategy:arrangeChildren(widget, contentX, contentY, contentWidth, contentHeight)
    local visibleChildren = {}

    for _, child in ipairs(widget.children) do
        if child:isVisible() then
            table.insert(visibleChildren, child)
        end
    end

    local childCount = #visibleChildren
    if childCount == 0 then return end

    local numColumns, numRows
    if self.rows then
        numRows = self.rows
        numColumns = self.columns or math.ceil(childCount / numRows)

        while numRows * numColumns < childCount do
            numRows = numRows + 1
        end
    else
        numColumns = self.columns or 1
        numRows = math.ceil(childCount / numColumns)
    end

    local totalColumnSpacing = (numColumns - 1) * self.columnSpacing
    local totalRowSpacing = (numRows - 1) * self.rowSpacing

    local columnWidths = {}
    local rowHeights = {}

    for i = 1, numColumns do
        columnWidths[i] = 0
    end

    for i = 1, numRows do
        rowHeights[i] = 0
    end

    local cellWidth = (contentWidth - totalColumnSpacing) / numColumns
    local cellHeight = (contentHeight - totalRowSpacing) / numRows

    for i, child in ipairs(visibleChildren) do
        local row = math.floor((i - 1) / numColumns) + 1
        local col = ((i - 1) % numColumns) + 1

        local childWidth = math.min(child.desiredWidth, cellWidth)
        local childHeight = math.min(child.desiredHeight, cellHeight)

        columnWidths[col] = math.max(columnWidths[col], childWidth)
        rowHeights[row] = math.max(rowHeights[row], childHeight)
    end

    local totalUsedWidth = 0
    for _, width in ipairs(columnWidths) do
        totalUsedWidth = totalUsedWidth + width
    end

    local extraWidth = contentWidth - totalUsedWidth - totalColumnSpacing
    if extraWidth > 0 then
        local extraPerColumn = extraWidth / numColumns

        for i = 1, numColumns do
            columnWidths[i] = columnWidths[i] + extraPerColumn
        end
    end

    local totalUsedHeight = 0
    for _, height in ipairs(rowHeights) do
        totalUsedHeight = totalUsedHeight + height
    end

    local extraHeight = contentHeight - totalUsedHeight - totalRowSpacing
    if extraHeight > 0 then
        local extraPerRow = extraHeight / numRows

        for i = 1, numRows do
            rowHeights[i] = rowHeights[i] + extraPerRow
        end
    end

    local currentY = contentY

    for row = 1, numRows do
        local currentX = contentX

        for col = 1, numColumns do
            local childIndex = (row - 1) * numColumns + col
            if childIndex <= childCount then
                local child = visibleChildren[childIndex]

                local cellW = columnWidths[col]
                local cellH = rowHeights[row]

                local childWidth = math.min(child.desiredWidth, cellW)
                local childHeight = math.min(child.desiredHeight, cellH)

                local childX = currentX

                if child.horizontalAlignment == "center" then
                    childX = currentX + (cellW - childWidth) / 2
                elseif child.horizontalAlignment == "right" then
                    childX = currentX + cellW - childWidth
                elseif child.horizontalAlignment == "stretch" then
                    childWidth = cellW
                end

                local childY = currentY

                if child.verticalAlignment == "center" then
                    childY = currentY + (cellH - childHeight) / 2
                elseif child.verticalAlignment == "bottom" then
                    childY = currentY + cellH - childHeight
                elseif child.verticalAlignment == "stretch" then
                    childHeight = cellH
                end

                child:arrange(childX, childY, childWidth, childHeight)
            end

            currentX = currentX + columnWidths[col] + self.columnSpacing
        end

        currentY = currentY + rowHeights[row] + self.rowSpacing
    end
end

return GridLayoutStrategy
