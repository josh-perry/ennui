local ennui = require("ennui")
local Widget = require("ennui.widget")
local Size = require("ennui.size")
local Text = require("widgets.text")
local HorizontalStackPanel = require("widgets.horizontalstackpanel")
local Rectangle = require("widgets.rectangle")
local AABB = require("ennui.utils.aabb")

---@class TreeViewNode : Widget
---@field label string Node label text
---@field expanded boolean Whether children are visible
---@field selected boolean Whether this node is selected
---@field level number Indentation level (0 = root)
---@field iconSize number Size of expand/collapse icon
---@field textColor number[] RGBA color for label
---@field iconColor number[] RGBA color for expand icon
---@field value any Custom value associated with this node
---@field __textWidget Text Internal Text widget for label
---@field __treeView TreeView? Parent TreeView reference
---@field __rowLayout HorizontalStackPanel Internal layout container for the row
---@field __indentSpacer Rectangle Spacer for indentation
---@field __iconPlaceholder Rectangle Placeholder for expand/collapse icon
local TreeViewNode = {}
TreeViewNode.__index = TreeViewNode
setmetatable(TreeViewNode, {
    __index = Widget,
    __call = function(class, label, value)
        return class.new(label, value)
    end,
})

function TreeViewNode:__tostring()
    return string.format("TreeViewNode(%q)", self.props.label or "")
end

