local ennui = require("ennui")

local StackPanel = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local Rectangle = ennui.Widgets.Rectangle
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Layout Examples")
    :setSize(600, ennui.Size.auto())
    :setPosition(100, 50)

local outerHorizontalStack = HorizontalStackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local leftPanel = StackPanel()
    :setSpacing(15)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local rightPanel = StackPanel()
    :setSpacing(15)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local vertLabel = Text("Vertical Layout (StackPanel):"):setColor(1, 1, 0.5)
local vertContainer = Rectangle()
    :setSize(ennui.Size.fill(), 100)
    :setColor(0.15, 0.15, 0.2)
    :setRadius(4)
    :setPadding(5)

local vertPanel = StackPanel()
    :setSpacing(5)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

for i = 1, 3 do
    local box = Rectangle()
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :setColor(0.3, 0.4, 0.6)
        :setRadius(2)
    local txt = Text("Item " .. i)
        :setColor(1, 1, 1)
        :setTextHorizontalAlignment("center")
        :setTextVerticalAlignment("center")
        :setSize(ennui.Size.fill(), ennui.Size.fill())
    box:addChild(txt)
    vertPanel:addChild(box)
end
vertContainer:addChild(vertPanel)

local horizLabel = Text("Horizontal Layout (HorizontalStackPanel):"):setColor(1, 1, 0.5)
local horizContainer = Rectangle()
    :setSize(ennui.Size.fill(), 60)
    :setColor(0.15, 0.15, 0.2)
    :setRadius(4)
    :setPadding(5)

local horizPanel = HorizontalStackPanel()
    :setSpacing(5)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local colors = {{0.6, 0.3, 0.3}, {0.3, 0.6, 0.3}, {0.3, 0.3, 0.6}, {0.6, 0.6, 0.3}}
for i = 1, 4 do
    local box = Rectangle()
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :setColor(colors[i][1], colors[i][2], colors[i][3])
        :setRadius(2)
    local txt = Text(tostring(i))
        :setColor(1, 1, 1)
        :setTextHorizontalAlignment("center")
        :setTextVerticalAlignment("center")
        :setSize(ennui.Size.fill(), ennui.Size.fill())
    box:addChild(txt)
    horizPanel:addChild(box)
end
horizContainer:addChild(horizPanel)

local gridLabel = Text("Grid Layout (3x3):"):setColor(1, 1, 0.5)
local gridContainer = Rectangle()
    :setSize(ennui.Size.fill(), 150)
    :setColor(0.15, 0.15, 0.2)
    :setRadius(4)
    :setPadding(5)

local gridWidget = ennui.Widget()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setLayoutStrategy(ennui.Layout.Grid(3, 3):setSpacing(5))

for i = 1, 9 do
    local hue = (i - 1) / 9
    local r = math.abs(hue * 6 - 3) - 1
    local g = 2 - math.abs(hue * 6 - 2)
    local b = 2 - math.abs(hue * 6 - 4)
    r, g, b = math.max(0, math.min(1, r)), math.max(0, math.min(1, g)), math.max(0, math.min(1, b))

    local box = Rectangle()
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :setColor(r * 0.7, g * 0.7, b * 0.7)
        :setRadius(4)
    local txt = Text(tostring(i))
        :setColor(1, 1, 1)
        :setTextHorizontalAlignment("center")
        :setTextVerticalAlignment("center")
        :setSize(ennui.Size.fill(), ennui.Size.fill())
    box:addChild(txt)
    gridWidget:addChild(box)
end
gridContainer:addChild(gridWidget)

leftPanel:addChild(vertLabel)
leftPanel:addChild(vertContainer)
leftPanel:addChild(horizLabel)
leftPanel:addChild(horizContainer)
leftPanel:addChild(gridLabel)
leftPanel:addChild(gridContainer)

local percentLabel = Text("Percentage-based Sizing:"):setColor(1, 1, 0.5)
local percentBarStackPanel = StackPanel()
    :setSpacing(5)
    :setSize(ennui.Size.auto(), ennui.Size.auto())

for i = 1, 9 do
    local percentContainer = HorizontalStackPanel()
        :setSpacing(5)
        :setSize(ennui.Size.fixed(150), 30)

    local leftPercent = i / 10
    local rightPercent = (10 - i) / 10

    print(leftPercent, rightPercent)

    local leftBox = Rectangle()
        :setSize(ennui.Size.percent(leftPercent), ennui.Size.fill())
        :setColor(0.5, 0.3, 0.5)
        :setRadius(4)
    local leftTxt = Text(string.format("%.0f%%", leftPercent * 100))
        :setColor(1, 1, 1)
        :setTextHorizontalAlignment("center")
        :setTextVerticalAlignment("center")
        :setSize(ennui.Size.fill(), ennui.Size.fill())
    leftBox:addChild(leftTxt)

    local rightBox = Rectangle()
        :setSize(ennui.Size.percent(rightPercent), ennui.Size.fill())
        :setColor(0.3, 0.5, 0.5)
        :setRadius(4)
    local rightTxt = Text(string.format("%.0f%%", rightPercent * 100))
        :setColor(1, 1, 1)
        :setTextHorizontalAlignment("center")
        :setTextVerticalAlignment("center")
        :setSize(ennui.Size.fill(), ennui.Size.fill())
    rightBox:addChild(rightTxt)

    percentContainer:addChild(leftBox)
    percentContainer:addChild(rightBox)

    percentBarStackPanel:addChild(percentContainer)
end

rightPanel:addChild(percentLabel)
rightPanel:addChild(percentBarStackPanel)

outerHorizontalStack:addChild(leftPanel)
outerHorizontalStack:addChild(rightPanel)

window:setContent(outerHorizontalStack)
host:addChild(window)

return host
