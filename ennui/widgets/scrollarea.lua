local Widget = require("ennui.widget")
local Size = require("ennui.size")
local Scissor = require("ennui.utils.scissor")
local AABB = require("ennui.utils.aabb")

---@class ScrollArea : Widget
---@field scrollX number Current horizontal scroll position
---@field scrollY number Current vertical scroll position
---@field scrollBarWidth number Width of scroll bars
---@field scrollBarColor number[] RGBA color for scroll bar
---@field scrollBarHoverColor number[] RGBA color for scroll bar hover
---@field scrollBarTrackColor number[] RGBA color for scroll bar track
---@field showHorizontalScrollBar boolean Whether to show horizontal scroll bar
---@field showVerticalScrollBar boolean Whether to show vertical scroll bar
---@field scrollSpeed number Scroll speed multiplier
---@field __contentWidth number Measured content width
---@field __contentHeight number Measured content height
---@field __isDraggingVertical boolean Whether dragging vertical scroll bar
---@field __isDraggingHorizontal boolean Whether dragging horizontal scroll bar
---@field __dragStartY number Y position when drag started
---@field __dragStartX number X position when drag started
---@field __dragStartScrollY number Scroll Y when drag started
---@field __dragStartScrollX number Scroll X when drag started
---@field __verticalBarHovered boolean Whether vertical bar is hovered
---@field __horizontalBarHovered boolean Whether horizontal bar is hovered
local ScrollArea = {}
ScrollArea.__index = ScrollArea
setmetatable(ScrollArea, {
    __index = Widget,
    __call = function(class)
        return class.new()
    end,
})

function ScrollArea:__tostring()
    return "ScrollArea"
end

---Create a new scroll area widget
---@return ScrollArea
function ScrollArea.new()
    local self = setmetatable(Widget(), ScrollArea) ---@cast self ScrollArea

    self:addProperty("scrollX", 0)
    self:addProperty("scrollY", 0)
    self:addProperty("scrollBarWidth", 10)
    self:addProperty("scrollBarColor", {0.5, 0.5, 0.5, 1})
    self:addProperty("scrollBarHoverColor", {0.7, 0.7, 0.7, 1})
    self:addProperty("scrollBarTrackColor", {0.2, 0.2, 0.2, 1})
    self:addProperty("showHorizontalScrollBar", true)
    self:addProperty("showVerticalScrollBar", true)
    self:addProperty("scrollSpeed", 20)

    self.__contentWidth = 0
    self.__contentHeight = 0
    self.__isDraggingVertical = false
    self.__isDraggingHorizontal = false
    self.__dragStartY = 0
    self.__dragStartX = 0
    self.__dragStartScrollY = 0
    self.__dragStartScrollX = 0
    self.__verticalBarHovered = false
    self.__horizontalBarHovered = false

    self:on("mousePressed", function(_, event)
        ---@diagnostic disable-next-line: invisible
        return self:__handleMousePressed(event)
    end)

    self:on("mouseReleased", function(_, event)
        self.__isDraggingVertical = false
        self.__isDraggingHorizontal = false
    end)

    self:on("mouseMoved", function(_, event)
        ---@diagnostic disable-next-line: invisible
        return self:__handleMouseMoved(event)
    end)

    return self
end

---Handle mouse pressed on scroll bars
---@private
function ScrollArea:__handleMousePressed(event)
    if event.button ~= 1 then return false end

    local vBarX, vBarY, vBarW, vBarH = self:__getVerticalScrollBarRect()
    local hBarX, hBarY, hBarW, hBarH = self:__getHorizontalScrollBarRect()

    -- Check vertical scroll bar
    if self:__needsVerticalScroll() and
       AABB.containsPoint(event.x, event.y, vBarX, vBarY, vBarW, vBarH) then
        self.__isDraggingVertical = true
        self.__dragStartY = event.y
        self.__dragStartScrollY = self.props.scrollY
        return true
    end

    -- Check horizontal scroll bar
    if self:__needsHorizontalScroll() and
       AABB.containsPoint(event.x, event.y, hBarX, hBarY, hBarW, hBarH) then
        self.__isDraggingHorizontal = true
        self.__dragStartX = event.x
        self.__dragStartScrollX = self.props.scrollX
        return true
    end

    return false
end

