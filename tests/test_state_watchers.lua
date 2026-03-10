local lu = require("lib.luaunit")
local State = require("ennui.state")

TestWatchers = {}

function TestWatchers:test_watch_string_fires_on_change()
    local state = State({ health = 100 })
    local received = {}
    state:watch("health", function(new, old)
        table.insert(received, { new = new, old = old })
    end)

    state.props.health = 90
    lu.assertEquals(#received, 1)
    lu.assertEquals(received[1].new, 90)
    lu.assertEquals(received[1].old, 100)

    state.props.health = 80
    lu.assertEquals(#received, 2)
    lu.assertEquals(received[2].new, 80)
    lu.assertEquals(received[2].old, 90)
end

function TestWatchers:test_watch_string_fires_multiple_times()
    local state = State({ health = 100 })
    local callCount = 0
    state:watch("health", function() callCount = callCount + 1 end)

    state.props.health = 90
    state.props.health = 80
    state.props.health = 70
    lu.assertEquals(callCount, 3)
end

function TestWatchers:test_watch_getter_fires_on_change()
    local state = State({ health = 80, maxHealth = 100 })
    local lastRatio = nil
    state:watch(function()
        return state.props.health / state.props.maxHealth
    end, function(ratio)
        lastRatio = ratio
    end)

    state.props.health = 40
    lu.assertAlmostEquals(lastRatio, 0.4, 0.001)
end

function TestWatchers:test_watch_getter_fires_on_either_dep_change()
    local state = State({ health = 80, maxHealth = 100 })
    local callCount = 0
    state:watch(function()
        return state.props.health / state.props.maxHealth
    end, function()
        callCount = callCount + 1
    end)

    state.props.health = 50
    lu.assertEquals(callCount, 1)
    state.props.maxHealth = 200
    lu.assertEquals(callCount, 2)
end

function TestWatchers:test_watch_immediate_fires_on_creation()
    local state = State({ health = 100 })
    local callCount = 0
    state:watch("health", function()
        callCount = callCount + 1
    end, { immediate = true })

    lu.assertEquals(callCount, 1)
end

function TestWatchers:test_watch_immediate_fires_on_change_too()
    local state = State({ health = 100 })
    local callCount = 0
    state:watch("health", function()
        callCount = callCount + 1
    end, { immediate = true })

    state.props.health = 90
    lu.assertEquals(callCount, 2)
end

function TestWatchers:test_watch_does_not_fire_if_value_unchanged()
    local state = State({ health = 100 })
    local callCount = 0
    state:watch("health", function() callCount = callCount + 1 end)

    state.props.health = 100 -- same value
    lu.assertEquals(callCount, 0)
end

function TestWatchers:test_unwatch_stops_one_watcher()
    local state = State({ health = 100 })
    local callCount = 0
    local w = state:watch("health", function()
        callCount = callCount + 1
    end)

    state.props.health = 90
    lu.assertEquals(callCount, 1)

    state:unwatch(w)
    state.props.health = 80
    lu.assertEquals(callCount, 1) -- no more calls
end

function TestWatchers:test_unwatch_leaves_other_watchers_active()
    local state = State({ health = 100 })
    local calls1, calls2 = 0, 0
    local w1 = state:watch("health", function() calls1 = calls1 + 1 end)
    state:watch("health", function() calls2 = calls2 + 1 end)

    state:unwatch(w1)
    state.props.health = 90
    lu.assertEquals(calls1, 0)
    lu.assertEquals(calls2, 1)
end

function TestWatchers:test_cleanup_removes_all_watchers()
    local state = State({ health = 100, mana = 50 })
    local hCalls, mCalls = 0, 0

    state:watch("health", function() hCalls = hCalls + 1 end)
    state:watch("mana", function() mCalls = mCalls + 1 end)

    state:cleanup()
    state.props.health = 90
    state.props.mana = 40
    lu.assertEquals(hCalls, 0)
    lu.assertEquals(mCalls, 0)
end

function TestWatchers:test_getRawDeep_in_watcher_callback()
    local state = State({ tasks = { { id = "a", text = "Task A", done = false } } })
    local plainTasks = nil
    state:watch("tasks", function()
        plainTasks = state:getRawDeep("tasks")
    end)

    state.props.tasks[1].done = true

    lu.assertNotIsNil(plainTasks) ---@cast plainTasks table

    local count = 0
    for _, task in ipairs(plainTasks) do
        lu.assertIsString(task.text)
        count = count + 1
    end

    lu.assertEquals(count, 1)
end
