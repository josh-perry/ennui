local Reactive = require("ennui.reactive")
local Computed = require("ennui.computed")
local Mixins = require("ennui.mixins")
local Mixin = require("ennui.utils.mixin")

local function parsePath(path)
    local segments = {}

    for segment in path:gmatch("[^.]+") do
        table.insert(segments, segment)
    end

    return segments
end

local function navigatePath(obj, pathSegments)
    local current = obj

    for _, segment in ipairs(pathSegments) do
        if not current then
            return nil
        end

        local numericKey = tonumber(segment)

        if numericKey then
            current = current[numericKey]
        else
            current = current[segment]
        end
    end

    return current
end

local StateScope

-- Map from proxy to its underlying raw table
local proxyToRaw = setmetatable({}, {__mode = "k"})

---@class StateDependency
---@field subscribers table<any, boolean> Set of watchers/computed that depend on this property
local StateDependency = {}
StateDependency.__index = StateDependency

function StateDependency.new()
    return setmetatable({ subscribers = {} }, StateDependency)
end

function StateDependency:depend(subscriber)
    if subscriber then
        self.subscribers[subscriber] = true

        if subscriber.dependencies then
            subscriber.dependencies[self] = true
        end
    end
end

function StateDependency:notify(forceUpdate)
    for subscriber in pairs(self.subscribers) do
        if subscriber and subscriber.update then
            if forceUpdate and subscriber.forceUpdate then
                subscriber:forceUpdate()
            else
                subscriber:update()
            end
        end
    end
end

---@class State : StatefulMixin
---@field props table Reactive properties table
---@field private __rawProps table<string, any> Underlying raw properties table (contains proxies for nested tables)
---@field private __dependencies table<string, StateDependency> Dependencies for each property
---@field private __nestedProps table<string, boolean> Set of property names that are nested/reactive tables
---@field private __watchers Watcher[] Active watchers
---@field private __computed table<string, Computed> Computed properties
---@field private __bindCache table<string, Computed> Cached Computed bindings
local State = {}
State.__index = State
setmetatable(State, {
    __call = function(class, ...)
        return class.new(...)
    end
})

Mixin.extend(State, Mixins.Stateful)

---Create a new State container
---@param initialProps table? Optional initial properties
---@return State
function State.new(initialProps)
    local self = setmetatable({}, State)

    -- Initialize StatefulMixin fields (__rawProps, __watchers, __computed)
    self:initStateful()

    -- State-specific fields
    self.__dependencies = {}
    self.__nestedProps = {}
    self.__bindCache = {}

    self.props = self:__createProxy()

    if initialProps then
        for name, value in pairs(initialProps) do
            if type(value) == "table" then
                self.__rawProps[name] = self:__makeNestedReactive(value, name)
                self.__nestedProps[name] = true
            else
                self.__rawProps[name] = value
            end
        end
    end

    return self
end

---Get or create a dependency for a property
---@private
---@param key string Property name
---@return StateDependency
function State:__getDependency(key)
    if not self.__dependencies[key] then
        self.__dependencies[key] = StateDependency.new()
    end
    return self.__dependencies[key]
end

---Notify subscribers of a property change
---@private
---@param key string Property name
function State:__notifyProperty(key)
    local forceUpdate = self.__nestedProps[key] or false
    self:__getDependency(key):notify(forceUpdate)
end

---Create the reactive proxy for props
---@private
---@return table
function State:__createProxy()
    local proxy = setmetatable({}, {
        __index = function(_, key)
            local collector = Reactive.getCurrentDep()
            if collector then
                self:__getDependency(key):depend(collector)
            end
            return self.__rawProps[key]
        end,

        __newindex = function(_, key, value)
            local oldValue = self.__rawProps[key]
            if value ~= oldValue then
                self.__rawProps[key] = value
                self:__notifyProperty(key)
            else
                self.__rawProps[key] = value
            end
        end,

        __pairs = function(_)
            return pairs(self.__rawProps)
        end,

        __len = function(_)
            return #self.__rawProps
        end,
    })

    return proxy
end

---Get a cached Computed binding for a property path
---Supports dot-notation paths: state:bind("employment.jobTitle")
---@param path string Property name or dot-notation path
---@return Computed
function State:bind(path)
    if not self.__bindCache[path] then
        local segments = parsePath(path)

        self.__bindCache[path] = Computed(function()
            return navigatePath(self.props, segments)
        end)
    end

    return self.__bindCache[path]
