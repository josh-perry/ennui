local DockLayoutStrategy = require("ennui.layout.dock_layout_strategy")
local DockNode = require("ennui.docking.docknode")
local Splitter = require("ennui.docking.widgets.splitter")
local TabBar = require("ennui.widgets.tabbar")
local Widget = require("ennui.widget")

---Check if a tab bar should be shown for a leaf node
---Show if more than 1 widget, OR if exactly 1 widget that is docked
---@param node DockNode The leaf node to check
---@return boolean
local function shouldShowTabBar(node)
    return #node.dockedWidgets > 1 or
        (#node.dockedWidgets == 1 and node.dockedWidgets[1].props.isDocked)
end

---@class DockSpace : Widget
---@field dockTree DockNode Root node of docking hierarchy
---@field layoutStrategy DockLayoutStrategy Layout strategy for dock tree
---@field isDockable boolean Whether to accept docking operations
---@field backgroundColor number[] Background color
---@field dividerColor number[] Divider color
---@field dividerHoverColor number[] Divider color when hovered
---@field dropZoneColor number[] Drop zone highlight color
---@field dropZoneSize number Size of edge drop zones (default 40)
---@field splitters Widget[] Active splitter widgets
---@field highlightedZone table? Currently highlighted drop zone
---@field previewOverlay table? Preview rectangle during drag
local DockSpace = setmetatable({}, Widget)
DockSpace.__index = DockSpace
setmetatable(DockSpace, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end
})

---Creates a new DockSpace
---@return DockSpace
function DockSpace.new()
    local self = setmetatable(Widget(), DockSpace) ---@cast self DockSpace

    self.dockTree = DockNode()
    self.layoutStrategy = DockLayoutStrategy(self.dockTree)
    self.isDockable = true

    self:addProperty("backgroundColor", {0.15, 0.15, 0.15})
    self:addProperty("dividerColor", {0.3, 0.3, 0.3})
    self:addProperty("dividerHoverColor", {0.5, 0.5, 0.5})
    self:addProperty("dropZoneColor", {0.2, 0.6, 1})
    self:addProperty("dropZoneSize", 40)

    self.splitters = {}
    self.highlightedZone = nil
    self.previewOverlay = nil

    return self
end

---Dock a widget to a drop zone
---@param widget Widget Widget to dock
---@param zone table Drop zone {type, bounds, targetNode, previewBounds}
---@return boolean success
function DockSpace:dock(widget, zone)
    if not zone or not zone.targetNode then
        return false
    end

    local node = zone.targetNode

    if zone.type == "center" then
        node:addWidget(widget, true)
        self:invalidateLayout()
        return true
    else
        local direction = (zone.type == "left" or zone.type == "right") and "horizontal" or "vertical"

        if node:isSplit() then
            self:insertSplitAtEdge(node, widget, zone.type)
        else
            local moveExistingToLeft = (zone.type == "right" or zone.type == "bottom")
            node:split(direction, 0.5, moveExistingToLeft)

            if zone.type == "left" or zone.type == "top" then
                node.leftChild:addWidget(widget, true)
            else
                node.rightChild:addWidget(widget, true)
            end
        end

        self:invalidateLayout()
        return true
    end
end

---Undock a widget and promote remaining content
---@param widget Widget Widget to undock
---@return boolean success
function DockSpace:undock(widget)
    local node = self.dockTree:findNodeContainingWidget(widget)
    if not node then
        return false
    end

    if not node:removeWidget(widget) then
        return false
    else
        widget:bringToFront()
    end

    if node:isEmpty() and node.parent then
        self:collapseEmptyNode(node)
    end

    self:invalidateLayout()
    return true
end

---Find the DockNode at a point
---@param x number X coordinate
---@param y number Y coordinate
---@return DockNode?
function DockSpace:findNodeAtPoint(x, y)
    if not self.dockTree then
        return nil
    end

    return self:findNodeAtPointRecursive(self.dockTree, x, y)
end

