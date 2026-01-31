local Widget = require("ennui.widget")
local Event = require("ennui.event")

---@class Host : Widget
---@field focusedWidget Widget? Currently focused widget
---@field focusedWindow Widget? Currently focused window for tab navigation scope
---@field __pressedWidget table<integer, Widget> Widgets with pressed mouse buttons
---@field __lastHoveredWidget Widget? Last widget that was hovered
---@field __focusSetDuringEvent boolean Flag to track if focus was set during current event
---@field __draggedWidget Widget? Currently dragged widget
---@field __dragOffsetX number X offset for position-based dragging
---@field __dragOffsetY number Y offset for position-based dragging
---@field __lastDragX number Last X position for delta calculation
---@field __lastDragY number Last Y position for delta calculation
---@field __dragMode string? "position" or "delta"
---@field __dragStarted boolean Whether drag has actually started
---@field __overlayWidgets Widget[] Overlay widgets (hit-tested first, rendered last)
local Host = setmetatable({}, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end
})

Host.__index = Host

function Host:__tostring()
    return "Host"
end

---@return Host
function Host.new()
    local self = setmetatable(Widget(), Host) ---@cast self Host

    self.focusedWidget = nil
    self.focusedWindow = nil
    self.__pressedWidget = {}
    self.__lastHoveredWidget = nil
    self.__focusSetDuringEvent = false

    self.__draggedWidget = nil
    self.__dragOffsetX = 0
    self.__dragOffsetY = 0
    self.__lastDragX = 0
    self.__lastDragY = 0
    self.__dragMode = nil
    self.__dragStarted = false
    self.__overlayWidgets = {}

    return self
end

---Register an overlay widget (hit-tested first, rendered last)
---@param widget Widget
function Host:registerOverlay(widget)
    for _, w in ipairs(self.__overlayWidgets) do
        if w == widget then return end
    end
    table.insert(self.__overlayWidgets, widget)
end

---Unregister a widget's overlay
---@param widget Widget
function Host:unregisterOverlay(widget)
    for i, w in ipairs(self.__overlayWidgets) do
        if w == widget then
            table.remove(self.__overlayWidgets, i)
            return
        end
    end
end

---@param contentX number Content area X
---@param contentY number Content area Y
---@param contentWidth number Content area width
---@param contentHeight number Content area height
function Host:arrangeChildren(contentX, contentY, contentWidth, contentHeight)
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            child:measure(contentWidth, contentHeight)

            local x = child.x or 0
            local y = child.y or 0

            local w = child.desiredWidth
            local h = child.desiredHeight

            local prefWidth = child.preferredWidth
            if type(prefWidth) == "number" and prefWidth > 0 then
                w = prefWidth
            end
            local prefHeight = child.preferredHeight
            if type(prefHeight) == "number" and prefHeight > 0 then
                h = prefHeight
            end

            child:arrange(x, y, w, h)
        end
    end
end

---@param width number Width in pixels
---@param height number Height in pixels
---@return Host self
function Host:setSize(width, height)
    if self.width ~= width or self.height ~= height then
        self.width = width
        self.height = height

        self:invalidateLayout()
    end

    return self
end

---@param width number Width in pixels
---@return Host self
function Host:setWidth(width)
    if self.width ~= width then
        self.width = width

        self:invalidateLayout()
    end

    return self
end

---@param height number Height in pixels
---@return Host self
function Host:setHeight(height)
    if self.height ~= height then
        self.height = height

        self:invalidateLayout()
    end

    return self
end

---@protected
function Host:__ensureLayout()
    if self.isLayoutDirty then
        self:measure(self.width, self.height)
        self:arrange(0, 0, self.width, self.height)
        self.isLayoutDirty = false
    end
end

---Override hitTest to check overlay widgets first
---@param x number Point X
---@param y number Point Y
---@return Widget? hitWidget
function Host:hitTest(x, y)
    for i = #self.__overlayWidgets, 1, -1 do
        local widget = self.__overlayWidgets[i]

        if widget:isVisible() then
            local hit = widget:hitTest(x, y)

            if hit then
                return hit
            end
        end
    end

    return Widget.hitTest(self, x, y)
