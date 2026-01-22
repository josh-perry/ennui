local Size = require("ennui.size")
local Reactive = require("ennui.reactive")
local PropertyMetadata = require("ennui.property_metadata")
local Watcher = require("ennui.watcher")
local Computed = require("ennui.computed")
local Scissor = require("ennui.utils.scissor")

---@class WidgetState
---@field public isHovered boolean Mouse is over widget
---@field public isFocused boolean Widget has keyboard focus
---@field public isPressed boolean Mouse button is pressed on widget
---@field public isDisabled boolean Widget is disabled
---@field public isVisible boolean Whether widget is visible

---@class Padding
---@field public top number Top padding in pixels
---@field public right number Right padding in pixels
---@field public bottom number Bottom padding in pixels
---@field public left number Left padding in pixels

---@class Margin
---@field public top number Top margin in pixels
---@field public right number Right margin in pixels
---@field public bottom number Bottom margin in pixels
---@field public left number Left margin in pixels

---@class Widget
---@field public id string? Optional widget identifier
---@field public props table Properties table
---@field public x number X position in pixels
---@field public y number Y position in pixels
---@field public width number Actual width in pixels
---@field public height number Actual height in pixels
---@field public preferredWidth number|Size Preferred width specification
---@field public preferredHeight number|Size Preferred height specification
---@field public desiredWidth number Measured desired width in pixels
---@field public desiredHeight number Measured desired height in pixels
---@field public minWidth number? Minimum width constraint
---@field public maxWidth number? Maximum width constraint
---@field public minHeight number? Minimum height constraint
---@field public maxHeight number? Maximum height constraint
---@field public aspectRatio number? Aspect ratio constraint (width/height)
---@field public sizeConstraint table? Size constraint specification
---@field public padding Padding Padding around content
---@field public margin Margin Margin around widget
---@field public parent Widget|Host Parent widget
---@field public children Widget[] Child widgets
---@field public state WidgetState Internal interaction state
---@field public isLayoutDirty boolean Whether layout needs recalculation
---@field public isRenderDirty boolean Whether widget needs redraw
---@field public horizontalAlignment "left"|"center"|"right"|"stretch" Horizontal alignment
---@field public verticalAlignment "top"|"center"|"bottom"|"stretch" Vertical alignment
---@field public layoutStrategy LayoutStrategy? Optional layout strategy for arranging children
---@field public isTabContext boolean Whether this widget creates a new tab focus scope
---@field public isDraggable boolean Whether widget can be dragged
---@field public dragMode string Drag mode: "position" or "delta"
---@field public dragHandle table? Drag handle rectangle {x, y, width, height} relative to widget
---@field public onDragStart function? Drag lifecycle callback
---@field public onDrag function? Drag lifecycle callback
---@field public onDragEnd function? Drag lifecycle callback
---@field private __handlers table Event handlers (bubble phase)
---@field private __captureHandlers table Event handlers (capture phase)
---@field private __focusable boolean Whether widget can receive focus
---@field private __tabIndex number Tab order for focus navigation
---@field private __hitTransparent boolean Whether widget passes through hit events to parent
---@field private __rawProps table<string, any> Underlying raw properties table
---@field public clipContent boolean Whether to clip children to widget bounds
local Widget = {}
Widget.__index = Widget
setmetatable(Widget, {
    __call = function(class, ...)
        return class.new(...)
    end,
    __tostring = function(self)
        return "Widget"
    end
})

function Widget:__tostring()
    return "Widget"
end