---Recursively find node at point
---@param node DockNode
---@param x number
---@param y number
---@return DockNode?
function DockSpace:findNodeAtPointRecursive(node, x, y)
    if not node.bounds then
        return nil
    end

    if x < node.bounds.x or x > node.bounds.x + node.bounds.width or
       y < node.bounds.y or y > node.bounds.y + node.bounds.height then
        return nil
    end

    if node:isSplit() then
        if node.leftChild then
            local result = self:findNodeAtPointRecursive(node.leftChild, x, y)
            if result then
                return result
            end
        end
        if node.rightChild then
            local result = self:findNodeAtPointRecursive(node.rightChild, x, y)
            if result then
                return result
            end
        end
    end

    return node
end

---Get all drop zones at a point
---@param x number X coordinate
---@param y number Y coordinate
---@return table[] Drop zones at this point
function DockSpace:getDropZonesAtPoint(x, y)
    local node = self:findNodeAtPoint(x, y)

    if not node or not node:isLeaf() then
        return {}
    end

    local zones = self.layoutStrategy:getDropZonesForNode(node, self.props.dropZoneSize)
    local result = {}

    for _, zone in ipairs(zones) do
        if self:pointInBounds(x, y, zone.bounds) then
            table.insert(result, zone)
        end
    end

    return result
end

---Get the highest priority drop zone (prefer center > edges)
---@param x number X coordinate
---@param y number Y coordinate
---@return table? Best drop zone
---@return DockSpace? The dock space that owns this zone
function DockSpace:getDropZoneAtPoint(x, y)
    local zones = self:getDropZonesAtPoint(x, y)

    for _, zone in ipairs(zones) do
        if zone.type == "center" then
            return zone, self
        end
    end

    return zones[1], self
end

---Check if point is in bounds
---@param x number
---@param y number
---@param bounds table {x, y, width, height}
---@return boolean
function DockSpace:pointInBounds(x, y, bounds)
    return x >= bounds.x and x < bounds.x + bounds.width and
           y >= bounds.y and y < bounds.y + bounds.height
end

---Show drop zone highlight and preview
---@param zone table Drop zone
---@return self
function DockSpace:showZonePreview(zone)
    self.highlightedZone = zone
    self.previewOverlay = zone.previewBounds
    self:invalidateRender()
    return self
end

---Hide drop zone preview
---@return self
function DockSpace:hideZonePreview()
    self.highlightedZone = nil
    self.previewOverlay = nil
    self:invalidateRender()
    return self
end

---Insert a new split at an edge of an existing split node
---@param node DockNode
---@param widget Widget Widget to add
---@param edgeType string "left"|"right"|"top"|"bottom"
function DockSpace:insertSplitAtEdge(node, widget, edgeType)
    if edgeType == "left" or edgeType == "top" then
        if node.leftChild and node.leftChild:isLeaf() then
            node.leftChild:addWidget(widget, true)
        elseif node.rightChild and node.rightChild:isLeaf() then
            local newNode = DockNode()
            local direction = (edgeType == "left") and "horizontal" or "vertical"
            newNode:split(direction, 0.5)
            newNode.rightChild:addWidget(widget, true)
            node.leftChild = newNode
            newNode.parent = node
        end
    else
        if node.rightChild and node.rightChild:isLeaf() then
            node.rightChild:addWidget(widget, true)
        elseif node.leftChild and node.leftChild:isLeaf() then
            local newNode = DockNode()
            local direction = (edgeType == "right") and "horizontal" or "vertical"
            newNode:split(direction, 0.5)
            newNode.leftChild:addWidget(widget, true)
            node.rightChild = newNode
            newNode.parent = node
        end
    end
end

