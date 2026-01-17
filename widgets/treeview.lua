local ennui = require("ennui")
local Widget = require("ennui.widget")
local Size = require("ennui.size")

---@class TreeView : Widget
---@field selectedNode TreeViewNode? Currently selected node
---@field indentSize number Pixels to indent each level
---@field rowHeight number Height of each row
---@field selectionColor number[] RGBA color for selected row
---@field hoverColor number[] RGBA color for hovered row
local TreeView = {}
TreeView.__index = TreeView
setmetatable(TreeView, {
    __index = Widget,
    __call = function(class)
        return class.new()
    end,
})

---Create a new tree view widget
---@return TreeView
function TreeView.new()
    local self = setmetatable(Widget(), TreeView) ---@cast self TreeView

    self:addProperty("indentSize", 20)
    self:addProperty("rowHeight", 24)
    self:addProperty("selectionColor", {0.3, 0.5, 0.8, 1})
    self:addProperty("hoverColor", {0.25, 0.25, 0.25, 1})

    self.selectedNode = nil

    local strategy = ennui.Layout.Vertical()
    strategy.spacing = 0
    self:setLayoutStrategy(strategy)

    return self
end

---Select a node
---@param node TreeViewNode? Node to select (nil to clear selection)
---@return TreeView self
function TreeView:selectNode(node)
    if self.selectedNode then
        self.selectedNode.props.selected = false
    end
    self.selectedNode = node
    if node then
        node.props.selected = true
    end
    self:invalidateRender()
    return self
end

---Get the selected node
---@return TreeViewNode? selectedNode
function TreeView:getSelectedNode()
    return self.selectedNode
end

---Set indent size
---@param size number Indent size in pixels
---@return TreeView self
function TreeView:setIndentSize(size)
    self.props.indentSize = size
    return self
end

---Set row height
---@param height number Row height in pixels
---@return TreeView self
function TreeView:setRowHeight(height)
    self.props.rowHeight = height
    return self
end

---Set selection color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TreeView self
function TreeView:setSelectionColor(r, g, b, a)
    self.props.selectionColor = {r, g, b, a or 1}
    return self
end

---Set hover color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TreeView self
function TreeView:setHoverColor(r, g, b, a)
    self.props.hoverColor = {r, g, b, a or 1}
    return self
end

return TreeView
