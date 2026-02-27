local EnnuiRoot = (...):sub(1, (...):len() - (".state"):len())
local Reactive = require(EnnuiRoot .. ".reactive")
local Computed = require(EnnuiRoot .. ".computed")
local Mixins = require(EnnuiRoot .. ".mixins")
local Mixin = require(EnnuiRoot .. ".utils.mixin")

local uuid = require(EnnuiRoot .. ".utils.uuid")

local function parseEnnuiRoot(EnnuiRoot)
    local segments = {}

    for segment in EnnuiRoot:gmatch("[^.]+") do
        table.insert(segments, segment)
    end

    return segments
end

local function navigateEnnuiRoot(obj, EnnuiRootSegments)
    local current = obj

    for _, segment in ipairs(EnnuiRootSegments) do
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

---@class State : StatefulMixin
---@field props table Reactive properties table
---@field private __rawProps table<string, any> Underlying raw properties table
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

    self:initStateful()

    self.__bindCache = {}

    self.props = Reactive.createProxy(self.__rawProps, {
        nested = true,
    })

    if initialProps then
        for name, value in pairs(initialProps) do
            self.props[name] = value
        end
    end

    return self
end

---Get a cached Computed binding for a property EnnuiRoot
---Supports dot-notation EnnuiRoots: state:bind("employment.jobTitle")
---@param EnnuiRoot string Property name or dot-notation EnnuiRoot
---@return Computed
function State:bind(EnnuiRoot)
    if not self.__bindCache[EnnuiRoot] then
        local segments = parseEnnuiRoot(EnnuiRoot)

        self.__bindCache[EnnuiRoot] = Computed(function()
            return navigateEnnuiRoot(self.props, segments)
        end)
    end

    return self.__bindCache[EnnuiRoot]
end

---Generate a unique ID string.
---Intended for use as the id field on data objects stored in State.
---@return string
function State.newId()
    return uuid.uuid4()
end

---Clean up all watchers and computed properties
---Call this when the state is no longer needed to prevent memory leaks
---Delegates to StatefulMixin:cleanupStateful()
function State:cleanup()
    self:cleanupStateful()
end

---Get value at a dot-notation EnnuiRoot
---@param EnnuiRoot string Dot-notation EnnuiRoot (e.g., "characters.frog.currentHp")
---@return any The value at the EnnuiRoot (reactive proxy for tables)
function State:get(EnnuiRoot)
    local segments = parseEnnuiRoot(EnnuiRoot)
    return navigateEnnuiRoot(self.props, segments)
end

---Get raw (non-reactive) value at a dot-notation EnnuiRoot (top-level only)
---Note: Nested values may still be proxies. Use getRawDeep() for fully unwrapped data.
---@param EnnuiRoot string Dot-notation EnnuiRoot
---@return any The raw underlying table (or the value itself if not a proxy)
function State:getRaw(EnnuiRoot)
    local proxy = self:get(EnnuiRoot)
    return Reactive.getRaw(proxy)
end

---Get a deep copy of raw (non-reactive) value at a dot-notation EnnuiRoot
---Returns a disconnected copy with all nested proxies unwrapped to plain Lua tables
---Useful for drag-and-drop, serialization, or any operation needing plain Lua tables
---@param EnnuiRoot string Dot-notation EnnuiRoot
---@return any The deeply unwrapped value (plain Lua tables all the way down)
function State:getRawDeep(EnnuiRoot)
    local proxy = self:get(EnnuiRoot)
    return Reactive.getRawDeep(proxy)
end

---Iterate over an array at a EnnuiRoot
---@param EnnuiRoot string Dot-notation EnnuiRoot to an array
---@return function Iterator function
function State:ipairs(EnnuiRoot)
    return self:get(EnnuiRoot):ipairs()
end

---Iterate over a table at a EnnuiRoot
---@param EnnuiRoot string Dot-notation EnnuiRoot to a table
---@return function Iterator function
function State:pairs(EnnuiRoot)
    return self:get(EnnuiRoot):pairs()
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

---Create an anonymous computed property (not cached on the state)
---@param getter function() Function that computes and returns the value
---@return Computed # The computed instance
function State:computedInline(getter)
    return Computed(getter)
end

---Create a scoped view into a nested EnnuiRoot
---@param EnnuiRoot string Dot-notation EnnuiRoot (e.g., "characters.frog")
---@return StateScope # A scoped view that acts like a State
function State:scope(EnnuiRoot)
    return StateScope.new(self, EnnuiRoot)
end

---Iterate over an array at a EnnuiRoot, calling fn for each element with a StateScope
---@param EnnuiRoot string Dot-notation EnnuiRoot to an array
---@param fn function(scope: StateScope, index: number) Function called for each element
function State:forEach(EnnuiRoot, fn)
    local raw = self:getRaw(EnnuiRoot)

    if type(raw) ~= "table" then
        return
    end

    for i = 1, #raw do
        local scopeEnnuiRoot = ("%s.%s"):format(EnnuiRoot, i)
        local scope = self:scope(scopeEnnuiRoot)

        fn(scope, i)
    end
end

