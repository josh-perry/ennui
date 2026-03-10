local lu = require("lib.luaunit")
local State = require("ennui.state")

TestStateContainers = {}

function TestStateContainers:test_create_empty_state()
    local state = State()

    lu.assertNotIsNil(state)
    lu.assertNotIsNil(state.props)
end

function TestStateContainers:test_create_state_with_initial_props()
    local state = State({
        name = "Player",
        health = 100,
        position = { x = 0, y = 0 },
    })

    lu.assertEquals(state.props.name, "Player")
    lu.assertEquals(state.props.health, 100)
end

function TestStateContainers:test_read_write_props()
    local state = State({ health = 100 })

    lu.assertEquals(state.props.health, 100)
    state.props.health = state.props.health - 10
    lu.assertEquals(state.props.health, 90)
end

function TestStateContainers:test_newId_returns_string()
    local id = State.newId()

    lu.assertIsString(id)
    lu.assertTrue(#id > 0)
end

function TestStateContainers:test_newId_returns_unique_ids()
    local id1 = State.newId()
    local id2 = State.newId()

    lu.assertNotEquals(id1, id2)
end

function TestStateContainers:test_cleanup_stops_watchers()
    local state = State({ health = 100 })
    local callCount = 0
    state:watch("health", function() callCount = callCount + 1 end)

    state.props.health = 90
    lu.assertEquals(callCount, 1)

    state:cleanup()
    state.props.health = 80
    lu.assertEquals(callCount, 1) -- no more calls after cleanup
end

function TestStateContainers:test_bind_returns_computed_with_value()
    local state = State({ health = 100 })
    local binding = state:bind("health")

    lu.assertNotIsNil(binding)
    lu.assertEquals(binding:get(), 100)
end

function TestStateContainers:test_bind_nested_path()
    local state = State({ position = { x = 5, y = 10 } })
    local xBinding = state:bind("position.x")
    local yBinding = state:bind("position.y")

    lu.assertEquals(xBinding:get(), 5)
    lu.assertEquals(yBinding:get(), 10)
end

function TestStateContainers:test_bind_caches_same_instance()
    local state = State({ health = 100 })
    local b1 = state:bind("health")
    local b2 = state:bind("health")

    lu.assertIs(b1, b2)
end

function TestStateContainers:test_get_reads_nested_value()
    local state = State({ position = { x = 3, y = 7 } })

    lu.assertEquals(state:get("position.x"), 3)
    lu.assertEquals(state:get("position.y"), 7)
end

function TestStateContainers:test_getRaw_returns_table()
    local state = State({ tasks = { { id = "a", text = "Buy milk", done = false } } })
    local raw = state:getRaw("tasks")

    lu.assertIsTable(raw)
    lu.assertEquals(raw[1].text, "Buy milk")
    lu.assertFalse(raw[1].done)
end

function TestStateContainers:test_getRawDeep_is_disconnected_copy()
    local state = State({ tasks = { { id = "a", text = "Buy milk", done = false } } })
    local snapshot = state:getRawDeep("tasks")

    lu.assertIsTable(snapshot)
    snapshot[1].text = "Changed"
    lu.assertEquals(state.props.tasks[1].text, "Buy milk")
end

function TestStateContainers:test_getRawDeep_can_ipairs()
    local state = State({
        tasks = {
            { id = "a", text = "Task A" },
            { id = "b", text = "Task B" },
        }
    })

    local plain = state:getRawDeep("tasks")
    local count = 0

    for _, task in ipairs(plain) do
        lu.assertIsString(task.text)
        count = count + 1
    end

    lu.assertEquals(count, 2)
end

function TestStateContainers:test_scope_props_read()
    local state = State({ position = { x = 5, y = 10 } })
    local scope = state:scope("position")

    lu.assertEquals(scope.props.x, 5)
    lu.assertEquals(scope.props.y, 10)
end

function TestStateContainers:test_scope_props_write_reflected_in_root()
    local state = State({ position = { x = 5, y = 10 } })
    local scope = state:scope("position")

    scope.props.y = scope.props.y + 1
    lu.assertEquals(state.props.position.y, 11)
end

function TestStateContainers:test_scope_get()
    local state = State({ position = { x = 5, y = 10 } })
    local scope = state:scope("position")

    lu.assertEquals(scope:get("x"), 5)
end

function TestStateContainers:test_scope_bind()
    local state = State({ position = { x = 5, y = 10 } })
    local scope = state:scope("position")
    local xBinding = scope:bind("x")
    local yBinding = scope:bind("y")

    lu.assertEquals(xBinding:get(), 5)
    lu.assertEquals(yBinding:get(), 10)
end

function TestStateContainers:test_scope_format()
    local state = State({ position = { x = 3, y = 7 } })
    local scope = state:scope("position")
    local label = scope:format("({x}, {y})")

    lu.assertEquals(label:get(), "(3, 7)")
end

function TestStateContainers:test_nested_scopes()
    local state = State({ world = { player = { name = "Frog" } } })
    local worldScope = state:scope("world")
    local playerScope = worldScope:scope("player")

    lu.assertEquals(playerScope.props.name, "Frog")
end

function TestStateContainers:test_nested_scope_path_roots_correctly()
    local state = State({ world = { player = { hp = 99 } } })
    local playerScope = state:scope("world"):scope("player")
    lu.assertEquals(playerScope:get("hp"), 99)
end

function TestStateContainers:test_len_on_proxy_array()
    local state = State({ tasks = { "a", "b", "c" } })
    lu.assertEquals(state.props.tasks:len(), 3)
end

function TestStateContainers:test_getRaw_write_does_not_trigger_watcher()
    local state = State({ tasks = { { id = "x", text = "original" } } })
    local callCount = 0
    state:watch("tasks", function() callCount = callCount + 1 end)

    local raw = state:getRaw("tasks")
    raw[1] = { id = "x2", text = "bypassed" }
    lu.assertEquals(callCount, 0)
end