end

function Host:draw()
    self:__ensureLayout()
    self:onRender()

    for _, widget in ipairs(self.__overlayWidgets) do
        if widget:isVisible() then
            widget:onRender()
        end
    end
end

---@param dt number Delta time in seconds
function Host:update(dt)
    self:__ensureLayout()
    self:onUpdate(dt)
end

---@protected
function Host:onRender()
    -- Render all children except the dragged widget
    for _, child in ipairs(self.children) do
        if child:isVisible() and child ~= self.__draggedWidget then
            child:onRender()
        end
    end

    -- Render dragged widget last
    if self.__draggedWidget and self.__draggedWidget:isVisible() then
        self.__draggedWidget:onRender()
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("fill", self.__draggedWidget.x, self.__draggedWidget.y, self.__draggedWidget.width, self.__draggedWidget.height)
    end
end

---@protected
---@param widget Widget
---@param x number Mouse X
---@param y number Mouse Y
---@param button integer Mouse button
function Host:__initDrag(widget, x, y, button)
    self.__draggedWidget = widget
    self.__dragMode = widget.dragMode or "position"
    self.__dragOffsetX = x - widget.x
    self.__dragOffsetY = y - widget.y
    self.__lastDragX = x
    self.__lastDragY = y
    self.__dragStarted = false

    ---@diagnostic disable-next-line: undefined-field
    if widget.props.isDocked and widget.undock then
        ---@diagnostic disable-next-line: undefined-field
        widget:undock()
    end

    if widget.onDragStart then
        local event = Event.createMouseEvent("mousePressed", x, y, button, widget, false)
        if widget.onDragStart(event) == false then
            self:__clearDrag()
            return false
        end
    end

    return true
end

---@protected
function Host:__clearDrag()
    self.__draggedWidget = nil
    self.__dragOffsetX = 0
    self.__dragOffsetY = 0
    self.__lastDragX = 0
    self.__lastDragY = 0
    self.__dragMode = nil
    self.__dragStarted = false
end

---@param widget Widget
---@return boolean
function Host:isWidgetDragged(widget)
    return self.__draggedWidget == widget
end

---@param x number Mouse X
---@param y number Mouse Y
---@param button integer Mouse button
---@param isTouch boolean Is touch event
function Host:mousepressed(x, y, button, isTouch)
    self:__ensureLayout()
    local target = self:hitTest(x, y)

    self.__focusSetDuringEvent = false

    if target and target ~= self then
        if target.isDraggable and target:isInDragHandle(x, y) then
            self:__initDrag(target, x, y, button)
        end

        self.__pressedWidget[button] = target

        if target:getFocusable() then
            self:setFocusedWidget(target)
            self.__focusSetDuringEvent = true
        end

        target.props.isPressed = true

        local event = Event.createMouseEvent("mousePressed", x, y, button, target, isTouch)
        self:__dispatchEvent(event)

        self.__focusSetDuringEvent = false

        return true
    end

    return false
end

---@param x number Mouse X
---@param y number Mouse Y
---@param button integer Mouse button
---@param isTouch boolean Is touch event
function Host:mousereleased(x, y, button, isTouch)
    self:__ensureLayout()

    local handled = false

    if self.__draggedWidget then
        local widget = self.__draggedWidget --[[@as Widget]]

        if widget.onDragEnd then
            local event = Event.createMouseEvent("mouseReleased", x, y, button, widget, isTouch)
            widget.onDragEnd(event)
        end

        self:__clearDrag()
        self:invalidateRender()
        handled = true
    end

    local target = self:hitTest(x, y)
    local pressedWidget = self.__pressedWidget[button]

    if pressedWidget then
        pressedWidget.props.isPressed = false

        local event = Event.createMouseEvent("mouseReleased", x, y, button, pressedWidget, isTouch)
        self:__dispatchEvent(event)
        handled = true
    elseif target and target ~= self then
        local event = Event.createMouseEvent("mouseReleased", x, y, button, target, isTouch)
        self:__dispatchEvent(event)
        handled = true
    end

    if target and target == pressedWidget then
        local event = Event.createMouseEvent("clicked", x, y, button, target, isTouch)
        self:__dispatchEvent(event)
    end

    self.__pressedWidget[button] = nil

    return handled
