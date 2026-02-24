```lua
local ennui = require("lib.ennui")
local TextButton = require("lib.ennui.widgets.textbutton")

local clicks = 0

local host = ennui.Host()
local button = TextButton("Click me!")
    :setSize(400, 300)
    :setPosition(100, 100)
    :onClick(function(button, event)
        clicks = clicks + 1
        button:setText(("Clicked %d times"):format(clicks))
    end)

host:addChild(button)
```
We define a `TextButton` widget and add it to the Host (which by default is going to fill the screen).

Then we need to tell the `Host` what is happening and allow it to draw:
```lua
function love.draw()
    host:draw()
end

function love.update(dt)
    host:update(dt)
end

function love.mousepressed(x, y, button, istouch, presses)
    host:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    host:mousereleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    host:mousemoved(x, y, dx, dy, istouch)
end
```

Run the code and you'll see a floating button. Click it and watch the number change!