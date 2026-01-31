local Widget = require("ennui.widget")

---@class Splitter : Widget
---@field orientation "horizontal"|"vertical" Splitter orientation
---@field thickness number Thickness in pixels (default 4)
---@field minSize number Minimum size for draggable region
---@field onSplitterDrag function? Callback when dragged
---@field isHovered boolean Whether mouse is over splitter
local Splitter = setmetatable({}, Widget)
Splitter.__index = Splitter
setmetatable(Splitter, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end
})

---Creates a new Splitter
---@param orientation "horizontal"|"vertical"
---@return self
function Splitter.new(orientation)
    local self = setmetatable(Widget.new(), Splitter) ---@cast self Splitter

    if orientation ~= "horizontal" and orientation ~= "vertical" then
        error("Orientation must be 'horizontal' or 'vertical'")
    end

    self.orientation = orientation
    self.thickness = 4
    self.minSize = 100
    self.onSplitterDrag = nil

    -- State properties
    self:addProperty("normalColor", {0.3, 0.3, 0.3})
    self:addProperty("hoverColor", {0.5, 0.5, 0.5})
    self:addProperty("activeColor", {0.7, 0.7, 0.7})

    self.isHovered = false

    -- Configure generic drag system for delta-based dragging
    self:setDraggable(true)
    self:setDragMode("delta")

    -- Set up drag callback to handle splitter movement
    self.onDrag = function(event, deltaX, deltaY)
        local delta = (self.orientation == "horizontal") and deltaX or deltaY
        if self.onSplitterDrag then
            self.onSplitterDrag(delta)
        end
    end

    return self
end

---Set the splitter thickness
---@param thickness number
---@return self
function Splitter:setThickness(thickness)
    self.thickness = thickness
    self:invalidateLayout()
    return self
end

---Set minimum size constraint
---@param minSize number
---@return self
function Splitter:setMinSize(minSize)
    self.minSize = minSize
    return self
end

---Handle mouse entered
---@param event MouseEvent
function Splitter:onMouseEntered(event)
    self.isHovered = true
    self:invalidateRender()

    -- Change cursor
    if self.orientation == "horizontal" then
        love.mouse.setCursor(love.mouse.getSystemCursor("sizewe"))
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("sizens"))
    end
end

---Handle mouse exited
---@param event MouseEvent
function Splitter:onMouseExited(event)
    if not self.props.isDragging then
        self.isHovered = false
        self:invalidateRender()
        love.mouse.setCursor()
    end
end

---Handle mouse moved
---@param event MouseEvent
function Splitter:onMouseMoved(event)
    if self:hitTest(event.x, event.y) then
        if not self.isHovered then
            self.isHovered = true
            self:invalidateRender()

            if self.orientation == "horizontal" then
                love.mouse.setCursor(love.mouse.getSystemCursor("sizewe"))
            else
                love.mouse.setCursor(love.mouse.getSystemCursor("sizens"))
            end
        end
    else
        if self.isHovered and not self:isDragging() then
            self.isHovered = false
            self:invalidateRender()
            love.mouse.setCursor()
        end
    end
end

---Handle mouse released
---@param event MouseEvent
function Splitter:onMouseReleased(event)
    if not self:isDragging() and not self.isHovered then
        love.mouse.setCursor()
    end
end

---Measure the splitter
---@param availableWidth number
---@param availableHeight number
---@return number, number
function Splitter:measure(availableWidth, availableHeight)
    if self.orientation == "horizontal" then
        return self.thickness, availableHeight
    else
        return availableWidth, self.thickness
    end
end

---Render the splitter
function Splitter:onRender()
    local color = self.props.normalColor

    if self.props.isDragging then
        color = self.props.activeColor
    elseif self.isHovered then
        color = self.props.hoverColor
    end

    love.graphics.setColor(color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return Splitter
