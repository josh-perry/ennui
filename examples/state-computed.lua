local ennui = require("ennui")

local State             = ennui.State
local Size              = ennui.Size
local StackPanel        = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local Text              = ennui.Widgets.Text
local Slider            = ennui.Widgets.Slider
local Rectangle         = ennui.Widgets.Rectangle
local Window            = ennui.Widgets.Window

-- Single reactive value that drives every derived display.
local state = State({
    celsius = 20
})

local celsiusBinding = state:bind("celsius")

local fahrenheit = celsiusBinding:map(function(c) return c * 9 / 5 + 32  end)
local kelvin     = celsiusBinding:map(function(c) return c + 273.15       end)

local celsiusLabel    = celsiusBinding:format("%.1f °C")
local fahrenheitLabel = fahrenheit:format("%.1f °F")
local kelvinLabel     = kelvin:format("%.1f K")

local feelLabel = celsiusBinding:map(function(c)
    if c < 0 then
        return "Freezing"
    elseif c < 10 then
        return "Cold"
    elseif c < 20 then
        return "Cool"
    elseif c < 30 then
        return "Warm"
    else
        return "Hot"
    end
end)

local barWidthComputed = celsiusBinding:map(function(c)
    return Size.percent(math.max(0, math.min(1, (c + 40) / 140)))
end)

local barColorComputed = celsiusBinding:map(function(c)
    -- TODO: interpolate colour
    if c < 0 then
        return { 0.3, 0.4, 1.0, 1 }
    elseif c < 20 then
        return { 0.3, 0.7, 0.9, 1 }
    elseif c < 30 then
        return { 1.0, 0.7, 0.2, 1 }
    else
        return { 1.0, 0.3, 0.1, 1 }
    end
end)

local host = ennui.Widgets.Host():setSize(love.graphics.getDimensions())

local window = Window("Computed Properties")
    :setSize(440, Size.auto())
    :setPosition(80, 60)

local panel = StackPanel()
    :setSpacing(14)
    :setPadding(14)
    :setSize(Size.fill(), Size.auto())

local slider = Slider(-40, 100, 20)
    :setSize(Size.fill(), 24)
    :setFillColor(0.4, 0.5, 0.9)

slider:watch("value", function(val)
    state.props.celsius = val
end)

local rangeRow = HorizontalStackPanel()
    :setSize(Size.fill(), Size.auto())

rangeRow:addChild(Text("-40 °C"):setColor(0.5, 0.5, 0.5))
rangeRow:addChild(
    Text("100 °C")
        :setColor(0.5, 0.5, 0.5)
        :setTextHorizontalAlignment("right")
        :setSize(Size.fill(), Size.auto())
)

local function TemperatureCard(title, labelComputed, r, g, b)
    local cardStack = StackPanel()
        :setSize(Size.fill(), Size.auto())
        :setSpacing(4)

    cardStack:addChild(
        Text(title)
        :setColor(r, g, b)
        :setTextHorizontalAlignment("center")
    )

    cardStack:addChild(
        Text()
        :setColor(1, 1, 1)
        :setTextHorizontalAlignment("center")
        :bindTo("text", labelComputed)
    )

    return cardStack
end

local displayRow = HorizontalStackPanel()
    :setSpacing(10)
    :setSize(Size.fill(), Size.auto())

displayRow:addChild(TemperatureCard("Celsius",    celsiusLabel,    1.0, 0.75, 0.3))
displayRow:addChild(TemperatureCard("Fahrenheit", fahrenheitLabel, 0.4, 0.8,  1.0))
displayRow:addChild(TemperatureCard("Kelvin",     kelvinLabel,     0.6, 1.0,  0.6))

local temperatureBar = Rectangle()
    :setSize(Size.fill(), 22)
    :setColor(0.12, 0.12, 0.18)
    :setRadius(4)

local temperatureBarFill = Rectangle()
    :setPreferredWidth(barWidthComputed)
    :setPreferredHeight(Size.fill())
    :setRadius(4)
    :setHorizontalAlignment("left")
    :bindTo("color", barColorComputed)

temperatureBar:addChild(temperatureBarFill)

local feelRow = HorizontalStackPanel()
    :setSpacing(8)
    :setSize(Size.fill(), Size.auto())

feelRow:addChild(Text("Feel:"):setColor(0.55, 0.55, 0.55))
feelRow:addChild(
    Text()
        :setColor(1, 1, 1)
        :bindTo("text", feelLabel)
)

panel:addChild(slider)
panel:addChild(rangeRow)
panel:addChild(displayRow)
panel:addChild(temperatureBar)
panel:addChild(feelRow)

window:setContent(panel)
host:addChild(window)

return host
