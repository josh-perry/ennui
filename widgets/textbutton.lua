local Widget = require("yui.widget")
local Size = require("yui.size")
local Text = require("widgets.text")

---@class TextButton : Widget
---@field textColor number[] RGBA color for text
---@field backgroundColor number[] RGBA color for normal state
---@field hoverColor number[] RGBA color for hover state
---@field pressedColor number[] RGBA color for pressed state
---@field disabledColor number[] RGBA color for disabled state
---@field cornerRadius number Corner radius for rounded corners
---@field __textWidget Text Internal Text widget reference
local TextButton = {}
TextButton.__index = TextButton
setmetatable(TextButton, {
    __index = Widget,
    __call = function(class, text)
        return class.new(text)
    end,
})

---Create a new text button widget
---@param text string? Button text (optional, defaults to "")
---@return TextButton
function TextButton.new(text)
    assert(text == nil or type(text) == "string", "TextButton.new: text must be a string or nil")

    local self = setmetatable(Widget(), TextButton) ---@cast self TextButton

    self:addProperty("text", text or "")
    self:addProperty("textColor", {1, 1, 1, 1})
    self:addProperty("backgroundColor", {0.2, 0.2, 0.2, 1})
    self:addProperty("hoverColor", {0.3, 0.3, 0.3, 1})
    self:addProperty("pressedColor", {0.15, 0.15, 0.15, 1})
    self:addProperty("disabledColor", {0.1, 0.1, 0.1, 1})
    self:addProperty("cornerRadius", 4)

    self.__textWidget = Text()
        :setTextHorizontalAlignment("center")
        :setTextVerticalAlignment("center")
        :setSize(Size.auto(), Size.auto())

    self:addChild(self.__textWidget)

    self:watch("text", function(newText)
        self.__textWidget.props.text = newText
        self:invalidateLayout()
    end, {
        immediate = true
    })

    self:watch("textColor", function(newColor)
        self.__textWidget.props.color = newColor
        self:invalidateRender()
    end, {immediate = true})

    self:setFocusable(true)

    return self
end

---Set button text
---@param text string Text to display
---@return TextButton self
function TextButton:setText(text)
    self.props.text = text
    return self
end

---Get button text
---@return string text
function TextButton:getText()
    return self.props.text
end

---Get the internal Text widget
---@return Text textWidget
function TextButton:getTextWidget()
    return self.__textWidget
end

---Set text color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TextButton self
function TextButton:setTextColor(r, g, b, a)
    self.props.textColor = {r, g, b, a or 1}
    return self
end

---Set background color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TextButton self
function TextButton:setBackgroundColor(r, g, b, a)
    self.props.backgroundColor = {r, g, b, a or 1}
    return self
end

---Set hover color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TextButton self
function TextButton:setHoverColor(r, g, b, a)
    self.props.hoverColor = {r, g, b, a or 1}
    return self
end

---Set pressed color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TextButton self
function TextButton:setPressedColor(r, g, b, a)
    self.props.pressedColor = {r, g, b, a or 1}
    return self
end

---Set disabled color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return TextButton self
function TextButton:setDisabledColor(r, g, b, a)
    self.props.disabledColor = {r, g, b, a or 1}
    return self
end

---Set corner radius
---@param radius number Corner radius in pixels
---@return TextButton self
function TextButton:setCornerRadius(radius)
    self.props.cornerRadius = radius
    return self
end

---Override hitTest to ensure button receives events, not text child
function TextButton:hitTest(x, y)
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
function TextButton:__calculateContentWidth()
    if self.__textWidget:isVisible() then
        return self.__textWidget.desiredWidth + self.padding.left + self.padding.right + 20
    end
    return self.padding.left + self.padding.right + 20
end

---Calculate content height (for auto sizing)
---@return number contentHeight
function TextButton:__calculateContentHeight()
    if self.__textWidget:isVisible() then
        return self.__textWidget.desiredHeight + self.padding.top + self.padding.bottom + 10
    end
    return self.padding.top + self.padding.bottom + 10
end

---Render the text button
function TextButton:onRender()
    local bgColor
    if self.state.isDisabled then
        bgColor = self.props.disabledColor
    elseif self.state.isPressed then
        bgColor = self.props.pressedColor
    elseif self.state.isHovered then
        bgColor = self.props.hoverColor
    else
        bgColor = self.props.backgroundColor
    end

    love.graphics.setColor(bgColor)
    love.graphics.rectangle(
        "fill",
        self.x,
        self.y,
        self.width,
        self.height,
        self.props.cornerRadius,
        self.props.cornerRadius
    )

    if self.state.isFocused then
        love.graphics.setColor(0.5, 0.7, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle(
            "line",
            self.x + 1,
            self.y + 1,
            self.width - 2,
            self.height - 2,
            self.props.cornerRadius,
            self.props.cornerRadius
        )
    end

    if self.__textWidget:isVisible() then
        self.__textWidget:onRender()
    end
end

return TextButton