end

---@param x number Mouse X
---@param y number Mouse Y
---@param dx number Delta X
---@param dy number Delta Y
---@param isTouch boolean Is touch event
function Host:mousemoved(x, y, dx, dy, isTouch)
    self:__ensureLayout()

    if self.__draggedWidget then
        if not self.__dragStarted then
            self.__dragStarted = true
        end

        local widget = self.__draggedWidget --[[@as Widget]]

        if self.__dragMode == "position" then
            local newX = x - self.__dragOffsetX
            local newY = y - self.__dragOffsetY

            widget:setPosition(newX, newY)
        elseif self.__dragMode == "delta" then
            local deltaX = x - self.__lastDragX
            local deltaY = y - self.__lastDragY

            if widget.onDrag then
                local event = Event.createMouseEvent("mouseMoved", x, y, 1, widget, isTouch, deltaX, deltaY)
                widget.onDrag(event, deltaX, deltaY)
            end

            self.__lastDragX = x
            self.__lastDragY = y
        end

        if self.__dragMode == "position" and widget.onDrag then
            local event = Event.createMouseEvent("mouseMoved", x, y, 1, widget, isTouch, dx, dy)
            widget.onDrag(event)
        end

        self:invalidateRender()
        return true
    end

    local target = self:hitTest(x, y)

    if target ~= self.__lastHoveredWidget then
        if self.__lastHoveredWidget then
            self.__lastHoveredWidget.props.isHovered = false

            local event = Event.createMouseEvent("mouseExited", x, y, 1, self.__lastHoveredWidget, isTouch)
            self:__dispatchEvent(event)
        end

        if target and target ~= self then
            target.props.isHovered = true

            local event = Event.createMouseEvent("mouseEntered", x, y, 1, target, isTouch)
            self:__dispatchEvent(event)
        end

        self.__lastHoveredWidget = (target ~= self) and target or nil
    end

    if target and target ~= self then
        local event = Event.createMouseEvent("mouseMoved", x, y, 1, target, isTouch, dx, dy)
        self:__dispatchEvent(event)
        return true
    end

    return false
end

---@param dx number Horizontal scroll amount
---@param dy number Vertical scroll amount
function Host:wheelmoved(dx, dy)
    self:__ensureLayout()
    local x, y = love.mouse.getPosition()
    local target = self:hitTest(x, y)

    if target and target ~= self then
        local event = Event.createMouseEvent("mouseWheel", x, y, 1, target, false, dx, dy)
        self:__dispatchEvent(event)
        return true
    end

    return false
end

---@param key string Key code
---@param scancode string Physical key scancode
---@param isRepeat boolean Is key repeat
function Host:keypressed(key, scancode, isRepeat)
    if key == "tab" then
        local shift = love.keyboard.isDown("lshift", "rshift")
        if shift then
            self:focusPrevious()
        else
            self:focusNext()
        end

        return true
    end

    if self.focusedWidget then
        local event = Event.createKeyboardEvent("keyPressed", key, scancode, isRepeat, self.focusedWidget)
        self:__dispatchEvent(event)
        return true
    end

    return false
end

---@param key string Key code
---@param scancode string Physical key scancode
function Host:keyreleased(key, scancode)
    if self.focusedWidget then
        local event = Event.createKeyboardEvent("keyReleased", key, scancode, false, self.focusedWidget)
        self:__dispatchEvent(event)
        return true
    end

    return false
end

---@param text string Text entered
function Host:textinput(text)
    if self.focusedWidget then
        local event = Event.createTextInputEvent(text, self.focusedWidget)
        self:__dispatchEvent(event)
        return event.consumed
    end

    return false
end

