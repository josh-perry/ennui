---@class DockNode
---@field parent DockNode? Parent node in the tree
---@field leftChild DockNode? Left/top child (for split nodes)
---@field rightChild DockNode? Right/bottom child (for split nodes)
---@field splitDirection "horizontal"|"vertical"? Split direction (nil if leaf)
---@field splitRatio number Position of splitter (0-1, only used if split)
---@field dockedWidgets Widget[] Widgets in this node (only used if leaf)
---@field activeTabIndex number Index of active widget (1-based, only if tabbed)
---@field tabBar TabBar? Tab bar widget (created when multiple widgets)
---@field bounds table? Calculated bounds {x, y, width, height}
---@field minSize number Minimum size for this node (default 100px)
local DockNode = {}
DockNode.__index = DockNode
setmetatable(DockNode, {
    __call = function(class, ...)
        return class.new(...)
    end
})

---Creates a new DockNode
---@return DockNode
function DockNode.new()
    local self = setmetatable({}, DockNode)

    self.parent = nil
    self.leftChild = nil
    self.rightChild = nil
    self.splitDirection = nil
    self.splitRatio = 0.5

    self.dockedWidgets = {}
    self.activeTabIndex = 1
    self.tabBar = nil

    self.bounds = {x = 0, y = 0, width = 0, height = 0}
    self.minSize = 100

    return self
end

---Check if this is a leaf node (contains widgets, not split)
---@return boolean
function DockNode:isLeaf()
    return self.splitDirection == nil
end

---Check if this is a split node (has children)
---@return boolean
function DockNode:isSplit()
    return self.splitDirection ~= nil
end

---Check if this node is empty
---@return boolean
function DockNode:isEmpty()
    return self:isLeaf() and #self.dockedWidgets == 0
end

---Split this leaf node into two children
---@param direction "horizontal"|"vertical"
---@param ratio number? Split ratio (default 0.5)
---@param moveExistingToLeft boolean? If true, move existing widgets to left/top child (default false = right/bottom)
---@return self
function DockNode:split(direction, ratio, moveExistingToLeft)
    if not self:isLeaf() then
        error("Cannot split a non-leaf node")
    end

    if direction ~= "horizontal" and direction ~= "vertical" then
        error("Direction must be 'horizontal' or 'vertical'")
    end

    self.splitDirection = direction
    self.splitRatio = ratio or 0.5

    self.leftChild = DockNode()
    self.leftChild.parent = self

    self.rightChild = DockNode()
    self.rightChild.parent = self

    if #self.dockedWidgets > 0 then
        local targetChild = moveExistingToLeft and self.leftChild or self.rightChild
        assert(targetChild, "Target child should not be nil")

        for _, widget in ipairs(self.dockedWidgets) do
            table.insert(targetChild.dockedWidgets, widget)
        end

        targetChild.activeTabIndex = self.activeTabIndex
        targetChild.tabBar = self.tabBar
    end

    self.dockedWidgets = {}
    self.tabBar = nil
    self.activeTabIndex = 1

    return self
end

---Merge two child nodes by removing the split
---@return self
function DockNode:merge()
    if not self:isSplit() then
        error("Cannot merge a leaf node")
    end

    if not self.leftChild or not self.rightChild then
        error("Cannot merge node with missing children")
    end

    local contentChild = nil
    if not self.leftChild:isEmpty() then
        contentChild = self.leftChild
    elseif not self.rightChild:isEmpty() then
        contentChild = self.rightChild
    end

    if not contentChild then
        error("Both children are empty")
    end

    self.splitDirection = contentChild.splitDirection
    self.splitRatio = contentChild.splitRatio
    self.leftChild = contentChild.leftChild
    self.rightChild = contentChild.rightChild
    self.dockedWidgets = contentChild.dockedWidgets
    self.activeTabIndex = contentChild.activeTabIndex
    self.tabBar = nil

    if self.leftChild then
        self.leftChild.parent = self
    end
    if self.rightChild then
        self.rightChild.parent = self
    end

    return self
end

---Add a widget to this leaf node
---@param widget Widget Widget to add
---@param makeTab boolean? Whether to create tab for 2+ widgets (default true)
---@return self
function DockNode:addWidget(widget, makeTab)
    if not self:isLeaf() then
        error("Cannot add widget to a split node")
    end

    if makeTab == nil then
        makeTab = true
    end

    table.insert(self.dockedWidgets, widget)

    if #self.dockedWidgets == 1 then
        self.activeTabIndex = 1
    else
        self.activeTabIndex = #self.dockedWidgets
    end

    return self
