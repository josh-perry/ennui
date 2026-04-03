# Lifecycle

Widgets have three lifecycle callbacks: `mount`, `unmount` and `update`.

## mount

Fires after a widget is added to the tree via `addChild`. `self.parent` is already set when the handler runs.

```lua
widget:onMount(function(self)
    print("mounted, parent is", self.parent)
end)
```

To override in a subclass:

```lua
function MyWidget:mount()
    Widget.mount(self)  -- fires registered onMount handlers
    -- custom setup
end
```

## unmount

Fires after a widget is removed from the tree via `removeChild`. `self.parent` is already `nil` when the handler runs but `self.children`, props, and reactive state are still intact.

```lua
widget:onUnmount(function(self)
    print("unmounted")
end)
```

To override in a subclass:

```lua
function MyWidget:unmount()
    Widget.unmount(self)  -- fires registered onUnmount handlers + cleans up reactive state
    -- custom teardown
end
```

## update

Fires every frame via `host:update(dt)`. `dt` is delta time in seconds.

```lua
local x = 0

widget:onUpdate(function(self, dt)
    x = x + 100 * dt
end)
```

To override in a subclass:

```lua
function MyWidget:update(dt)
    Widget.update(self, dt)  -- fires registered onUpdate handlers + propagates to children
    -- per-frame logic
end
```

## Examples
Search `lifecycle` in the example browser.