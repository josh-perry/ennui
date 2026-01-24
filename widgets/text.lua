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
    __tostring = function(self)
        return "Text"
    end
})

function Text:__tostring()
    return string.format("Text(%q)", self.props.text or "")
end

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

---Override to calculate height based on wrapped text
---@param availableHeight number Available height
---@return number desiredHeight
function Text:calculateDesiredHeight(availableHeight)
    local height = self.preferredHeight

    if type(height) == "number" then
        return height
    end

    if height.type == "fixed" then
        return height.value
    elseif height.type == "percent" then
        return availableHeight * height.value
    elseif height.type == "fill" then
        return availableHeight
    elseif height.type == "auto" then
        if self.props.text == "" then
            return self.padding.top + self.padding.bottom
        end

        local wrapWidth = self.desiredWidth - self.padding.left - self.padding.right

        if wrapWidth <= 0 then
            -- Fallback to single line if no width available
            return self.props.font:getHeight() + self.padding.top + self.padding.bottom
        end

        -- Calculate wrapped text height
        local _, wrappedLines = self.props.font:getWrap(self.props.text, wrapWidth)
        local lineHeight = self.props.font:getHeight()
        local totalHeight = lineHeight * #wrappedLines

        return totalHeight + self.padding.top + self.padding.bottom
    end

    return 100
end

---Override measure to properly handle text wrapping
---@param availableWidth number Available width in pixels
---@param availableHeight number Available height in pixels
---@return number desiredWidth
---@return number desiredHeight
function Text:measure(availableWidth, availableHeight)
    -- Calculate width first
    local desiredWidth = self:calculateDesiredWidth(availableWidth)

    -- Store it temporarily so calculateDesiredHeight can use it
    self.desiredWidth = desiredWidth

    -- Now calculate height with knowledge of the width
    local desiredHeight = self:calculateDesiredHeight(availableHeight)

    -- Apply constraints
    desiredWidth, desiredHeight = self:__applyConstraints(desiredWidth, desiredHeight)

    -- Store final values
    self.desiredWidth = desiredWidth
    self.desiredHeight = desiredHeight

    self.isLayoutDirty = false

    return desiredWidth, desiredHeight
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

---Alias for setTextHorizontalAlignment
---@param alignment string Horizontal alignment: "left", "center", "right"
---@return Text self
function Text:setTextAlign(alignment)
    return self:setTextHorizontalAlignment(alignment)
end

---Alias for setTextVerticalAlignment
---@param alignment string Vertical alignment: "top", "center", "bottom"
---@return Text self
function Text:setTextVAlign(alignment)
    return self:setTextVerticalAlignment(alignment)
end

return Text