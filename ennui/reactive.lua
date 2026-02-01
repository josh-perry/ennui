---Reactive property system using Lua proxy tables
---Enables automatic change detection and dependency tracking for computed properties and watchers

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

---@class Reactive
local Reactive = {}

local currentDependencyCollector = nil
local dependencyStack = {}

local proxyToRaw = setmetatable({}, { __mode = "k" })

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

---Get the raw underlying table from a proxy
---Useful for iteration with pairs/ipairs since reactive proxies don't work here
---@param proxy table The reactive proxy
---@return table The raw underlying table (or the proxy itself if not found)
function Reactive.getRaw(proxy)
    if type(proxy) == "table" then
        return proxyToRaw[proxy] or proxy
    end

    return proxy
end

---Check if a table is a reactive proxy
---@param t table The table to check
---@return boolean
function Reactive.isProxy(t)
    return type(t) == "table" and proxyToRaw[t] ~= nil
end

---@class ProxyOptions
---@field onGet function? Called when property is accessed: onGet(key)
---@field onSet function? Called when property changes: onSet(key, newValue, oldValue)
---@field nested boolean? If true, automatically wrap table values in nested proxies
---@field nestedNotify function? Called when nested property changes: nestedNotify(forceUpdate)

---Create a reactive proxy table
---Properties accessed through the proxy are tracked as dependencies
---Properties set through the proxy trigger change detection
---@param rawTable table The underlying data table
---@param options ProxyOptions? Proxy configuration options
---@return table proxy The reactive proxy
function Reactive.createProxy(rawTable, options)
    options = options or {}

    local dependencies = {}

    ---Get or create a dependency for a given key
    ---@param key string
    ---@return Dependency
    local function getDependency(key)
        if not dependencies[key] then
            dependencies[key] = Dependency.new()
        end
        return dependencies[key]
    end

    ---Create a nested proxy for table values
    ---@param nestedTable table
    ---@param parentKey string
    ---@return table
    local function makeNestedProxy(nestedTable, parentKey)
        -- Recursively wrap nested tables first
        for key, value in pairs(nestedTable) do
            if type(value) == "table" and not Reactive.isProxy(value) then
                nestedTable[key] = makeNestedProxy(value, parentKey)
            end
        end

        local nestedProxy = setmetatable({}, {
            __index = function(_, key)
                local collector = currentDependencyCollector
                if collector then
                    getDependency(parentKey):depend(collector)
                end
                return nestedTable[key]
            end,

            __newindex = function(_, key, value)
                local oldValue = nestedTable[key]
                if type(value) == "table" and not Reactive.isProxy(value) then
                    value = makeNestedProxy(value, parentKey)
                end
                if value ~= oldValue then
                    nestedTable[key] = value

                    getDependency(parentKey):notify(true)

                    if options.nestedNotify then
                        options.nestedNotify(true)
                    end
                else
                    nestedTable[key] = value
                end
            end,

            __pairs = function(_)
                return pairs(nestedTable)
            end,

            __len = function(_)
                return #nestedTable
            end,
        })

        proxyToRaw[nestedProxy] = nestedTable
        return nestedProxy
    end

    if options.nested then
        for key, value in pairs(rawTable) do
            if type(value) == "table" and not Reactive.isProxy(value) then
                rawTable[key] = makeNestedProxy(value, key)
            end
        end
    end

    local proxy = setmetatable({}, {
        __index = function(_, key)
            if currentDependencyCollector then
                getDependency(key):depend(currentDependencyCollector)
            end

            if options.onGet then
                options.onGet(key)
            end

            return rawTable[key]
        end,

        __newindex = function(_, key, value)
            local oldValue = rawTable[key]

            if options.nested and type(value) == "table" and not Reactive.isProxy(value) then
                value = makeNestedProxy(value, key)
            end

            if value ~= oldValue then
                rawTable[key] = value

                if options.onSet then
                    options.onSet(key, value, oldValue)
                end

                -- Use forceUpdate for nested table changes
                local isNestedChange = type(value) == "table" or type(oldValue) == "table"
                getDependency(key):notify(isNestedChange)
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

    proxyToRaw[proxy] = rawTable
    return proxy
end

return Reactive