end

---Remove a widget from this leaf node
---@param widget Widget Widget to remove
---@return boolean true if widget was removed
function DockNode:removeWidget(widget)
    if not self:isLeaf() then
        return false
    end

    for i, w in ipairs(self.dockedWidgets) do
        if w == widget then
            table.remove(self.dockedWidgets, i)

            if #self.dockedWidgets == 0 then
                self.activeTabIndex = 0
            elseif self.activeTabIndex > #self.dockedWidgets then
                self.activeTabIndex = #self.dockedWidgets
            end

            return true
        end
    end

    return false
end

---Remove all widgets from this leaf node
---@return self
function DockNode:clearWidgets()
    if not self:isLeaf() then
        error("Cannot clear widgets from a split node")
    end

    self.dockedWidgets = {}
    self.activeTabIndex = 0
    self.tabBar = nil

    return self
end

---Set the active tab by index
---@param index number Tab index (1-based)
---@return self
function DockNode:setActiveTab(index)
    if not self:isLeaf() then
        error("Cannot set active tab on a split node")
    end

    if index < 1 or index > #self.dockedWidgets then
        error(("Invalid tab index %d (node has %d widgets)"):format(index, #self.dockedWidgets))
    end

    self.activeTabIndex = index
    return self
end

---Get the active widget
---@return Widget?
function DockNode:getActiveWidget()
    if not self:isLeaf() or #self.dockedWidgets == 0 then
        return nil
    end

    return self.dockedWidgets[self.activeTabIndex]
end

---Check if this node has multiple tabbed widgets
---@return boolean
function DockNode:isTabbed()
    return self:isLeaf() and #self.dockedWidgets > 1
end

---Find a node containing a specific widget (recursive search)
---@param widget Widget Widget to find
---@return DockNode?
function DockNode:findNodeContainingWidget(widget)
    if self:isLeaf() then
        for _, w in ipairs(self.dockedWidgets) do
            if w == widget then
                return self
            end
        end

        return nil
    else
        if self.leftChild then
            local result = self.leftChild:findNodeContainingWidget(widget)

            if result then
                return result
            end
        end
        if self.rightChild then
            local result = self.rightChild:findNodeContainingWidget(widget)

            if result then
                return result
            end
        end

        return nil
    end
end

---Get the splitter bounds for a split node
---@return table? Splitter bounds {x, y, width, height} or nil if not split
function DockNode:getSplitterBounds()
    if not self:isSplit() or not self.bounds then
        return nil
    end

    local thickness = 4

    if self.splitDirection == "horizontal" then
        local splitterX = self.bounds.x + self.bounds.width * self.splitRatio

        return {
            x = splitterX - thickness / 2,
            y = self.bounds.y,
            width = thickness,
            height = self.bounds.height
        }
    else
        local splitterY = self.bounds.y + self.bounds.height * self.splitRatio

        return {
            x = self.bounds.x,
            y = splitterY - thickness / 2,
            width = self.bounds.width,
            height = thickness
        }
    end
end

---Update the split ratio and enforce constraints
---@param ratio number New split ratio (0-1)
---@return self
function DockNode:setRatio(ratio)
    if not self:isSplit() then
        error("Cannot set ratio on a leaf node")
    end

    ratio = math.max(0.1, math.min(0.9, ratio))
    self.splitRatio = ratio

    return self
end

---Traverse all nodes in the tree (depth-first)
---@param callback function Called with (node, depth)
---@param depth number? Current depth
function DockNode:traverse(callback, depth)
    depth = depth or 0
    callback(self, depth)

    if self:isSplit() then
        if self.leftChild then
            self.leftChild:traverse(callback, depth + 1)
        end
        if self.rightChild then
            self.rightChild:traverse(callback, depth + 1)
        end
    end
end

---Get all leaf nodes (nodes with widgets)
---@return DockNode[]
function DockNode:getLeafNodes()
    local leaves = {}

    self:traverse(function(node)
        if node:isLeaf() then
            table.insert(leaves, node)
        end
    end)

    return leaves
end

return DockNode