---Handle mouse moved for scroll bar dragging
---@private
function ScrollArea:__handleMouseMoved(event)
    -- Update hover states
    local vBarX, vBarY, vBarW, vBarH = self:__getVerticalScrollBarRect()
    local hBarX, hBarY, hBarW, hBarH = self:__getHorizontalScrollBarRect()

    self.__verticalBarHovered = self:__needsVerticalScroll() and
        AABB.containsPoint(event.x, event.y, vBarX, vBarY, vBarW, vBarH)

    self.__horizontalBarHovered = self:__needsHorizontalScroll() and
        AABB.containsPoint(event.x, event.y, hBarX, hBarY, hBarW, hBarH)

    -- Handle dragging
    if self.__isDraggingVertical then
        local viewHeight = self:__getViewportHeight()
        local trackHeight = viewHeight - self.props.scrollBarWidth
        local barHeight = self:__getVerticalBarHeight()
        local maxBarY = trackHeight - barHeight

        local deltaY = event.y - self.__dragStartY
        local scrollRatio = deltaY / maxBarY
        local maxScroll = self.__contentHeight - viewHeight

        self.props.scrollY = math.max(0, math.min(maxScroll,
            self.__dragStartScrollY + scrollRatio * maxScroll))
        self:invalidateLayout()
        return true
    end

    if self.__isDraggingHorizontal then
        local viewWidth = self:__getViewportWidth()
        local trackWidth = viewWidth - self.props.scrollBarWidth
        local barWidth = self:__getHorizontalBarWidth()
        local maxBarX = trackWidth - barWidth

        local deltaX = event.x - self.__dragStartX
        local scrollRatio = deltaX / maxBarX
        local maxScroll = self.__contentWidth - viewWidth

        self.props.scrollX = math.max(0, math.min(maxScroll,
            self.__dragStartScrollX + scrollRatio * maxScroll))
        self:invalidateLayout()
        return true
    end

    return false
end

---Handle mouse wheel scrolling
---@param event MouseEvent
function ScrollArea:onMouseWheel(event)
    local scrolled = false

    if self:__needsVerticalScroll() then
        local maxScroll = self.__contentHeight - self:__getViewportHeight()
        local newScrollY = self.props.scrollY - event.dy * self.props.scrollSpeed
        newScrollY = math.max(0, math.min(maxScroll, newScrollY))

        if newScrollY ~= self.props.scrollY then
            self.props.scrollY = newScrollY
            scrolled = true
        end
    end

    if self:__needsHorizontalScroll() and event.dx ~= 0 then
        local maxScroll = self.__contentWidth - self:__getViewportWidth()
        local newScrollX = self.props.scrollX - event.dx * self.props.scrollSpeed
        newScrollX = math.max(0, math.min(maxScroll, newScrollX))

        if newScrollX ~= self.props.scrollX then
            self.props.scrollX = newScrollX
            scrolled = true
        end
    end

    if scrolled then
        self:invalidateLayout()
        event:consume()
        return true
    end

    return false
end

---Get base viewport width (without considering scrollbars)
---@return number width
function ScrollArea:__getBaseViewportWidth()
    return self.width - self.padding.left - self.padding.right
end

---Get base viewport height (without considering scrollbars)
---@return number height
function ScrollArea:__getBaseViewportHeight()
    return self.height - self.padding.top - self.padding.bottom
end

---Check if vertical scroll is needed
---@return boolean needsScroll
function ScrollArea:__needsVerticalScroll()
    local baseHeight = self:__getBaseViewportHeight()
    return self.props.showVerticalScrollBar and self.__contentHeight > baseHeight
end

---Check if horizontal scroll is needed
---@return boolean needsScroll
function ScrollArea:__needsHorizontalScroll()
    local baseWidth = self:__getBaseViewportWidth()
    return self.props.showHorizontalScrollBar and self.__contentWidth > baseWidth
end

---Get viewport width (content area minus scroll bars)
---@return number width
function ScrollArea:__getViewportWidth()
    local width = self:__getBaseViewportWidth()
    if self:__needsVerticalScroll() then
        width = width - self.props.scrollBarWidth
    end
    return width
end

---Get viewport height (content area minus scroll bars)
---@return number height
function ScrollArea:__getViewportHeight()
    local height = self:__getBaseViewportHeight()
    if self:__needsHorizontalScroll() then
        height = height - self.props.scrollBarWidth
    end
    return height
end

---Get vertical scroll bar height
---@return number height
function ScrollArea:__getVerticalBarHeight()
    local viewHeight = self:__getViewportHeight()
    local ratio = viewHeight / self.__contentHeight
    return math.max(20, viewHeight * ratio)
end

