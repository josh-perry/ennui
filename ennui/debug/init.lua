local debugger = {}

local ennui = require("ennui")

local ScrollArea = ennui.Widgets.Scrollarea
local Treeview = ennui.Widgets.Treeview
local TreeViewNode = ennui.Widgets.Treeviewnode
local Rectangle = ennui.Widgets.Rectangle
local Splitter = ennui.Widgets.Splitter
local Tabbar = ennui.Widgets.Tabbar
local Text = ennui.Widgets.Text

local Window = ennui.Widgets.Window

local propertiesPanel = ennui.Widget()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setLayoutStrategy(ennui.Layout.Grid(2, 1))
    :addChild(Text("Property"):setTextHorizontalAlignment("center"))
    :addChild(Text("Value"):setTextHorizontalAlignment("center"))

local debuggerWindow = Window("Inspector")
    :setSize(600, 400)

local leftPanelWidth = 180
local splitterWidth = 4

local container = ennui.Widget()
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local treeview = Treeview()
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local treeScrollArea = ScrollArea()
    :setSize(ennui.Size.fixed(leftPanelWidth), ennui.Size.fill())
    :addChild(treeview)

local splitter = Splitter("horizontal")
    :setThickness(splitterWidth)

local inspectorPanel = ennui.Widget()
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local tabbar = Tabbar()
    :setSize(ennui.Size.fill(), ennui.Size.fill())

tabbar:addTab("Properties", propertiesPanel)

tabbar:addTab("Styles", Rectangle()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setColor(0.2, 0.2, 0.9)
)

tabbar:addTab("Layout", Rectangle()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setColor(0.9, 0.9, 0.2)
)

inspectorPanel:addChild(tabbar)

splitter.onSplitterDrag = function(delta)
    leftPanelWidth = math.max(100, math.min(leftPanelWidth + delta, debuggerWindow.width - 100 - splitterWidth))
    treeScrollArea:setSize(ennui.Size.fixed(leftPanelWidth), ennui.Size.fill())
    container:invalidateLayout()
end

container.arrangeChildren = function(self, contentX, contentY, contentWidth, contentHeight)
    treeScrollArea:arrange(contentX, contentY, leftPanelWidth, contentHeight)

    splitter:arrange(contentX + leftPanelWidth, contentY, splitterWidth, contentHeight)

    local rightPanelX = contentX + leftPanelWidth + splitterWidth
    local rightPanelWidth = contentWidth - leftPanelWidth - splitterWidth
    inspectorPanel:arrange(rightPanelX, contentY, rightPanelWidth, contentHeight)
end

container:addChild(treeScrollArea)
container:addChild(splitter)
container:addChild(inspectorPanel)

debuggerWindow:setContent(container)

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())
    :addChild(debuggerWindow)

debugger.host = host

function debugger:setInspectedWidget(widget)
    self.inspectingWidget = widget

    propertiesPanel.children = {}
    propertiesPanel:setLayoutStrategy(ennui.Layout.Grid(2, 1))

    propertiesPanel:addChild(Text("Property"):setTextHorizontalAlignment("center"))
    propertiesPanel:addChild(Text("Value"):setTextHorizontalAlignment("center"))

    if not widget then
        return
    end

    propertiesPanel:addChild(Text("Size (pixels)"))
    propertiesPanel:addChild(Text(string.format("%d x %d", widget.width, widget.height)))

    for propertyName, propertyValue in pairs(widget.__rawProps) do
        propertiesPanel:addChild(Text(propertyName))

        local valueText = ""

        if type(propertyValue) == "table" then
            valueText = "{ " .. table.concat(propertyValue, ", ") .. " }"
        else
            valueText = tostring(propertyValue)
        end

        propertiesPanel:addChild(Text(valueText))
    end
end

local function buildTreeNode(tree, debuggerRef)
    local widget = tree.widget

    local node = TreeViewNode(tostring(widget))
        :onClick(function()
            debuggerRef:setInspectedWidget(widget)
        end)

    for _, childTree in ipairs(tree.children) do
        local childNode = buildTreeNode(childTree, debuggerRef)
        node:addChild(childNode)
    end

    return node
end

function debugger:setTargetHost(host)
    self.targettingHost = host
    self:setInspectedWidget(nil)

    treeview.children = {}

    local tree = host:buildDescendantTree()
    local rootNode = buildTreeNode(tree, self)
    treeview:addChild(rootNode)
end

debugger.inspectingWidget = nil

return debugger