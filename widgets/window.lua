local Widget = require("ennui.widget")
local Size = require("ennui.size")
local AABB = require("ennui.utils.aabb")

---@class Window : Widget
---@field title string Window title text
---@field content Widget? Content widget
---@field isDragging boolean Whether window is being dragged
---@field dragOffsetX number X offset for dragging
---@field dragOffsetY number Y offset for dragging
---@field titleBarHeight number Height of title bar in pixels
---@field titleBarColor number[] RGBA color for title bar
---@field titleTextColor number[] RGBA color for title text
---@field backgroundColor number[] RGBA color for content background
---@field borderColor number[] RGBA color for border
---@field font love.Font Font for title text
---@field showCloseButton boolean Whether to show close button
---@field closeButtonHovered boolean Whether close button is hovered
---@field __lastFocusedWidget Widget? Last widget that had focus in this window
local Window = {}
Window.__index = Window
setmetatable(Window, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

function Window:__tostring()
    return string.format("Window(%q)", self.props.title or "")
end

---Create a new window widget
---@return Window
function Window.new(title)
    local self = setmetatable(Widget(), Window) ---@cast self Window

    self:addProperty("title", title or "Window")
    self:addProperty("content", nil)
    self:addProperty("titleBarHeight", 30)
    self:addProperty("titleBarColor", {0.2, 0.2, 0.2, 1})
    self:addProperty("titleTextColor", {1, 1, 1, 1})
    self:addProperty("backgroundColor", {0.15, 0.15, 0.15, 1})
    self:addProperty("borderColor", {0.4, 0.4, 0.4, 1})
    self:addProperty("font", love.graphics.getFont())
    self:addProperty("showCloseButton", true)
    self:addProperty("closeButtonHovered", false)
    self:addProperty("showTitleBar", true)

    self:setDraggable(true)
    self:setDragHandle({x = 0, y = 0, width = 0, height = self.props.titleBarHeight})

    self.__lastFocusedWidget = nil
    self.isTabContext = true

    return self
end

---Set window title
---@param title string Title text
---@return Window self
function Window:setTitle(title)
    if self.props.title ~= title then
        self.props.title = title
        self:invalidateRender()
    end
    return self
end

---Get window title
---@return string title
function Window:getTitle()
    return self.props.title
end

---Set content widget
---@param widget Widget? Content widget (nil to clear)
---@return Window self
function Window:setContent(widget)
    if self.props.content then
        self:removeChild(self.props.content)
    end

    self.props.content = widget

    if widget then
        self:addChild(widget)
        self:invalidateLayout()
    end

    return self
end

---Measure window (override to properly measure content)
---@param availableWidth number Available width
---@param availableHeight number Available height
---@return number desiredWidth
---@return number desiredHeight
function Window:measure(availableWidth, availableHeight)
    local contentWidth = availableWidth - self.padding.left - self.padding.right
    local titleBarSpace = self.props.showTitleBar and self.props.titleBarHeight or 0
    local contentHeight = availableHeight - self.padding.top - self.padding.bottom - titleBarSpace

    if self.props.content then
        self.props.content:measure(contentWidth, contentHeight)
    end

    local desiredWidth = self:calculateDesiredWidth(availableWidth)
    local desiredHeight = self:calculateDesiredHeight(availableHeight)


    if self.minWidth and self.minWidth > 0 then
        ---@diagnostic disable-next-line: cast-local-type
        desiredWidth = math.max(self.minWidth, desiredWidth)
    end
    if self.maxWidth and self.maxWidth > 0 then
        ---@diagnostic disable-next-line: cast-local-type
        desiredWidth = math.min(self.maxWidth, desiredWidth)
    end
    if self.minHeight and self.minHeight > 0 then
        ---@diagnostic disable-next-line: cast-local-type
        desiredHeight = math.max(self.minHeight, desiredHeight)
    end
    if self.maxHeight and self.maxHeight > 0 then
        ---@diagnostic disable-next-line: cast-local-type
        desiredHeight = math.min(self.maxHeight, desiredHeight)
    end

    self.desiredWidth = desiredWidth
    self.desiredHeight = desiredHeight

    self.isLayoutDirty = false

    assert(desiredWidth, "Desired width not defined after measure")
    assert(desiredHeight, "Desired height not defined after measure")
    return desiredWidth, desiredHeight
end

---Get content widget
---@return Widget? content
function Window:getContent()
    return self.props.content
end

---Close the window (hide it)
---@return Window self
function Window:close()
    -- Clean up Host state before hiding
    local host = self:getHost()
    if host then
        -- Clear hover state if hovering over this window or its descendants
        if host.__lastHoveredWidget then
            local current = host.__lastHoveredWidget
            while current do
                if current == self then
                    host.__lastHoveredWidget.props.isHovered = false
                    host.__lastHoveredWidget = nil
                    break
                end
                current = current.parent
            end
        end
        
        -- Clear pressed widget state for any button if pressed on this window or descendants
        for button, pressedWidget in pairs(host.__pressedWidget) do
            if pressedWidget then
                local current = pressedWidget
                while current do
                    if current == self then
                        pressedWidget.props.isPressed = false
                        host.__pressedWidget[button] = nil
                        break
                    end
                    current = current.parent
                end
            end
        end
        
        -- Clear drag state if dragging this window or a descendant
        if host.__draggedWidget then
            local current = host.__draggedWidget
            while current do
                if current == self then
                    -- Clear drag state manually
                    host.__draggedWidget = nil
                    host.__dragOffsetX = 0
                    host.__dragOffsetY = 0
                    host.__lastDragX = 0
                    host.__lastDragY = 0
                    host.__dragMode = nil
                    host.__dragStarted = false
                    break
                end
                current = current.parent
            end
        end
    end
    
    self:setVisible(false)
    return self
end

---Set title bar height
---@param height number Title bar height in pixels
---@return Window self
function Window:setTitleBarHeight(height)
    if self.props.titleBarHeight ~= height then
        self.props.titleBarHeight = height
        self:invalidateLayout()
    end
    return self
end

---Set font for title
---@param font love.Font Font to use
---@return Window self
function Window:setFont(font)
    if self.props.font ~= font then
        self.props.font = font
        self:invalidateRender()
    end
    return self
end

---Check if point is in title bar
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean inTitleBar
function Window:isInTitleBar(x, y)
    return AABB.containsPoint(x, y, self.x, self.y, self.width, self.props.titleBarHeight)
end

---Check if point is on close button
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean onCloseButton
function Window:isOnCloseButton(x, y)
    if not self.props.showCloseButton then
        return false
    end

    local buttonSize = self.props.titleBarHeight - 6
    local buttonX = self.x + self.width - buttonSize - 3
    local buttonY = self.y + 3

    return AABB.containsPoint(x, y, buttonX, buttonY, buttonSize, buttonSize)
end

---Get the first focusable widget in this window
---@return Widget? widget First focusable widget or nil
function Window:__getFirstFocusableWidget()
    local function findFirst(widget)
        if widget.focusable and widget:isVisible() and not widget.props.isDisabled then
            return widget
        end
        for _, child in ipairs(widget.children) do
            local found = findFirst(child)
            if found then return found end
        end
        return nil
    end

    return findFirst(self)
end

---Check if a widget is a descendant of this window
---@param widget Widget
---@return boolean
function Window:__isDescendant(widget)
    local current = widget.parent
    while current do
        if current == self then
            return true
        end
        current = current.parent
    end
    return false
end

---Get the Host instance
---@return Host?
function Window:getHost()
    local current = self.parent
    while current do
        if not current.parent then
            ---@diagnostic disable-next-line: return-type-mismatch
            return current
        end

        current = current.parent
    end

    return nil
end

---Handle mouse pressed
---@param event MouseEvent Mouse event
function Window:onMousePressed(event)
    self:bringToFront()

    if self:isOnCloseButton(event.x, event.y) then
        self:close()
        event:consume()
        return
    end

    if self:isInTitleBar(event.x, event.y) then
        local host = self:getHost()
        if host then
            if not (host.focusedWidget and self:__isDescendant(host.focusedWidget)) then
                if self.__lastFocusedWidget and self:__isDescendant(self.__lastFocusedWidget) then
                    host:setFocusedWidget(self.__lastFocusedWidget)
                else
                    local firstFocusable = self:__getFirstFocusableWidget()
                    if firstFocusable then
                        host:setFocusedWidget(firstFocusable)
                    end
                end
            end
        end
        return
    end

    -- If we get here, the click was on window content
    -- Check if a descendant widget already received focus during this event
    local host = self:getHost()
    if host and host.__focusSetDuringEvent then
        if host.focusedWidget and self:__isDescendant(host.focusedWidget) then
            return
        end
    end

    -- Only reach here if:
    -- 1. No descendant was focused during this event, OR
    -- 2. The focused widget is not a descendant of this window
    -- In these cases, apply window's default focus behavior
    if host then
        if host.focusedWidget and self:__isDescendant(host.focusedWidget) then
            return
        end

        if self.__lastFocusedWidget and self:__isDescendant(self.__lastFocusedWidget) then
            host:setFocusedWidget(self.__lastFocusedWidget)
        else
            local firstFocusable = self:__getFirstFocusableWidget()
            if firstFocusable then
                host:setFocusedWidget(firstFocusable)
            end
        end
    end
end

---Handle mouse moved
---@param event MouseEvent Mouse event
function Window:onMouseMoved(event)
    local wasHovered = self.props.closeButtonHovered
    self.props.closeButtonHovered = self:isOnCloseButton(event.x, event.y)
    if wasHovered ~= self.props.closeButtonHovered then
        self:invalidateRender()
    end
end

---Arrange children (position content widget)
---@param contentX number Content area X
---@param contentY number Content area Y
---@param contentWidth number Content area width
---@param contentHeight number Content area height
function Window:arrangeChildren(contentX, contentY, contentWidth, contentHeight)
    if self.props.content then
        local titleBarSpace = self.props.showTitleBar and self.props.titleBarHeight or 0
        local contentAreaY = contentY + titleBarSpace
        local contentAreaHeight = contentHeight - titleBarSpace

        self.props.content:measure(contentWidth, contentAreaHeight)
        self.props.content:arrange(contentX, contentAreaY, contentWidth, contentAreaHeight)
    end
end

---Override setPosition to re-arrange children when window moves
---@param x number X position
---@param y number Y position
---@return Window self
function Window:setPosition(x, y)
    Widget.setPosition(self, x, y)

    if self.width and self.height then
        local contentX = self.x + self.padding.left
        local contentY = self.y + self.padding.top
        local contentWidth = self.width - self.padding.left - self.padding.right
        local contentHeight = self.height - self.padding.top - self.padding.bottom

        self:arrangeChildren(contentX, contentY, contentWidth, contentHeight)
    end

    return self
end

---Calculate window content height (for auto sizing)
---@return number contentHeight
function Window:__calculateContentHeight()
    if not self.props.content then
        return self.props.titleBarHeight + self.padding.top + self.padding.bottom
    end

    local contentDesiredHeight = self.props.content.desiredHeight

    return self.props.titleBarHeight + contentDesiredHeight + self.padding.top + self.padding.bottom
end

function Window:__collectFocusableWidgets(widget, widgets)
    if widget.focusable and widget:isVisible() and not widget.props.isDisabled then
        table.insert(widgets, widget)
    end

    for _, child in ipairs(widget.children) do
        self:__collectFocusableWidgets(child, widgets)
    end
end

---Render a widget (onRender handles children recursively)
---@param widget Widget Widget to render
---@protected
function Window:__renderWidget(widget)
    if widget:isVisible() then
        widget:onRender()
    end
end

---Draw the title bar
---@protected
function Window:__drawTitlebar()
    love.graphics.setColor(self.props.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    love.graphics.setColor(self.props.titleBarColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.props.titleBarHeight)

    love.graphics.setColor(self.props.borderColor)
    love.graphics.line(
        self.x,
        self.y + self.props.titleBarHeight,
        self.x + self.width,
        self.y + self.props.titleBarHeight
    )

    love.graphics.setFont(self.props.font)
    love.graphics.setColor(self.props.titleTextColor)
    local titleY = self.y + (self.props.titleBarHeight - self.props.font:getHeight()) / 2
    love.graphics.print(self.props.title, self.x + 8, titleY)

    if self.props.showCloseButton then
        local buttonSize = self.props.titleBarHeight - 6
        local buttonX = self.x + self.width - buttonSize - 3
        local buttonY = self.y + 3

        if self.props.closeButtonHovered then
            love.graphics.setColor(0.8, 0.2, 0.2, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
        end
        love.graphics.rectangle("fill", buttonX, buttonY, buttonSize, buttonSize)

        -- X mark
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(2)
        local padding = 6
        love.graphics.line(
            buttonX + padding,
            buttonY + padding,
            buttonX + buttonSize - padding,
            buttonY + buttonSize - padding
        )
        love.graphics.line(
            buttonX + buttonSize - padding,
            buttonY + padding,
            buttonX + padding,
            buttonY + buttonSize - padding
        )
        love.graphics.setLineWidth(1)
    end
end

---Render the window
function Window:onRender()
    if self.props.showTitleBar then
        self:__drawTitlebar()
    end

    love.graphics.setColor(self.props.backgroundColor)
    love.graphics.rectangle(
        "fill",
        self.x,
        self.y + self.props.titleBarHeight,
        self.width,
        self.height - self.props.titleBarHeight
    )

    for _, child in ipairs(self.children) do
        self:__renderWidget(child)
    end
end

return Window