---@return Widget
function Widget.new()
    local self = setmetatable({}, Widget)

    -- Non-reactive properties (used by layout engine, event system, etc)
    self.id = nil
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.desiredWidth = 0
    self.desiredHeight = 0
    self.parent = nil
    self.children = {}
    self.state = {
        isHovered = false,
        isFocused = false,
        isPressed = false,
        isDisabled = false,
        isVisible = true
    }
    self.isLayoutDirty = true
    self.isRenderDirty = true
    self.isTabContext = false
    self.layoutStrategy = nil
    self.__handlers = {}
    self.__captureHandlers = {}
    self.__focusable = false
    self.__tabIndex = 0
    self.__hitTransparent = false
    self.clipContent = false

    self.__rawProps = {
        preferredWidth = Size.auto(),
        preferredHeight = Size.auto(),
        minWidth = nil,
        maxWidth = nil,
        minHeight = nil,
        maxHeight = nil,
        aspectRatio = nil,
        sizeConstraint = nil,
        padding = { top = 0, right = 0, bottom = 0, left = 0 },
        margin = { top = 0, right = 0, bottom = 0, left = 0 },
        horizontalAlignment = "stretch",
        verticalAlignment = "stretch",
    }

    self:addProperty("isDocked", false)

    self.__watchers = {}
    self.__computed = {}

    -- Drag system properties
    self.isDraggable = false
    self.dragMode = "position" -- "position" or "delta"
    self.dragHandle = nil -- {x, y, width, height} relative to widget
    -- Drag callbacks
    self.onDragStart = nil -- function(event) -> bool (return false to cancel)
    self.onDrag = nil -- function(event, deltaX, deltaY) for delta mode, or function(event) for position mode
    self.onDragEnd = nil -- function(event)

    self.props = Reactive.createProxy(
        self.__rawProps,
        nil,
        function(key, value, oldValue)
            self[key] = value

            if PropertyMetadata.isLayoutProperty(key) then
                self:invalidateLayout()
            elseif PropertyMetadata.isRenderProperty(key) then
                self:invalidateRender()
            end
        end
    )

    -- Make nested tables reactive (padding and margin)
    self.props.padding = self:__makeReactiveNested(self.__rawProps.padding, "padding")
    self.props.margin = self:__makeReactiveNested(self.__rawProps.margin, "margin")

    -- Mirror reactive properties to direct properties for layout engine compatibility
    -- These are kept in sync and allow the rest of the code to work unchanged
    self.preferredWidth = self.__rawProps.preferredWidth
    self.preferredHeight = self.__rawProps.preferredHeight
    self.minWidth = self.__rawProps.minWidth
    self.maxWidth = self.__rawProps.maxWidth
    self.minHeight = self.__rawProps.minHeight
    self.maxHeight = self.__rawProps.maxHeight
    self.aspectRatio = self.__rawProps.aspectRatio
    self.sizeConstraint = self.__rawProps.sizeConstraint
    self.padding = self.__rawProps.padding
    self.margin = self.__rawProps.margin
    self.horizontalAlignment = self.__rawProps.horizontalAlignment
    self.verticalAlignment = self.__rawProps.verticalAlignment

    return self
end

---Set widget ID
---@param id string Widget identifier
---@return Widget self
function Widget:setId(id)
    self.id = id
    return self
end

---@generic T : Widget
---@param width number|string|Size Preferred width specification
---@param height number|string|Size Preferred height specification
---@return T
function Widget:setSize(width, height, keepUniform)
    self:setPreferredWidth(width)
    self:setPreferredHeight(height)

    return self
end

---@param width number|string|Size Preferred width specification
---@return Widget self
function Widget:setPreferredWidth(width)
    self.props.preferredWidth = Size.normalize(width)
    return self
end

---@param height number|string|Size Preferred height specification
---@return Widget self
function Widget:setPreferredHeight(height)
    self.props.preferredHeight = Size.normalize(height)
    return self
end

---@param width number|string|Size Preferred width specification
---@return Widget self
function Widget:setWidth(width)
    return self:setPreferredWidth(width)
end

---@param height number|string|Size Preferred height specification
---@return Widget self
function Widget:setHeight(height)
    return self:setPreferredHeight(height)
end

---@param x number X position
---@param y number Y position
---@return Widget self
function Widget:setPosition(x, y)
    self.x = x
    self.y = y
    return self
end

---@param top number Top padding (or all sides if only argument)
---@param right number? Right padding (or horizontal if 2 args)
---@param bottom number? Bottom padding
---@param left number? Left padding
---@return Widget self
function Widget:setPadding(top, right, bottom, left)
    if not right then
        -- 1 arg: all sides
        self.props.padding.top = top
        self.props.padding.right = top
        self.props.padding.bottom = top
        self.props.padding.left = top
    elseif not bottom then
        -- 2 args: vertical, horizontal
        self.props.padding.top = top
        self.props.padding.right = right
        self.props.padding.bottom = top
        self.props.padding.left = right
    elseif left then
        -- 4 args: top, right, bottom, left
        self.props.padding.top = top
        self.props.padding.right = right
        self.props.padding.bottom = bottom
        self.props.padding.left = left
    else
        error("setPadding requires 1, 2, or 4 arguments")
    end

    return self
end

---@param top number Top margin (or all sides if only argument)
---@param right number? Right margin (or horizontal if 2 args)
---@param bottom number? Bottom margin
---@param left number? Left margin
---@return Widget self
function Widget:setMargin(top, right, bottom, left)
    if not right then
        -- 1 arg: all sides
        self.props.margin.top = top
        self.props.margin.right = top
        self.props.margin.bottom = top
        self.props.margin.left = top
    elseif not bottom then
        -- 2 args: vertical, horizontal
        self.props.margin.top = top
        self.props.margin.right = right
        self.props.margin.bottom = top
        self.props.margin.left = right
    elseif left then
        -- 4 args: top, right, bottom, left
        self.props.margin.top = top
        self.props.margin.right = right
        self.props.margin.bottom = bottom
        self.props.margin.left = left
    else
        error("setMargin requires 1, 2, or 4 arguments")
    end

    return self
end