---@param event Event Event object
function Host:__dispatchEvent(event)
    local target = event.target
    if not target then return end

    ---@type Widget[]
    local ancestors = {}
    local current = target
    while current do
        table.insert(ancestors, 1, current)
        current = current.parent
    end

    for _, ancestor in ipairs(ancestors) do
        if event.stopsPropagation then break end
        event.currentTarget = ancestor
        ancestor:__handleCaptureEvent(event)
    end

    if not event.stopsPropagation then
        event.currentTarget = target
        target:__handleEvent(event)
    end

    if not event.stopsPropagation then
        for i = #ancestors - 1, 1, -1 do
            event.currentTarget = ancestors[i]
            ancestors[i]:__handleEvent(event)
            if event.stopsPropagation then break end
        end
    end
end

---@param widget Widget? Widget to focus (or nil to clear focus)
function Host:setFocusedWidget(widget)
    local oldWidget = self.focusedWidget

    if oldWidget == widget then
        return
    end

    if oldWidget then
        local oldWindow = self:__findContainingTabContext(oldWidget)
        if oldWindow then
            ---@cast oldWindow Window
            oldWindow.__lastFocusedWidget = oldWidget
        end

        oldWidget.props.isFocused = false

        local event = Event.createFocusEvent("focusLost", oldWidget)
        event.currentTarget = oldWidget
        oldWidget:__handleEvent(event)
    end

    self.focusedWidget = widget

    if widget then
        local window = self:__findContainingTabContext(widget)
        self.focusedWindow = window

        widget.props.isFocused = true

        local event = Event.createFocusEvent("focusGained", widget)
        event.currentTarget = widget
        widget:__handleEvent(event)
    else
        self.focusedWindow = nil
    end
end

---@return Widget? focusedWidget
function Host:getFocusedWidget()
    return self.focusedWidget
end

function Host:focusNext()
    local tabContext = nil
    if self.focusedWidget then
        tabContext = self:__findContainingTabContext(self.focusedWidget)
    end

    local focusable = self:__getFocusableWidgets(tabContext)
    if #focusable == 0 then return end

    if #focusable == 1 then
        if not self.focusedWidget then
            self:setFocusedWidget(focusable[1])
        end
        return
    end

    local currentIndex = 0
    if self.focusedWidget then
        for i, widget in ipairs(focusable) do
            if widget == self.focusedWidget then
                currentIndex = i
                break
            end
        end
    end

    local nextIndex = (currentIndex % #focusable) + 1
    self:setFocusedWidget(focusable[nextIndex])
end

function Host:focusPrevious()
    local tabContext = nil
    if self.focusedWidget then
        tabContext = self:__findContainingTabContext(self.focusedWidget)
    end

    local focusable = self:__getFocusableWidgets(tabContext)
    if #focusable == 0 then return end

    if #focusable == 1 then
        if not self.focusedWidget then
            self:setFocusedWidget(focusable[1])
        end
        return
    end

    local currentIndex = 0
    if self.focusedWidget then
        for i, widget in ipairs(focusable) do
            if widget == self.focusedWidget then
                currentIndex = i
                break
            end
        end
    end

    local prevIndex = currentIndex - 1
    if prevIndex < 1 then prevIndex = #focusable end
    self:setFocusedWidget(focusable[prevIndex])
end

---@param tabContext Widget? Optional tab context to constrain search (nil = entire tree)
---@return Widget[]
function Host:__getFocusableWidgets(tabContext)
    local focusable = {}

    local function collectFocusable(widget, isRootContext)
        if widget.isTabContext and not isRootContext then
            return
        end

        if widget.focusable and widget:isVisible() and not widget:isDisabled() then
            table.insert(focusable, widget)
        end

        for _, child in ipairs(widget.children) do
            collectFocusable(child, false)
        end
    end

    if tabContext then
        collectFocusable(tabContext, true)
    else
        collectFocusable(self, true)
    end

    table.sort(focusable, function(a, b)
        return a.tabIndex < b.tabIndex
    end)

    return focusable
end

---@param widget Widget
---@return Widget? tabContext The containing tab context, or nil if not in one
function Host:__findContainingTabContext(widget)
    local current = widget
    while current do
        if current.isTabContext then
            return current
        end

        current = current.parent
    end

    return nil
end

return Host
