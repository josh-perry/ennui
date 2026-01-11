local LayoutStrategy = require("ennui.layout.layout_strategy")

---@class DockLayoutStrategy : LayoutStrategy
---@field dockTree DockNode? Root node of the dock tree
---@field splitterThickness number Thickness of splitters (default 4)
---@field dividerColor table Color for splitter widgets
local DockLayoutStrategy = setmetatable({}, LayoutStrategy)
DockLayoutStrategy.__index = DockLayoutStrategy
setmetatable(DockLayoutStrategy, {
    __index = LayoutStrategy,
    __call = function(class, ...)
        return class.new(...)
    end
})

---Check if a tab bar should be shown for a leaf node
---Show if more than 1 widget, OR if exactly 1 widget that is docked
---@param node DockNode The leaf node to check
---@return boolean
local function shouldShowTabBar(node)
    return #node.dockedWidgets > 1 or
        (#node.dockedWidgets == 1 and node.dockedWidgets[1].props.isDocked)
end

---Creates a new DockLayoutStrategy
---@param dockTree DockNode? Root dock node
---@return DockLayoutStrategy
function DockLayoutStrategy.new(dockTree)
    local self = setmetatable(LayoutStrategy.new(), DockLayoutStrategy)

    self.dockTree = dockTree
    self.splitterThickness = 4
    self.dividerColor = {0.3, 0.3, 0.3}

    return self
end

---Measure the dock tree
---@param widget Widget The DockSpace widget
---@param availableWidth number Available width
---@param availableHeight number Available height
---@return number desiredWidth, number desiredHeight
function DockLayoutStrategy:measure(widget, availableWidth, availableHeight)
    if not self.dockTree then
        return 0, 0
    end

    return self:measureNode(self.dockTree, availableWidth, availableHeight)
end

---Recursively measure a node
---@param node DockNode The node to measure
---@param availableWidth number Available width
---@param availableHeight number Available height
---@return number desiredWidth, number desiredHeight
function DockLayoutStrategy:measureNode(node, availableWidth, availableHeight)
    if node:isLeaf() then
        local maxWidth = 0
        local maxHeight = 0

        if #node.dockedWidgets > 0 then
            local activeWidget = node:getActiveWidget()
            if activeWidget then
                activeWidget:measure(availableWidth, availableHeight)
                maxWidth = math.max(maxWidth, activeWidget.desiredWidth or 0)
                maxHeight = math.max(maxHeight, activeWidget.desiredHeight or 0)
            end
        end

        local showTabBar = shouldShowTabBar(node)
        if showTabBar then
            local tabBarHeight = 30
            maxHeight = maxHeight + tabBarHeight
        end

        return maxWidth, maxHeight
    else
        local childCount = 0
        local leftWidth, leftHeight = 0, 0
        local rightWidth, rightHeight = 0, 0

        if node.splitDirection == "horizontal" then
            local splitterWidth = self.splitterThickness
            local leftAvailWidth = (availableWidth - splitterWidth) * node.splitRatio
            local rightAvailWidth = (availableWidth - splitterWidth) * (1 - node.splitRatio)

            if node.leftChild then
                leftWidth, leftHeight = self:measureNode(node.leftChild, leftAvailWidth, availableHeight)
                childCount = childCount + 1
            end

            if node.rightChild then
                rightWidth, rightHeight = self:measureNode(node.rightChild, rightAvailWidth, availableHeight)
                childCount = childCount + 1
            end

            return leftWidth + rightWidth + splitterWidth, math.max(leftHeight, rightHeight)
        else
            local splitterHeight = self.splitterThickness
            local topAvailHeight = (availableHeight - splitterHeight) * node.splitRatio
            local botAvailHeight = (availableHeight - splitterHeight) * (1 - node.splitRatio)

            if node.leftChild then
                leftWidth, leftHeight = self:measureNode(node.leftChild, availableWidth, topAvailHeight)
                childCount = childCount + 1
            end

            if node.rightChild then
                rightWidth, rightHeight = self:measureNode(node.rightChild, availableWidth, botAvailHeight)
                childCount = childCount + 1
            end

            return math.max(leftWidth, rightWidth), leftHeight + rightHeight + splitterHeight
        end
    end
end

---Arrange children (position the dock tree)
---@param widget Widget The DockSpace widget
---@param contentX number Content area X
---@param contentY number Content area Y
---@param contentWidth number Content area width
---@param contentHeight number Content area height
function DockLayoutStrategy:arrangeChildren(widget, contentX, contentY, contentWidth, contentHeight)
    if not self.dockTree then
        return
    end

    self:arrangeNode(self.dockTree, contentX, contentY, contentWidth, contentHeight, widget)
end

---Recursively arrange a node and position it
---@param node DockNode The node to arrange
---@param x number Position X
---@param y number Position Y
---@param width number Width
---@param height number Height
---@param dockSpaceWidget Widget The DockSpace widget for adding splitters
function DockLayoutStrategy:arrangeNode(node, x, y, width, height, dockSpaceWidget)
    node.bounds = {x = x, y = y, width = width, height = height}

    if node:isLeaf() then
        local contentX = x
        local contentY = y
        local contentWidth = width
        local contentHeight = height

        if node.tabBar then
            node.tabBar:setVisible(false)
        end

        if shouldShowTabBar(node) then
            local tabBarHeight = 30
            if node.tabBar then
                node.tabBar:arrange(contentX, contentY, contentWidth, tabBarHeight)
                node.tabBar:setVisible(true)
            end

            contentY = y + tabBarHeight
            contentHeight = height - tabBarHeight
        end

        for _, widget in ipairs(node.dockedWidgets) do
            widget:arrange(contentX, contentY, contentWidth, contentHeight)
        end

        for i, widget in ipairs(node.dockedWidgets) do
            if i == node.activeTabIndex then
                widget:setVisible(true)
            else
                widget:setVisible(false)
            end
        end
    else
        if node.splitDirection == "horizontal" then
            local splitterWidth = self.splitterThickness
            local leftWidth = (width - splitterWidth) * node.splitRatio
            local rightWidth = (width - splitterWidth) * (1 - node.splitRatio)
            local splitterX = x + leftWidth

            if node.leftChild then
                self:arrangeNode(node.leftChild, x, y, leftWidth, height, dockSpaceWidget)
            end

            if node.rightChild then
                self:arrangeNode(node.rightChild, splitterX + splitterWidth, y, rightWidth, height, dockSpaceWidget)
            end
        else
            local splitterHeight = self.splitterThickness
            local topHeight = (height - splitterHeight) * node.splitRatio
            local botHeight = (height - splitterHeight) * (1 - node.splitRatio)
            local splitterY = y + topHeight

            if node.leftChild then
                self:arrangeNode(node.leftChild, x, y, width, topHeight, dockSpaceWidget)
            end

            if node.rightChild then
                self:arrangeNode(node.rightChild, x, splitterY + splitterHeight, width, botHeight, dockSpaceWidget)
            end
        end
    end
end

---Get drop zones for a node (for drag-and-drop detection)
---@param node DockNode The node
---@param dropZoneSize number Size of edge drop zones
---@return table[] Array of drop zone objects
function DockLayoutStrategy:getDropZonesForNode(node, dropZoneSize)
    if not node.bounds then
        return {}
    end

    local zones = {}
    local bounds = node.bounds
    local x, y, w, h = bounds.x, bounds.y, bounds.width, bounds.height

    table.insert(zones, {
        type = "left",
        bounds = {x = x, y = y, width = dropZoneSize, height = h},
        targetNode = node,
        previewBounds = {x = x, y = y, width = w * 0.5, height = h}
    })

    table.insert(zones, {
        type = "right",
        bounds = {x = x + w - dropZoneSize, y = y, width = dropZoneSize, height = h},
        targetNode = node,
        previewBounds = {x = x + w * 0.5, y = y, width = w * 0.5, height = h}
    })

    table.insert(zones, {
        type = "top",
        bounds = {x = x, y = y, width = w, height = dropZoneSize},
        targetNode = node,
        previewBounds = {x = x, y = y, width = w, height = h * 0.5}
    })

    table.insert(zones, {
        type = "bottom",
        bounds = {x = x, y = y + h - dropZoneSize, width = w, height = dropZoneSize},
        targetNode = node,
        previewBounds = {x = x, y = y + h * 0.5, width = w, height = h * 0.5}
    })

    table.insert(zones, {
        type = "center",
        bounds = {x = x + dropZoneSize, y = y + dropZoneSize, width = w - dropZoneSize * 2, height = h - dropZoneSize * 2},
        targetNode = node,
        previewBounds = {x = x, y = y, width = w, height = h}
    })

    return zones
end

return DockLayoutStrategy
