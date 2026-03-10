# Computed Properties

## Creating

`state:computed(name, getter)` creates a named computed and caches it on the state.  The getter runs inside a reactive tracking context - any `state.props` access inside it registers a dependency:

```lua
local fullName = state:computed("fullName", function()
    return state.props.firstName .. " " .. state.props.lastName
end)

-- bind to a widget property
label:bindTo("text", fullName)
```

## Anonymous computed - computedInline

`state:computedInline(getter)` creates a computed without caching it by name. Use this for one-off or per-item derived values:

```lua
local doneComputed = state:computedInline(function()
    for _, task in state:ipairs("tasks") do
        if task.id == taskId then
            return task.done
        end
    end
    return false
end)
```

## Formatting

`state:format(template)` produces a `Computed` that interpolates `{propName}` placeholders from `state.props`:

```lua
local label = state:format("HP: {health} / {maxHealth}")
local celsiusLabel = state:bind("celsius"):format("%.1f °C")
```

Computed chains also work - map first, then format:

```lua
local fahrenheit = state:bind("celsius"):map(function(c) return c * 9 / 5 + 32 end)
local fahrenheitLabel = fahrenheit:format("%.1f °F")
```

## Caching and dependencies

`state:bind(path)` is cached - calling it multiple times with the same path returns the same `Computed` instance. `state:computed(name, getter)` is also cached by name.  `computedInline` is never cached.

Dependencies are tracked automatically during the getter execution. Accessing `state.props.foo` inside a getter registers `foo` as a dependency; the computed re-evaluates whenever `foo` changes:

```lua
-- both health and maxHealth are dependencies of this computed
local percent = state:computedInline(function()
    return state.props.health / state.props.maxHealth
end)
```

Changing either `health` or `maxHealth` will cause the computed to re-evaluate.