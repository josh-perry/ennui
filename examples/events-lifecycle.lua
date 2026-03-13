local ennui = require("ennui")

local Host = ennui.Widgets.Host
local Rectangle = ennui.Widgets.Rectangle
local StackPanel = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local Text = ennui.Widgets.Text
local TextButton = ennui.Widgets.Textbutton
local Window = ennui.Widgets.Window

local host = Host():setSize(love.graphics.getDimensions())

local window = Window("Events - Lifecycle")
    :setSize(560, 300)
    :setPosition(60, 60)

local root = HorizontalStackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local messages = {}
local logText = Text("")
    :setColor(0.8, 0.95, 0.8)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local function log(msg)
    table.insert(messages, msg)

    while #messages > 10 do
        table.remove(messages, 1)
    end

    logText:setText(table.concat(messages, "\n"))
end

-- Demo widget
local demoWidget = Rectangle()
    :setSize(ennui.Size.fill(), ennui.Size.fixed(60))
    :setColor(0.3, 0.6, 0.9)
    :setRadius(6)

local demoLabel = Text("Demo Widget")
    :setColor(1, 1, 1)
    :setTextHorizontalAlignment("center")
    :setTextVerticalAlignment("center")
    :setSize(ennui.Size.fill(), ennui.Size.fill())

demoWidget:addChild(demoLabel)

demoWidget:onMount(function()
    log("mount fired")
end)

demoWidget:onUnmount(function()
    log("unmount fired")
end)

local demoPanel = StackPanel()
    :setSize(ennui.Size.fill(), ennui.Size.fixed(68))

demoPanel:addChild(demoWidget)

local removeBtn = TextButton("Remove Widget")
    :setSize(ennui.Size.fill(), 34)

local addBtn = TextButton("Add Widget")
    :setSize(ennui.Size.fill(), 34)
    :setDisabled(true)

removeBtn:onClick(function(self)
    if self:isDisabled() then return end

    demoPanel:removeChild(demoWidget)
    removeBtn:setDisabled(true)
    addBtn:setDisabled(false)
end)

addBtn:onClick(function(self)
    if self:isDisabled() then return end

    demoPanel:addChild(demoWidget)
    removeBtn:setDisabled(false)
    addBtn:setDisabled(true)
end)

local leftPanel = StackPanel()
    :setSpacing(8)
    :setSize(ennui.Size.fixed(220), ennui.Size.fill())

leftPanel:addChild(Text("Widget Zone:"):setColor(1, 1, 0.5))
leftPanel:addChild(demoPanel)
leftPanel:addChild(removeBtn)
leftPanel:addChild(addBtn)

local rightPanel = StackPanel()
    :setSpacing(6)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

rightPanel:addChild(Text("Log:"):setColor(1, 1, 0.5))
rightPanel:addChild(logText)

root:addChild(leftPanel)
root:addChild(rightPanel)

window:setContent(root)
host:addChild(window)

log("Ready - use buttons to mount/unmount.")

return host
