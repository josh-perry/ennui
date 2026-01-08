---Watcher system for explicit reactions to property changes
---Similar to Vue's watch() - allows running callbacks when properties change

local Reactive = require("yui.reactive")

---@class Watcher
---@field widget Widget The widget this watcher is attached to
---@field getter function The getter function that returns the watched value
---@field callback function The callback to run when value changes
---@field immediate boolean Whether to run immediately on creation
---@field deep boolean Whether to deeply watch objects (not yet implemented)
---@field oldValue any The previous value (for computing old -> new)
---@field dependencies table<Dependency, boolean> Dependencies this watcher depends on
local Watcher = {}
Watcher.__index = Watcher
setmetatable(Watcher, {
    __call = function(class, ...)
        return class.new(...)
    end
})

---Create a new watcher
---@param widget Widget The widget this watcher is attached to
---@param source string|function Property name or getter function
---@param callback function(newValue, oldValue) Callback when value changes
---@param options {immediate: boolean?, deep: boolean?}? Watcher options
---@return Watcher
function Watcher.new(widget, source, callback, options)
    options = options or {}

    local self = setmetatable({
        widget = widget,
        callback = callback,
        immediate = options.immediate or false,
        deep = options.deep or false,
        oldValue = nil,
        dependencies = {},
    }, Watcher)

    if type(source) == "string" then
        local propName = source
        self.getter = function()
            return widget.props[propName]
        end
    else
        self.getter = source
    end

    if self.immediate then
        self:update()
    else
        self:evaluate()
    end

    return self
end

---Evaluate the getter and collect dependencies
---@return any The current value from the getter
function Watcher:evaluate()
    for dependency in pairs(self.dependencies) do
        dependency.subscribers[self] = nil
    end

    self.dependencies = {}

    Reactive.pushDep(self)
    local value = self.getter()
    Reactive.popDep()

    return value
end

---Called by a dependency when it changes
---Reevaluates the getter and calls the callback if value changed
function Watcher:update()
    local newValue = self:evaluate()
    local oldValue = self.oldValue

    if newValue ~= oldValue then
        self.oldValue = newValue
        self.callback(newValue, oldValue)
    else
        self.oldValue = newValue
    end
end

---Unwatch - remove this watcher and clean up dependencies
function Watcher:unwatch()
    for dep in pairs(self.dependencies) do
        dep.subscribers[self] = nil
    end
    self.dependencies = {}
end

return Watcher
