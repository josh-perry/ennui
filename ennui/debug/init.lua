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

local layoutPanel = ennui.Widget()
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local function centerLabel(text, x, y, w, font)
    love.graphics.printf(text, x, y - 6, w, "center")
end

local function midLabel(text, x, y, font)
    local tw = font:getWidth(text)
    love.graphics.print(text, x - tw / 2, y - 6)
end

function layoutPanel:onRender()
    local widget = debugger.inspectingWidget
    if not widget then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf("No widget selected", self.x, self.y + self.height / 2 - 8, self.width, "center")
        return
    end

    local m = widget.margin
    local p = widget.padding
    local contentW = widget.width - p.left - p.right
    local contentH = widget.height - p.top - p.bottom

    local inset = 20
    local availW = self.width - inset * 2
    local availH = self.height - inset * 2
    local totalW = m.left + widget.width + m.right
    local totalH = m.top + widget.height + m.bottom
    local scale = math.min(availW / math.max(totalW, 1), availH / math.max(totalH, 1), 1)

    local minBand = 18
    local mLeft = math.max(m.left * scale, minBand)
    local mRight = math.max(m.right * scale, minBand)
    local mTop = math.max(m.top * scale, minBand)
    local mBottom = math.max(m.bottom * scale, minBand)
    local pLeft = math.max(p.left * scale, minBand)
    local pRight = math.max(p.right * scale, minBand)
    local pTop = math.max(p.top * scale, minBand)
    local pBottom = math.max(p.bottom * scale, minBand)
    local cW = contentW * scale
    local cH = contentH * scale
    local wW = pLeft + cW + pRight
    local wH = pTop + cH + pBottom
    local drawW = mLeft + wW + mRight
    local drawH = mTop + wH + mBottom

    local fitScale = math.min(availW / drawW, availH / drawH, 1)
    if fitScale < 1 then
        mLeft, mRight, mTop, mBottom = mLeft * fitScale, mRight * fitScale, mTop * fitScale, mBottom * fitScale
        pLeft, pRight, pTop, pBottom = pLeft * fitScale, pRight * fitScale, pTop * fitScale, pBottom * fitScale
        cW, cH = cW * fitScale, cH * fitScale
        wW, wH = pLeft + cW + pRight, pTop + cH + pBottom
        drawW, drawH = mLeft + wW + mRight, mTop + wH + mBottom
    end

    local ox = self.x + (self.width - drawW) / 2
    local oy = self.y + (self.height - drawH) / 2
    local font = love.graphics.getFont()

    love.graphics.setColor(0.93, 0.68, 0.38, 0.6)
    love.graphics.rectangle("fill", ox, oy, drawW, drawH)

    love.graphics.setColor(0.6, 0.84, 0.6, 0.6)
    love.graphics.rectangle("fill", ox + mLeft, oy + mTop, wW, wH)

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", ox + mLeft, oy + mTop, wW, wH)

    love.graphics.setColor(0.55, 0.7, 0.9, 0.8)
    love.graphics.rectangle("fill", ox + mLeft + pLeft, oy + mTop + pTop, cW, cH)

    local my = oy + drawH / 2
    love.graphics.setColor(0, 0, 0)
    centerLabel(tostring(m.top), ox, oy + mTop / 2, drawW, font)
    centerLabel(tostring(m.bottom), ox, oy + drawH - mBottom / 2, drawW, font)
    midLabel(tostring(m.left), ox + mLeft / 2, my, font)
    midLabel(tostring(m.right), ox + drawW - mRight / 2, my, font)

    local px, py = ox + mLeft, oy + mTop
    local pcy = py + wH / 2
    love.graphics.setColor(0, 0.3, 0)
    centerLabel(tostring(p.top), px, py + pTop / 2, wW, font)
    centerLabel(tostring(p.bottom), px, py + wH - pBottom / 2, wW, font)
    midLabel(tostring(p.left), px + pLeft / 2, pcy, font)
    midLabel(tostring(p.right), px + wW - pRight / 2, pcy, font)

    love.graphics.setColor(1, 1, 1)
    centerLabel(("%d x %d"):format(contentW, contentH), ox + mLeft + pLeft, oy + mTop + pTop + cH / 2, cW, font)
    love.graphics.setColor(1, 1, 1)
end

tabbar:addTab("Layout", layoutPanel)

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
    propertiesPanel:addChild(Text(("%d x %d"):format(widget.width, widget.height)))

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

function debugger:drawOverlay()
    if self.inspectingWidget then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle(
            "line",
            self.inspectingWidget.x,
            self.inspectingWidget.y,
            self.inspectingWidget.width,
            self.inspectingWidget.height
        )
    end
end

return debugger