---Collapse an empty node by promoting its sibling
---@param emptyNode DockNode
function DockSpace:collapseEmptyNode(emptyNode)
    if not emptyNode:isEmpty() then
        return
    end

    local parent = emptyNode.parent
    if not parent or not parent:isSplit() then
        return
    end

    local sibling
    if parent.leftChild == emptyNode then
        sibling = parent.rightChild
    else
        sibling = parent.leftChild
    end

    if not sibling then
        return
    end

    if emptyNode.tabBar then
        self:removeChild(emptyNode.tabBar)
        emptyNode.tabBar = nil
    end

    if parent.tabBar then
        self:removeChild(parent.tabBar)
        parent.tabBar = nil
    end

    local function removeTabBarsFromNode(node)
        if node:isLeaf() then
            if node.tabBar then
                self:removeChild(node.tabBar)
                node.tabBar = nil
            end
        else
            if node.leftChild then removeTabBarsFromNode(node.leftChild) end
            if node.rightChild then removeTabBarsFromNode(node.rightChild) end
        end
    end

    removeTabBarsFromNode(sibling)

    parent.splitDirection = sibling.splitDirection
    parent.splitRatio = sibling.splitRatio
    parent.leftChild = sibling.leftChild
    parent.rightChild = sibling.rightChild
    parent.dockedWidgets = sibling.dockedWidgets
    parent.activeTabIndex = sibling.activeTabIndex
    parent.tabBar = nil

    if parent.leftChild then
        parent.leftChild.parent = parent
    end
    if parent.rightChild then
        parent.rightChild.parent = parent
    end
end

---Measure the dock space
---@param availableWidth number
---@param availableHeight number
---@return number, number
function DockSpace:measure(availableWidth, availableHeight)
    local desiredWidth, desiredHeight

    local prefWidth = self.preferredWidth
    if type(prefWidth) == "number" then
        desiredWidth = prefWidth
    elseif type(prefWidth) == "table" then
        if prefWidth.type == "fill" then
            desiredWidth = availableWidth
        elseif prefWidth.type == "fixed" then
            desiredWidth = prefWidth.value
        elseif prefWidth.type == "percent" then
            desiredWidth = availableWidth * prefWidth.value
        end
    end

    local prefHeight = self.preferredHeight
    if type(prefHeight) == "number" then
        desiredHeight = prefHeight
    elseif type(prefHeight) == "table" then
        if prefHeight.type == "fill" then
            desiredHeight = availableHeight
        elseif prefHeight.type == "fixed" then
            desiredHeight = prefHeight.value
        elseif prefHeight.type == "percent" then
            desiredHeight = availableHeight * prefHeight.value
        end
    end

    -- Always measure children so they have valid desiredWidth/Height for arrange
    local contentWidth, contentHeight = 0, 0
    if self.layoutStrategy then
        contentWidth, contentHeight = self.layoutStrategy:measure(self, availableWidth, availableHeight)
    end

    -- Use measured content size if own size wasn't determined
    desiredWidth = desiredWidth or contentWidth
    desiredHeight = desiredHeight or contentHeight

    self.desiredWidth = desiredWidth
    self.desiredHeight = desiredHeight

    return desiredWidth, desiredHeight
end

---Arrange children (position dock tree)
---@param contentX number
---@param contentY number
---@param contentWidth number
---@param contentHeight number
function DockSpace:arrangeChildren(contentX, contentY, contentWidth, contentHeight)
    if self.layoutStrategy then
        self.layoutStrategy:arrangeChildren(self, contentX, contentY, contentWidth, contentHeight)
    end

    self:updateTabBars()
    self:updateSplitters()
end

---Update splitter widgets based on dock tree
function DockSpace:updateSplitters()
    for _, splitter in ipairs(self.splitters) do
        self:removeChild(splitter)
    end
    self.splitters = {}

    self.dockTree:traverse(function(node)
        if node:isSplit() then
            self:createSplitterForNode(node)
        end
    end)
end

---Create a splitter widget for a split node
---@param node DockNode
function DockSpace:createSplitterForNode(node)
    if not node.bounds then
        return
    end

    local splitter = Splitter(node.splitDirection)
    splitter:setMinSize(node.minSize)

    splitter.props.normalColor = self.props.dividerColor
    splitter.props.hoverColor = self.props.dividerHoverColor

    if node.splitDirection == "horizontal" then
        local splitterX = node.bounds.x + node.bounds.width * node.splitRatio
        splitter:arrange(splitterX - 2, node.bounds.y, 4, node.bounds.height)
    else
        local splitterY = node.bounds.y + node.bounds.height * node.splitRatio
        splitter:arrange(node.bounds.x, splitterY - 2, node.bounds.width, 4)
    end

    splitter.onSplitterDrag = function(delta)
        local parentSize
        if node.splitDirection == "horizontal" then
            parentSize = node.bounds.width
        else
            parentSize = node.bounds.height
        end

        if parentSize > 0 then
            local newRatio = node.splitRatio + (delta / parentSize)
            newRatio = math.max(0.1, math.min(0.9, newRatio))
            node:setRatio(newRatio)
            self:invalidateLayout()
        end
    end

    self:addChild(splitter)
    table.insert(self.splitters, splitter)
