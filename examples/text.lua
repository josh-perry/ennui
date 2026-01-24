local ennui = require("ennui")

local loremIpsum = [[
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque posuere gravida enim, non vehicula nibh elementum sed. Ut consequat facilisis luctus.ennui

Morbi porttitor vulputate massa a lacinia. Interdum et malesuada fames ac ante ipsum primis in faucibus. Mauris lobortis id ligula eu accumsan. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.

Fusce eget quam sed nibh lobortis finibus.
]]

local Text = require("widgets.text")
local StackPanel = require("widgets.stackpanel")
local Rectangle = require("widgets.rectangle")
local Window = require("widgets.window")

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Text Widget Example")
    :setSize(400, ennui.Size.auto())
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local basicText = Text("Hello, World!")
    :setColor(1, 1, 1)

local coloredText = Text("This text is cyan!")
    :setColor(0.4, 0.9, 1)

local leftAlignBox = Rectangle()
    :setSize(ennui.Size.fill(), 30)
    :setColor(0.2, 0.2, 0.25)
    :setRadius(4)

local leftText = Text("Left aligned")
    :setColor(1, 1, 1)
    :setTextHorizontalAlignment("left")
    :setTextVerticalAlignment("center")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setPadding(10, 0, 10, 0)
leftAlignBox:addChild(leftText)

local centerAlignBox = Rectangle()
    :setSize(ennui.Size.fill(), 30)
    :setColor(0.2, 0.25, 0.2)
    :setRadius(4)

local centerText = Text("Center aligned")
    :setColor(1, 1, 1)
    :setTextHorizontalAlignment("center")
    :setTextVerticalAlignment("center")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
centerAlignBox:addChild(centerText)

local rightAlignBox = Rectangle()
    :setSize(ennui.Size.fill(), 30)
    :setColor(0.25, 0.2, 0.2)
    :setRadius(4)

local rightText = Text("Right aligned")
    :setColor(1, 1, 1)
    :setTextHorizontalAlignment("right")
    :setTextVerticalAlignment("center")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setPadding(10, 0, 10, 0)
rightAlignBox:addChild(rightText)

local font = love.graphics.newFont(18)
local largeText = Text("Larger text with custom font")
    :setColor(1, 0.8, 0.4)
    :setFont(font)

local longTextBox = Rectangle()
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setColor(0.15, 0.15, 0.2)
    :setRadius(4)
    :setPadding(10)
    :setVerticalAlignment("top")

local longText = Text(loremIpsum)
    :setColor(0.9, 0.9, 0.9)
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setVerticalAlignment("top")
longTextBox:addChild(longText)

panel:addChild(Text("Text Styles:"):setColor(1, 1, 0.5))
panel:addChild(basicText)
panel:addChild(coloredText)
panel:addChild(largeText)
panel:addChild(Text("Alignment:"):setColor(1, 1, 0.5))
panel:addChild(leftAlignBox)
panel:addChild(centerAlignBox)
panel:addChild(rightAlignBox)
panel:addChild(Text("Text Wrapping:"):setColor(1, 1, 0.5))
panel:addChild(longTextBox)

window:setContent(panel)
host:addChild(window)

return host
