local ennui = require("ennui")

local Slider = require("widgets.slider")
local StackPanel = require("widgets.stackpanel")
local HorizontalStackPanel = require("widgets.horizontalstackpanel")
local Text = require("widgets.text")
local Rectangle = require("widgets.rectangle")
local Window = require("widgets.window")

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Slider Example")
    :setSize(400, ennui.Size.auto())
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(15)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local volumeRow = HorizontalStackPanel()
    :setSpacing(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local volumeLabel = Text("Volume:")
    :setColor(1, 1, 1)
    :setSize(60, ennui.Size.auto())

local volumeSlider = Slider(0, 100, 75)
    :setSize(ennui.Size.fill(), 24)

local volumeValue = Text("75")
    :setColor(0.7, 0.9, 1)
    :setSize(40, ennui.Size.auto())
    :setTextHorizontalAlignment("right")

volumeSlider:watch("value", function(val)
    volumeValue:setText(tostring(math.floor(val)))
end)

volumeRow:addChild(volumeLabel)
volumeRow:addChild(volumeSlider)
volumeRow:addChild(volumeValue)

local brightnessRow = HorizontalStackPanel()
    :setSpacing(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local brightnessLabel = Text("Brightness:")
    :setColor(1, 1, 1)
    :setSize(60, ennui.Size.auto())

local brightnessSlider = Slider(0, 100, 50)
    :setStep(10)
    :setFillColor(1, 0.8, 0.2)
    :setSize(ennui.Size.fill(), 24)

local brightnessValue = Text("50")
    :setColor(1, 0.9, 0.5)
    :setSize(40, ennui.Size.auto())
    :setTextHorizontalAlignment("right")

brightnessSlider:watch("value", function(val)
    brightnessValue:setText(tostring(math.floor(val)))
end)

brightnessRow:addChild(brightnessLabel)
brightnessRow:addChild(brightnessSlider)
brightnessRow:addChild(brightnessValue)

local colorPreview = Rectangle()
    :setSize(ennui.Size.fill(), 60)
    :setColor(0.5, 0.5, 0.5)
    :setRadius(4)

local redSlider = Slider(0, 1, 0.5):setFillColor(1, 0.3, 0.3)
local greenSlider = Slider(0, 1, 0.5):setFillColor(0.3, 1, 0.3)
local blueSlider = Slider(0, 1, 0.5):setFillColor(0.3, 0.3, 1)

local function updateColor()
    colorPreview:setColor(
        redSlider:getValue() / 1,
        greenSlider:getValue() / 1,
        blueSlider:getValue() / 1
    )
end

redSlider:watch("value", updateColor)
greenSlider:watch("value", updateColor)
blueSlider:watch("value", updateColor)
updateColor()

panel:addChild(Text("Volume Control:"):setColor(1, 1, 0.5))
panel:addChild(volumeRow)
panel:addChild(Text("Brightness (stepped):"):setColor(1, 1, 0.5))
panel:addChild(brightnessRow)
panel:addChild(Text("RGB Color Mixer:"):setColor(1, 1, 0.5))
panel:addChild(redSlider)
panel:addChild(greenSlider)
panel:addChild(blueSlider)
panel:addChild(colorPreview)

window:setContent(panel)
host:addChild(window)

return host
