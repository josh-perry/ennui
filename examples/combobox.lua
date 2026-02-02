local ennui = require("ennui")

local ComboBox = ennui.Widgets.Combobox
local StackPanel = ennui.Widgets.Stackpanel
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("ComboBox Example")
    :setSize(350, 280)
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(15)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local langLabel = Text("Programming Language:"):setColor(1, 1, 1)
local langComboBox = ComboBox({
    { label = "C#", value = "csharp" },
    { label = "JavaScript", value = "js" },
    { label = "Python", value = "py" },
    { label = "Lua", value = "lua" },
    { label = "Rust", value = "rs" },
    { label = "Go", value = "go" },
    { label = "TypeScript", value = "ts" },
    { label = "C++", value = "cpp" },
    { label = "Java", value = "java" },
    { label = "Ruby", value = "rb" },
})
langComboBox:setPlaceholder("Type to search languages...")

local cityLabel = Text("City:"):setColor(1, 1, 1)
local cityComboBox = ComboBox()
    :setPlaceholder("Search for a city...")
cityComboBox:addItem("New York", "NYC")
cityComboBox:addItem("Los Angeles", "LA")
cityComboBox:addItem("Chicago", "CHI")
cityComboBox:addItem("Houston", "HOU")
cityComboBox:addItem("Phoenix", "PHX")
cityComboBox:addItem("San Francisco", "SF")
cityComboBox:addItem("Seattle", "SEA")
cityComboBox:addItem("Denver", "DEN")
cityComboBox:addItem("Boston", "BOS")
cityComboBox:addItem("Miami", "MIA")

local statusText = Text("Type to filter options")
    :setColor(0.7, 0.9, 1)

langComboBox:watch("selectedIndex", function(index)
    local item = langComboBox:getSelectedItem()
    if item then
        statusText:setText("Selected: " .. item.label .. " (" .. item.value .. ")")
    end
end)

cityComboBox:watch("selectedIndex", function(index)
    local item = cityComboBox:getSelectedItem()
    if item then
        statusText:setText("Selected city: " .. item.label)
    end
end)

panel:addChild(langLabel)
panel:addChild(langComboBox)
panel:addChild(cityLabel)
panel:addChild(cityComboBox)
panel:addChild(statusText)

window:setContent(panel)
host:addChild(window)

return host
