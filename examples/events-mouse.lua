local ennui = require("ennui")

local Host = ennui.Widgets.Host
local Rectangle = ennui.Widgets.Rectangle
local StackPanel = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local host = Host():setSize(love.graphics.getDimensions())

local window = Window("Events - Mouse")
    :setSize(620, 360)
    :setPosition(50, 50)

local root = HorizontalStackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local messages = {}
local logText = Text("")
    :setColor(0.85, 0.92, 1)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local function log(msg)
    table.insert(messages, msg)

    while #messages > 10 do
        table.remove(messages, 1)
    end

    logText:setText(table.concat(messages, "\n"))
end

local colourNormal  = {0.25, 0.45, 0.75}
local colourHover   = {0.35, 0.60, 0.95}
local colourPressed = {0.65, 0.85, 0.45}

local interactRect = Rectangle()
    :setSize(ennui.Size.fixed(200), ennui.Size.fill())
    :setColor(colourNormal[1], colourNormal[2], colourNormal[3])
    :setRadius(6)
    :setHitTransparent(false)

local hintText = Text("Hover, click\nscroll, move\nover me")
    :setColor(1, 1, 1)
    :setTextHorizontalAlignment("center")
    :setTextVerticalAlignment("center")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setHitTransparent(true)

interactRect:addChild(hintText)

local lastLoggedX, lastLoggedY = 0, 0

interactRect:onMousePressed(function(_, event)
    interactRect:setColor(colourPressed[1], colourPressed[2], colourPressed[3])
    log(("mousePressed  button=%d  at (%d, %d)"):format(event.button, event.x, event.y))
end)

interactRect:onMouseReleased(function(_, event)
    interactRect:setColor(colourHover[1], colourHover[2], colourHover[3])
    log(("mouseReleased button=%d  at (%d, %d)"):format(event.button, event.x, event.y))
end)

interactRect:onClick(function(_, event)
    log(("clicked       button=%d"):format(event.button))
end)

interactRect:onMouseMoved(function(_, event)
    local dx = event.x - lastLoggedX
    local dy = event.y - lastLoggedY
    if math.abs(dx) > 5 or math.abs(dy) > 5 then
        lastLoggedX, lastLoggedY = event.x, event.y
        log(("mouseMoved    (%d, %d)  \xce\x94=(%d, %d)"):format(
            event.x, event.y, event.dx, event.dy))
    end
end)

interactRect:onMouseEntered(function()
    interactRect:setColor(colourHover[1], colourHover[2], colourHover[3])
    log("mouseEntered")
end)

interactRect:onMouseExited(function()
    interactRect:setColor(colourNormal[1], colourNormal[2], colourNormal[3])
    log("mouseExited")
end)

interactRect:onMouseWheel(function(_, event)
    log(("mouseWheel    dy=%d"):format(event.dy))
end)

local rightPanel = StackPanel()
    :setSpacing(6)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

rightPanel:addChild(Text("Log:"):setColor(1, 1, 0.5))
rightPanel:addChild(logText)

root:addChild(interactRect)
root:addChild(rightPanel)

window:setContent(root)
host:addChild(window)

log("Interact with the blue rectangle.")

return host
