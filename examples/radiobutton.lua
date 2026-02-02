local ennui = require("ennui")

local RadioButton = ennui.Widgets.Radiobutton
local StackPanel = ennui.Widgets.Stackpanel
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Radio Button Example")
    :setSize(350, 350)
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(8)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local sizeLabel = Text("Select size:"):setColor(1, 1, 0.5)
local sizeSmall = RadioButton("Small", "size", "S"):setSelected(true)
local sizeMedium = RadioButton("Medium", "size", "M")
local sizeLarge = RadioButton("Large", "size", "L")
local sizeXL = RadioButton("Extra Large", "size", "XL")

local colorLabel = Text("Select color:"):setColor(1, 1, 0.5)
local colorRed = RadioButton("Red", "color", "red")
    :setSelectedColor(1, 0.3, 0.3)
local colorGreen = RadioButton("Green", "color", "green")
    :setSelectedColor(0.3, 1, 0.3)
local colorBlue = RadioButton("Blue", "color", "blue")
    :setSelectedColor(0.3, 0.3, 1)
    :setSelected(true)

local selectionText = Text("Selection: Size=S, Color=blue")
    :setColor(0.7, 0.9, 1)

local function updateSelection()
    local size = "none"
    local color = "none"

    for _, radio in ipairs({sizeSmall, sizeMedium, sizeLarge, sizeXL}) do
        if radio:isSelected() then size = radio:getValue() end
    end
    for _, radio in ipairs({colorRed, colorGreen, colorBlue}) do
        if radio:isSelected() then color = radio:getValue() end
    end

    selectionText:setText("Selection: Size=" .. size .. ", Color=" .. color)
end

for _, radio in ipairs({sizeSmall, sizeMedium, sizeLarge, sizeXL, colorRed, colorGreen, colorBlue}) do
    radio:watch("selected", updateSelection)
end

panel:addChild(sizeLabel)
panel:addChild(sizeSmall)
panel:addChild(sizeMedium)
panel:addChild(sizeLarge)
panel:addChild(sizeXL)
panel:addChild(colorLabel)
panel:addChild(colorRed)
panel:addChild(colorGreen)
panel:addChild(colorBlue)
panel:addChild(selectionText)

window:setContent(panel)
host:addChild(window)

return host
