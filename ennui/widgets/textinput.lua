local EnnuiRoot = (...):sub(1, (...):len() - (".widgets.textinput"):len())
local Widget = require(EnnuiRoot .. ".widget")
local Size = require(EnnuiRoot .. ".size")
local Text = require(EnnuiRoot .. ".widgets.text")

---@class TextInput : Widget
---@field text string Current text content
---@field placeholder string Placeholder text when empty
---@field isPassword boolean Whether to mask text with dots
---@field cursorPosition number Cursor position (0 = before first char)
---@field cursorBlinkTime number Time accumulator for cursor blink
---@field cursorVisible boolean Whether cursor is currently visible
---@field font love.Font Font to use
---@field textColor number[] RGBA color for text
---@field placeholderColor number[] RGBA color for placeholder
---@field backgroundColor number[] RGBA color for background
---@field borderColor number[] RGBA color for border
---@field focusedBorderColor number[] RGBA color for border when focused
---@field selectionStart number? Start of selection (nil if no selection)
---@field selectionEnd number? End of selection (nil if no selection)
---@field __textWidget Text Child widget for text/placeholder rendering
---@field __selectionAnchor number? Anchor point for drag/keyboard selection
local TextInput = {}
TextInput.__index = TextInput
setmetatable(TextInput, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

function TextInput:__tostring()
    return "TextInput"
end

---Create a new text input widget
---@return TextInput
function TextInput.new()
    local self = setmetatable(Widget(), TextInput) ---@cast self TextInput

    self:addProperty("value", "")
    self:addProperty("placeholder", "")
    self:addProperty("isPassword", false)
    self:addProperty("cursorPosition", 0)
    self:addProperty("cursorBlinkTime", 0)
    self:addProperty("cursorVisible", true)
    self:addProperty("font", love.graphics.getFont())
    self:addProperty("inputTextColor", {1, 1, 1, 1})
    self:addProperty("placeholderColor", {0.5, 0.5, 0.5, 1})
    self:addProperty("inputBackgroundColor", {0.1, 0.1, 0.1, 1})
    self:addProperty("borderColor", {0.3, 0.3, 0.3, 1})
    self:addProperty("focusedBorderColor", {0.5, 0.7, 1, 1})
    self:addProperty("selectionStart", nil)
    self:addProperty("selectionEnd", nil)
    self:addProperty("selectionColor", {0.3, 0.5, 0.8, 0.5})

    self:setFocusable(true)
    self.__selectionAnchor = nil

    self.__textWidget = Text()
        :setFont(self.props.font)
        :setColor(self.props.inputTextColor[1], self.props.inputTextColor[2], self.props.inputTextColor[3], self.props.inputTextColor[4])
        :setSize(Size.fill(), Size.auto())
        :setPadding(4, 4, 4, 4)
        :setHorizontalAlignment("center")
        :setVerticalAlignment("center")

    self:addChild(self.__textWidget)

    return self
end

---Set text content
---@param text string Text to set
---@return TextInput self
function TextInput:setText(text)
    if self.props.value ~= text then
        self.props.value = text
        self.props.cursorPosition = math.min(self.props.cursorPosition, #text)
        self:clearSelection()
        self:__updateTextWidget()
    end

    return self
end

---Get text content
---@return string text
function TextInput:getText()
    return self.props.value
end

---Get the internal Text widget
function TextInput:getTextWidget()
    return self.__textWidget
end

---Set placeholder text
---@param placeholder string Placeholder to display when empty
---@return TextInput self
function TextInput:setPlaceholder(placeholder)
    if self.props.placeholder ~= placeholder then
        self.props.placeholder = placeholder
        self:__updateTextWidget()
    end
    return self
end

---Set password mode
---@param isPassword boolean Whether to mask text
---@return TextInput self
function TextInput:setPassword(isPassword)
    if self.props.isPassword ~= isPassword then
        self.props.isPassword = isPassword
        self:__updateTextWidget()
    end
    return self
end

---Set font
---@param font love.Font Font to use
---@return TextInput self
function TextInput:setFont(font)
    if self.props.font ~= font then
        self.props.font = font
        self.__textWidget:setFont(font)
        self:invalidateLayout()
    end

    return self
end

---Set text color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TextInput self
function TextInput:setTextColor(r, g, b, a)
    self.props.inputTextColor = {r, g, b, a or 1}
    self:__updateTextWidget()

    return self
end

---Set placeholder color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TextInput self
function TextInput:setPlaceholderColor(r, g, b, a)
    self.props.placeholderColor = {r, g, b, a or 1}
    self:__updateTextWidget()
    return self
end

---Set background color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TextInput self
function TextInput:setBackgroundColor(r, g, b, a)
    self.props.inputBackgroundColor = {r, g, b, a or 1}

    return self
end

---Update the child text widget with current display state
---@protected
function TextInput:__updateTextWidget()
    local displayText = self.props.value
    local displayColor = self.props.inputTextColor

    if displayText == "" and self.props.placeholder ~= "" then
        displayText = self.props.placeholder
        displayColor = self.props.placeholderColor
    elseif self.props.isPassword and displayText ~= "" then
        displayText = string.rep("*", #displayText)
    end

    self.__textWidget:setText(displayText)
    self.__textWidget:setColor(displayColor[1], displayColor[2], displayColor[3], displayColor[4])
    self:invalidateLayout()
end

---Clear selection and anchor
function TextInput:clearSelection()
    self.props.selectionStart = nil
    self.props.selectionEnd = nil
end

---Select all text
function TextInput:selectAll()
    self.props.selectionStart = 0
    self.props.selectionEnd = #self.props.value
    self.props.cursorPosition = #self.props.value
    self.__selectionAnchor = nil
end

---Get display text (masked if password mode)
---@return string displayText
function TextInput:getDisplayText()
    if self.props.isPassword and #self.props.value > 0 then
        return string.rep("*", #self.props.value)
    end
    return self.props.value
end

---Replace the current selection with replacement text, then clear selection and anchor.
---@param replacement string
---@protected
function TextInput:__replaceSelection(replacement)
    local selStart = math.min(self.props.selectionStart, self.props.selectionEnd)
    local selEnd   = math.max(self.props.selectionStart, self.props.selectionEnd)
    self.props.value = string.sub(self.props.value, 1, selStart) .. replacement .. string.sub(self.props.value, selEnd + 1)
    self.props.cursorPosition = selStart + #replacement

    self:clearSelection()
    self.__selectionAnchor = nil
end

---Update selectionStart/End from anchor to cursor, or clear if they match.
---@protected
function TextInput:__updateSelectionFromAnchor()
    if self.props.cursorPosition ~= self.__selectionAnchor then
        self.props.selectionStart = self.__selectionAnchor
        self.props.selectionEnd   = self.props.cursorPosition
    else
        self:clearSelection()
    end
end

---Calculate content width (for auto sizing)
---@private
---@return number contentWidth
function TextInput:__calculateContentWidth()
    return 100 + self.padding.left + self.padding.right
end

---Calculate content height (for auto sizing)
---@private
---@return number contentHeight
function TextInput:__calculateContentHeight()
    local maxChildHeight = 0
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            maxChildHeight = math.max(maxChildHeight, child.desiredHeight)
        end
    end
    return maxChildHeight + self.padding.top + self.padding.bottom + 10
end

---Update cursor blink
---@param dt number Delta time
function TextInput:onUpdate(dt)
    if self.props.isFocused then
        self.props.cursorBlinkTime = self.props.cursorBlinkTime + dt
        if self.props.cursorBlinkTime >= 0.5 then
            self.props.cursorVisible = not self.props.cursorVisible
            self.props.cursorBlinkTime = 0
            self:invalidateRender()
        end
    end

    for _, child in ipairs(self.children) do
        if child:isVisible() then
            child:onUpdate(dt)
        end
    end
end

---Handle text input
---@param event TextInputEvent Text input event
function TextInput:onTextInput(event)
    if not self.props.isFocused or self.props.isDisabled then
        return
    end

    if self.props.selectionStart ~= nil then
        self:__replaceSelection(event.text)
    else
        local before = string.sub(self.props.value, 1, self.props.cursorPosition)
        local after = string.sub(self.props.value, self.props.cursorPosition + 1)
        self.props.value = before .. event.text .. after
        self.props.cursorPosition = self.props.cursorPosition + #event.text
    end

    self.props.cursorVisible = true
    self.props.cursorBlinkTime = 0
    self:__updateTextWidget()
    event.value = self.props.value
end

---Handle key press
---@param event KeyboardEvent Keyboard event
function TextInput:onKeyPressed(event)
    if not self.props.isFocused or self.props.isDisabled then
        return
    end

    local key = event.key
    local textChanged = false

    if key == "backspace" then
        if self.props.selectionStart ~= nil then
            self:__replaceSelection("")
            textChanged = true
            self:__updateTextWidget()
        elseif self.props.cursorPosition > 0 then
            local before = string.sub(self.props.value, 1, self.props.cursorPosition - 1)
            local after  = string.sub(self.props.value, self.props.cursorPosition + 1)
            self.props.value = before .. after
            self.props.cursorPosition = self.props.cursorPosition - 1
            textChanged = true
            self:__updateTextWidget()
        end
    elseif key == "delete" then
        if self.props.selectionStart ~= nil then
            self:__replaceSelection("")
            textChanged = true
            self:__updateTextWidget()
        elseif self.props.cursorPosition < #self.props.value then
            local before = string.sub(self.props.value, 1, self.props.cursorPosition)
            local after  = string.sub(self.props.value, self.props.cursorPosition + 2)
            self.props.value = before .. after
            textChanged = true
            self:__updateTextWidget()
        end
    elseif key == "left" then
        if event.modifiers.shift then
            if self.__selectionAnchor == nil then
                self.__selectionAnchor = self.props.cursorPosition
            end

            self.props.cursorPosition = math.max(0, self.props.cursorPosition - 1)

            self:__updateSelectionFromAnchor()
        else
            if self.props.selectionStart ~= nil then
                self.props.cursorPosition = math.min(self.props.selectionStart, self.props.selectionEnd)
                self:clearSelection()
            elseif self.props.cursorPosition > 0 then
                self.props.cursorPosition = self.props.cursorPosition - 1
            end

            self.__selectionAnchor = nil
        end

        self:invalidateRender()
    elseif key == "right" then
        if event.modifiers.shift then
            if self.__selectionAnchor == nil then
                self.__selectionAnchor = self.props.cursorPosition
            end

            self.props.cursorPosition = math.min(self.props.cursorPosition + 1, #self.props.value)

            self:__updateSelectionFromAnchor()
        else
            if self.props.selectionStart ~= nil then
                self.props.cursorPosition = math.max(self.props.selectionStart, self.props.selectionEnd)
                self:clearSelection()
            elseif self.props.cursorPosition < #self.props.value then
                self.props.cursorPosition = self.props.cursorPosition + 1
            end

            self.__selectionAnchor = nil
        end

        self:invalidateRender()
    elseif key == "home" then
        self:clearSelection()
        self.__selectionAnchor = nil
        self.props.cursorPosition = 0
        self:invalidateRender()
    elseif key == "end" then
        self:clearSelection()
        self.__selectionAnchor = nil
        self.props.cursorPosition = #self.props.value
        self:invalidateRender()
    elseif key == "a" and event.modifiers.ctrl then
        self:selectAll()
        self:invalidateRender()
    end

    self.props.cursorVisible = true
    self.props.cursorBlinkTime = 0

    if textChanged then
        event.value = self.props.value
    end
end

---Handle focus gained
function TextInput:onFocusGained()
    self.props.cursorVisible = true
    self.props.cursorBlinkTime = 0
    self:invalidateRender()
end

---Handle focus lost
function TextInput:onFocusLost()
    self:clearSelection()
    self.__selectionAnchor = nil
    self:invalidateRender()
end

---Calculate the character position closest to a given X coordinate
---@param localX number X coordinate relative to the widget
---@return number position Character position
function TextInput:__xToPosition(localX)
    local displayText = self:getDisplayText()
    local clickX = localX - self.padding.left - self.__textWidget.padding.left

    local closestPos = 0
    local closestDist = math.abs(clickX)

    for i = 1, #displayText do
        local dist = math.abs(clickX - self.props.font:getWidth(string.sub(displayText, 1, i)))

        if dist < closestDist then
            closestDist = dist
            closestPos = i
        end
    end

    return closestPos
end

---Handle mouse pressed
---@param event MouseEvent Mouse event
function TextInput:onMousePressed(event)
    local position  = self:__xToPosition(event.localX)
    self.props.cursorPosition = position
    self.__selectionAnchor = position

    self:clearSelection()

    self.props.cursorVisible = true
    self.props.cursorBlinkTime = 0
    self:invalidateRender()
end

---Handle mouse moved (drag selection)
---@param event MouseEvent Mouse event
function TextInput:onMouseMoved(event)
    if not self.__selectionAnchor or not love.mouse.isDown(1) then
        return
    end

    local position = self:__xToPosition(event.localX)
    self.props.cursorPosition = position

    if position ~= self.__selectionAnchor then
        self.props.selectionStart = self.__selectionAnchor
        self.props.selectionEnd = position
    else
        self:clearSelection()
    end

    self:invalidateRender()
end

---Handle mouse released
function TextInput:onMouseReleased()
    self.__selectionAnchor = nil
end

---Override hitTest to return TextInput itself, not the Text child
---@param x number Point X
---@param y number Point Y
---@return Widget? hitWidget
function TextInput:hitTest(x, y)
    if not self:isVisible() then
        return nil
    end

    if not self:containsPoint(x, y) then
        return nil
    end

    return self
end

---Render the text input
function TextInput:onRender()
    local borderColor = self.props.isFocused and self.props.focusedBorderColor or self.props.borderColor

    love.graphics.setColor(self.props.inputBackgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(self.props.isFocused and 2 or 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    local prevScissorX, prevScissorY, prevScissorW, prevScissorH = love.graphics.getScissor()
    local newX = self.x + self.padding.left
    local newY = self.y + self.padding.top
    local newW = self.width - self.padding.left - self.padding.right
    local newH = self.height - self.padding.top - self.padding.bottom

    if prevScissorX then
        local right = math.min(newX + newW, prevScissorX + prevScissorW)
        local bottom = math.min(newY + newH, prevScissorY + prevScissorH)
        newX = math.max(newX, prevScissorX)
        newY = math.max(newY, prevScissorY)
        newW = math.max(0, right - newX)
        newH = math.max(0, bottom - newY)
    end

    love.graphics.setScissor(newX, newY, newW, newH)

    self.__textWidget:onRender()

    local textX = self.__textWidget.x + self.__textWidget.padding.left
    local textY = self.__textWidget.y + self.__textWidget.padding.top
    local displayText = self:getDisplayText()

    if self.props.selectionStart ~= nil then
        local selStart = math.min(self.props.selectionStart, self.props.selectionEnd)
        local selEnd = math.max(self.props.selectionStart, self.props.selectionEnd)
        local selX = textX + self.props.font:getWidth(string.sub(displayText, 1, selStart))
        local selWidth = self.props.font:getWidth(string.sub(displayText, selStart + 1, selEnd))

        love.graphics.setColor(self.props.selectionColor)
        love.graphics.rectangle("fill", selX, textY, selWidth, self.props.font:getHeight())
    end

    if self.props.isFocused and self.props.cursorVisible then
        local cursorX = textX + self.props.font:getWidth(string.sub(displayText, 1, self.props.cursorPosition))
        love.graphics.setColor(self.props.inputTextColor)
        love.graphics.setLineWidth(1)
        love.graphics.line(cursorX, textY, cursorX, textY + self.props.font:getHeight())
    end

    if prevScissorX then
        love.graphics.setScissor(prevScissorX, prevScissorY, prevScissorW, prevScissorH)
    else
        love.graphics.setScissor()
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return TextInput