---@param width number Minimum width in pixels
---@return Widget self
function Widget:setMinWidth(width)
    self.props.minWidth = width
    return self
end

---@param width number Maximum width in pixels
---@return Widget self
function Widget:setMaxWidth(width)
    self.props.maxWidth = width
    return self
end

---@param height number Minimum height in pixels
---@return Widget self
function Widget:setMinHeight(height)
    self.props.minHeight = height
    return self
end

---@param height number Maximum height in pixels
---@return Widget self
function Widget:setMaxHeight(height)
    self.props.maxHeight = height
    return self
end

---@param ratio number Aspect ratio
---@return Widget self
function Widget:setAspectRatio(ratio)
    self.props.aspectRatio = ratio
    return self
end

---@param constraint table Size constraint specification
---@return Widget self
function Widget:setSizeConstraint(constraint)
    self.props.sizeConstraint = constraint
    return self
end

---@param visible boolean Whether widget is visible
---@return Widget self
function Widget:setVisible(visible)
    if self.state.isVisible == visible then
        return self
    end

    self.state.isVisible = visible

    -- If becoming invisible, clear focus from this widget and its descendants
    if not visible then
        local host = self:__getHost()
        if host and host.focusedWidget then
            local current = host.focusedWidget
            -- Check if the focused widget is this widget or a descendant
            while current do
                if current == self then
                    host:setFocusedWidget(nil)
                    break
                end
                current = current.parent
            end
        end
    end

    self:invalidateLayout()
    return self
end

---@param disabled boolean Whether widget is disabled
---@return Widget self
function Widget:setDisabled(disabled)
    if self.state.isDisabled == disabled then
        return self
    end

    self.state.isDisabled = disabled
    self:invalidateRender()
    return self
end

---@param alignment "left"|"center"|"right"|"stretch" Horizontal alignment
---@return Widget self
function Widget:setHorizontalAlignment(alignment)
    self.props.horizontalAlignment = alignment
    return self
end

---@param alignment "top"|"center"|"bottom"|"stretch" Vertical alignment
---@return Widget self
function Widget:setVerticalAlignment(alignment)
    self.props.verticalAlignment = alignment
    return self
end

---@param strategy LayoutStrategy? Layout strategy instance (nil to use default)
---@return Widget self
function Widget:setLayoutStrategy(strategy)
    self.layoutStrategy = strategy
    self:invalidateLayout()
    return self
end

---@param focusable boolean Whether widget can receive focus
---@return Widget self
function Widget:setFocusable(focusable)
    self.__focusable = focusable
    return self
end

---@return boolean
function Widget:getFocusable()
    return self.__focusable
end

---@param index number Tab order (lower = earlier)
---@return Widget self
function Widget:setTabIndex(index)
    self.__tabIndex = index
    return self
end

---@param transparent boolean Whether widget should pass through hit events
---@return Widget self
function Widget:setHitTransparent(transparent)
    self.__hitTransparent = transparent
    return self
end

---@return boolean hitTransparent
function Widget:isHitTransparent()
    return self.__hitTransparent
end

---Set whether to clip children to widget bounds
---@param clip boolean Whether to enable content clipping
---@return Widget self
function Widget:setClipContent(clip)
    self.clipContent = clip
    return self
end

---@return string? id
function Widget:getId()
    return self.id
end

---@return number width
function Widget:getWidth()
    return self.width
end

---@return number height
function Widget:getHeight()
    return self.height
end

---@return number x, number y
function Widget:getPosition()
    return self.x, self.y
end

---@return number width, number height
function Widget:getSize()
    return self.width, self.height
end

---@return number x, number y, number width, number height
function Widget:getBounds()
    return self.x, self.y, self.width, self.height
end

---@return table padding
function Widget:getPadding()
    return {
        top = self.padding.top,
        right = self.padding.right,
        bottom = self.padding.bottom,
        left = self.padding.left
    }
end

---@return table margin
function Widget:getMargin()
    return {
        top = self.margin.top,
        right = self.margin.right,
        bottom = self.margin.bottom,
        left = self.margin.left
    }
end

---@return string alignment
function Widget:getHorizontalAlignment()
    return self.horizontalAlignment
end

---@return string alignment
function Widget:getVerticalAlignment()
    return self.verticalAlignment
end

---@return boolean visible
function Widget:isVisible()
    return self.state.isVisible
end

---@return boolean disabled
function Widget:isDisabled()
    return self.state.isDisabled
end

---@return LayoutStrategy? strategy
function Widget:getLayoutStrategy()
    return self.layoutStrategy
end

---@param widget Widget
---@return number
local function getMaxTabIndexInSubtree(widget)
    local maxIndex = widget.__tabIndex
    for _, child in ipairs(widget.children) do
        local childMax = getMaxTabIndexInSubtree(child)
        if childMax > maxIndex then
            maxIndex = childMax
        end
    end
    return maxIndex
