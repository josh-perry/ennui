local ennui = require("ennui")

local Host = ennui.Widgets.Host
local Rectangle = ennui.Widgets.Rectangle
local StackPanel = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local host = Host()
host:setSize(love.graphics.getDimensions())

local window = Window("Events - Propagation & Bubbling")
    :setSize(ennui.Size.auto(), ennui.Size.auto())
    :setPosition(50, 50)

local root = HorizontalStackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.auto(), ennui.Size.auto())

local messages = {}
local logText = Text("")
    :setColor(0.85, 0.92, 1)
    :setSize(ennui.Size.auto(), ennui.Size.fill())

local function log(msg)
    table.insert(messages, msg)
    while #messages > 16 do
        table.remove(messages, 1)
    end
    logText:setText(table.concat(messages, "\n"))
end

local flashDuration = 0.6

local colourBlue = {0.25, 0.45, 0.9}
local colourRed  = {0.85, 0.25, 0.25}

local delayPerStep = 0.1   -- seconds of ripple delay per level of distance from the target

local function makeFlashable(rect, baseColour)
    local flashTimer  = 0
    local pendingDelay = -1

    rect:onUpdate(function(self, dt)
        if pendingDelay >= 0 then
            pendingDelay = pendingDelay - dt
            if pendingDelay <= 0 then
                pendingDelay = -1
                flashTimer = flashDuration
            end
        end

        if flashTimer > 0 then
            flashTimer = math.max(0, flashTimer - dt)
            local t = flashTimer / flashDuration
            local r = baseColour[1] + (1 - baseColour[1]) * t
            local g = baseColour[2] + (1 - baseColour[2]) * t
            local b = baseColour[3] + (1 - baseColour[3]) * t
            self:setColor(r, g, b)
        end
    end)

    return function(delay)
        if delay > 0 then
            pendingDelay = delay
        else
            flashTimer = flashDuration
        end
    end
end

local rectCount    = 30
local redEvery     = 10   -- every Nth rectangle is red (consumes); others are blue (bubbles)
local outerSize    = 600
local sizeStep     = math.floor(outerSize / (rectCount + 1))

local rects = {}

for index = 1, rectCount do
    local size     = outerSize - (index - 1) * sizeStep
    local isRed    = (index % redEvery) == 0
    local colour   = isRed and colourRed or colourBlue
    local label    = isRed and ("rect %d  red"):format(index)
                            or ("rect %d  blue"):format(index)

    local rect = Rectangle()
        :setSize(ennui.Size.fixed(size), ennui.Size.fixed(size))
        :setColor(colour[1], colour[2], colour[3])
        :setRadius(6)
        :setHorizontalAlignment("center")
        :setVerticalAlignment("center")
        :setHitTransparent(false)

    local flash = makeFlashable(rect, colour)

    rect.rectIndex = index

    rect:onMousePressed(function(self, event)
        if event.target == self then log("---") end
        local depth = event.target.rectIndex - index
        flash(depth * delayPerStep)
        if isRed then
            log(label .. "   consumed")
            event:consume()
        else
            log(label .. "   bubbles up")
        end
    end)

    rects[index] = rect
end

-- nest from innermost outward
for index = rectCount, 2, -1 do
    rects[index - 1]:addChild(rects[index])
end

local arenaBackground = Rectangle()
    :setSize(ennui.Size.auto(), ennui.Size.fill())
    :setColor(0.08, 0.08, 0.12)
    :setRadius(6)

arenaBackground:addChild(rects[1])

local rightPanel = StackPanel()
    :setSpacing(8)
    :setSize(ennui.Size.auto(), ennui.Size.fill())

local legend = Text(
    "Blue  = allows bubbling\n" ..
    "Red   = consumes event\n" ..
    ("Every %dth rect is red.\n\n"):format(redEvery) ..
    "Rectangles flash white\nwhen the event passes through."
)
    :setColor(0.6, 0.6, 0.65)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

rightPanel:addChild(Text("Legend:"):setColor(1, 1, 0.5))
rightPanel:addChild(legend)
rightPanel:addChild(Text("Log:"):setColor(1, 1, 0.5))
rightPanel:addChild(logText)

root:addChild(arenaBackground)
root:addChild(rightPanel)

window:setContent(root)
host:addChild(window)

log("Click the rectangles to see propagation.")

return host
