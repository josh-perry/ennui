local ennui = require("ennui")

local Checkbox = require("widgets.checkbox")
local StackPanel = require("widgets.stackpanel")
local Text = require("widgets.text")
local Window = require("widgets.window")

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Checkbox Example")
    :setSize(350, 280)
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local basicCheckbox = Checkbox("Enable notifications")

local checkedCheckbox = Checkbox("Accept terms and conditions")
    :setChecked(true)

local styledCheckbox = Checkbox("Big and green")
    :setCheckColor(0.2, 1, 0.4)
    :setBoxColor(0.6, 0.6, 0.6)
    :setBoxSize(48)

local statusText = Text("Status: notifications disabled")
    :setColor(0.7, 0.7, 0.7)

basicCheckbox:watch("checked", function(checked)
    local status = checked and "enabled" or "disabled"
    statusText:setText("Status: notifications " .. status)
end)

panel:addChild(Text("Basic Checkboxes:"):setColor(1, 1, 0.5))
panel:addChild(basicCheckbox)
panel:addChild(checkedCheckbox)
panel:addChild(styledCheckbox)
panel:addChild(statusText)

window:setContent(panel)
host:addChild(window)

return host