end

---@param widget Widget
---@param counter number
---@return number
local function assignSequentialTabIndexes(widget, counter)
    counter = counter + 1
    widget.__tabIndex = counter

    for _, child in ipairs(widget.children) do
        counter = assignSequentialTabIndexes(child, counter)
    end

    return counter
end

---Build a nested tree structure of this widget and its descendants
---@return table tree { widget: Widget, children: table[] }
function Widget:buildDescendantTree()
    local tree = {
        widget = self,
        children = {}
    }

    for _, child in ipairs(self.children) do
        table.insert(tree.children, child:buildDescendantTree())
    end

    return tree
end

---@param child Widget Child widget to add
---@return Widget self
function Widget:addChild(child)
    table.insert(self.children, child)
    child.parent = self

    local maxSiblingIndex = self.__tabIndex
    for _, sibling in ipairs(self.children) do
        if sibling ~= child then
            local siblingMax = getMaxTabIndexInSubtree(sibling)
            if siblingMax > maxSiblingIndex then
                maxSiblingIndex = siblingMax
            end
        end
    end

    assignSequentialTabIndexes(child, maxSiblingIndex)

    child:onMount()
    self:invalidateLayout()
    return self
end

---@param child Widget Child widget to remove
---@return Widget self
function Widget:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil

            local host = self:__getHost()
            if host and host.focusedWidget then
                local current = host.focusedWidget
                while current do
                    if current == child then
                        host:setFocusedWidget(nil)
                        break
                    end
                    current = current.parent
                end
            end

            child:onUnmount()
            self:invalidateLayout()
            break
        end
    end
    return self
end

---@param index number Index of child to remove
---@return Widget self
function Widget:removeChildAt(index)
    local child = self.children[index]
    if child then
        table.remove(self.children, index)
        child.parent = nil

        local host = self:__getHost()
        if host and host.focusedWidget then
            local current = host.focusedWidget
            while current do
                if current == child then
                    host:setFocusedWidget(nil)
                    break
                end
                current = current.parent
            end
        end

        child:onUnmount()
        self:invalidateLayout()
    end
    return self
end

---@return Widget self
function Widget:clearChildren()
    local host = self:__getHost()
    if host and host.focusedWidget then
        for _, child in ipairs(self.children) do
            local current = host.focusedWidget
            while current do
                if current == child then
                    host:setFocusedWidget(nil)
                    break
                end
                current = current.parent
            end
        end
    end

    for _, child in ipairs(self.children) do
        child.parent = nil
        child:onUnmount()
    end
    self.children = {}
    self:invalidateLayout()
    return self
end

---@return Widget self
function Widget:removeAllChildren()
    return self:clearChildren()
end

---@param index number Index of child
---@return Widget? child
function Widget:getChild(index)
    return self.children[index]
end

---@return Widget[]
function Widget:getChildren()
    return self.children
end

---@return Widget? parent
function Widget:getParent()
    return self.parent
end

---@param id string Widget ID to search for
---@return Widget? widget
function Widget:findById(id)
    if self.id == id then
        return self
    end

    for _, child in ipairs(self.children) do
        local found = child:findById(id)
        if found then
            return found
        end
    end

    return nil
end

---@return Widget self For method chaining
function Widget:bringToFront()
    if not self.parent then
        return self
    end

    local currentIndex = nil
    for i, child in ipairs(self.parent.children) do
        if child == self then
            currentIndex = i
            break
        end
    end

    if not currentIndex then
        return self
    end

    if currentIndex == #self.parent.children then
        return self
    end

    table.remove(self.parent.children, currentIndex)
    table.insert(self.parent.children, self)

    self.parent:invalidateRender()

    return self
end

---@param event string Event name
---@param handler fun(self: Widget, event: Event): boolean? Event handler function (return true to consume)
---@param options {capture: boolean}? Handler options
---@return Widget self
function Widget:on(event, handler, options)
    options = options or {}
    local handlersTable = options.capture and self.__captureHandlers or self.__handlers

    if not handlersTable[event] then
        handlersTable[event] = {}
    end

    table.insert(handlersTable[event], handler)
    return self
end

---@param event string Event name
---@param handler fun(self: Widget, event: Event)? Specific handler to remove (or nil for all)
---@return Widget self
function Widget:off(event, handler)
    if not handler then
        self.__handlers[event] = nil
        self.__captureHandlers[event] = nil
    else
        if self.__handlers[event] then
            for i, h in ipairs(self.__handlers[event]) do
                if h == handler then
                    table.remove(self.__handlers[event], i)
                    break
                end
            end
        end
        if self.__captureHandlers[event] then
            for i, h in ipairs(self.__captureHandlers[event]) do
                if h == handler then
                    table.remove(self.__captureHandlers[event], i)
                    break
                end
            end
        end
    end
    return self