---Create a new tree view node widget
---@param label string? Node label (optional)
---@param value any? Custom value (optional)
---@return TreeViewNode
function TreeViewNode.new(label, value)
    local self = setmetatable(Widget(), TreeViewNode) ---@cast self TreeViewNode

    self:addProperty("label", label or "")
    self:addProperty("expanded", true)
    self:addProperty("selected", false)
    self:addProperty("level", 0)
    self:addProperty("iconSize", 10)
    self:addProperty("textColor", {1, 1, 1, 1})
    self:addProperty("iconColor", {0.6, 0.6, 0.6, 1})
    self:addProperty("value", value)

    self.__treeViewCache = nil

    -- Create internal row layout (NOT added as a child - managed separately)
    self.__rowLayout = HorizontalStackPanel()
        :setSpacing(4)
        :setSize(Size.auto(), Size.auto())
        :setHitTransparent(true)

    -- Create indent spacer (width will be set based on level)
    self.__indentSpacer = Rectangle()
        :setSize(0, 1)
        :setColor(0, 0, 0, 0) -- Invisible

    -- Create icon placeholder
    self.__iconPlaceholder = Rectangle()
        :setSize(self.props.iconSize + 8, self.props.iconSize) -- icon + some padding
        :setColor(0, 0, 0, 0) -- Invisible

    -- Create text widget
    self.__textWidget = Text()
        :setTextVerticalAlignment("center")
        :setSize(Size.auto(), Size.auto())

    -- Build row layout structure (but don't add to self.children)
    self.__rowLayout:addChild(self.__indentSpacer)
    self.__rowLayout:addChild(self.__iconPlaceholder)
    self.__rowLayout:addChild(self.__textWidget)

    self:watch("label", function(newLabel)
        self.__textWidget.props.text = newLabel
        self:invalidateLayout()
    end, { immediate = true })

    self:watch("textColor", function(newColor)
        self.__textWidget.props.color = newColor
        self:invalidateRender()
    end, { immediate = true })

    self:watch("iconSize", function(newSize)
        self.__iconPlaceholder:setSize(newSize + 8, newSize)
        self:invalidateLayout()
    end)

    local strategy = ennui.Layout.Vertical()
    strategy.spacing = 0
    self:setLayoutStrategy(strategy)

    self:setFocusable(true)

    return self
end

---Find the TreeView ancestor (lazy lookup)
---@return TreeView?
function TreeViewNode:__getTreeView()
    if self.__treeViewCache then
        return self.__treeViewCache
    end
    local current = self.parent
    while current do
        if current.selectNode then -- Duck-type check for TreeView
            self.__treeViewCache = current
            return current
        end
        current = current.parent
    end
    return nil
end

---Called when node is mounted
function TreeViewNode:onMount()
    -- Calculate level based on parent chain
    local level = 0
    local current = self.parent
    while current do
        if current.props and current.props.level ~= nil then
            level = current.props.level + 1
            break
        elseif current.selectNode then
            break
        end
        current = current.parent
    end
    self.props.level = level

    -- Update indent spacer width
    self:__updateIndentWidth()
end

---Update the indent spacer width based on current level
---@private
function TreeViewNode:__updateIndentWidth()
    local indentSize = self:__getIndentSize()
    local level = self:__getLevel()
    self.__indentSpacer:setSize(level * indentSize, 1)
end

---Toggle expanded state
---@return TreeViewNode self
function TreeViewNode:toggle()
    if #self.children > 0 then
        self.props.expanded = not self.props.expanded
        self:invalidateLayout()
    end
    return self
end

---Set expanded state
---@param expanded boolean Whether children are visible
---@return TreeViewNode self
function TreeViewNode:setExpanded(expanded)
    self.props.expanded = expanded
    return self
end

---Get expanded state
---@return boolean expanded
function TreeViewNode:isExpanded()
    return self.props.expanded
end

---Set the node label
---@param label string Label text
---@return TreeViewNode self
function TreeViewNode:setLabel(label)
    self.props.label = label
    return self
end

---Get the node label
---@return string label
function TreeViewNode:getLabel()
    return self.props.label
end

---Set the custom value
---@param value any Custom value
---@return TreeViewNode self
function TreeViewNode:setValue(value)
    self.props.value = value
    return self
end

---Get the custom value
---@return any value
function TreeViewNode:getValue()
    return self.props.value
end

---Set text color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TreeViewNode self
function TreeViewNode:setTextColor(r, g, b, a)
    self.props.textColor = {r, g, b, a or 1}
    return self
end

---Set icon color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TreeViewNode self
function TreeViewNode:setIconColor(r, g, b, a)
    self.props.iconColor = {r, g, b, a or 1}
    return self
end

---Check if node has children
---@return boolean hasChildren
function TreeViewNode:hasChildren()
    return #self.children > 0
end

---Get row height from TreeView or default
---@return number rowHeight
function TreeViewNode:__getRowHeight()
    if self:__getTreeView() then
        return self:__getTreeView().props.rowHeight
    end
    return 24
end

---Get indent size from TreeView or default
---@return number indentSize
function TreeViewNode:__getIndentSize()
    if self:__getTreeView() then
        return self:__getTreeView().props.indentSize
    end
    return 20
end

---Calculate level dynamically based on parent chain
---@return number level
function TreeViewNode:__getLevel()
    local level = 0
    local current = self.parent
    while current do
        -- If parent is a TreeViewNode, count it as a level
        if current.props and current.props.label ~= nil then
            level = level + 1
        elseif current.selectNode then
            -- Reached the TreeView, stop counting
            break
        end
        current = current.parent
    end
    return level
end

---Override measure
function TreeViewNode:measure(availableWidth, availableHeight)
    -- Update indent width in case level changed
    self:__updateIndentWidth()

    -- Measure the row layout (text widget is inside)
    self.__rowLayout:measure(availableWidth, availableHeight)

    local rowHeight = self:__getRowHeight()
    local totalHeight = rowHeight

    -- Measure and count children heights if expanded
    if self.props.expanded and #self.children > 0 then
        for _, child in ipairs(self.children) do
            if child:isVisible() then
                child:measure(availableWidth, availableHeight - totalHeight)
                totalHeight = totalHeight + child.desiredHeight
            end
        end
    end

    local desiredWidth = availableWidth
    local desiredHeight = totalHeight

    desiredWidth, desiredHeight = self:__applyConstraints(desiredWidth, desiredHeight)

    self.desiredWidth = desiredWidth
    self.desiredHeight = desiredHeight
    self.isLayoutDirty = false

    return desiredWidth, desiredHeight
end

---Override arrange
function TreeViewNode:arrange(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    local rowHeight = self:__getRowHeight()

    -- Arrange the row layout for the current node
    self.__rowLayout:arrange(x, y, width, rowHeight)

    -- Arrange children below this row
    if self.props.expanded and #self.children > 0 then
        local childY = y + rowHeight
        for _, child in ipairs(self.children) do
            if child:isVisible() then
                child:arrange(x, childY, width, child.desiredHeight)
                childY = childY + child.desiredHeight
            end
        end
    end
end

---Override hitTest
function TreeViewNode:hitTest(x, y)
    if not self:isVisible() then
        return nil
    end

    if not self:containsPoint(x, y) then
        return nil
    end

    local rowHeight = self:__getRowHeight()

    -- Check if in this node's row
    if y < self.y + rowHeight then
        return self
    end

    -- Check children if expanded
    if self.props.expanded then
        for i = #self.children, 1, -1 do
            local hit = self.children[i]:hitTest(x, y)
            if hit then
                return hit
            end
        end
    end

    return nil
end

---Handle click events
function TreeViewNode:onClicked(event)
    local rowHeight = self:__getRowHeight()

    -- Check if clicked on expand icon (using icon placeholder position)
    local iconX = self.__iconPlaceholder.x
    local iconY = self.y + (rowHeight - self.props.iconSize) / 2
    local iconSize = self.props.iconSize

    if #self.children > 0 and
       AABB.containsPoint(event.x, event.y, iconX, iconY, iconSize + 8, iconSize) then
        self:toggle()
        event:consume()
        return true
    end

    -- Select this node
    if self:__getTreeView() then
        self:__getTreeView():selectNode(self)
    end

    event:consume()
    return true
end

function TreeViewNode:onKeyPressed(event)
    if event.key == "space" or event.key == "return" then
        if self:__getTreeView() then
            self:__getTreeView():selectNode(self)
        end
        return true
    elseif event.key == "left" then
        if self.props.expanded and #self.children > 0 then
            self:setExpanded(false)
        end
        return true
    elseif event.key == "right" then
        if not self.props.expanded and #self.children > 0 then
            self:setExpanded(true)
        end
        return true
    end
end

---Render the tree view node
function TreeViewNode:onRender()
    local rowHeight = self:__getRowHeight()

    -- Draw selection/hover background
    if self.props.selected and self:__getTreeView() then
        love.graphics.setColor(self:__getTreeView().props.selectionColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, rowHeight)
    elseif self.state.isHovered then
        local hoverColor = self:__getTreeView() and self:__getTreeView().props.hoverColor or {0.25, 0.25, 0.25, 1}
        love.graphics.setColor(hoverColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, rowHeight)
    end

    -- Draw expand/collapse icon if has children
    if #self.children > 0 then
        local iconSize = self.props.iconSize
        local iconX = self.__iconPlaceholder.x + 4
        local iconY = self.y + (rowHeight - iconSize) / 2

        love.graphics.setColor(self.props.iconColor)
        if self.props.expanded then
            -- Pointing down
            love.graphics.polygon("fill",
                iconX, iconY,
                iconX + iconSize, iconY,
                iconX + iconSize / 2, iconY + iconSize
            )
        else
            -- Pointing right
            love.graphics.polygon("fill",
                iconX, iconY,
                iconX + iconSize, iconY + iconSize / 2,
                iconX, iconY + iconSize
            )
        end
    end

    -- Render the text widget (positioned by row layout)
    self.__textWidget:onRender()

    -- Draw focus indicator
    if self.state.isFocused then
        love.graphics.setColor(0.5, 0.7, 1, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", self.x + 1, self.y + 1, self.width - 2, rowHeight - 2)
    end

    -- Render children if expanded
    if self.props.expanded then
        for _, child in ipairs(self.children) do
            if child:isVisible() then
                child:onRender()
            end
        end
    end
end

return TreeViewNode
