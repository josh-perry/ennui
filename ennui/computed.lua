local Reactive = require("ennui.reactive")

---@class Computed
---@field getter function The function that computes the value
---@field value any The cached computed value
---@field dirty boolean Whether the cached value is stale
---@field dependencies table<Dependency, boolean> Properties this computed depends on
---@field subscribers function[] Callbacks invoked when value changes
local Computed = {}
Computed.__index = Computed
setmetatable(Computed, {
    __call = function(class, content)
        return class.new(content)
    end
})

---Create a new computed property
---@param getter function() The getter function that computes and returns the value
---@return Computed
function Computed.new(getter)
    local self = setmetatable({
        getter = getter,
        value = nil,
        dirty = true,
        dependencies = {},
        subscribers = {},
    }, Computed)

    return self
end

---Get the computed value (evaluates if dirty)
---Lazy evaluation - only recomputes when dependencies change
---@return any The computed value
function Computed:get()
    if self.dirty then
        self:evaluate()
    end

    return self.value
end

---Evaluate the getter and collect dependencies
---Internal function - called when dirty flag is set
function Computed:evaluate()
    -- Clear old dependencies
    for dep in pairs(self.dependencies) do
        dep.subscribers[self] = nil
    end

    self.dependencies = {}

    -- Collect new dependencies while running the getter
    Reactive.pushDep(self)
    self.value = self.getter()
    Reactive.popDep()

    self.dirty = false
end

---Called by a dependency when it changes
---Marks this computed as dirty so it will recalculate on next access
function Computed:update()
    self.dirty = true
    for _, callback in ipairs(self.subscribers) do
        callback()
    end
end

---Subscribe to updates when this computed's value changes
---@param callback function Callback to invoke when value changes
function Computed:subscribe(callback)
    table.insert(self.subscribers, callback)
end

return Computed
