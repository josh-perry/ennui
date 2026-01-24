local ennui = require("ennui")

local Window = require("widgets.window")
local StackPanel = require("widgets.stackpanel")
local TextButton = require("widgets.textbutton")
local Text = require("widgets.text")
local Checkbox = require("widgets.checkbox")
local Slider = require("widgets.slider")

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local controlWindow = Window("Window Controls")
    :setSize(300, 200)
    :setPosition(50, 50)

local controlPanel = StackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local settingsWindow = Window("Settings")
    :setSize(280, 250)
    :setPosition(380, 50)

local settingsPanel = StackPanel()
    :setSpacing(8)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

settingsPanel:addChild(Text("Audio Volume:"):setColor(1, 1, 1))
settingsPanel:addChild(Slider(0, 100, 75))
settingsPanel:addChild(Checkbox("Enable music"))
settingsPanel:addChild(Checkbox("Enable sound effects"):setChecked(true))
settingsPanel:addChild(Text("Graphics Quality:"):setColor(1, 1, 1))
settingsPanel:addChild(Slider(1, 3, 2):setStep(1))

settingsWindow:setContent(settingsPanel)

local infoWindow = Window("Information")
    :setSize(250, 180)
    :setPosition(100, 280)

local infoPanel = StackPanel()
    :setSpacing(5)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

infoPanel:addChild(Text("Drag windows by title bar"):setColor(0.7, 0.7, 0.7))
infoPanel:addChild(Text("Click X to close windows"):setColor(0.7, 0.7, 0.7))
infoPanel:addChild(Text("Tab between focusable widgets"):setColor(0.7, 0.7, 0.7))

infoWindow:setContent(infoPanel)

local hiddenWindow = Window("Hidden Window")
    :setSize(200, 150)
    :setPosition(400, 300)
    :setVisible(false)

local hiddenPanel = StackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

hiddenPanel:addChild(Text("You found me!"):setColor(0.5, 1, 0.5))
hiddenPanel:addChild(Text("This window was hidden"):setColor(0.8, 0.8, 0.8))

hiddenWindow:setContent(hiddenPanel)

local showHiddenBtn = TextButton("Toggle Hidden Window")
    :setSize(ennui.Size.fill(), 35)
    :onClick(function()
        hiddenWindow:setVisible(not hiddenWindow:isVisible())
    end)

local showSettingsBtn = TextButton("Show Settings")
    :setSize(ennui.Size.fill(), 35)
    :onClick(function()
        settingsWindow:setVisible(true)
        settingsWindow:bringToFront()
    end)

local showInfoBtn = TextButton("Show Info")
    :setSize(ennui.Size.fill(), 35)
    :onClick(function()
        infoWindow:setVisible(true)
        infoWindow:bringToFront()
    end)

controlPanel:addChild(Text("Window Management:"):setColor(1, 1, 0.5))
controlPanel:addChild(showHiddenBtn)
controlPanel:addChild(showSettingsBtn)
controlPanel:addChild(showInfoBtn)

controlWindow:setContent(controlPanel)

host:addChild(controlWindow)
host:addChild(settingsWindow)
host:addChild(infoWindow)
host:addChild(hiddenWindow)

return host
