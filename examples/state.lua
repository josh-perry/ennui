local ennui = require("ennui")

local StackPanel = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local TextButton = ennui.Widgets.Textbutton
local Text = ennui.Widgets.Text
local Slider = ennui.Widgets.Slider
local Rectangle = ennui.Widgets.Rectangle
local Window = ennui.Widgets.Window

local state = ennui.State({
    counter = 0,
    name = "Player",
    health = 100,
    maxHealth = 100,
    level = 1,
    experience = 0,
    position = {
        x = 0,
        y = 0
    }
})

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Reactive State Example")
    :setSize(400, ennui.Size.auto())
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local counterRow = HorizontalStackPanel()
    :setSpacing(10)
    :setSize(ennui.Size.fill(), 40)

local counterText = Text()
    :setColor(1, 1, 1)
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setTextVerticalAlignment("center")
    :bindTo("text", state:computed("counter", function()
        return "Counter: " .. state.props.counter
    end))

local incBtn = TextButton("+")
    :setSize(40, ennui.Size.fill())
    :onClick(function()
        state.props.counter = state.props.counter + 1
    end)

local decBtn = TextButton("-")
    :setSize(40, ennui.Size.fill())
    :onClick(function()
        state.props.counter = state.props.counter - 1
    end)

counterRow:addChild(counterText)
counterRow:addChild(decBtn)
counterRow:addChild(incBtn)

local healthLabel = Text()
    :setColor(1, 1, 1)
    :bindTo("text", state:format("Health: {health} / {maxHealth}"))

local healthBarBg = Rectangle()
    :setSize(ennui.Size.fill(), 20)
    :setColor(0.3, 0.1, 0.1)
    :setRadius(4)

local healthBar = Rectangle()
    :setSize(ennui.Size.percent(1), ennui.Size.fill())
    :setColor(0.2, 0.8, 0.3)
    :setRadius(4)
    :setHorizontalAlignment("left")

state:watch("health", function(health)
    local percent = health / state.props.maxHealth
    healthBar:setSize(ennui.Size.percent(percent), ennui.Size.fill())
end, { immediate = true })

healthBarBg:addChild(healthBar)

local healthSlider = Slider(0, 100, 100)
    :setFillColor(0.8, 0.3, 0.3)

healthSlider:watch("value", function(val)
    state.props.health = math.floor(val)
end)

local positionScope = state:scope("position")

local posText = Text()
    :setColor(0.7, 0.9, 1)
    :bindTo("text", positionScope:format("Position: ({x}, {y})"))

local positionRow = HorizontalStackPanel()
    :setSpacing(5)
    :setSize(ennui.Size.fill(), 30)

local moveLeftBtn = TextButton("Left")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :onClick(function()
        state.props.position.x = state.props.position.x - 1
    end)

local moveRightBtn = TextButton("Right")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :onClick(function()
        state.props.position.x = state.props.position.x + 1
    end)

local moveUpBtn = TextButton("Up")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :onClick(function()
        state.props.position.y = state.props.position.y - 1
    end)

local moveDownBtn = TextButton("Down")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :onClick(function()
        state.props.position.y = state.props.position.y + 1
    end)

positionRow:addChild(moveLeftBtn)
positionRow:addChild(moveRightBtn)
positionRow:addChild(moveUpBtn)
positionRow:addChild(moveDownBtn)

local levelText = Text()
    :setColor(1, 0.9, 0.5)
    :bindTo("text", state:computed("level", function()
        return "Level " .. state.props.level
    end))

local levelUpBtn = TextButton("Level Up!")
    :setSize(ennui.Size.fill(), 35)
    :onClick(function()
        state.props.level = state.props.level + 1
        state.props.maxHealth = state.props.maxHealth + 10
        state.props.health = state.props.maxHealth
        healthSlider:setValue(state.props.health)
    end)

panel:addChild(Text("Counter (with binding):"):setColor(1, 1, 0.5))
panel:addChild(counterRow)
panel:addChild(Text("Health Bar (computed):"):setColor(1, 1, 0.5))
panel:addChild(healthLabel)
panel:addChild(healthBarBg)
panel:addChild(healthSlider)
panel:addChild(Text("Position (scoped state):"):setColor(1, 1, 0.5))
panel:addChild(posText)
panel:addChild(positionRow)
panel:addChild(Text("Level System:"):setColor(1, 1, 0.5))
panel:addChild(levelText)
panel:addChild(levelUpBtn)

window:setContent(panel)
host:addChild(window)

return host