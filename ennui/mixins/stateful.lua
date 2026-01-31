---Mixin for reactive property management
---Optional hooks:
---  - __beforeAddTransformPropertyValue(name, value) - transform value before storing
---  - __afterAddProperty(name, value) - called after property is added

local Watcher = require("ennui.watcher")
local Computed = require("ennui.computed")

---@class StatefulMixin
---@field __rawProps table<string, any> Underlying property storage
---@field __watchers Watcher[] Active watchers
---@field __computed table<string, Computed> Computed properties
---@field props table Reactive proxy (created by consumer)
local StatefulMixin = {}

---Initialize stateful fields on an instance
---Call this from the constructor of classes using this mixin
---@param self table The instance to initialize
function StatefulMixin.initStateful(self)
    self.__rawProps = self.__rawProps or {}
    self.__watchers = {}
    self.__computed = {}
end

---Add a property to the reactive state
---Calls optional hooks: __beforeAddTransformPropertyValue, __afterAddProperty
---@param name string Property name
---@param initialValue any Initial value for the property
---@return self
function StatefulMixin:addProperty(name, initialValue)
    ---@diagnostic disable-next-line: undefined-field
    if self.__beforeAddTransformPropertyValue then
        ---@diagnostic disable-next-line: undefined-field
        initialValue = self:__beforeAddTransformPropertyValue(name, initialValue)
    end

    self.__rawProps[name] = initialValue

    ---@diagnostic disable-next-line: undefined-field
    if self.__afterAddProperty then
        ---@diagnostic disable-next-line: undefined-field
        self:__afterAddProperty(name, initialValue)
    end

    return self
end

---Watch a property for changes
---Calls callback when the watched property changes
---@param source string|function Property name (string) or getter function
---@param callback function(newValue, oldValue) Callback when value changes
---@param options {immediate: boolean?, deep: boolean?}? Watcher options
---@return Watcher The watcher instance (can be passed to unwatch)
function StatefulMixin:watch(source, callback, options)
    local watcher = Watcher(self, source, callback, options)
    table.insert(self.__watchers, watcher)

    return watcher
end

---Remove a specific watcher
---@param watcher Watcher The watcher to remove
function StatefulMixin:unwatch(watcher)
    watcher:unwatch()

    for i, w in ipairs(self.__watchers) do
        if w == watcher then
            table.remove(self.__watchers, i)
            break
        end
    end
end

---Create a computed property
---Computed properties automatically track dependencies and update lazily
---@param name string Name of the computed property
---@param getter function() Function that computes and returns the value
---@return Computed # The computed instance (access value with :get())
function StatefulMixin:computed(name, getter)
    local computed = Computed(getter)
    self.__computed[name] = computed
    return computed
end

---Get a computed property by name
---@param name string Name of the computed property
---@return Computed? # The computed instance, or nil if not found
function StatefulMixin:getComputed(name)
    return self.__computed[name]
end

---Clean up all watchers and computed properties
function StatefulMixin:cleanupStateful()
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

return StatefulMixin
