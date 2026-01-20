local Widget = require("ennui.widget")
local Size = require("ennui.size")
local Text = require("widgets.text")
local HorizontalStackPanel = require("widgets.horizontalstackpanel")
local Rectangle = require("widgets.rectangle")

---@class RadioButton : Widget
---@field selected boolean Whether this radio button is selected
---@field groupName string Name of the radio group this belongs to
---@field radioSize number Size of the radio circle in pixels
---@field radioColor number[] RGBA color for the radio border
---@field selectedColor number[] RGBA color for the selected indicator
---@field backgroundColor number[] RGBA color for the radio background
---@field hoverColor number[] RGBA color for hover state
---@field textColor number[] RGBA color for the label text
---@field spacing number Spacing between radio and label
---@field value any Value associated with this radio button
---@field __textWidget Text Internal Text widget reference
---@field __layoutContainer HorizontalStackPanel Internal layout container
---@field __indicatorPlaceholder Rectangle Internal placeholder for radio indicator
local RadioButton = {}
RadioButton.__index = RadioButton
setmetatable(RadioButton, {
    __index = Widget,
    __call = function(class, label, groupName, value)
        return class.new(label, groupName, value)
    end,
})

---Create a new radio button widget
---@param label string? Radio button label text (optional)
---@param groupName string? Name of the radio group (optional)
---@param value any? Value associated with this radio button (optional)
---@return RadioButton
function RadioButton.new(label, groupName, value)
    local self = setmetatable(Widget(), RadioButton) ---@cast self RadioButton

    self:addProperty("selected", false)
    self:addProperty("groupName", groupName or "default")
    self:addProperty("radioSize", 18)
    self:addProperty("radioColor", {0.5, 0.5, 0.5, 1})
    self:addProperty("selectedColor", {0.3, 0.7, 1, 1})
    self:addProperty("backgroundColor", {0.15, 0.15, 0.15, 1})
    self:addProperty("hoverColor", {0.2, 0.2, 0.2, 1})
    self:addProperty("textColor", {1, 1, 1, 1})
    self:addProperty("spacing", 8)
    self:addProperty("label", label or "")
    self:addProperty("value", value)

    -- Create internal layout container
    self.__layoutContainer = HorizontalStackPanel()
        :setSpacing(self.props.spacing)
        :setSize(Size.auto(), Size.auto())
        :setHitTransparent(true)

    -- Create indicator placeholder (invisible, just for layout)
    self.__indicatorPlaceholder = Rectangle()
        :setSize(self.props.radioSize, self.props.radioSize)
        :setColor(0, 0, 0, 0) -- Invisible

    -- Create text widget
    self.__textWidget = Text()
        :setTextVerticalAlignment("center")
        :setSize(Size.auto(), Size.auto())

    -- Build layout structure
    self.__layoutContainer:addChild(self.__indicatorPlaceholder)
    self.__layoutContainer:addChild(self.__textWidget)
    self:addChild(self.__layoutContainer)

    self:watch("label", function(newLabel)
        self.__textWidget.props.text = newLabel
        self:invalidateLayout()
    end, { immediate = true })

    self:watch("textColor", function(newColor)
        self.__textWidget.props.color = newColor
        self:invalidateRender()
    end, { immediate = true })

    self:watch("spacing", function(newSpacing)
        self.__layoutContainer:setSpacing(newSpacing)
        self:invalidateLayout()
    end)

    self:watch("radioSize", function(newSize)
        self.__indicatorPlaceholder:setSize(newSize, newSize)
        self:invalidateLayout()
    end)

    self:setFocusable(true)

    self:on("clicked", function()
        if not self.state.isDisabled then
            self:select()
        end
    end)

    self:on("keyPressed", function(_, event)
        if event.key == "space" or event.key == "return" then
            if not self.state.isDisabled then
                self:select()
            end
            return true
        end
    end)

    return self
end

---Select this radio button and deselect siblings in the same group
function RadioButton:select()
    if self.props.selected then return self end

    -- Find and deselect other radio buttons in the same group
    local parent = self.parent
    if parent then
        for _, sibling in ipairs(parent.children) do
            if sibling ~= self and sibling.props and sibling.props.groupName == self.props.groupName then
                if sibling.props.selected then
                    sibling.props.selected = false
                end
            end
        end
    end

    self.props.selected = true
    return self
end

---Set the selected state
---@param selected boolean Whether the radio button is selected
---@return RadioButton self
function RadioButton:setSelected(selected)
    if selected then
        self:select()
    else
        self.props.selected = false
    end
    return self
end

---Get the selected state
---@return boolean selected
function RadioButton:isSelected()
    return self.props.selected
end

---Set the label text
---@param label string Label text
---@return RadioButton self
function RadioButton:setLabel(label)
    self.props.label = label
    return self
end

---Get the label text
---@return string label
function RadioButton:getLabel()
    return self.props.label
end

---Set the value
---@param value any Value associated with this radio button
---@return RadioButton self
function RadioButton:setValue(value)
    self.props.value = value
    return self
end

---Get the value
---@return any value
function RadioButton:getValue()
    return self.props.value
end

---Set text color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return RadioButton self
function RadioButton:setTextColor(r, g, b, a)
    self.props.textColor = {r, g, b, a or 1}
    return self
end

---Set radio color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return RadioButton self
function RadioButton:setRadioColor(r, g, b, a)
    self.props.radioColor = {r, g, b, a or 1}
    return self
end

---Set selected color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return RadioButton self
function RadioButton:setSelectedColor(r, g, b, a)
    self.props.selectedColor = {r, g, b, a or 1}
    return self
end

---Set radio size
---@param size number Size in pixels
---@return RadioButton self
function RadioButton:setRadioSize(size)
    self.props.radioSize = size
    return self
end

---Override hitTest to ensure radio button receives events
function RadioButton:hitTest(x, y)
    if not self:isVisible() then
        return nil
    end

    if not self:containsPoint(x, y) then
        return nil
    end

    return self
end

---Calculate content width (for auto sizing)
---@return number contentWidth
function RadioButton:__calculateContentWidth()
    return self.__layoutContainer.desiredWidth + self.padding.left + self.padding.right
end

---Calculate content height (for auto sizing)
---@return number contentHeight
function RadioButton:__calculateContentHeight()
    return self.__layoutContainer.desiredHeight + self.padding.top + self.padding.bottom
end

---Render the radio button
function RadioButton:onRender()
    local radioSize = self.props.radioSize
    -- Use the indicator placeholder's position for drawing the actual radio circle
    local radioX = self.__indicatorPlaceholder.x + radioSize / 2
    local radioY = self:__centerVertically(radioSize) + radioSize / 2

    -- Draw background circle
    local bgColor = self.state.isHovered and self.props.hoverColor or self.props.backgroundColor
    love.graphics.setColor(bgColor)
    love.graphics.circle("fill", radioX, radioY, radioSize / 2)

    -- Draw border
    love.graphics.setColor(self.props.radioColor)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", radioX, radioY, radioSize / 2)

    -- Draw selection indicator if selected
    if self.props.selected then
        love.graphics.setColor(self.props.selectedColor)
        love.graphics.circle("fill", radioX, radioY, radioSize / 4)
    end

    -- Draw focus indicator
    if self.state.isFocused then
        love.graphics.setColor(0.5, 0.7, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", radioX, radioY, radioSize / 2 + 3)
        love.graphics.setLineWidth(1)
    end

    -- Render label
    if self.__textWidget:isVisible() then
        self.__textWidget:onRender()
    end
end

return RadioButton