---Get horizontal scroll bar width
---@return number width
function ScrollArea:__getHorizontalBarWidth()
    local viewWidth = self:__getViewportWidth()
    local ratio = viewWidth / self.__contentWidth
    return math.max(20, viewWidth * ratio)
end

---Get vertical scroll bar rectangle
---@return number x, number y, number width, number height
function ScrollArea:__getVerticalScrollBarRect()
    local viewHeight = self:__getViewportHeight()
    local barHeight = self:__getVerticalBarHeight()
    local maxScroll = self.__contentHeight - viewHeight
    local scrollRatio = maxScroll > 0 and (self.props.scrollY / maxScroll) or 0
    local trackHeight = viewHeight - (self:__needsHorizontalScroll() and self.props.scrollBarWidth or 0)
    local barY = scrollRatio * (trackHeight - barHeight)

    local x = self.x + self.width - self.padding.right - self.props.scrollBarWidth
    local y = self.y + self.padding.top + barY

    return x, y, self.props.scrollBarWidth, barHeight
end

---Get horizontal scroll bar rectangle
---@return number x, number y, number width, number height
function ScrollArea:__getHorizontalScrollBarRect()
    local viewWidth = self:__getViewportWidth()
    local barWidth = self:__getHorizontalBarWidth()
    local maxScroll = self.__contentWidth - viewWidth
    local scrollRatio = maxScroll > 0 and (self.props.scrollX / maxScroll) or 0
    local trackWidth = viewWidth
    local barX = scrollRatio * (trackWidth - barWidth)

    local x = self.x + self.padding.left + barX
    local y = self.y + self.height - self.padding.bottom - self.props.scrollBarWidth

    return x, y, barWidth, self.props.scrollBarWidth
end

---Scroll to a specific position
---@param x number? X scroll position (nil to keep current)
---@param y number? Y scroll position (nil to keep current)
---@return ScrollArea self
function ScrollArea:scrollTo(x, y)
    if x then
        local maxScrollX = math.max(0, self.__contentWidth - self:__getViewportWidth())
        self.props.scrollX = math.max(0, math.min(maxScrollX, x))
    end
    if y then
        local maxScrollY = math.max(0, self.__contentHeight - self:__getViewportHeight())
        self.props.scrollY = math.max(0, math.min(maxScrollY, y))
    end
    self:invalidateLayout()
    return self
end

---Scroll to top
---@return ScrollArea self
function ScrollArea:scrollToTop()
    return self:scrollTo(nil, 0)
end

---Scroll to bottom
---@return ScrollArea self
function ScrollArea:scrollToBottom()
    return self:scrollTo(nil, self.__contentHeight)
end

---Set scroll bar width
---@param width number Width in pixels
---@return ScrollArea self
function ScrollArea:setScrollBarWidth(width)
    self.props.scrollBarWidth = width
    return self
end

---Set scroll bar color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return ScrollArea self
function ScrollArea:setScrollBarColor(r, g, b, a)
    self.props.scrollBarColor = {r, g, b, a or 1}
    return self
end

---Set scroll speed
---@param speed number Scroll speed multiplier
---@return ScrollArea self
function ScrollArea:setScrollSpeed(speed)
    self.props.scrollSpeed = speed
    return self
end

---Override measure to calculate content size
function ScrollArea:measure(availableWidth, availableHeight)
    local contentWidth = availableWidth - self.padding.left - self.padding.right
    local contentHeight = availableHeight - self.padding.top - self.padding.bottom

    -- First pass: measure children to get content size
    -- Temporarily override fill heights to auto so we get actual content size
    local maxChildWidth = 0
    local totalChildHeight = 0

    for _, child in ipairs(self.children) do
        if child:isVisible() then
            -- Save original preferredHeight and temporarily use auto for fill-sized children
            local originalHeight = child.preferredHeight
            local needsRestore = false

            if type(originalHeight) == "table" and originalHeight.type == "fill" then
                child.preferredHeight = Size.auto()
                needsRestore = true
            end

            child:measure(contentWidth, contentHeight)
            maxChildWidth = math.max(maxChildWidth, child.desiredWidth)
            totalChildHeight = totalChildHeight + child.desiredHeight

            -- Restore original preferredHeight
            if needsRestore then
                child.preferredHeight = originalHeight
            end
        end
    end

    self.__contentWidth = maxChildWidth
    self.__contentHeight = totalChildHeight

    -- Clamp scroll positions
    local maxScrollX = math.max(0, self.__contentWidth - self:__getViewportWidth())
    local maxScrollY = math.max(0, self.__contentHeight - self:__getViewportHeight())
    self.props.scrollX = math.min(self.props.scrollX, maxScrollX)
    self.props.scrollY = math.min(self.props.scrollY, maxScrollY)

    local desiredWidth = self:calculateDesiredWidth(availableWidth)
    local desiredHeight = self:calculateDesiredHeight(availableHeight)

    desiredWidth, desiredHeight = self:__applyConstraints(desiredWidth, desiredHeight)

    self.desiredWidth = desiredWidth
    self.desiredHeight = desiredHeight
    self.isLayoutDirty = false

    return desiredWidth, desiredHeight
