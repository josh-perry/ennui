local Reactive = require("ennui.reactive")
local PropertyMetadata = require("ennui.property_metadata")
local Scissor = require("ennui.utils.scissor")
local Mixins = require("ennui.mixins")
local Mixin = require("ennui.utils.mixin")

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

---@class Widget : StatefulMixin, ParentableMixin, PositionableMixin, LayoutableMixin, DraggableMixin, FocusableMixin, EventEmitterMixin
---@field public id string? Optional widget identifier
---@field public isLayoutDirty boolean Whether layout needs recalculation
---@field public isRenderDirty boolean Whether widget needs redraw
---@field public layoutStrategy LayoutStrategy? Optional layout strategy for arranging children
---@field public isTabContext boolean Whether this widget creates a new tab focus scope
---@field public clipContent boolean Whether to clip children to widget bounds
---@field private __hitTransparent boolean Whether widget passes through hit events to parent
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

Mixin.extend(Widget,
    Mixins.Stateful,
    Mixins.Parentable,
    Mixins.Positionable,
    Mixins.Layoutable,
    Mixins.Draggable,
    Mixins.Focusable,
    Mixins.EventEmitter
)

function Widget:__tostring()
    return "Widget"
end

---@return Widget
function Widget.new()
    local self = setmetatable({}, Widget)

    self:initStateful()
    self:initParentable()
    self:initPositionable()
    self:initLayoutable()
    self:initDraggable()
    self:initFocusable()
    self:initEventEmitter()

    self.id = nil
    self.isLayoutDirty = true
    self.isRenderDirty = true
    self.isTabContext = false
    self.layoutStrategy = nil
    self.__hitTransparent = false
    self.clipContent = false
    self.__subscriptions = {}

    self:addProperty("isHovered", false)
    self:addProperty("isFocused", false)
    self:addProperty("isPressed", false)
    self:addProperty("isDisabled", false)
    self:addProperty("isVisible", true)
    self:addProperty("isDocked", false)

    self.props = Reactive.createProxy(self.__rawProps, {
        onSet = function(key, value, oldValue)
            if PropertyMetadata.isLayoutProperty(key) then
                self:invalidateLayout()
            elseif PropertyMetadata.isRenderProperty(key) then
                self:invalidateRender()
            end
        end,
    })

    self.props.padding = self:__makeReactiveNested(self.__rawProps.padding, "padding")
    self.props.margin = self:__makeReactiveNested(self.__rawProps.margin, "margin")

    return self
end

---Set widget ID
---@generic T : Widget
---@param self T
---@param id string Widget identifier
---@return T
function Widget:setId(id)
    self.id = id
    return self
end

---@generic T : Widget
---@param self T
---@param visible boolean Whether widget is visible
---@return T
function Widget:setVisible(visible)
    ---@cast self Widget
    if self.props.isVisible == visible then
        return self
    end

    self.props.isVisible = visible

    -- If becoming invisible, clear focus from this widget and its descendants
    if not visible then
        local host = self:getHost()
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

---@generic T : Widget
---@param self T
---@param disabled boolean Whether widget is disabled
---@return T
function Widget:setDisabled(disabled)
    ---@cast self Widget
    if self.props.isDisabled == disabled then
        return self
    end

    self.props.isDisabled = disabled
    return self
end

---@generic T : Widget
---@param self T
---@param strategy LayoutStrategy? Layout strategy instance (nil to use default)
---@return T
function Widget:setLayoutStrategy(strategy)
    ---@cast self Widget
    self.layoutStrategy = strategy
    self:invalidateLayout()
    return self
end


---@generic T : Widget
---@param self T
---@param transparent boolean Whether widget should pass through hit events
---@return T
function Widget:setHitTransparent(transparent)
    ---@cast self Widget
    self.__hitTransparent = transparent
    return self
end

---@return boolean hitTransparent
function Widget:isHitTransparent()
    return self.__hitTransparent
end

---Set whether to clip children to widget bounds
---@generic T : Widget
---@param self T
---@param clip boolean Whether to enable content clipping
---@return T
function Widget:setClipContent(clip)
    ---@cast self Widget
    self.clipContent = clip
    return self
end

---@return string? id
function Widget:getId()
    return self.id
end

---@return boolean visible
---@diagnostic disable-next-line: assign-type-mismatch
function Widget:isVisible()
    if self.props then
        return not not self.props.isVisible
    end

    return false
end

---@return boolean disabled
---@diagnostic disable-next-line: assign-type-mismatch
function Widget:isDisabled()
    if self.props then
        return not not self.props.isDisabled
    end

    return false
