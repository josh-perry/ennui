---Lightweight reactive state container with property watching/binding
---Similar to a Widget's reactive props, but without the widget overhead
---State objects are source-only - widgets bind FROM them via widget:bindFrom(state, {...})

local Reactive = require("ennui.reactive")
local Watcher = require("ennui.watcher")
local Computed = require("ennui.computed")

-- Path parsing helpers
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

---@class State
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

---Create a new State container
---@param initialProps table? Optional initial properties
---@return State
function State.new(initialProps)
    local self = setmetatable({}, State)

    self.__rawProps = {}
    self.__dependencies = {}
    self.__nestedProps = {}
    self.__watchers = {}
    self.__computed = {}
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

---Add a property to the state
---Tables are automatically made nested-reactive
---@param name string Property name
---@param initialValue any Initial value for the property
---@return State self
function State:addProperty(name, initialValue)
    if type(initialValue) == "table" then
        self.__rawProps[name] = self:__makeNestedReactive(initialValue, name)
        self.__nestedProps[name] = true
    else
        self.__rawProps[name] = initialValue
    end
    return self
end

---Watch a property for changes
---Calls callback when the watched property changes
---@param source string|function Property name (string) or getter function
---@param callback function(newValue, oldValue) Callback when value changes
---@param options {immediate: boolean?, deep: boolean?}? Watcher options
---@return Watcher The watcher instance (can be passed to unwatch)
function State:watch(source, callback, options)
    local watcher = Watcher(self, source, callback, options)
    table.insert(self.__watchers, watcher)
    return watcher
end

---Remove a specific watcher
---@param watcher Watcher The watcher to remove
function State:unwatch(watcher)
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
---@return Computed The computed instance (access value with :get())
function State:computed(name, getter)
    local computed = Computed(getter)
    self.__computed[name] = computed
    return computed
end

---Get a computed property by name
---@param name string Name of the computed property
---@return Computed? The computed instance, or nil if not found
function State:getComputed(name)
    return self.__computed[name]
end

---Clean up all watchers and computed properties
---Call this when the state is no longer needed to prevent memory leaks
function State:cleanup()
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

    local k, _ = pairs(proxy)
    return k
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

---@class StateScope
---@field private __root State The root state
---@field private __path string The dot-notation path
---@field protected __pathSegments string[] Parsed path segments
---@field props table Proxy to access scoped properties
---@field private __bindCache table<string, Computed> Cached Computed bindings
StateScope = {}
StateScope.__index = StateScope

---Create a new scoped view of a State
---@param root State The root state
---@param path string Dot-notation path
---@return StateScope
function StateScope.new(root, path)
    local self = setmetatable({}, StateScope) ---@cast self StateScope

    self.__root = root
    self.__path = path
    self.__pathSegments = parsePath(path)

    -- Create a proxy that navigates the path
    self.props = setmetatable({}, {
        __index = function(_, key)
            ---@diagnostic disable-next-line: invisible
            local target = navigatePath(root.props, self.__pathSegments)

            if not target then
                return nil
            end

            return target[key] or nil
        end,

        __newindex = function(_, key, value)
            ---@diagnostic disable-next-line: invisible
            local target = navigatePath(root.props, self.__pathSegments)

            if target then
                target[key] = value
            end
        end,

        __pairs = function(_)
            ---@diagnostic disable-next-line: invisible
            local target = navigatePath(root.props, self.__pathSegments)

            if target then
                return pairs(target)
            end

            return pairs({})
        end,
    })

    self.__bindCache = {}

    return self
end

---Get a cached Computed binding for a property path
---Supports dot-notation paths: scope:bind("stats.level")
---@param path string Property name or dot-notation path
---@return Computed
function StateScope:bind(path)
    if not self.__bindCache[path] then
        local segments = parsePath(path)

        self.__bindCache[path] = Computed(function()
            return navigatePath(self.props, segments)
        end)
    end

    return self.__bindCache[path]
end

---Get value at a relative path (or direct property name)
---@param path string Property name or relative dot-notation path
---@return any The value at the path
function StateScope:get(path)
    local segments = parsePath(path)
    return navigatePath(self.props, segments)
end

---Watch a property for changes (relative to scope)
---@param source string|function Property name or getter function
---@param callback function(newValue, oldValue) Callback when value changes
---@param options {immediate: boolean?, deep: boolean?}? Watcher options
---@return Watcher The watcher instance
function StateScope:watch(source, callback, options)
    local getter
    if type(source) == "string" then
        local propName = source
        local self_ref = self
        getter = function()
            return self_ref.props[propName]
        end
    else
        getter = source
    end

    return self.__root:watch(getter, callback, options)
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
    local fullPath = self.__path .. "." .. path
    return StateScope.new(self.__root, fullPath)
end

return State
