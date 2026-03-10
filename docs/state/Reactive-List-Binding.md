# Reactive List Binding

## Key-based reconciliation

`widget:bindChildren(state, path, opts)` keeps a container widget's children in sync with an array in state. It diffs by `key` so only changed items are created or removed:

```lua
taskList:bindChildren(state, "tasks", {
    key = "id",
    create = function(data)
        return TaskRow(data)
    end,
    update = function(data)
        -- do something when it changes
    end,
    onRemove = function(data)
        -- do something when it's removed
    end
})
```

`create` receives the raw (non-reactive) item data and must return a widget.

## Using State.newId() for list items

Always assign a stable unique `id` to each item when it is created. This is what `bindChildren` uses to match old and new items during reconciliation:

```lua
state.props.tasks[n] = {
    id = ennui.State.newId(),
    text = "New task",
    done = false,
}
```