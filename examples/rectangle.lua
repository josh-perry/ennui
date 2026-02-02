local ennui = require("ennui")

local Rectangle = ennui.Widgets.Rectangle
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local StackPanel = ennui.Widgets.Stackpanel
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Rectangle Widget Example")
    :setSize(400, ennui.Size.auto())
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(15)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local colorRow = HorizontalStackPanel()
    :setSpacing(10)
    :setSize(ennui.Size.fill(), 50)

local red = Rectangle():setSize(ennui.Size.fill(), ennui.Size.fill()):setColor(0.9, 0.3, 0.3)
local green = Rectangle():setSize(ennui.Size.fill(), ennui.Size.fill()):setColor(0.3, 0.9, 0.3)
local blue = Rectangle():setSize(ennui.Size.fill(), ennui.Size.fill()):setColor(0.3, 0.3, 0.9)
local yellow = Rectangle():setSize(ennui.Size.fill(), ennui.Size.fill()):setColor(0.9, 0.9, 0.3)

colorRow:addChild(red)
colorRow:addChild(green)
colorRow:addChild(blue)
colorRow:addChild(yellow)

local borderRow = HorizontalStackPanel()
    :setSpacing(10)
    :setSize(ennui.Size.fill(), 50)

local bordered1 = Rectangle()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setColor(0.2, 0.2, 0.2)
    :setBorderColor(1, 1, 1)
    :setBorderWidth(2)

local bordered2 = Rectangle()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setColor(0.1, 0.1, 0.3)
    :setBorderColor(0.5, 0.5, 1)
    :setBorderWidth(3)

local bordered3 = Rectangle()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setColor(0.3, 0.1, 0.1)
    :setBorderColor(1, 0.5, 0.5)
    :setBorderWidth(1)

borderRow:addChild(bordered1)
borderRow:addChild(bordered2)
borderRow:addChild(bordered3)

local roundedRow = HorizontalStackPanel()
    :setSpacing(10)
    :setSize(ennui.Size.fill(), 60)

local rounded1 = Rectangle()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setColor(0.4, 0.6, 0.8)
    :setRadius(5)

local rounded2 = Rectangle()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setColor(0.6, 0.4, 0.8)
    :setRadius(15)

local rounded3 = Rectangle()
    :setSize(60, ennui.Size.fill())
    :setColor(0.8, 0.6, 0.4)
    :setRadius(30)

roundedRow:addChild(rounded1)
roundedRow:addChild(rounded2)
roundedRow:addChild(rounded3)

local containerBox = Rectangle()
    :setSize(ennui.Size.fill(), 80)
    :setColor(0.15, 0.2, 0.25)
    :setRadius(8)
    :setBorderColor(0.4, 0.5, 0.6)
    :setBorderWidth(2)
    :setPadding(15)

local containerText = Text("Rectangle as a container with padding and border")
    :setColor(1, 1, 1)
    :setTextVerticalAlignment("center")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
containerBox:addChild(containerText)

local overlayContainer = Rectangle()
    :setSize(ennui.Size.fill(), 60)
    :setColor(0.8, 0.8, 0.8)
    :setRadius(4)

local overlay = Rectangle()
    :setSize(ennui.Size.percent(0.5), ennui.Size.fill())
    :setColor(0, 0, 0.5, 0.5)
    :setHorizontalAlignment("center")

local overlayText = Text("Semi-transparent overlay")
    :setColor(1, 1, 1)
    :setTextHorizontalAlignment("center")
    :setTextVerticalAlignment("center")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
overlay:addChild(overlayText)
overlayContainer:addChild(overlay)

panel:addChild(Text("Solid Colors:"):setColor(1, 1, 0.5))
panel:addChild(colorRow)
panel:addChild(Text("With Borders:"):setColor(1, 1, 0.5))
panel:addChild(borderRow)
panel:addChild(Text("Rounded Corners:"):setColor(1, 1, 0.5))
panel:addChild(roundedRow)
panel:addChild(Text("As Container:"):setColor(1, 1, 0.5))
panel:addChild(containerBox)
panel:addChild(Text("Transparency:"):setColor(1, 1, 0.5))
panel:addChild(overlayContainer)

window:setContent(panel)
host:addChild(window)

return host