end

---@param event string Event name
---@param handler fun(self: Widget, event: Event) Event handler function
---@return Widget self
function Widget:once(event, handler)
    local wrappedHandler
    wrappedHandler = function(self, eventData)
        handler(self, eventData)
        self:off(event, wrappedHandler)
    end
    return self:on(event, wrappedHandler)
end

---@param handler fun(self: Widget, event: Event) Click handler function
---@return Widget self
function Widget:onClick(handler)
    return self:on("clicked", handler)
end

---@param handler fun(self: Widget, event: Event) Hover handler function
---@return Widget self
function Widget:onHover(handler)
    return self:on("mouseEntered", handler)
end

---@param event Event Event object
function Widget:dispatchEvent(event)
    self:__handleEvent(event)
end

---@protected
---@param event Event Event object
function Widget:__handleEvent(event)
    if self.__handlers and self.__handlers[event.type] then
        for _, handler in ipairs(self.__handlers[event.type]) do
            local consumed = handler(self, event)
            if consumed then
                event.consumed = true
            end
        end
    end

    local methodName = "on" .. event.type:sub(1, 1):upper() .. event.type:sub(2)
    if self[methodName] and type(self[methodName]) == "function" then
        local consumed = self[methodName](self, event)
        if consumed then
            event.consumed = true
        end
    end
end

---@protected
---@param event Event Event object
function Widget:__handleCaptureEvent(event)
    if self.__captureHandlers[event.type] then
        for _, handler in ipairs(self.__captureHandlers[event.type]) do
            local consumed = handler(self, event)
            if consumed then
                event.consumed = true
            end
        end
    end
end

function Widget:focus()
    if self.__focusable then
        local host = self:__getHost()
        if host then
            host:setFocusedWidget(self)
        end
    end
end

function Widget:blur()
    local host = self:__getHost()
    if host and host:getFocusedWidget() == self then
        host:setFocusedWidget(nil)
    end
end

---@return boolean
function Widget:isFocused()
    return self.state.isFocused
end

---@protected
---@return Host? host
function Widget:__getHost()
    local current = self

    while current and current.parent do
        current = current.parent
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return current
end

---@param availableWidth number Available width in pixels
---@param availableHeight number Available height in pixels
---@return number desiredWidth
---@return number desiredHeight
function Widget:measure(availableWidth, availableHeight)
    if self.layoutStrategy then
        local desiredWidth, desiredHeight = self.layoutStrategy:measure(self, availableWidth, availableHeight)

        self.desiredWidth = desiredWidth
        self.desiredHeight = desiredHeight

        self.isLayoutDirty = false

        return desiredWidth, desiredHeight
    end

    local contentWidth = availableWidth - self.padding.left - self.padding.right
    local contentHeight = availableHeight - self.padding.top - self.padding.bottom

    for _, child in ipairs(self.children) do
        if child:isVisible() then
            child:measure(contentWidth, contentHeight)
        end
    end

    ---@type number|number?
    local desiredWidth = self:calculateDesiredWidth(availableWidth)

    ---@type number|number?
    local desiredHeight = self:calculateDesiredHeight(availableHeight)

    desiredWidth, desiredHeight = self:__applyConstraints(desiredWidth, desiredHeight)

    assert(desiredWidth, "Desired width must be calculated")
    assert(desiredHeight, "Desired height must be calculated")

    self.desiredWidth = desiredWidth
    self.desiredHeight = desiredHeight

    self.isLayoutDirty = false

    return desiredWidth, desiredHeight
end

---@param availableWidth number Available width
---@return number desiredWidth
function Widget:calculateDesiredWidth(availableWidth)
    local width = self.preferredWidth

    if type(width) == "number" then
        return width
    else
        if width.type == "fixed" then
            return width.value
        elseif width.type == "percent" then
            return availableWidth * width.value
        elseif width.type == "auto" then
            return self:__calculateContentWidth()
        elseif width.type == "fill" then
            return availableWidth
        end
    end

    return 100
end

---@param availableHeight number Available height
---@return number desiredHeight
function Widget:calculateDesiredHeight(availableHeight)
    local height = self.preferredHeight
    if type(height) == "number" then
        return height
    else
        if height.type == "fixed" then
            return height.value
        elseif height.type == "percent" then
            return availableHeight * height.value
        elseif height.type == "auto" then
            return self:__calculateContentHeight()
        elseif height.type == "fill" then
            return availableHeight
        end
    end
    return 100
end

