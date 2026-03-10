# Watchers

## Creating watchers

`state:watch(source, callback)` fires `callback(newValue, oldValue)` whenever the
watched value changes. `source` is either a property name string or a getter function:

```lua
-- watch a single property by name
state:watch("health", function(new, old)
    print(("health changed from %d to %d"):format(old, new))
end)

-- watch a derived expression with a getter
state:watch(function()
    return state.props.health / state.props.maxHealth
end, function(ratio)
    healthBar:setSize(ennui.Size.percent(ratio), ennui.Size.fill())
end)
```

## Watch options

Pass an options table as the third argument:

- `immediate = true` - fires the callback immediately with the current value
- `deep = true` - also fires when nested table contents change

```lua
state:watch("health", function(hp)
    healthBar:setSize(ennui.Size.percent(hp / state.props.maxHealth), ennui.Size.fill())
end, {
    immediate = true
})

state:watch("settings", function(s)
    print("settings changed")
end, {
    deep = true
})
```

## Watcher cleanup

`state:watch()` returns a `Watcher` instance. Pass it to `state:unwatch()` to remove
just that watcher. `state:cleanup()` removes all watchers at once:

```lua
local w = state:watch("health", function(hp)
    print(hp)
end)

-- remove one watcher
state:unwatch(w)

-- remove all watchers (and computed)
state:cleanup()
```