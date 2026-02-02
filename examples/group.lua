local ennui = require("ennui")

local Group = ennui.Widgets.Group
local StackPanel = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local Checkbox = ennui.Widgets.Checkbox
local Slider = ennui.Widgets.Slider
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Group Widget Example")
    :setSize(400, ennui.Size.auto())
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(15)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local settingsGroup = Group("Settings")
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setSpacing(8)

settingsGroup:addChild(Checkbox("Enable sounds"))
settingsGroup:addChild(Checkbox("Show tooltips"):setChecked(true))
settingsGroup:addChild(Checkbox("Auto-save"))

local networkGroup = Group("Network")
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setSpacing(8)
    :setBorderColor(0.3, 0.5, 0.8)
    :setTitleColor(0.5, 0.7, 1)
    :setBackgroundColor(0.1, 0.12, 0.18, 0.5)

networkGroup:addChild(Checkbox("Use proxy"))
networkGroup:addChild(Text("Timeout (seconds):"):setColor(0.8, 0.8, 0.8))
networkGroup:addChild(Slider(1, 60, 30):setStep(1))

local actionGroup = Group()
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setSpacing(5)
    :setBorderColor(0.5, 0.5, 0.5)
    :setCornerRadius(8)

local row = HorizontalStackPanel()
    :setSpacing(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

row:addChild(Text("Volume:"):setColor(1, 1, 1):setSize(60, ennui.Size.auto()))
row:addChild(Slider(0, 100, 75):setSize(ennui.Size.fill(), 24))

actionGroup:addChild(row)

local outerGroup = Group("Appearance")
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setSpacing(10)

local themeGroup = Group("Theme")
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setSpacing(5)
    :setBorderWidth(1)
    :setBorderColor(0.3, 0.3, 0.3)

themeGroup:addChild(Checkbox("Dark mode"):setChecked(true))
themeGroup:addChild(Checkbox("High contrast"))

outerGroup:addChild(themeGroup)
outerGroup:addChild(Text("Font size:"):setColor(0.8, 0.8, 0.8))
outerGroup:addChild(Slider(8, 24, 14):setStep(1))

panel:addChild(settingsGroup)
panel:addChild(networkGroup)
panel:addChild(actionGroup)
panel:addChild(outerGroup)

window:setContent(panel)
host:addChild(window)

return host
