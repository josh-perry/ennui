local ennui = require("ennui")

local Image = ennui.Widgets.Image
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local StackPanel = ennui.Widgets.Stackpanel
local Text = ennui.Widgets.Text
local Rectangle = ennui.Widgets.Rectangle
local Window = ennui.Widgets.Window

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Image Widget Example")
    :setSize(400, ennui.Size.auto())
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local frogImage = love.graphics.newImage("examples/assets/img/frog.png")
local luccaImage = love.graphics.newImage("examples/assets/img/lucca.png")
local cronoImage = love.graphics.newImage("examples/assets/img/crono.png")

local imageRow = HorizontalStackPanel()
    :setSpacing(10)
    :setSize(ennui.Size.fill(), 80)

local img1Box = Rectangle()
    :setSize(70, ennui.Size.fill())
    :setColor(0.2, 0.2, 0.3)
    :setRadius(4)

local img1 = Image(frogImage)
    :setSize(ennui.Size.fill(), ennui.Size.fill())
img1Box:addChild(img1)

local img2Box = Rectangle()
    :setSize(70, ennui.Size.fill())
    :setColor(0.3, 0.2, 0.2)
    :setRadius(4)

local img2 = Image(luccaImage)
    :setSize(ennui.Size.fill(), ennui.Size.fill())
img2Box:addChild(img2)

local img3Box = Rectangle()
    :setSize(70, ennui.Size.fill())
    :setColor(0.2, 0.3, 0.2)
    :setRadius(4)

local img3 = Image(cronoImage)
    :setSize(ennui.Size.fill(), ennui.Size.fill())
img3Box:addChild(img3)

imageRow:addChild(img1Box)
imageRow:addChild(img2Box)
imageRow:addChild(img3Box)

local tintRow = HorizontalStackPanel()
    :setSpacing(10)
    :setSize(ennui.Size.fill(), 60)

local normalImg = Image(frogImage):setSize(50, 50)
local redTint = Image(frogImage):setSize(50, 50):setColor(1, 0.5, 0.5)
local greenTint = Image(frogImage):setSize(50, 50):setColor(0.5, 1, 0.5)
local blueTint = Image(frogImage):setSize(50, 50):setColor(0.5, 0.5, 1)

tintRow:addChild(normalImg)
tintRow:addChild(redTint)
tintRow:addChild(greenTint)
tintRow:addChild(blueTint)

local scaledBox = Rectangle()
    :setSize(ennui.Size.fill(), 100)
    :setColor(0.15, 0.15, 0.2)
    :setRadius(4)

local scaledImg = Image(cronoImage)
    :setScale(2)
    :setSize(ennui.Size.fill(), ennui.Size.fill())
scaledBox:addChild(scaledImg)

panel:addChild(Text("Character Images:"):setColor(1, 1, 0.5))
panel:addChild(imageRow)
panel:addChild(Text("Color Tints:"):setColor(1, 1, 0.5))
panel:addChild(tintRow)
panel:addChild(Text("Scaled Image:"):setColor(1, 1, 0.5))
panel:addChild(scaledBox)

window:setContent(panel)
host:addChild(window)

return host
