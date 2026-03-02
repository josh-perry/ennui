---Reactive property system using proxy tables
---Enables automatic change detection and dependency tracking for computed properties and watchers

---@class ProxyOptions
---@field onGet function? Called when property is accessed: onGet(key)
---@field onSet function? Called when property changes: onSet(key, newValue, oldValue)
---@field nested boolean? If true, automatically wrap table values in nested proxies
---@field nestedNotify function? Called when nested property changes: nestedNotify(forceUpdate)

---@class Dependency
---@field subscribers table<any, boolean> Set of watchers/computed that depend on this property
local Dependency = {}
Dependency.__index = Dependency
setmetatable(Dependency, {
    __call = function(class, ...)
        return class.new(...)
    end
})

function Dependency.new()
    return setmetatable({
        subscribers = {},
    }, Dependency)
end

---Register a subscriber (watcher or computed) that depends on this property
---@param subscriber any Watcher or Computed instance
function Dependency:depend(subscriber)
    if subscriber then
        self.subscribers[subscriber] = true

        if subscriber.dependencies then
            subscriber.dependencies[self] = true
        end
    end
end

---Notify all subscribers that this property changed
---@param forceUpdate boolean? If true, call forceUpdate instead of update on subscribers
function Dependency:notify(forceUpdate)
    for subscriber in pairs(self.subscribers) do
        if subscriber then
            if forceUpdate and subscriber.forceUpdate then
                subscriber:forceUpdate()
            elseif subscriber.update then
                subscriber:update()
            end
        end
    end
end

local currentDependencyCollector = nil
local dependencyStack = {}

local proxyToRaw = setmetatable({}, { __mode = "k" })

---@class ProxyInternals
---@field raw table Raw underlying table
---@field getDep fun(key: any): Dependency Dependency getter scoped to the owning createProxy call
---@field isNested boolean Whether this proxy wraps a nested table (not the top-level rawTable)
---@field parentKey any? For nested proxies: the parent key whose dependency to notify on change
---@field onGet (fun(key: any))? Top-level only: called on property access
---@field onSet (fun(key: any, newValue: any, oldValue: any))? Top-level only: called on property change
---@field nestedNotify (fun(forceUpdate: boolean))? Nested only: extra callback on nested change
---@field makeNested (fun(t: table, key: any): ReactiveProxy)? Wraps plain tables in nested proxies; nil if not needed

---@type table<ReactiveProxy, ProxyInternals>
local proxyInternals = setmetatable({}, { __mode = "k" })

---The normal pairs/ipairs bypass __index, so they see empty proxies and lose dependency tracking.
---So we need to do it ourselves.
---@class ReactiveProxy
local ReactiveProxy = {}

ReactiveProxy.__index = function(self, key)
    local method = rawget(ReactiveProxy, key)
    if method ~= nil then return method end

    local internal = proxyInternals[self]
    local collector = currentDependencyCollector

    if collector then
        internal.getDep(internal.isNested and internal.parentKey or key):depend(collector)
    end

    if internal.onGet then internal.onGet(key) end
    return internal.raw[key]
end

ReactiveProxy.__newindex = function(self, key, value)
    assert(rawget(ReactiveProxy, key) == nil, ("'%s' is a proxy method and cannot be used as a data key"):format(key))

    local internal = proxyInternals[self]
    local raw = internal.raw
    local oldValue = raw[key]

    if type(value) == "table" and proxyInternals[value] == nil and internal.makeNested then
        value = internal.makeNested(value, internal.isNested and internal.parentKey or key)
    end

    if value ~= oldValue then
        raw[key] = value
        if internal.isNested then
            internal.getDep(internal.parentKey):notify(true)
            if internal.nestedNotify then internal.nestedNotify(true) end
        else
            if internal.onSet then internal.onSet(key, value, oldValue) end
            internal.getDep(key):notify(type(value) == "table" or type(oldValue) == "table")
        end
    else
        raw[key] = value
    end
end

---Iterate over the proxy as an array, tracking dependencies
---@return fun(): integer?, any?
function ReactiveProxy:ipairs()
    local i = 0

    return function()
        i = i + 1

        local v = self[i]

        -- cant use # here!
        if v ~= nil then
            return i, v
        end
    end
end

