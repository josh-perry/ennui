local debugger = {}

local ennui = require("ennui")

local ScrollArea = ennui.Widgets.Scrollarea
local Treeview = ennui.Widgets.Treeview
local TreeViewNode = ennui.Widgets.Treeviewnode
local Rectangle = ennui.Widgets.Rectangle
local Splitter = ennui.Widgets.Splitter
local Tabbar = ennui.Widgets.Tabbar
local Text = ennui.Widgets.Text
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel

local Window = ennui.Widgets.Window
local SizeConstraint = ennui.SizeConstraint
local Size = ennui.Size

local colours = {
    margin       = { 1.0, 1.0, 0.5 },
    text   = { 0, 0, 0 },
    padding     = { 1.0, 0.5, 1.0 },
    content = { 0.2, 0.2, 1.0 },
    noSelection  = { 0.6, 0.6, 0.6 },
    overlay      = { 1, 0, 0 }
}

colours.marginFaded = { colours.margin[1], colours.margin[2], colours.margin[3], 0.2 }
colours.paddingFaded = { colours.padding[1], colours.padding[2], colours.padding[3], 0.2 }
colours.overlayMargin = { colours.margin[1], colours.margin[2], colours.margin[3], 0.9 }
colours.overlayPadding = { colours.padding[1], colours.padding[2], colours.padding[3], 0.9 }
colours.overlayContent = { colours.content[1], colours.content[2], colours.content[3], 0.9 }

local propertiesPanel = ennui.Widget()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setLayoutStrategy(ennui.Layout.Grid(2, 1))
    :addChild(Text("Property"):setTextHorizontalAlignment("center"))
    :addChild(Text("Value"):setTextHorizontalAlignment("center"))

local debuggerWindow = Window("Inspector")
    :setSize(1000, 700)

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
    :setSize(Size.fill(), Size.fill())
    :setLayoutStrategy(ennui.Layout.Overlay())

local function centeredText(label)
    return Text(label)
        :setSize(Size.fill(), Size.fill())
        :setTextHorizontalAlignment("center")
        :setTextVerticalAlignment("center")
end

local noSelectionText = centeredText("No widget selected"):setColor(unpack(colours.noSelection))

local topMarginText = centeredText("0"):setColor(unpack(colours.text))
local bottomMarginText = centeredText("0"):setColor(unpack(colours.text))
local leftMarginText = centeredText("0"):setColor(unpack(colours.text))
local rightMarginText = centeredText("0"):setColor(unpack(colours.text))

local topPaddingText = centeredText("0"):setColor(unpack(colours.text))
local bottomPaddingText = centeredText("0"):setColor(unpack(colours.text))
local leftPaddingText = centeredText("0"):setColor(unpack(colours.text))
local rightPaddingText = centeredText("0"):setColor(unpack(colours.text))

local contentText = centeredText("0 x 0")

local function band(color, textWidget)
    return Rectangle():setColor(unpack(color)):setBorderWidth(0)
        :setSize(Size.fill(), Size.fill())
        :addChild(textWidget)
        :setLayoutStrategy(ennui.Layout.Overlay())
end

local function labelText(label, color)
    return Text(label)
        :setSize(Size.fill(), Size.fill())
        :setTextVerticalAlignment("center")
        :setColor(unpack(color))
        :setPadding(4)
end

local marginLabel = labelText("margin", colours.text)
local paddingLabel = labelText("padding", colours.text)

local topMargin = band(colours.margin, topMarginText):addChild(marginLabel)
local bottomMargin = band(colours.margin, bottomMarginText)
local leftMargin = band(colours.margin, leftMarginText)
local rightMargin = band(colours.margin, rightMarginText)

local topPadding = band(colours.padding, topPaddingText):addChild(paddingLabel)
local bottomPadding = band(colours.padding, bottomPaddingText)
local leftPadding = band(colours.padding, leftPaddingText)
local rightPadding = band(colours.padding, rightPaddingText)

local contentBox = band(colours.content, contentText)

local padMiddleRow = HorizontalStackPanel()
    :setSize(Size.fill(), Size.fill())
    :addChild(leftPadding)
    :addChild(contentBox)
    :addChild(rightPadding)

local paddingBox = Rectangle()
    :setColor(unpack(colours.padding))
    --:setBorderColor(unpack(colors.paddingBorder))
    :setBorderWidth(1)
    :setSize(Size.fill(), Size.fill())
    :setLayoutStrategy(ennui.Layout.Vertical())
    :addChild(topPadding)
    :addChild(padMiddleRow)
    :addChild(bottomPadding)

local middleRow = HorizontalStackPanel()
    :setSize(Size.fill(), Size.fill())
    :addChild(leftMargin)
    :addChild(paddingBox)
    :addChild(rightMargin)

