local ennui = require("ennui")

local Host = ennui.Widgets.Host
local Rectangle = ennui.Widgets.Rectangle
local StackPanel = ennui.Widgets.Stackpanel
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local host = Host():setSize(love.graphics.getDimensions())

local window = Window("Events - Update")
    :setSize(400, 260)
    :setPosition(80, 80)

local panel = StackPanel()
    :setSpacing(12)
    :setPadding(14)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local infoText = Text(
    "The rectangle below is animated using onUpdate.\n" ..
    "The callback fires every frame and receives dt.")
    :setColor(0.75, 0.75, 0.75)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local trackBar = Rectangle()
    :setSize(ennui.Size.fill(), ennui.Size.fixed(50))
    :setColor(0.15, 0.15, 0.2)
    :setRadius(4)

local ball = Rectangle()
    :setSize(ennui.Size.fixed(40), ennui.Size.fixed(40))
    :setColor(0.3, 0.8, 0.5)
    :setRadius(20)
    :setHorizontalAlignment("left")
    :setVerticalAlignment("center")

trackBar:addChild(ball)

local dtLabel = Text("dt: -")
    :setColor(0.6, 0.8, 1)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local t = 0

ball:onUpdate(function(self, dt)
    t = t + dt

    local range = math.max(0, trackBar.width - self.width - 10)
    local offsetX = (math.sin(t * 2) * 0.5 + 0.5) * range + 5
    self.x = trackBar.x + math.floor(offsetX)
    self.y = trackBar.y + math.floor((trackBar.height - self.height) / 2)

    dtLabel:setText(("dt: %.4f s  (~%d fps)"):format(dt, math.floor(1 / (dt + 0.0001) + 0.5)))
end)

panel:addChild(infoText)
panel:addChild(trackBar)
panel:addChild(dtLabel)

window:setContent(panel)
host:addChild(window)

return host
