---Mixin for event handling functionality
---Provides: on, off, once, onClick, onHover, dispatchEvent
---Used by: Widget

---@class EventEmitterMixin
---@field eventHandlers table Event handlers (bubble phase)
---@field eventCaptureHandlers table Event handlers (capture phase)
local EventEmitterMixin = {}

---Initialize event emitter fields on an instance
---Call this from the constructor of classes using this mixin
---@param self table The instance to initialize
function EventEmitterMixin.initEventEmitter(self)
    self.eventHandlers = {}
    self.eventCaptureHandlers = {}
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