---@protected
---@param desiredWidth number? Desired width before constraints
---@param desiredHeight number? Desired height before constraints
---@return number constrainedWidth, number constrainedHeight
function Widget:__applyConstraints(desiredWidth, desiredHeight)
    if self.minWidth and self.minWidth > 0 then
        desiredWidth = math.max(self.minWidth, desiredWidth)
    end
    if self.maxWidth and self.maxWidth > 0 then
        desiredWidth = math.min(self.maxWidth, desiredWidth)
    end
    if self.minHeight and self.minHeight > 0 then
        desiredHeight = math.max(self.minHeight, desiredHeight)
    end
    if self.maxHeight and self.maxHeight > 0 then
        desiredHeight = math.min(self.maxHeight, desiredHeight)
    end

    if self.sizeConstraint then
        local c = self.sizeConstraint

        if not c then
            ---@diagnostic disable-next-line: return-type-mismatch
            return desiredWidth, desiredHeight
        end

        if c.type == "width_by_height" then
            ---@diagnostic disable-next-line: param-type-mismatch
            desiredWidth = math.min(desiredWidth, desiredHeight)
        elseif c.type == "height_by_width" then
            ---@diagnostic disable-next-line: param-type-mismatch
            desiredHeight = math.min(desiredHeight, desiredWidth)
        elseif c.type == "square" then
            ---@diagnostic disable-next-line: param-type-mismatch
            local minDim = math.min(desiredWidth, desiredHeight)
            desiredWidth = minDim
            desiredHeight = minDim
        elseif c.type == "max_both" then
            ---@diagnostic disable-next-line: param-type-mismatch
            desiredWidth = math.min(desiredWidth, c.value)

            ---@diagnostic disable-next-line: param-type-mismatch
            desiredHeight = math.min(desiredHeight, c.value)
        elseif c.type == "ratio" then
            local ratioWidth = desiredHeight * c.value
            local ratioHeight = desiredWidth / c.value
            if ratioWidth <= desiredWidth then
                desiredWidth = ratioWidth
            else
                desiredHeight = ratioHeight
            end
        end
    end

    if self.aspectRatio then
        local ratioWidth = desiredHeight * self.aspectRatio
        local ratioHeight = desiredWidth / self.aspectRatio

        if ratioWidth <= desiredWidth then
            desiredWidth = ratioWidth
        else
            desiredHeight = ratioHeight
        end
    end

    assert(desiredWidth, "Desired width not defined after constraints")
    assert(desiredHeight, "Desired height not defined after constraints")

    return desiredWidth, desiredHeight
end

---@protected
---@return number contentWidth
function Widget:__calculateContentWidth()
    -- Default: sum of children widths (containers override this)
    local maxWidth = 0
    for _, child in ipairs(self.children) do
        if child.isVisible then
            maxWidth = math.max(maxWidth, child.desiredWidth)
        end
    end
    return maxWidth + self.padding.left + self.padding.right
end

---@protected
---@return number contentHeight
function Widget:__calculateContentHeight()
    local maxHeight = 0

    for _, child in ipairs(self.children) do
        if child.isVisible then
            maxHeight = math.max(maxHeight, child.desiredHeight)
        end
    end
    return maxHeight + self.padding.top + self.padding.bottom
end

---Get the content bounds (area inside padding)
---@protected
---@return number contentX, number contentY, number contentWidth, number contentHeight
function Widget:__getContentBounds()
    return self.x + self.padding.left,
           self.y + self.padding.top,
           self.width - self.padding.left - self.padding.right,
           self.height - self.padding.top - self.padding.bottom
end

---Calculate Y position to vertically center an element within content bounds
---@protected
---@param elementHeight number Height of the element to center
---@return number centerY The Y position that centers the element
function Widget:__centerVertically(elementHeight)
    local contentX, contentY, contentW, contentH = self:__getContentBounds()
    return contentY + (contentH - elementHeight) / 2
end

---@param x number X position
---@param y number Y position
---@param width number Final width
---@param height number Final height
function Widget:arrange(x, y, width, height)
    -- Apply size constraints to final dimensions
    if self.sizeConstraint then
        local c = self.sizeConstraint

        if not c then
            return
        end

        if c.type == "width_by_height" then
            width = math.min(width, height)
        elseif c.type == "height_by_width" then
            height = math.min(height, width)
        elseif c.type == "square" then
            local minDim = math.min(width, height)
            width = minDim
            height = minDim
        elseif c.type == "max_both" then
            width = math.min(width, c.value)
            height = math.min(height, c.value)
        elseif c.type == "ratio" then
            local ratioWidth = height * c.value
            local ratioHeight = width / c.value
            if ratioWidth <= width then
                width = ratioWidth
            else
                height = ratioHeight
            end
        end
    end

    self.x = x
    self.y = y
    self.width = width
    self.height = height

    local contentX = x + self.padding.left
    local contentY = y + self.padding.top
    local contentWidth = width - self.padding.left - self.padding.right
    local contentHeight = height - self.padding.top - self.padding.bottom

    self:arrangeChildren(contentX, contentY, contentWidth, contentHeight)
end

