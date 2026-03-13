---Mixin for event handling functionality

---@class EventEmitterMixin
---@field eventHandlers table Event handlers (bubble phase)
---@field eventCaptureHandlers table Event handlers (capture phase)
---@field __handlers table Lifecycle and drag callback handlers
local EventEmitterMixin = {}

---Initialize event emitter fields on an instance
---Call this from the constructor of classes using this mixin
---@param self table The instance to initialize
function EventEmitterMixin.initEventEmitter(self)
    self.eventHandlers = {}
    self.eventCaptureHandlers = {}
    self.__handlers = {}
end

---Add an event listener
---@param event string Event name
---@param handler fun(self: any, event: Event): boolean? Event handler function (return true to consume)
---@param options {capture: boolean}? Handler options
---@return self
function EventEmitterMixin:on(event, handler, options)
    options = options or {}
    local handlersTable = options.capture and self.eventCaptureHandlers or self.eventHandlers

    if not handlersTable[event] then
        handlersTable[event] = {}
    end

    table.insert(handlersTable[event], handler)
    return self
end

---Remove an event listener
---@param event string Event name
---@param handler fun(self: any, event: Event)? Specific handler to remove (or nil for all)
---@return self
function EventEmitterMixin:off(event, handler)
    if not handler then
        self.eventHandlers[event] = nil
        self.eventCaptureHandlers[event] = nil
    else
        if self.eventHandlers[event] then
            for i, h in ipairs(self.eventHandlers[event]) do
                if h == handler then
                    table.remove(self.eventHandlers[event], i)
                    break
                end
            end
        end

        if self.eventCaptureHandlers[event] then
            for i, h in ipairs(self.eventCaptureHandlers[event]) do
                if h == handler then
                    table.remove(self.eventCaptureHandlers[event], i)
                    break
                end
            end
        end
    end

    return self
end

---Add a one-time event listener
---@param event string Event name
---@param handler fun(self: any, event: Event) Event handler function
---@return self
function EventEmitterMixin:once(event, handler)
    local wrappedHandler

    wrappedHandler = function(self, eventData)
        handler(self, eventData)
        self:off(event, wrappedHandler)
    end

    return self:on(event, wrappedHandler)
end

---Add a click event listener (convenience method)
---@param handler fun(self: any, event: Event) Click handler function
---@return self
function EventEmitterMixin:onClick(handler)
    return self:on("clicked", handler)
end

---Add a hover event listener (convenience method)
---@param handler fun(self: any, event: Event) Hover handler function
---@return self
function EventEmitterMixin:onHover(handler)
    return self:on("mouseEntered", handler)
end

---Add a handler to the unified __handlers table
---@param name string Handler name (e.g. "update", "mount", "dragStart")
---@param fn function Handler function
---@return self
function EventEmitterMixin:__addHandler(name, fn)
    if not self.__handlers[name] then
        self.__handlers[name] = {}
    end

    table.insert(self.__handlers[name], fn)
    return self
end

---Call all handlers registered under the given name
---@param name string Handler name
---@param ... any Arguments to pass to each handler
function EventEmitterMixin:__callHandlers(name, ...)
    local handlers = self.__handlers[name]

    if handlers then
        for _, fn in ipairs(handlers) do
            fn(self, ...)
        end
    end
end

-- Lifecycle registration wrappers

---Add an update handler called every frame
---@param handler fun(self: any, dt: number)
---@return self
function EventEmitterMixin:onUpdate(handler)
    return self:__addHandler("update", handler)
end

---Add a mount handler called when widget is added to the tree
---@param handler fun(self: any)
---@return self
function EventEmitterMixin:onMount(handler)
    return self:__addHandler("mount", handler)
end

---Add an unmount handler called when widget is removed from the tree
---@param handler fun(self: any)
---@return self
function EventEmitterMixin:onUnmount(handler)
    return self:__addHandler("unmount", handler)
end

---Add a mouse wheel event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onMouseWheel(handler)
    return self:on("mouseWheel", handler)
end

---Add a mouse pressed event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onMousePressed(handler)
    return self:on("mousePressed", handler)
end

---Add a mouse released event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onMouseReleased(handler)
    return self:on("mouseReleased", handler)
end

---Add a mouse moved event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onMouseMoved(handler)
    return self:on("mouseMoved", handler)
end

---Add a mouse entered event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onMouseEntered(handler)
    return self:on("mouseEntered", handler)
end

---Add a mouse exited event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onMouseExited(handler)
    return self:on("mouseExited", handler)
end

---Add a key pressed event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onKeyPressed(handler)
    return self:on("keyPressed", handler)
end

---Add a key released event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onKeyReleased(handler)
    return self:on("keyReleased", handler)
end

---Add a text input event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onTextInput(handler)
    return self:on("textInput", handler)
end

---Add a focus gained event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onFocusGained(handler)
    return self:on("focusGained", handler)
end

---Add a focus lost event listener
---@param handler fun(self: any, event: Event)
---@return self
function EventEmitterMixin:onFocusLost(handler)
    return self:on("focusLost", handler)
end

---Add a drag start handler
---@param handler fun(self: any)
---@return self
function EventEmitterMixin:onDragStart(handler)
    return self:__addHandler("dragStart", handler)
end

---Add a drag handler
---@param handler fun(self: any)
---@return self
function EventEmitterMixin:onDrag(handler)
    return self:__addHandler("drag", handler)
end

---Add a drag end handler
---@param handler fun(self: any)
---@return self
function EventEmitterMixin:onDragEnd(handler)
    return self:__addHandler("dragEnd", handler)
end

---Add a drag over handler
---@param handler fun(self: any)
---@return self
function EventEmitterMixin:onDragOver(handler)
    return self:__addHandler("dragOver", handler)
end

---Add a drag leave handler
---@param handler fun(self: any)
---@return self
function EventEmitterMixin:onDragLeave(handler)
    return self:__addHandler("dragLeave", handler)
end

---Add a drop handler
---@param handler fun(self: any, ...: any)
---@return self
function EventEmitterMixin:onDrop(handler)
    return self:__addHandler("drop", handler)
end

---Dispatch an event to this widget
---@param event Event Event object
function EventEmitterMixin:dispatchEvent(event)
    ---@diagnostic disable-next-line: undefined-field
    if self.__handleEvent then
        ---@diagnostic disable-next-line: undefined-field
        self:__handleEvent(event)
    end
end

return EventEmitterMixin