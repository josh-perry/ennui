local Widget = require("ennui.widget")
local Size = require("ennui.size")
local TextInput = require("ennui.widgets.textinput")
local Menu = require("ennui.widgets.menu")

---@class ComboBoxItem
---@field label string Display text
---@field value any Associated value

---@class ComboBox : Widget
---@field items ComboBoxItem[] List of all items
---@field selectedIndex number Currently selected item index (0 = none)
---@field placeholder string Placeholder text when no selection
---@field isOpen boolean Whether dropdown is open
---@field maxVisibleItems number Maximum visible items in dropdown
---@field itemHeight number Height of each item
---@field backgroundColor number[] RGBA color for background
---@field hoverColor number[] RGBA color for hover state
---@field selectedColor number[] RGBA color for selected item
---@field menuColor number[] RGBA color for menu background
---@field textColor number[] RGBA color for text
---@field borderColor number[] RGBA color for border
---@field cornerRadius number Corner radius
---@field __textInput TextInput Internal TextInput widget
---@field __menu Menu Internal Menu widget
---@field __filteredItems ComboBoxItem[] Filtered items based on input
---@field __filteredIndices number[] Maps filtered index to original index
local ComboBox = {}
ComboBox.__index = ComboBox
setmetatable(ComboBox, {
    __index = Widget,
    __call = function(class, items)
        return class.new(items)
    end,
})

function ComboBox:__tostring()
    return "ComboBox"
end

---Create a new combo box widget
---@param items ComboBoxItem[]? Initial items (optional)
---@return ComboBox
function ComboBox.new(items)
    local self = setmetatable(Widget(), ComboBox) ---@cast self ComboBox

    self:addProperty("items", items or {})
    self:addProperty("selectedIndex", 0)
    self:addProperty("placeholder", "Type to search...")
    self:addProperty("isOpen", false)
    self:addProperty("maxVisibleItems", 8)
    self:addProperty("itemHeight", 28)
    self:addProperty("backgroundColor", {0.1, 0.1, 0.1, 1})
    self:addProperty("hoverColor", {0.3, 0.3, 0.3, 1})
    self:addProperty("selectedColor", {0.3, 0.5, 0.8, 1})
    self:addProperty("menuColor", {0.18, 0.18, 0.18, 1})
    self:addProperty("textColor", {1, 1, 1, 1})
    self:addProperty("borderColor", {0.35, 0.35, 0.35, 1})
    self:addProperty("cornerRadius", 4)

    self.__filteredItems = {}
    self.__filteredIndices = {}

    -- Create text input
    self.__textInput = TextInput()
        :setPlaceholder(self.props.placeholder)
        :setSize(Size.fill(), Size.fill())
    self:addChild(self.__textInput)

    -- Create menu widget
    self.__menu = Menu()
    self.__menu:setVisible(false)
    self.__menu.onItemSelected = function(index, item)
        local originalIndex = self.__filteredIndices[index]

        if originalIndex then
            self:selectItem(originalIndex)
        end

        self:close()
    end

    -- Sync properties to menu
    self:watch("itemHeight", function(val)
        self.__menu.props.itemHeight = val
    end, { immediate = true })

    self:watch("maxVisibleItems", function(val)
        self.__menu.props.maxVisibleItems = val
    end, { immediate = true })

    self:watch("menuColor", function(val)
        self.__menu.props.backgroundColor = val
    end, { immediate = true })

    self:watch("hoverColor", function(val)
        self.__menu.props.hoverColor = val
    end, { immediate = true })

    self:watch("selectedColor", function(val)
        self.__menu.props.selectedColor = val
    end, { immediate = true })

    self:watch("textColor", function(val)
        self.__menu.props.textColor = val
        self.__textInput.props.inputTextColor = val
    end, { immediate = true })

    self:watch("borderColor", function(val)
        self.__menu.props.borderColor = val
        self.__textInput.props.borderColor = val
    end, { immediate = true })

    self:watch("cornerRadius", function(val)
        self.__menu.props.cornerRadius = val
    end, { immediate = true })

    self:watch("backgroundColor", function(val)
        self.__textInput.props.inputBackgroundColor = val
    end, { immediate = true })

    self:watch("placeholder", function(val)
        self.__textInput:setPlaceholder(val)
    end, { immediate = true })

    self:setSize(Size.fill(), 32)

    return self
end

---Filter items based on input text
---@param filterText string Text to filter by
---@private
function ComboBox:__filterItems(filterText)
    self.__filteredItems = {}
    self.__filteredIndices = {}

    local lowerFilter = string.lower(filterText)

    for i, item in ipairs(self.props.items) do
        if filterText == "" or string.find(item.label:lower(), lowerFilter, 1, true) then
            table.insert(self.__filteredItems, item)
            table.insert(self.__filteredIndices, i)
        end
    end

    self.__menu:setItems(self.__filteredItems)
end

---Select an item by original index
---@param index number Original item index
function ComboBox:selectItem(index)
    self.props.selectedIndex = index
    local item = self.props.items[index]
    if item then
        self.__textInput:setText(item.label)
        self.__textInput.props.cursorPosition = #item.label
    end
end

---Add an item to the combo box
---@param label string Display text
---@param value any? Associated value (defaults to label)
---@return ComboBox self
function ComboBox:addItem(label, value)
    table.insert(self.props.items, { label = label, value = value or label })
    return self