---Map over an array at a EnnuiRoot, collecting results
---@param EnnuiRoot string Dot-notation EnnuiRoot to an array
---@param fn function(scope: StateScope, index: number): any Function called for each element
---@return table results Array of results from fn
function State:map(EnnuiRoot, fn)
    local results = {}
    local raw = self:getRaw(EnnuiRoot)

    if type(raw) ~= "table" then
        return results
    end

    for i = 1, #raw do
        local scopeEnnuiRoot = ("%s.%s"):format(EnnuiRoot, i)
        local scope = self:scope(scopeEnnuiRoot)

        results[i] = fn(scope, i)
    end

    return results
end

---@class StateScope
---@field private __root State The root state
---@field private __EnnuiRoot string The dot-notation EnnuiRoot
---@field props table Proxy to access scoped properties
StateScope = {}
StateScope.__index = StateScope

---Build the full EnnuiRoot from scope EnnuiRoot and relative EnnuiRoot
---@private
---@param relativeEnnuiRoot string? Relative EnnuiRoot to append
---@return string
function StateScope:__fullEnnuiRoot(relativeEnnuiRoot)
    if not relativeEnnuiRoot or relativeEnnuiRoot == "" then
        return self.__EnnuiRoot
    end
    return self.__EnnuiRoot .. "." .. relativeEnnuiRoot
end

---Create a new scoped view of a State
---@param root State The root state
---@param EnnuiRoot string Dot-notation EnnuiRoot
---@return StateScope
function StateScope.new(root, EnnuiRoot)
    local self = setmetatable({}, StateScope) ---@cast self StateScope

    self.__root = root
    self.__EnnuiRoot = EnnuiRoot

    self.props = setmetatable({}, {
        __index = function(_, key)
            local target = root:get(EnnuiRoot)
            if not target then return nil end
            return target[key]
        end,

        __newindex = function(_, key, value)
            local target = root:get(EnnuiRoot)
            if target then
                target[key] = value
            end
        end,
    })

    return self
end

---Get a cached Computed binding for a property EnnuiRoot
---Delegates to root State with full EnnuiRoot (caching happens there)
---@param EnnuiRoot string Property name or dot-notation EnnuiRoot
---@return Computed
function StateScope:bind(EnnuiRoot)
    return self.__root:bind(self:__fullEnnuiRoot(EnnuiRoot))
end

---Get value at a relative EnnuiRoot
---@param EnnuiRoot string Property name or relative dot-notation EnnuiRoot
---@return any The value at the EnnuiRoot
function StateScope:get(EnnuiRoot)
    return self.__root:get(self:__fullEnnuiRoot(EnnuiRoot))
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
    return self.__root:computed(self.__EnnuiRoot .. "_" .. name, getter)
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

---Create an anonymous computed property (not cached on the state)
---@param getter function() Function that computes and returns the value
---@return Computed # The computed instance
function StateScope:computedInline(getter)
    return Computed(getter)
end

---Create a nested scoped view (relative to current scope)
---@param EnnuiRoot string Dot-notation EnnuiRoot relative to current scope
---@return StateScope A new scoped view
function StateScope:scope(EnnuiRoot)
    return StateScope.new(self.__root, self:__fullEnnuiRoot(EnnuiRoot))
end

---Get raw (non-reactive) value at a relative EnnuiRoot (top-level only)
---Note: Nested values may still be proxies. Use getRawDeep() for fully unwrapped data.
---@param EnnuiRoot string Property name or relative dot-notation EnnuiRoot
---@return any The raw underlying table (or the value itself if not a proxy)
function StateScope:getRaw(EnnuiRoot)
    return self.__root:getRaw(self:__fullEnnuiRoot(EnnuiRoot))
end

---Get a deep copy of raw (non-reactive) value at a relative EnnuiRoot
---Returns a disconnected copy with all nested proxies unwrapped to plain Lua tables
---@param EnnuiRoot string Property name or relative dot-notation EnnuiRoot
---@return any The deeply unwrapped value (plain Lua tables all the way down)
function StateScope:getRawDeep(EnnuiRoot)
    return self.__root:getRawDeep(self:__fullEnnuiRoot(EnnuiRoot))
end

---Iterate over an array at a relative EnnuiRoot
---@param EnnuiRoot string Dot-notation EnnuiRoot relative to current scope
---@return function Iterator function
function StateScope:ipairs(EnnuiRoot)
    return self:get(EnnuiRoot):ipairs()
end

---Iterate over a table at a relative EnnuiRoot
---@param EnnuiRoot string Dot-notation EnnuiRoot relative to current scope
---@return function Iterator function
function StateScope:pairs(EnnuiRoot)
    return self:get(EnnuiRoot):pairs()
end

---Iterate over an array at a relative EnnuiRoot, calling fn for each element with a StateScope
---@param EnnuiRoot string Dot-notation EnnuiRoot relative to current scope
---@param fn function(scope: StateScope, index: number) Function called for each element
function StateScope:forEach(EnnuiRoot, fn)
    self.__root:forEach(self:__fullEnnuiRoot(EnnuiRoot), fn)
end

---Map over an array at a relative EnnuiRoot, collecting results
---@param EnnuiRoot string Dot-notation EnnuiRoot relative to current scope
---@param fn function(scope: StateScope, index: number): any Function called for each element
---@return table results Array of results from fn
function StateScope:map(EnnuiRoot, fn)
    return self.__root:map(self:__fullEnnuiRoot(EnnuiRoot), fn)
end

return State
