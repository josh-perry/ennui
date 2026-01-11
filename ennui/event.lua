---@class Event
---@field public type string Event type
---@field public timestamp number Event timestamp
---@field public target Widget Widget that triggered event
---@field public currentTarget Widget Widget currently handling event
---@field public consumed boolean Whether event was consumed
---@field public stopsPropagation boolean Whether event propagation should stop
---@field public consume fun(self: Event) Method to consume the event

---@class MouseEvent : Event
---@field public x number Mouse X in screen coordinates
---@field public y number Mouse Y in screen coordinates
---@field public localX number Mouse X in widget coordinates
---@field public localY number Mouse Y in widget coordinates
---@field public button integer Mouse button
---@field public dx number? Mouse delta X (for mouseMoved, mouseWheel)
---@field public dy number? Mouse delta Y (for mouseMoved, mouseWheel)
---@field public isTouch boolean Whether this is a touch event

---@class KeyboardEvent : Event
---@field public key string Key code
---@field public scancode string Physical key scancode
---@field public isRepeat boolean Whether this is a key repeat
---@field public modifiers KeyModifiers Modifier keys held
---@field public value string? Optional value for text changes

---@class KeyModifiers
---@field public shift boolean Shift key held
---@field public ctrl boolean Control key held
---@field public alt boolean Alt key held

---@class TextInputEvent : Event
---@field public text string The text entered
---@field public value string? The full text value after input
---@field public modifiers KeyModifiers Modifier keys held

---@class FocusEvent : Event
---@field public currentTarget Widget

local Event = {}
Event.__index = Event

--- Consume the event
function Event:consume()
    self.consumed = true
    self.stopsPropagation = true
end

---@param type string Event type
---@param target Widget? Target widget
---@return Event
local function createBaseEvent(type, target)
    local event = setmetatable({
        type = type,
        timestamp = love.timer.getTime(),
        target = target,
        currentTarget = nil,
        consumed = false,
        stopsPropagation = false,
    }, Event)

    return event
end

---@param type string Event type
---@param x number Mouse X coordinate
---@param y number Mouse Y coordinate
---@param button integer? Mouse button (default 1)
---@param target Widget Target widget
---@param isTouch boolean? Whether this is a touch event (default false)
---@param dx number? Delta X (for wheel/move events)
---@param dy number? Delta Y (for wheel/move events)
---@return MouseEvent
function Event.createMouseEvent(type, x, y, button, target, isTouch, dx, dy)
    local event = createBaseEvent(type, target) ---@cast event MouseEvent
    event.x = x
    event.y = y
    event.localX = target and (x - target.x) or x
    event.localY = target and (y - target.y) or y
    event.button = button or 1
    event.dx = dx
    event.dy = dy
    event.isTouch = isTouch or false

    return event
end

---@param type string Event type
---@param key string Key code
---@param scancode string Physical key scancode
---@param isRepeat boolean Whether this is a key repeat
---@param target Widget Target widget
---@return KeyboardEvent
function Event.createKeyboardEvent(type, key, scancode, isRepeat, target)
    local event = createBaseEvent(type, target) ---@cast event KeyboardEvent
    event.key = key
    event.scancode = scancode
    event.isRepeat = isRepeat or false
    event.modifiers = {
        shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift"),
        ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl"),
        alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
    }

    return event
end

---@param text string The text entered
---@param target Widget Target widget
---@return TextInputEvent
function Event.createTextInputEvent(text, target)
    local event = createBaseEvent("textInput", target) ---@cast event TextInputEvent
    event.text = text
    event.modifiers = {
        shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift"),
        ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl"),
        alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
    }

    return event
end

---@param type string Event type ("focusGained" or "focusLost")
---@param target Widget Target widget
---@return FocusEvent
function Event.createFocusEvent(type, target)
    local event = createBaseEvent(type, target) ---@cast event FocusEvent
    event.currentTarget = target
    return event
end

return Event