end

---Override arrange to position children with scroll offset
function ScrollArea:arrange(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    local contentX = x + self.padding.left - self.props.scrollX
    local contentY = y + self.padding.top - self.props.scrollY

    -- Arrange children vertically
    local childY = contentY
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            child:arrange(contentX, childY, child.desiredWidth, child.desiredHeight)
            childY = childY + child.desiredHeight
        end
    end
end

---Override hitTest to account for scroll area bounds
function ScrollArea:hitTest(x, y)
    if not self:isVisible() then
        return nil
    end

    if not self:containsPoint(x, y) then
        return nil
    end

    -- Check scroll bars first
    if self:__needsVerticalScroll() then
        local vBarX, vBarY, vBarW, vBarH = self:__getVerticalScrollBarRect()
        if AABB.containsPoint(x, y, vBarX, vBarY, vBarW, vBarH) then
            return self
        end
    end

    if self:__needsHorizontalScroll() then
        local hBarX, hBarY, hBarW, hBarH = self:__getHorizontalScrollBarRect()
        if AABB.containsPoint(x, y, hBarX, hBarY, hBarW, hBarH) then
            return self
        end
    end

    -- Check children within viewport
    local viewX = self.x + self.padding.left
    local viewY = self.y + self.padding.top
    local viewWidth = self:__getViewportWidth()
    local viewHeight = self:__getViewportHeight()

    if AABB.containsPoint(x, y, viewX, viewY, viewWidth, viewHeight) then

        for i = #self.children, 1, -1 do
            local hit = self.children[i]:hitTest(x, y)

            if hit then
                return hit
            end
        end
    end

    return self
end

---Render the scroll area
function ScrollArea:onRender()
    local viewX = self.x + self.padding.left
    local viewY = self.y + self.padding.top
    local viewWidth = self:__getViewportWidth()
    local viewHeight = self:__getViewportHeight()

    local prevX, prevY, prevW, prevH = Scissor.push(viewX, viewY, viewWidth, viewHeight)

    -- Render children
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            child:onRender()
        end
    end

    Scissor.pop(prevX, prevY, prevW, prevH)

    -- Draw vertical scroll bar
    if self:__needsVerticalScroll() then
        local trackX = self.x + self.width - self.padding.right - self.props.scrollBarWidth
        local trackY = self.y + self.padding.top
        local trackHeight = viewHeight

        -- Draw track
        love.graphics.setColor(self.props.scrollBarTrackColor)
        love.graphics.rectangle("fill", trackX, trackY, self.props.scrollBarWidth, trackHeight)

        -- Draw bar
        local vBarX, vBarY, vBarW, vBarH = self:__getVerticalScrollBarRect()
        local barColor = self.__verticalBarHovered and self.props.scrollBarHoverColor or self.props.scrollBarColor
        love.graphics.setColor(barColor)
        love.graphics.rectangle("fill", vBarX, vBarY, vBarW, vBarH, 3, 3)
    end

    -- Draw horizontal scroll bar
    if self:__needsHorizontalScroll() then
        local trackX = self.x + self.padding.left
        local trackY = self.y + self.height - self.padding.bottom - self.props.scrollBarWidth
        local trackWidth = viewWidth

        -- Draw track
        love.graphics.setColor(self.props.scrollBarTrackColor)
        love.graphics.rectangle("fill", trackX, trackY, trackWidth, self.props.scrollBarWidth)

        -- Draw bar
        local hBarX, hBarY, hBarW, hBarH = self:__getHorizontalScrollBarRect()
        local barColor = self.__horizontalBarHovered and self.props.scrollBarHoverColor or self.props.scrollBarColor
        love.graphics.setColor(barColor)
        love.graphics.rectangle("fill", hBarX, hBarY, hBarW, hBarH, 3, 3)
    end
end

return ScrollArea