end

---Create a reactive nested table that notifies the parent property when changed
---Recursively wraps nested tables for deep reactivity
---@private
---@param rawTable table The raw nested table
---@param parentKey string The parent property key (top-level key for dependency tracking)
---@return table proxy The reactive proxy for the nested table
function State:__makeNestedReactive(rawTable, parentKey)
    -- Recursively wrap nested tables first
    for key, value in pairs(rawTable) do
        if type(value) == "table" then
            rawTable[key] = self:__makeNestedReactive(value, parentKey)
        end
    end

    local proxy = setmetatable({}, {
        __index = function(_, key)
            local collector = Reactive.getCurrentDep()
            if collector then
                self:__getDependency(parentKey):depend(collector)
            end
            return rawTable[key]
        end,

        __newindex = function(_, key, value)
            local oldValue = rawTable[key]
            -- Wrap new table values in reactive proxy
            if type(value) == "table" then
                value = self:__makeNestedReactive(value, parentKey)
            end
            if value ~= oldValue then
                rawTable[key] = value
                self:__notifyProperty(parentKey)
            else
                rawTable[key] = value
            end
        end,

        __pairs = function(_)
            return pairs(rawTable)
        end,

        __len = function(_)
            return #rawTable
        end,
    })

    -- Store mapping so getRaw can retrieve the underlying table
    proxyToRaw[proxy] = rawTable

    return proxy
end

---Hook to transform property values before storing (implements StatefulMixin hook)
---Tables are wrapped in nested reactivity
---@param name string Property name
---@param value any Initial value
---@return any transformedValue The value to store (potentially wrapped)
function State:__beforeAddTransformPropertyValue(name, value)
    if type(value) == "table" then
        self.__nestedProps[name] = true
        return self:__makeNestedReactive(value, name)
    end
    return value
end

---Clean up all watchers and computed properties
---Call this when the state is no longer needed to prevent memory leaks
---Delegates to StatefulMixin:cleanupStateful()
function State:cleanup()
    self:cleanupStateful()
end

---Get value at a dot-notation path
---@param path string Dot-notation path (e.g., "characters.frog.currentHp")
---@return any The value at the path (reactive proxy for tables)
function State:get(path)
    local segments = parsePath(path)
    return navigatePath(self.props, segments)
end

---Get raw (non-reactive) value at a dot-notation path
---Useful for iteration with pairs/ipairs since reactive proxies don't work with them in LuaJIT
---@param path string Dot-notation path
---@return any The raw underlying table (or the value itself if not a proxy)
function State:getRaw(path)
    local proxy = self:get(path)

    if type(proxy) == "table" then
        return proxyToRaw[proxy] or proxy
    end

    return proxy
end

---Iterate over an array at a path
---@param path string Dot-notation path to an array
---@return function Iterator function
function State:ipairs(path)
    local proxy = self:get(path)
    local i = 0

    return function()
        i = i + 1

        local v = proxy[i]

        if v ~= nil then
            return i, v
        end
    end
end

---Iterate over a table at a path
---@param path string Dot-notation path to a table
---@return function Iterator function
function State:pairs(path)
    local proxy = self:get(path)
    local mt = getmetatable(proxy)

    if mt and mt.__pairs then
        return mt.__pairs(proxy)
    end

    return pairs(proxy)
end

---Create a computed that interpolates {property} placeholders in a template
---@param template string Template string with {propName} placeholders
---@return Computed The computed instance
function State:format(template)
    local selfReference = self

    return Computed(function()
        return (template:gsub("{([^}]+)}", function(propName)
            local value = selfReference.props[propName]

            if value ~= nil then
                return tostring(value)
            end

            return "{" .. propName .. "}"
        end))
    end)
end

---Create a scoped view into a nested path
---@param path string Dot-notation path (e.g., "characters.frog")
---@return StateScope A scoped view that acts like a State
function State:scope(path)
    return StateScope.new(self, path)
end

---Iterate over an array at a path, calling fn for each element with a StateScope
---@param path string Dot-notation path to an array
---@param fn function(scope: StateScope, index: number) Function called for each element
function State:forEach(path, fn)
    local raw = self:getRaw(path)

    if type(raw) ~= "table" then
        return
    end

    for i = 1, #raw do
        local scopePath = ("%s.%s"):format(path, i)
        local scope = self:scope(scopePath)

        fn(scope, i)
    end