---Iterate over all keys in the proxy, tracking dependencies per value
---@return fun(): any, any
function ReactiveProxy:pairs()
    local proxy = self
    local raw = proxyInternals[self].raw
    local key = nil

    return function()
        key = next(raw, key)

        if key ~= nil then
            return key, proxy[key]
        end
    end
end

---Count the number of elements in an array-like proxy.
---Needed because # in Luajit doesn't trigger __len and we can't just count the underlying raw table
---@return number # The number of elements
function ReactiveProxy:len()
    -- Bad
    local i = 0

    for _, _ in self:ipairs() do
        i = i + 1
    end

    return i
end

---@class Reactive
local Reactive = {}

---Push a dependency collector onto the stack
---@param collector any Watcher or Computed instance
function Reactive.pushDep(collector)
    table.insert(dependencyStack, currentDependencyCollector)
    currentDependencyCollector = collector
end

---Pop the dependency collector from the stack
function Reactive.popDep()
    currentDependencyCollector = table.remove(dependencyStack)
end

---Get the current dependency collector
---@return any? collector
function Reactive.getCurrentDep()
    return currentDependencyCollector
end

---Get the raw underlying table from a proxy (top-level only)
---Note: Nested values may still be proxies. Use getRawDeep() for fully unwrapped data.
---@param proxy table The reactive proxy
---@return table The raw underlying table (or the proxy itself if not found)
function Reactive.getRaw(proxy)
    if type(proxy) == "table" then
        return proxyToRaw[proxy] or proxy
    end

    return proxy
end

---Get a deep copy of the raw underlying data with all nested proxies unwrapped
---Returns a disconnected copy - modifications won't affect the original state
---@param proxy any The reactive proxy (or any value)
---@return any The deeply unwrapped value (plain Lua tables all the way down)
function Reactive.getRawDeep(proxy)
    if type(proxy) ~= "table" then
        return proxy
    end

    local raw = proxyToRaw[proxy] or proxy
    local result = {}

    for key, value in pairs(raw) do
        result[key] = Reactive.getRawDeep(value)
    end

    return result
end

---Check if a table is a reactive proxy
---@param t table The table to check
---@return boolean
function Reactive.isProxy(t)
    return type(t) == "table" and proxyToRaw[t] ~= nil
end

---Create a reactive proxy table
---Properties accessed through the proxy are tracked as dependencies
---Properties set through the proxy trigger change detection
---@param rawTable table The underlying data table
---@param options ProxyOptions? Proxy configuration options
---@return ReactiveProxy
function Reactive.createProxy(rawTable, options)
    options = options or {}

    ---@type table<string, Dependency>
    local dependencies = {}

    ---Get or create a dependency for a given key
    ---@param key string
    ---@return Dependency
    local function getDependency(key)
        if not dependencies[key] then
            dependencies[key] = Dependency()
        end

        return dependencies[key]
    end

    ---Create a nested proxy for table values
    ---@param nestedTable table
    ---@param parentKey string
    ---@return ReactiveProxy
    local function makeNestedProxy(nestedTable, parentKey)
        for key, value in pairs(nestedTable) do
            if type(value) == "table" and not Reactive.isProxy(value) then
                nestedTable[key] = makeNestedProxy(value, parentKey)
            end
        end

        local nestedProxy = setmetatable({}, ReactiveProxy)
        proxyToRaw[nestedProxy] = nestedTable
        proxyInternals[nestedProxy] = {
            raw = nestedTable,
            getDep = getDependency,
            isNested = true,
            parentKey = parentKey,
            nestedNotify = options.nestedNotify,
            makeNested = makeNestedProxy,
        }

        return nestedProxy
    end

    if options.nested then
        for key, value in pairs(rawTable) do
            if type(value) == "table" and not Reactive.isProxy(value) then
                rawTable[key] = makeNestedProxy(value, key)
            end
        end
    end

    local proxy = setmetatable({}, ReactiveProxy) ---@cast proxy ReactiveProxy
    proxyToRaw[proxy] = rawTable
    proxyInternals[proxy] = {
        raw = rawTable,
        getDep = getDependency,
        isNested = false,
        onGet = options.onGet,
        onSet = options.onSet,
        makeNested = options.nested and makeNestedProxy or nil,
    }

    return proxy
end

return Reactive
