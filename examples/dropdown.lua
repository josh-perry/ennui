local ennui = require("ennui")

local Dropdown = require("widgets.dropdown")
local StackPanel = require("widgets.stackpanel")
local Text = require("widgets.text")
local Window = require("widgets.window")

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Dropdown Example")
    :setSize(350, 300)
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(15)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local fruitLabel = Text("Select a fruit:"):setColor(1, 1, 1)
local fruitDropdown = Dropdown({
    { label = "Apple", value = "apple" },
    { label = "Banana", value = "banana" },
    { label = "Cherry", value = "cherry" },
    { label = "Dragon Fruit", value = "dragonfruit" },
    { label = "Elderberry", value = "elderberry" },
})
fruitDropdown:setSelectedIndex(1)

local countryLabel = Text("Select a country:"):setColor(1, 1, 1)
local countryDropdown = Dropdown()
    :addItem("United States", "US")
    :addItem("United Kingdom", "UK")
    :addItem("Canada", "CA")
    :addItem("Australia", "AU")
    :addItem("Germany", "DE")
    :addItem("Japan", "JP")

local selectionText = Text("Selected: none")
    :setColor(0.7, 0.9, 1)

fruitDropdown:watch("selectedIndex", function(index)
    local item = fruitDropdown:getSelectedItem()
    if item then
        selectionText:setText("Selected fruit: " .. item.label)
    end
end)

countryDropdown:watch("selectedIndex", function(index)
    local item = countryDropdown:getSelectedItem()
    if item then
        selectionText:setText("Selected country: " .. item.label .. " (" .. item.value .. ")")
    end
end)

panel:addChild(fruitLabel)
panel:addChild(fruitDropdown)
panel:addChild(countryLabel)
panel:addChild(countryDropdown)
panel:addChild(selectionText)

window:setContent(panel)
host:addChild(window)

return host
