local ennui = require("ennui")

local ScrollArea = ennui.Widgets.Scrollarea
local StackPanel = ennui.Widgets.Stackpanel
local Text = ennui.Widgets.Text
local Rectangle = ennui.Widgets.Rectangle
local Window = ennui.Widgets.Window

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("ScrollArea Example")
    :setSize(350, 350)
    :setPosition(100, 100)

local scrollArea = ScrollArea()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setScrollSpeed(30)
    :setPadding(5)

local panel = StackPanel()
    :setSpacing(8)
    :setSize(ennui.Size.auto(), ennui.Size.auto())

for i = 1, 30 do
    local itemBox = Rectangle()
        :setSize(ennui.Size.fill(), 40)
        :setColor(0.2 + (i % 2) * 0.05, 0.2, 0.3)
        :setRadius(4)
        :setPadding(10, 0, 0, 0)

    local itemText = Text("Item " .. i)
        :setColor(1, 1, 1)
        :setTextVerticalAlignment("center")
        :setSize(ennui.Size.fill(), ennui.Size.fill())

    itemBox:addChild(itemText)
    panel:addChild(itemBox)
end

scrollArea:addChild(panel)
window:setContent(scrollArea)
host:addChild(window)

return host
