local ennui = require("ennui")

local TextButton = ennui.Widgets.Textbutton
local Window = ennui.Widgets.Window

local state = {
    clicks = 0
}

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Button Example")
    :setSize(400, 300)
    :setPosition(100, 100)

local button = TextButton("Click me!")
    :onClick(function(button, event)
        state.clicks = state.clicks + 1
        button:setText(("Clicked %d time%s"):format(
            state.clicks,
            state.clicks == 1 and "" or "s"
        ))
    end)

window:setContent(button)
host:addChild(window)

return host