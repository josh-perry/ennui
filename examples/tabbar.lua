local ennui = require("ennui")

local TabBar = ennui.Widgets.Tabbar
local StackPanel = ennui.Widgets.Stackpanel
local Text = ennui.Widgets.Text
local Checkbox = ennui.Widgets.Checkbox
local Slider = ennui.Widgets.Slider
local Window = ennui.Widgets.Window

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("TabBar Example")
    :setSize(400, 350)
    :setPosition(100, 100)

local tabBar = TabBar()
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local generalPanel = StackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

generalPanel:addChild(Text("General Settings"):setColor(1, 1, 0.5))
generalPanel:addChild(Checkbox("Start on boot"))
generalPanel:addChild(Checkbox("Check for updates"):setChecked(true))
generalPanel:addChild(Checkbox("Send anonymous usage data"))

local audioPanel = StackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

audioPanel:addChild(Text("Audio Settings"):setColor(1, 1, 0.5))
audioPanel:addChild(Text("Master Volume:"):setColor(0.8, 0.8, 0.8))
audioPanel:addChild(Slider(0, 100, 80))
audioPanel:addChild(Text("Music Volume:"):setColor(0.8, 0.8, 0.8))
audioPanel:addChild(Slider(0, 100, 60))
audioPanel:addChild(Checkbox("Mute when minimized"))

local displayPanel = StackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

displayPanel:addChild(Text("Display Settings"):setColor(1, 1, 0.5))
displayPanel:addChild(Checkbox("Fullscreen"))
displayPanel:addChild(Checkbox("V-Sync"):setChecked(true))
displayPanel:addChild(Text("Brightness:"):setColor(0.8, 0.8, 0.8))
displayPanel:addChild(Slider(0, 100, 50))

tabBar:addTab("General", generalPanel)
tabBar:addTab("Audio", audioPanel)
tabBar:addTab("Display", displayPanel)

tabBar.onTabChanged = function(index)
    print("Switched to tab " .. index)
end

window:setContent(tabBar)
host:addChild(window)

return host