local marginBox = Rectangle()
    :setColor(unpack(colours.margin))
    :setBorderWidth(0)
    :setSize(Size.fill(), Size.fill())
    :setLayoutStrategy(ennui.Layout.Vertical())
    :addChild(topMargin)
    :addChild(middleRow)
    :addChild(bottomMargin)

marginBox:setVisible(false)
noSelectionText:setHorizontalAlignment("stretch")
noSelectionText:setVerticalAlignment("stretch")
marginBox:setHorizontalAlignment("stretch")
marginBox:setVerticalAlignment("stretch")
layoutPanel:setPadding(20)
layoutPanel:addChild(noSelectionText)
layoutPanel:addChild(marginBox)

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

    if widget then
        local m = widget.margin
        local p = widget.padding
        local cntW = widget.width - p.left - p.right
        local cntH = widget.height - p.top - p.bottom

        topMarginText:setText(tostring(m.top))
        bottomMarginText:setText(tostring(m.bottom))
        leftMarginText:setText(tostring(m.left))
        rightMarginText:setText(tostring(m.right))
        topPaddingText:setText(tostring(p.top))
        bottomPaddingText:setText(tostring(p.bottom))
        leftPaddingText:setText(tostring(p.left))
        rightPaddingText:setText(tostring(p.right))
        contentText:setText(("%d x %d"):format(cntW, cntH))

        local minBand = 18
        local mL = math.max(m.left, minBand)
        local mR = math.max(m.right, minBand)
        local mT = math.max(m.top, minBand)
        local mB = math.max(m.bottom, minBand)
        local pL = math.max(p.left, minBand)
        local pR = math.max(p.right, minBand)
        local pT = math.max(p.top, minBand)
        local pB = math.max(p.bottom, minBand)
        local cW = math.max(cntW, minBand)
        local cH = math.max(cntH, minBand)
        local wW = pL + cW + pR
        local wH = pT + cH + pB
        local totalW = mL + wW + mR
        local totalH = mT + wH + mB

        marginBox:setSizeConstraint(SizeConstraint.ratio(totalW / totalH))

        topMargin:setSize(Size.fill(), Size.fill(mT))
        bottomMargin:setSize(Size.fill(), Size.fill(mB))
        middleRow:setSize(Size.fill(), Size.fill(wH))

        leftMargin:setSize(Size.fill(mL), Size.fill())
        rightMargin:setSize(Size.fill(mR), Size.fill())
        paddingBox:setSize(Size.fill(wW), Size.fill())

        topPadding:setSize(Size.fill(), Size.fill(pT))
        bottomPadding:setSize(Size.fill(), Size.fill(pB))
        padMiddleRow:setSize(Size.fill(), Size.fill(cH))

        leftPadding:setSize(Size.fill(pL), Size.fill())
        rightPadding:setSize(Size.fill(pR), Size.fill())
        contentBox:setSize(Size.fill(cW), Size.fill())

        local mc = function(v) return unpack(v == 0 and colours.marginFaded or colours.margin) end
        local pc = function(v) return unpack(v == 0 and colours.paddingFaded or colours.padding) end
        topMargin:setColor(mc(m.top))
        bottomMargin:setColor(mc(m.bottom))
        leftMargin:setColor(mc(m.left))
        rightMargin:setColor(mc(m.right))
        topPadding:setColor(pc(p.top))
        bottomPadding:setColor(pc(p.bottom))
        leftPadding:setColor(pc(p.left))
        rightPadding:setColor(pc(p.right))

        marginBox:setVisible(true)
        noSelectionText:setVisible(false)
    else
        marginBox:setVisible(false)
        noSelectionText:setVisible(true)
    end

    layoutPanel:invalidateLayout()

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
    local w = self.inspectingWidget
    if not w then
        return
    end

    local m = w.margin
    local p = w.padding

    local mx = w.x - m.left
    local my = w.y - m.top
    local mw = m.left + w.width + m.right
    local mh = m.top + w.height + m.bottom

    love.graphics.setColor(unpack(colours.overlayMargin))
    love.graphics.rectangle("fill", mx, my, mw, m.top)
    love.graphics.rectangle("fill", mx, my + m.top, m.left, w.height)
    love.graphics.rectangle("fill", w.x + w.width, my + m.top, m.right, w.height)
    love.graphics.rectangle("fill", mx, w.y + w.height, mw, m.bottom)

    love.graphics.setColor(unpack(colours.overlayPadding))
    love.graphics.rectangle("fill", w.x, w.y, w.width, p.top)
    love.graphics.rectangle("fill", w.x, w.y + p.top, p.left, w.height - p.top - p.bottom)
    love.graphics.rectangle("fill", w.x + w.width - p.right, w.y + p.top, p.right, w.height - p.top - p.bottom)
    love.graphics.rectangle("fill", w.x, w.y + w.height - p.bottom, w.width, p.bottom)

    love.graphics.setColor(unpack(colours.overlay))
    love.graphics.rectangle("line", w.x, w.y, w.width, w.height)
end

return debugger