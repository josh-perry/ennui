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
function Dependency:notify()
    for subscriber in pairs(self.subscribers) do
        if subscriber and subscriber.update then
            subscriber:update()
        end
    end
end

---@class Reactive
local Reactive = {}

local currentDependencyCollector = nil
local dependencyStack = {}

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

---Create a reactive proxy table
---Properties accessed through the proxy are tracked as dependencies
---Properties set through the proxy trigger change detection
---@param rawTable table The underlying data table
---@param onGet function? Called when property is accessed: onGet(key)
---@param onSet function? Called when property changes: onSet(key, newValue, oldValue)
---@return table proxy The reactive proxy
function Reactive.createProxy(rawTable, onGet, onSet)
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

    local proxy = setmetatable({}, {
        __index = function(_, key)
            if currentDependencyCollector then
                getDependency(key):depend(currentDependencyCollector)
            end

            if onGet then
                onGet(key)
            end

            return rawTable[key]
        end,

        __newindex = function(_, key, value)
            local oldValue = rawTable[key]

            if value ~= oldValue then
                rawTable[key] = value

                if onSet then
                    onSet(key, value, oldValue)
                end

                getDependency(key):notify()
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

    return proxy
end

return Reactive