---@param contentX number Content area X
---@param contentY number Content area Y
---@param contentWidth number Content area width
---@param contentHeight number Content area height
function Widget:arrangeChildren(contentX, contentY, contentWidth, contentHeight)
    if self.layoutStrategy then
        self.layoutStrategy:arrangeChildren(self, contentX, contentY, contentWidth, contentHeight)
        return
    end

    for _, child in ipairs(self.children) do
        if child.isVisible then
            local childWidth = child.desiredWidth
            local childHeight = child.desiredHeight

            local childX = contentX
            local childY = contentY

            if child.horizontalAlignment == "center" then
                childX = contentX + (contentWidth - childWidth) / 2
            elseif child.horizontalAlignment == "right" then
                childX = contentX + contentWidth - childWidth
            elseif child.horizontalAlignment == "stretch" then
                childWidth = contentWidth
            end

            if child.verticalAlignment == "center" then
                childY = contentY + (contentHeight - childHeight) / 2
            elseif child.verticalAlignment == "bottom" then
                childY = contentY + contentHeight - childHeight
            elseif child.verticalAlignment == "stretch" then
                childHeight = contentHeight
            end

            child:arrange(childX, childY, childWidth, childHeight)
        end
    end
end

function Widget:invalidateLayout()
    self.isLayoutDirty = true

    if self.parent then
        self.parent:invalidateLayout()
    end
end

function Widget:invalidateRender()
    self.isRenderDirty = true
end

---@param x number Point X
---@param y number Point Y
---@return boolean
function Widget:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height
end

---@param x number Point X
---@param y number Point Y
---@return Widget? hitWidget
function Widget:hitTest(x, y)
    if not self:isVisible() then
        return nil
    end

    if not self:containsPoint(x, y) then
        return nil
    end

    -- If this widget is hit transparent, don't return it
    -- Instead, check children and return them if they're hit
    -- Otherwise return nil to allow parent to handle the hit
    if self:isHitTransparent() then
        for i = #self.children, 1, -1 do
            local hit = self.children[i]:hitTest(x, y)
            if hit then
                return hit
            end
        end
        return nil
    end

    for i = #self.children, 1, -1 do
        local hit = self.children[i]:hitTest(x, y)
        if hit then
            return hit
        end
    end

    return self
end

---Create a reactive proxy for nested tables (padding, margin)
---@private
---@param rawTable table The raw nested table
---@param parentKey string The parent property key (e.g., "padding")
---@return table proxy The reactive proxy for the nested table
function Widget:__makeReactiveNested(rawTable, parentKey)
    local proxy = Reactive.createProxy(
        rawTable,
        nil,
        function(key, value, oldValue)
            -- When any nested property changes, invalidate based on parent property type
            local config = PropertyMetadata.getConfig(parentKey)

            if config.type == "layout" then
                self:invalidateLayout()
            elseif config.type == "render" then
                self:invalidateRender()
            end
        end
    )
    return proxy
end

---Watch a property for changes
---Calls callback when the watched property changes
---@param source string|function Property name (string) or getter function
---@param callback function(newValue, oldValue) Callback when value changes
---@param options {immediate: boolean?, deep: boolean?}? Watcher options
---@return Watcher The watcher instance (can be passed to unwatch)
function Widget:watch(source, callback, options)
    local watcher = Watcher(self, source, callback, options)
    table.insert(self.__watchers, watcher)
    return watcher
end

---Add a custom property to the widget
---Custom properties are reactive and accessible via self.props
---@param name string Property name
---@param initialValue any Initial value for the property
---@return Widget self
function Widget:addProperty(name, initialValue)
    self.__rawProps[name] = initialValue
    self[name] = initialValue
    return self
end

---Create a computed property
---Computed properties automatically track dependencies and update lazily
---@param name string Name of the computed property
---@param getter function() Function that computes and returns the value
---@return Computed The computed instance (access value with :get())
function Widget:computed(name, getter)
    local computed = Computed(getter)
    self.__computed[name] = computed
    return computed
end