end

---@return LayoutStrategy? strategy
function Widget:getLayoutStrategy()
    return self.layoutStrategy
end

---@param widget Widget
---@return number
local function getMaxTabIndexInSubtree(widget)
    local maxIndex = widget.tabIndex

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
    widget.tabIndex = counter

    for _, child in ipairs(widget.children) do
        counter = assignSequentialTabIndexes(child, counter)
    end

    return counter
end


---Hook called after a child is added (implements ParentableMixin hook)
---@param child Widget The child that was added
function Widget:__onAfterAddChild(child)
    -- Assign tab indexes
    local maxSiblingIndex = self.tabIndex
    for _, sibling in ipairs(self.children) do
        if sibling ~= child then
            local siblingMax = getMaxTabIndexInSubtree(sibling)
            if siblingMax > maxSiblingIndex then
                maxSiblingIndex = siblingMax
            end
        end
    end

    assignSequentialTabIndexes(child, maxSiblingIndex)

    -- Invalidate layout
    self:invalidateLayout()
end

---Hook called after a child is removed (implements ParentableMixin hook)
---@param child Widget The child that was removed
function Widget:__onAfterRemoveChild(child)
    -- Clear focus if focused widget is being removed
    local host = self:getHost()
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

    -- Invalidate layout
    self:invalidateLayout()
end


---@generic T : Widget
---@param self T
---@return T
function Widget:bringToFront()
    ---@cast self Widget
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

---@protected
---@param event Event Event object
function Widget:__handleEvent(event)
    if self.eventHandlers and self.eventHandlers[event.type] then
        for _, handler in ipairs(self.eventHandlers[event.type]) do
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
    if self.eventCaptureHandlers[event.type] then
        for _, handler in ipairs(self.eventCaptureHandlers[event.type]) do
            local consumed = handler(self, event)

            if consumed then
                event.consumed = true
            end
        end
    end
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
        if child:isVisible() then
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
    return Reactive.createProxy(rawTable, {
        onSet = function(key, value, oldValue)
            -- When any nested property changes, invalidate based on parent property type
            local config = PropertyMetadata.getConfig(parentKey)

            if config.type == "layout" then
                self:invalidateLayout()
            elseif config.type == "render" then
                self:invalidateRender()
            end
        end,
    })
end

---Bind a widget property to a computed property
---The property will automatically update whenever the computed value changes
---@generic T : Widget
---@param self T
---@param propertyName string Name of the property to bind (e.g., "text" or "margin.left")
---@param computed Computed The computed property to bind to
---@return T
function Widget:bindTo(propertyName, computed)
    ---@cast self Widget
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

    local unsubscribe = computed:subscribe(function()
        setNestedProperty(computed:get())
    end)

    table.insert(self.__subscriptions, unsubscribe)

    return self
end

---Bind properties from a source (Widget, State, or StateScope)
---Properties automatically sync when the source changes
---@generic T : Widget
---@param self T
---@param source Widget|State|StateScope The source to bind from
---@param mapping table|string Property mapping table, or single property name (string)
---@param transform function? Optional transform function when using single property syntax
---@return T
function Widget:bindFrom(source, mapping, transform)
    ---@cast self Widget

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

---Clean up all watchers, computed properties and subscriptions
---Called automatically on unmount to prevent memory leaks
---Delegates to StatefulMixin:cleanupStateful()
---@private
---@generic T : Widget
---@param self T
function Widget:__cleanupReactive()
    ---@cast self Widget
    for _, unsubscribe in ipairs(self.__subscriptions) do
        unsubscribe()
    end

    self.__subscriptions = {}
    self:cleanupStateful()
end

---Called when the widget is mounted to the widget tree
---@generic T : Widget
---@param self T
function Widget:onMount()
    ---@cast self Widget
end

---Called when the widget is unmounted from the widget tree
---@generic T : Widget
---@param self T
function Widget:onUnmount()
    ---@cast self Widget
    self:__cleanupReactive()
end

---Called every frame to update the widget
---@generic T : Widget
---@param self T
---@param dt number Delta time in seconds
function Widget:onUpdate(dt)
    ---@cast self Widget
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            child:onUpdate(dt)
        end
    end
end

---Called when mouse wheel is scrolled over this widget
---@generic T : Widget
---@param self T
---@param event MouseEvent Mouse wheel event with dx and dy
---@return boolean? consumed Return true to consume the event
function Widget:onMouseWheel(event)
    ---@cast self Widget
end

---Called to render the widget and its children
---@generic T : Widget
---@param self T
function Widget:onRender()
    ---@cast self Widget
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