end

---Remove an item by index
---@param index number Item index to remove
---@return ComboBox self
function ComboBox:removeItem(index)
    table.remove(self.props.items, index)
    if self.props.selectedIndex == index then
        self.props.selectedIndex = 0
        self.__textInput:setText("")
    elseif self.props.selectedIndex > index then
        self.props.selectedIndex = self.props.selectedIndex - 1
    end
    return self
end

---Clear all items
---@return ComboBox self
function ComboBox:clearItems()
    self.props.items = {}
    self.props.selectedIndex = 0
    self.__textInput:setText("")
    return self
end

---Set selected index
---@param index number Item index to select (0 for none)
---@return ComboBox self
function ComboBox:setSelectedIndex(index)
    if index >= 0 and index <= #self.props.items then
        if index == 0 then
            self.props.selectedIndex = 0
            self.__textInput:setText("")
        else
            self:selectItem(index)
        end
    end
    return self
end

---Get selected index
---@return number index
function ComboBox:getSelectedIndex()
    return self.props.selectedIndex
end

---Get selected item
---@return ComboBoxItem? item
function ComboBox:getSelectedItem()
    if self.props.selectedIndex > 0 then
        return self.props.items[self.props.selectedIndex]
    end
    return nil
end

---Get selected value
---@return any? value
function ComboBox:getSelectedValue()
    local item = self:getSelectedItem()
    return item and item.value
end

---Set selected value
---@param value any Value to select
---@return ComboBox self
function ComboBox:setSelectedValue(value)
    for i, item in ipairs(self.props.items) do
        if item.value == value then
            self:selectItem(i)
            break
        end
    end
    return self
end

---Set placeholder text
---@param text string Placeholder text
---@return ComboBox self
function ComboBox:setPlaceholder(text)
    self.props.placeholder = text
    return self
end

---Get the current text in the input
---@return string text
function ComboBox:getText()
    return self.__textInput:getText()
end

---Open the dropdown
---@return ComboBox self
function ComboBox:open()
    if self.props.isOpen then return self end
    self.props.isOpen = true

    -- Filter and position menu
    self:__filterItems(self.__textInput:getText())
    self:__positionMenu()
    self.__menu:setVisible(true)

    -- Register menu as overlay
    local host = self:getHost()
    if host and host.registerOverlay then
        host:registerOverlay(self.__menu)
    end
    return self
end

---Close the dropdown
---@return ComboBox self
function ComboBox:close()
    if not self.props.isOpen then return self end
    self.props.isOpen = false

    self.__menu:setVisible(false)

    local host = self:getHost()
    if host and host.unregisterOverlay then
        host:unregisterOverlay(self.__menu)
    end

    return self
end

---Toggle dropdown open state
---@return ComboBox self
function ComboBox:toggle()
    if self.props.isOpen then
        self:close()
    else
        self:open()
    end
    return self
end

---Position the menu below the input
---@private
function ComboBox:__positionMenu()
    self.__menu.x = self.x
    self.__menu.y = self.y + self.height
    self.__menu.width = self.width
end

---Set background color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return ComboBox self
function ComboBox:setBackgroundColor(r, g, b, a)
    self.props.backgroundColor = {r, g, b, a or 1}
    return self
end

---Set text color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return ComboBox self
function ComboBox:setTextColor(r, g, b, a)
    self.props.textColor = {r, g, b, a or 1}
    return self
end

---Override arrange to keep menu positioned
function ComboBox:arrange(x, y, width, height)
    Widget.arrange(self, x, y, width, height)
    if self.props.isOpen then
        self:__positionMenu()
    end
end

---Handle text input from child
function ComboBox:onTextInput(event)
    if self.props.isOpen then
        self:__filterItems(self.__textInput:getText())
    else
        self:open()
    end

    self.props.selectedIndex = 0
end

---Handle key press
function ComboBox:onKeyPressed(event)
    if event.key == "backspace" or event.key == "delete" then
        if event.value ~= nil then
            if self.props.isOpen then
                self:__filterItems(event.value)
            end

            self.props.selectedIndex = 0
        end
    elseif event.key == "escape" then
        self:close()
        return true
    elseif event.key == "return" then
        if self.props.isOpen and self.__menu.props.hoveredIndex > 0 then
            local originalIndex = self.__filteredIndices[self.__menu.props.hoveredIndex]

            if originalIndex then
                self:selectItem(originalIndex)
            end

            self:close()
            return true
        end
    elseif event.key == "up" then
        if self.props.isOpen then
            local previousIndex = self.__menu.props.hoveredIndex - 1

            if previousIndex >= 1 then
                self.__menu.props.hoveredIndex = previousIndex
            end

            return true
        end
    elseif event.key == "down" then
        if self.props.isOpen then
            local nextIndex = self.__menu.props.hoveredIndex + 1

            if nextIndex <= #self.__filteredItems then
                self.__menu.props.hoveredIndex = nextIndex
            end
        else
            self:open()

            if #self.__filteredItems > 0 then
                self.__menu.props.hoveredIndex = 1
            end
        end

        return true
    end
end

---Handle focus gained
function ComboBox:onFocusGained(event)
    self:open()
end

---Handle focus lost
function ComboBox:onFocusLost(event)
    self:close()
end

return ComboBox
