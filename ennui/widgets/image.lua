local Widget = require("ennui.widget")
local Size = require("ennui.size")

---@class Image : Widget
---@field drawable love.Image|love.Canvas? Drawable to display (Image or Canvas)
---@field scaleX number Horizontal scale factor
---@field scaleY number Vertical scale factor
---@field color number[] RGBA color tint
local Image = {}
Image.__index = Image
setmetatable(Image, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

function Image:__tostring()
    return "Image"
end

---Create a new image widget
---@return Image
---@param drawable love.Image|love.Canvas? Optional drawable to display
function Image.new(drawable)
    local self = setmetatable(Widget(), Image) ---@cast self Image

    self:addProperty("image", drawable)
    self:addProperty("scaleX", 1)
    self:addProperty("scaleY", 1)
    self:addProperty("color", {1, 1, 1, 1})

    self:setHitTransparent(true)
    return self
end

---Set drawable to display
---@param drawable love.Image|love.Canvas? Image or Canvas
---@return Image self
function Image:setDrawable(drawable)
    self.props.image = drawable
    return self
end

---Get drawable
---@return love.Image|love.Canvas? drawable
function Image:getDrawable()
    return self.props.image
end

---Set image from file path
---@param path string Path to image file
---@return Image self
function Image:setImagePath(path)
    local image = love.graphics.newImage(path)
    return self:setDrawable(image)
end

---Set image from ImageData
---@param imageData love.ImageData Image data
---@return Image self
function Image:setImageData(imageData)
    local image = love.graphics.newImage(imageData)
    return self:setDrawable(image)
end

---Set scale
---@param scaleX number Horizontal scale
---@param scaleY number? Vertical scale (defaults to scaleX)
---@return Image self
function Image:setScale(scaleX, scaleY)
    self.props.scaleX = scaleX
    self.props.scaleY = scaleY or scaleX
    return self
end

---Set color tint
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Image self
function Image:setColor(r, g, b, a)
    self.props.color = {r, g, b, a or 1}
    return self
end

---Get drawable dimensions
---@return number width
---@return number height
function Image:getDrawableSize()
    if not self.props.image then
        return 0, 0
    end

    local width, height
    if self.props.image.getWidth and self.props.image.getHeight then
        width = self.props.image:getWidth()
        height = self.props.image:getHeight()
    elseif self.props.image.getDimensions then
        width, height = self.props.image:getDimensions()
    else
        width, height = 0, 0
    end

    return width * self.props.scaleX, height * self.props.scaleY
end

---Calculate content width (for auto sizing)
---@return number contentWidth
function Image:__calculateContentWidth()
    if not self.props.image then
        return self.padding.left + self.padding.right
    end

    local width, _ = self:getDrawableSize()
    return width + self.padding.left + self.padding.right
end

---Calculate content height (for auto sizing)
---@return number contentHeight
function Image:__calculateContentHeight()
    if not self.props.image then
        return self.padding.top + self.padding.bottom
    end

    local _, height = self:getDrawableSize()
    return height + self.padding.top + self.padding.bottom
end

---Render the image
function Image:onRender()
    if not self.props.image then
        return
    end

    love.graphics.setColor(self.props.color)

    local renderX = self.x + self.padding.left
    local renderY = self.y + self.padding.top
    local availableWidth = self.width - self.padding.left - self.padding.right
    local availableHeight = self.height - self.padding.top - self.padding.bottom

    local drawableWidth, drawableHeight = self:getDrawableSize()

    local scaleToFit = math.min(
        availableWidth / drawableWidth,
        availableHeight / drawableHeight
    )

    local finalScaleX = self.props.scaleX * scaleToFit
    local finalScaleY = self.props.scaleY * scaleToFit

    local scaledWidth = drawableWidth * scaleToFit
    local scaledHeight = drawableHeight * scaleToFit
    renderX = renderX + (availableWidth - scaledWidth) / 2
    renderY = renderY + (availableHeight - scaledHeight) / 2

    love.graphics.draw(
        self.props.image,
        renderX,
        renderY,
        0,
        finalScaleX,
        finalScaleY
    )
end

return Image