---Bind a widget property to a computed property
---The property will automatically update whenever the computed value changes
---@param propertyName string Name of the property to bind (e.g., "text" or "margin.left")
---@param computed Computed The computed property to bind to
---@return Widget self
function Widget:bindTo(propertyName, computed)
    local function setNestedProperty(value)
        if not propertyName:find("%.") then
            self.props[propertyName] = value
        else
            local target = self.props
            local segments = {}
            for segment in propertyName:gmatch("[^%.]+") do
                table.insert(segments, segment)
            end
            for i = 1, #segments - 1 do
                target = target[segments[i]]
            end
            target[segments[#segments]] = value
        end
    end

    setNestedProperty(computed:get())

    computed:subscribe(function()
        setNestedProperty(computed:get())
    end)

    return self
end

---Bind properties from a source (Widget, State, or StateScope)
---Properties automatically sync when the source changes
---@param source Widget|State|StateScope The source to bind from
---@param mapping table|string Property mapping table, or single property name (string)
---@param transform function? Optional transform function when using single property syntax
---@return Widget self
function Widget:bindFrom(source, mapping, transform)
    -- Single property syntax: bindFrom(source, "propName", optionalTransform)
    if type(mapping) == "string" then
        local sourceProperty = mapping
        local targetProperty = mapping
        local initialValue = source.props[sourceProperty]

        if transform then
            initialValue = transform(initialValue)
        end

        self.props[targetProperty] = initialValue

        source:watch(sourceProperty, function(newValue)
            if transform then
                newValue = transform(newValue)
            end

            self.props[targetProperty] = newValue
        end)

        return self
    end

    for key, value in pairs(mapping) do
        local targetProperty, sourceProperty
        if type(key) == "number" then
            targetProperty = value
            sourceProperty = value
        else
            targetProperty = key
            sourceProperty = value
        end

        self.props[targetProperty] = source.props[sourceProperty]

        source:watch(sourceProperty, function(newValue)
            self.props[targetProperty] = newValue
        end)
    end

    return self
end

---Remove a specific watcher
---@param watcher Watcher The watcher to remove
function Widget:unwatch(watcher)
    watcher:unwatch()
    for i, w in ipairs(self.__watchers) do
        if w == watcher then
            table.remove(self.__watchers, i)
            break
        end
    end
end

---Configure whether this widget is draggable
---@param draggable boolean Whether the widget can be dragged
---@param dragHandle table? Optional drag handle rectangle {x, y, width, height}
---@return Widget self
function Widget:setDraggable(draggable, dragHandle)
    self.isDraggable = draggable
    if dragHandle then
        self.dragHandle = dragHandle
    end
    return self
end

---Set the drag mode ("position" or "delta")
---@param mode string "position" for position-based dragging, "delta" for delta-based
---@return Widget self
function Widget:setDragMode(mode)
    assert(mode == "position" or mode == "delta", "dragMode must be 'position' or 'delta'")
    self.dragMode = mode
    return self
end

---Set the drag handle rectangle
---@param rect table? Rectangle {x, y, width, height} relative to widget, or nil to allow drag from anywhere
---@return Widget self
function Widget:setDragHandle(rect)
    self.dragHandle = rect
    return self
end

---Check if a point is within the drag handle
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean True if point is in drag handle
function Widget:isInDragHandle(x, y)
    -- Check if point is within widget bounds
    if x < self.x or x > self.x + self.width or
       y < self.y or y > self.y + self.height then
        return false
    end

    -- If no drag handle specified, entire widget is draggable
    if not self.dragHandle then
        return true
    end

    -- Convert point to local coordinates
    local localX = x - self.x
    local localY = y - self.y

    local handleX = self.dragHandle.x or 0
    local handleY = self.dragHandle.y or 0

    -- width/height of 0 means full widget dimension
    local handleWidth = self.dragHandle.width == 0 and self.width or (self.dragHandle.width or self.width)
    local handleHeight = self.dragHandle.height == 0 and self.height or (self.dragHandle.height or self.height)

    return localX >= handleX and localX < handleX + handleWidth and
           localY >= handleY and localY < handleY + handleHeight
end

---Check if this widget is currently being dragged
---@return boolean True if widget is currently being dragged
function Widget:isDragging()
    local host = self:__getHost()

    return host and host.isWidgetDragged and host:isWidgetDragged(self) or false
end

---Clean up all watchers and computed properties
---Called automatically on unmount to prevent memory leaks
---@private
function Widget:__cleanupReactive()
    for _, watcher in ipairs(self.__watchers) do
        watcher:unwatch()
    end

    self.__watchers = {}

    for _, computed in pairs(self.__computed) do
        for dependency in pairs(computed.dependencies) do
            dependency.subscribers[computed] = nil
        end
    end

    self.__computed = {}
end

function Widget:onMount()
end

function Widget:onUnmount()
    self:__cleanupReactive()
end

---@param dt number Delta time in seconds
function Widget:onUpdate(dt)
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            child:onUpdate(dt)
        end
    end
end

---Called when mouse wheel is scrolled over this widget
---@param event MouseEvent Mouse wheel event with dx and dy
---@return boolean? consumed Return true to consume the event
function Widget:onMouseWheel(event)
    -- Default: do nothing, let event propagate
end

function Widget:onRender()
    if self.clipContent then
        local prevX, prevY, prevW, prevH = Scissor.push(self.x, self.y, self.width, self.height)

        for _, child in ipairs(self.children) do
            if child:isVisible() then
                child:onRender()
            end
        end

        Scissor.pop(prevX, prevY, prevW, prevH)
    else
        for _, child in ipairs(self.children) do
            if child:isVisible() then
                child:onRender()
            end
        end
    end
end

return Widget
