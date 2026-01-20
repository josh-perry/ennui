local Widget = require("ennui.widget")

---@class Text : Widget
---@field text string Text to display
---@field color number[] RGBA color array
---@field font love.Font Font to use
---@field textHorizontalAlignment string Horizontal alignment: "left", "center", "right"
---@field textVerticalAlignment string Vertical alignment: "top", "center", "bottom"
local Text = {}
Text.__index = Text
setmetatable(Text, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

---@return Text
function Text.new(text)
    local self = setmetatable(Widget(), Text) ---@cast self Text

    self:addProperty("text", text or "")
    self:addProperty("color", {1, 1, 1, 1})
    self:addProperty("font", love.graphics.getFont())
    self:addProperty("textHorizontalAlignment", "left")
    self:addProperty("textVerticalAlignment", "top")

    self:setHitTransparent(true)

    return self
end

---@param text string Text to display
---@return Text self
function Text:setText(text)
    self.props.text = text
    return self
end

---@return string text
function Text:getText()
    return self.props.text
end

---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Text self
function Text:setColor(r, g, b, a)
    self.props.color = {r, g, b, a or 1}
    return self
end

---@param font love.Font Font to use
---@return Text self
function Text:setFont(font)
    self.props.font = font
    return self
end

---@return number contentWidth
function Text:__calculateContentWidth()
    if self.props.text == "" then
        return self.padding.left + self.padding.right
    end

    return self.props.font:getWidth(self.props.text) + self.padding.left + self.padding.right
end

---@return number contentHeight
function Text:__calculateContentHeight()
    if self.props.text == "" then
        return self.padding.top + self.padding.bottom
    end
    return self.props.font:getHeight() + self.padding.top + self.padding.bottom
end

function Text:onRender()
    if not self.props.text or self.props.text == "" then return end

    love.graphics.setFont(self.props.font)
    love.graphics.setColor(unpack(self.props.color))

    local textHeight = self.props.font:getHeight()

    local textX = self.x + self.padding.left
    local textY = self.y + self.padding.top
    local contentWidth = self.width - self.padding.left - self.padding.right

    if self.props.textVerticalAlignment == "center" then
        local contentHeight = self.height - self.padding.top - self.padding.bottom
        textY = self.y + self.padding.top + (contentHeight - textHeight) / 2
    elseif self.props.textVerticalAlignment == "bottom" then
        local contentHeight = self.height - self.padding.top - self.padding.bottom
        textY = self.y + self.padding.top + contentHeight - textHeight
    end

    local printAlignment = "left"

    if self.props.textHorizontalAlignment == "center" then
        printAlignment = "center"
    elseif self.props.textHorizontalAlignment == "right" then
        printAlignment = "right"
    end

    love.graphics.printf(self.props.text, textX, textY, contentWidth, printAlignment)
end


function Text:setTextHorizontalAlignment(alignment)
    self.props.textHorizontalAlignment = alignment
    return self
end

function Text:setTextVerticalAlignment(alignment)
    self.props.textVerticalAlignment = alignment
    return self
end

return Text