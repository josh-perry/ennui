# State Containers

## Creating state objects

```lua
local state = ennui.State()
```

### Initial properties

Pass a table to pre-populate state:

```lua
local state = ennui.State({
    name = "Player",
    health = 100,
    position = { x = 0, y = 0 }
})
```

## The props table

Read and write reactive properties through `state.props`:

```lua
-- read
local hp = state.props.health

-- write (triggers watchers and computed)
state.props.health = state.props.health - 10
```

## Binding methods

### bind() - Property path binding

`bind()` returns a cached `Computed` that tracks a property path. Subsequent calls with
the same path return the same instance:

```lua
local healthBinding = state:bind("health")

-- dot-notation for nested paths
local xBinding = state:bind("position.x")
```

### get() - Accessing values with ot-notation

`get()` reads a value at a dot-notation path. The returned value is still a reactive
proxy when it is a table:

```lua
local x = state:get("position.x")
```

### getRaw() - Getting non-reactive values

`getRaw()` unwraps the top-level proxy. Nested tables inside the result may still be
proxies. Useful when you need a plain reference but don't care about deep nesting:

```lua
local rawTasks = state:getRaw("tasks")

-- rawTasks is a plain table, but rawTasks[1] may still be a proxy
```

### getRawDeep() - Fully unwrapped deep copies

`getRawDeep()` returns a disconnected plain-Lua copy with all nested proxies unwrapped.
Use this for serialization, drag-and-drop data, rebuilding arrays etc. etc.:

```lua
local snapshot = state:getRawDeep("tasks")

-- snapshot is a plain Lua table with no reactivity at any level
```

## State scopes

### Creating scoped views

`scope()` returns a `StateScope` that roots all paths at the given prefix:

```lua
local positionScope = state:scope("position")
```

### Relative paths in scopes

Inside a scope, paths are relative to the scope root. `scope.props` works like
`state.props` for the scoped object:

```lua
local positionScope = state:scope("position")

local x = positionScope.props.x
positionScope.props.y = positionScope.props.y + 1

-- dot-notation also works
local x2 = positionScope:get("x")
```

### Scoped binding and computed

`bind()` and `format()` on a scope use paths relative to the scope root:

```lua
local positionScope = state:scope("position")

local xBinding = positionScope:bind("x")
local positionLabel = positionScope:format("({x}, {y})")
```

### Nested scopes

`scope()` can be called on an existing scope to nest further:

```lua
local worldScope = state:scope("world")
local playerScope = worldScope:scope("player")

-- playerScope roots at "world.player"
```

## IDs

`State.newId()` returns a unique string ID. Use it as a stable key for list items:

```lua
state.props.tasks[1] = { id = ennui.State.newId(), text = "Buy milk", done = false }
```

This is particularly useful when using [reactive list binding](Reactive-List-Binding).

## Nested state in lists

Nested objects inside arrays are also reactive proxies. Assign whole objects to replace them, or write individual fields to update in place:

```lua
-- replace the whole item
state.props.tasks[1] = { id = existingId, text = "Updated text", done = true }

-- update a single field
state.props.tasks[1].text = "Updated text"
```

## Array iteration

### :ipairs()

`state:ipairs(path)` is the reactive equivalent of `ipairs`. Use it inside a `computedInline` getter so the computed re-runs when the array changes:

```lua
local activeCount = state:computedInline(function()
    local count = 0

    for _, task in state:ipairs("tasks") do
        if not task.done then
            count = count + 1
        end
    end

    return count
end)
```

### :pairs()

`state:pairs(path)` is the reactive equivalent of `pairs` for non-array tables:

```lua
local keyCount = state:computedInline(function()
    local n = 0
    for _ in state:pairs("config") do n = n + 1 end
    return n
end)
```

### :forEach()

`state:forEach(path, fn)` calls `fn(scope, index)` for each element, where `scope` is a `StateScope` rooted at that element's path. Useful for imperative setup:

```lua
state:forEach("players", function(scope, i)
    print(i, scope.props.name)
end)
```

### :map() - array mapping

`state:map(path, fn)` collects the return values of `fn(scope, index)` into an array:

```lua
local names = state:map("players", function(scope)
    return scope.props.name
end)
```

### :len() - Counting Array Elements

Use `:len()` on a reactive array proxy - the `#` operator **does not work** correctly on
proxies:

```lua
local n = state.props.tasks:len()
```

## State cleanup

Call `state:cleanup()` to dispose all watchers and computed properties when the state
is no longer needed:

```lua
state:cleanup()
```

## Common pitfalls

### Using # vs :len() on reactive proxies

The `#` operator does not work correctly on reactive proxies. Use `:len()` instead:

```lua
-- Wrong: may return 0 or stale length
local n = #state.props.tasks

-- Correct
local n = state.props.tasks:len()
```

### Updating raw table doesn't update

Mutating a table obtained via `getRaw()` bypasses the reactive proxy, so watchers and
computed properties will not fire:

```lua
-- Wrong: modifies the raw table directly, no updates triggered
local raw = state:getRaw("tasks")
raw[1] = { id = "x", text = "oops, bad, wrong" }

-- Correct: write through the proxy
state.props.tasks[1] = { id = "x", text = "good, correct, wonderful" }
```

### table.insert() and table.remove() don't work!

`table.insert` and `table.remove` operate on the underlying raw table and do not trigger reactive updates. Use direct index assignment instead:

```lua
-- Wrong
table.insert(state.props.tasks, { id = ennui.State.newId(), text = "Task" })

-- Correct: append via indexed assignment
local n = state.props.tasks:len()
state.props.tasks[n + 1] = { id = ennui.State.newId(), text = "Task" }

-- Correct: remove by rebuilding from getRawDeep and reassigning
local plain = state:getRawDeep("tasks")
table.remove(plain, index)
state.props.tasks = plain
```