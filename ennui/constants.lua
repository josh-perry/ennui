---@class Alignment
---@field LEFT string
---@field CENTER string
---@field RIGHT string
---@field STRETCH string
---@field TOP string
---@field BOTTOM string
local Alignment = {
    -- Horizontal
    LEFT = "left",
    CENTER = "center",
    RIGHT = "right",
    STRETCH = "stretch",

    -- Vertical
    TOP = "top",
    BOTTOM = "bottom",
}

---@class EventType
---@field MOUSE_PRESSED string
---@field MOUSE_RELEASED string
---@field MOUSE_MOVED string
---@field MOUSE_ENTERED string
---@field MOUSE_EXITED string
---@field MOUSE_WHEEL string
---@field CLICKED string
---@field KEY_PRESSED string
---@field KEY_RELEASED string
---@field FOCUS_GAINED string
---@field FOCUS_LOST string
---@field TEXT_INPUT string
local EventType = {
    -- Mouse
    MOUSE_PRESSED = "mousePressed",
    MOUSE_RELEASED = "mouseReleased",
    MOUSE_MOVED = "mouseMoved",
    MOUSE_ENTERED = "mouseEntered",
    MOUSE_EXITED = "mouseExited",
    MOUSE_WHEEL = "mouseWheel",
    CLICKED = "clicked",

    -- Keyboard
    KEY_PRESSED = "keyPressed",
    KEY_RELEASED = "keyReleased",

    -- Focus
    FOCUS_GAINED = "focusGained",
    FOCUS_LOST = "focusLost",

    -- Text
    TEXT_INPUT = "textInput",
}

return {
    Alignment = Alignment,
    EventType = EventType,
}