end

---Update tab bars based on dock tree
function DockSpace:updateTabBars()
    self.dockTree:traverse(function(node)
        if node:isLeaf() and #node.dockedWidgets > 0 then
            if not shouldShowTabBar(node) then
                if node.tabBar then
                    self:removeChild(node.tabBar)
                    node.tabBar = nil
                end

                return
            end

            if not node.tabBar then
                node.tabBar = TabBar(node)
                self:addChild(node.tabBar)
            end

            if node.bounds then
                local tabBarHeight = 30
                node.tabBar:arrange(node.bounds.x, node.bounds.y, node.bounds.width, tabBarHeight)
                node.tabBar:setVisible(true)
            end

            if #node.tabBar.tabs ~= #node.dockedWidgets then
                node.tabBar:clearTabs()

                for i, widget in ipairs(node.dockedWidgets) do
                    local title = (widget.props and widget.props.title) or widget.id or ("Tab " .. i)
                    node.tabBar:addTab(title, widget)
                end
            end

            if node.tabBar.activeIndex ~= node.activeTabIndex then
                node.tabBar.activeIndex = node.activeTabIndex
                node.tabBar:invalidateRender()
            end

            node.tabBar.onTabChanged = function(index)
                node:setActiveTab(index)
                self:invalidateLayout()
            end

            node.tabBar.onTabClosed = function(index, widget)
                if widget then
                    local found = false

                    for _, w in ipairs(node.dockedWidgets) do
                        if w == widget then
                            found = true
                            break
                        end
                    end

                    if found then
                        widget:setVisible(false)
                        node:removeWidget(widget)
                        if node:isEmpty() and node.parent then
                            self:collapseEmptyNode(node)
                        end
                        self:invalidateLayout()
                    end
                end
            end
        elseif node:isLeaf() and node.tabBar then
            self:removeChild(node.tabBar)
            node.tabBar = nil
        end
    end)
end

---Render the dock space and previews
function DockSpace:onRender()
    love.graphics.setColor(self.props.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    self.dockTree:traverse(function(node)
        if node:isLeaf() then
            for _, widget in ipairs(node.dockedWidgets) do
                if widget:isVisible() then
                    widget:onRender()
                end
            end
        end
    end)

    self.dockTree:traverse(function(node)
        if node.tabBar and node.tabBar:isVisible() then
            node.tabBar:onRender()
        end
    end)

    for _, splitter in ipairs(self.splitters) do
        if splitter:isVisible() then
            splitter:onRender()
        end
    end

    if self.highlightedZone then
        love.graphics.setColor(self.props.dropZoneColor[1], self.props.dropZoneColor[2], self.props.dropZoneColor[3], 0.3)

        local zone = self.highlightedZone
        ---@diagnostic disable-next-line: need-check-nil
        love.graphics.rectangle("fill", self.highlightedZone.bounds.x, zone.bounds.y, zone.bounds.width, zone.bounds.height)
    end

    if self.previewOverlay then
        local preview = self.previewOverlay

        love.graphics.setColor(self.props.dropZoneColor[1], self.props.dropZoneColor[2], self.props.dropZoneColor[3], 0.5)
        ---@diagnostic disable-next-line: need-check-nil
        love.graphics.rectangle("fill", preview.x, preview.y, preview.width, preview.height)

        love.graphics.setColor(self.props.dropZoneColor[1], self.props.dropZoneColor[2], self.props.dropZoneColor[3], 0.8)
        ---@diagnostic disable-next-line: need-check-nil
        love.graphics.rectangle("line", preview.x, preview.y, preview.width, preview.height, 2)
    end
end

---Find a node containing a specific widget
---@param widget Widget
---@return DockNode?
function DockSpace:findNodeContaining(widget)
    return self.dockTree:findNodeContainingWidget(widget)
end

return DockSpace
