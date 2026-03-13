local ennui = require("ennui")

local Host = ennui.Widgets.Host
local StackPanel = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local TextInput = ennui.Widgets.Textinput
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local host = Host():setSize(love.graphics.getDimensions())

local window = Window("Events - Focus")
    :setSize(560, 320)
    :setPosition(60, 60)

local root = HorizontalStackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local messages = {}
local logText = Text("")
    :setColor(0.85, 0.95, 1)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local function log(msg)
    table.insert(messages, msg)
    if #messages > 8 then table.remove(messages, 1) end
    logText:setText(table.concat(messages, "\n"))
end

local currentFieldLabel = Text("Focused: (none)")
    :setColor(0.7, 0.9, 0.7)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local function makeField(labelStr, placeholder, isPassword)
    local field = TextInput()
        :setPlaceholder(placeholder)
        :setSize(ennui.Size.fill(), 32)

    if isPassword then
        field:setPassword(true)
    end

    field:onFocusGained(function()
        log(("focusGained: %s"):format(labelStr))
        currentFieldLabel:setText(("Focused: %s"):format(labelStr))
    end)

    field:onFocusLost(function()
        log(("focusLost:   %s"):format(labelStr))
        currentFieldLabel:setText("Focused: (none)")
    end)

    return field
end

local leftPanel = StackPanel()
    :setSpacing(8)
    :setSize(ennui.Size.fixed(240), ennui.Size.fill())

leftPanel:addChild(Text("Click between fields:"):setColor(1, 1, 0.5))
leftPanel:addChild(Text("Username:"):setColor(0.75, 0.75, 0.75))
leftPanel:addChild(makeField("Username", "Enter username"))
leftPanel:addChild(Text("Email:"):setColor(0.75, 0.75, 0.75))
leftPanel:addChild(makeField("Email", "user@example.com"))
leftPanel:addChild(Text("Password:"):setColor(0.75, 0.75, 0.75))
leftPanel:addChild(makeField("Password", "Enter password", true))
leftPanel:addChild(currentFieldLabel)

local rightPanel = StackPanel()
    :setSpacing(6)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

rightPanel:addChild(Text("Log:"):setColor(1, 1, 0.5))
rightPanel:addChild(logText)

root:addChild(leftPanel)
root:addChild(rightPanel)

window:setContent(root)
host:addChild(window)

log("Click a text field to see focus events.")

return host