end

---Map over an array at a path, collecting results
---@param path string Dot-notation path to an array
---@param fn function(scope: StateScope, index: number): any Function called for each element
---@return table results Array of results from fn
function State:map(path, fn)
    local results = {}
    local raw = self:getRaw(path)

    if type(raw) ~= "table" then
        return results
    end

    for i = 1, #raw do
        local scopePath = ("%s.%s"):format(path, i)
        local scope = self:scope(scopePath)

        results[i] = fn(scope, i)
    end

    return results
end

---@class StateScope
---@field private __root State The root state
---@field private __path string The dot-notation path
---@field props table Proxy to access scoped properties
StateScope = {}
StateScope.__index = StateScope

---Build the full path from scope path and relative path
---@private
---@param relativePath string? Relative path to append
---@return string
function StateScope:__fullPath(relativePath)
    if not relativePath or relativePath == "" then
        return self.__path
    end
    return self.__path .. "." .. relativePath
end

---Create a new scoped view of a State
---@param root State The root state
---@param path string Dot-notation path
---@return StateScope
function StateScope.new(root, path)
    local self = setmetatable({}, StateScope) ---@cast self StateScope

    self.__root = root
    self.__path = path

    -- Create a proxy that delegates to root with path prefix
    self.props = setmetatable({}, {
        __index = function(_, key)
            local target = root:get(path)
            if not target then return nil end
            return target[key]
        end,

        __newindex = function(_, key, value)
            local target = root:get(path)
            if target then
                target[key] = value
            end
        end,

        __pairs = function(_)
            local target = root:get(path)
            if target then return pairs(target) end
            return pairs({})
        end,
    })

    return self
end

---Get a cached Computed binding for a property path
---Delegates to root State with full path (caching happens there)
---@param path string Property name or dot-notation path
---@return Computed
function StateScope:bind(path)
    return self.__root:bind(self:__fullPath(path))
end

---Get value at a relative path
---@param path string Property name or relative dot-notation path
---@return any The value at the path
function StateScope:get(path)
    return self.__root:get(self:__fullPath(path))
end

---Watch a property for changes (relative to scope)
---@param source string|function Property name or getter function
---@param callback function(newValue, oldValue) Callback when value changes
---@param options {immediate: boolean?, deep: boolean?}? Watcher options
---@return Watcher The watcher instance
function StateScope:watch(source, callback, options)
    if type(source) == "string" then
        local self_ref = self
        local propName = source
        source = function()
            return self_ref.props[propName]
        end
    end
    return self.__root:watch(source, callback, options)
end

---Create a computed property (relative to scope)
---@param name string Name of the computed property
---@param getter function() Function that computes and returns the value
---@return Computed The computed instance
function StateScope:computed(name, getter)
    return self.__root:computed(self.__path .. "_" .. name, getter)
end

---Create a computed that interpolates {property} placeholders (relative to scope)
---@param template string Template string with {propName} placeholders
---@return Computed The computed instance
function StateScope:format(template)
    local self_ref = self
    return Computed(function()
        return (template:gsub("{([^}]+)}", function(propName)
            local value = self_ref.props[propName]
            if value ~= nil then
                return tostring(value)
            end
            return "{" .. propName .. "}"
        end))
    end)
end

function StateScope:computedInline(getter)
    return Computed(getter)
end

---Create a nested scoped view (relative to current scope)
---@param path string Dot-notation path relative to current scope
---@return StateScope A new scoped view
function StateScope:scope(path)
    return StateScope.new(self.__root, self:__fullPath(path))
end

---Get raw (non-reactive) value at a relative path
---@param path string Property name or relative dot-notation path
---@return any The raw underlying table (or the value itself if not a proxy)
function StateScope:getRaw(path)
    return self.__root:getRaw(self:__fullPath(path))
end

---Iterate over an array at a relative path, calling fn for each element with a StateScope
---@param path string Dot-notation path relative to current scope
---@param fn function(scope: StateScope, index: number) Function called for each element
function StateScope:forEach(path, fn)
    self.__root:forEach(self:__fullPath(path), fn)
end

---Map over an array at a relative path, collecting results
---@param path string Dot-notation path relative to current scope
---@param fn function(scope: StateScope, index: number): any Function called for each element
---@return table results Array of results from fn
function StateScope:map(path, fn)
    return self.__root:map(self:__fullPath(path), fn)
end

return State
