local lu = require("lib.luaunit")
local State = require("ennui.state")

TestReactiveList = {}

function TestReactiveList:test_ipairs_in_computedInline()
    local state = State({
        tasks = {
            { id = "1", done = false },
            { id = "2", done = true },
            { id = "3", done = false },
        }
    })

    local activeCount = state:computedInline(function()
        local count = 0
        for _, task in state:ipairs("tasks") do
            if not task.done then count = count + 1 end
        end

        return count
    end)

    lu.assertEquals(activeCount:get(), 2)
end

function TestReactiveList:test_ipairs_computed_updates_on_field_change()
    local state = State({
        tasks = {
            { id = "1", done = false },
            { id = "2", done = false },
        }
    })

    local activeCount = state:computedInline(function()
        local count = 0

        for _, task in state:ipairs("tasks") do
            if not task.done then
                count = count + 1
            end
        end

        return count
    end)

    lu.assertEquals(activeCount:get(), 2)
    state.props.tasks[1].done = true
    lu.assertEquals(activeCount:get(), 1)
end

function TestReactiveList:test_ipairs_computed_updates_on_new_item()
    local state = State({
        tasks = {
            { id = "1", done = false },
        }
    })

    local activeCount = state:computedInline(function()
        local count = 0

        for _, task in state:ipairs("tasks") do
            if not task.done then
                count = count + 1
            end
        end

        return count
    end)

    lu.assertEquals(activeCount:get(), 1)
    state.props.tasks[2] = { id = "2", done = false }
    lu.assertEquals(activeCount:get(), 2)
end

function TestReactiveList:test_pairs_counts_keys()
    local state = State({ config = { a = 1, b = 2, c = 3 } })

    local keyCount = state:computedInline(function()
        local n = 0

        for _ in state:pairs("config") do
            n = n + 1
        end

        return n
    end)

    lu.assertEquals(keyCount:get(), 3)
end

function TestReactiveList:test_pairs_yields_correct_values()
    local state = State({ config = { x = 10, y = 20 } })

    local collected = {}

    for key, value in state:pairs("config") do
        collected[key] = value
    end

    lu.assertEquals(collected.x, 10)
    lu.assertEquals(collected.y, 20)
end

function TestReactiveList:test_pairs_computed_updates_on_key_change()
    local state = State({ config = { a = 1, b = 2 } })

    local sum = state:computedInline(function()
        local total = 0

        for _, value in state:pairs("config") do
            total = total + value
        end

        return total
    end)

    lu.assertEquals(sum:get(), 3)
    state.props.config.a = 10
    lu.assertEquals(sum:get(), 12)
end

function TestReactiveList:test_insert_append()
    local state = State({ items = { "a", "b" } })

    state.props.items:insert("c")

    lu.assertEquals(state.props.items:len(), 3)
    lu.assertEquals(state.props.items[3], "c")
end

function TestReactiveList:test_insert_append_to_empty()
    local state = State({ items = {} })

    state.props.items:insert("a")

    lu.assertEquals(state.props.items:len(), 1)
    lu.assertEquals(state.props.items[1], "a")
end

function TestReactiveList:test_insert_positional_shifts_elements()
    local state = State({ items = { "a", "b", "c" } })

    state.props.items:insert(2, "x")

    lu.assertEquals(state.props.items:len(), 4)
    lu.assertEquals(state.props.items[1], "a")
    lu.assertEquals(state.props.items[2], "x")
    lu.assertEquals(state.props.items[3], "b")
    lu.assertEquals(state.props.items[4], "c")
end

function TestReactiveList:test_insert_at_beginning()
    local state = State({ items = { "b", "c" } })

    state.props.items:insert(1, "a")

    lu.assertEquals(state.props.items:len(), 3)
    lu.assertEquals(state.props.items[1], "a")
    lu.assertEquals(state.props.items[2], "b")
    lu.assertEquals(state.props.items[3], "c")
end

function TestReactiveList:test_insert_triggers_watcher()
    local state = State({ items = {} })
    local callCount = 0
    state:watch("items", function() callCount = callCount + 1 end)

    state.props.items:insert("a")

    lu.assertEquals(callCount, 1)
end

function TestReactiveList:test_insert_updates_computed()
    local state = State({ items = { "a", "b" } })

    local count = state:computedInline(function()
        return state.props.items:len()
    end)

    lu.assertEquals(count:get(), 2)
    state.props.items:insert("c")
    lu.assertEquals(count:get(), 3)
end

function TestReactiveList:test_insert_table_value_is_reactive()
    local state = State({ tasks = {} })

    state.props.tasks:insert({ id = "1", done = false })

    lu.assertEquals(state.props.tasks[1].id, "1")
    state.props.tasks[1].done = true
    lu.assertIsTrue(state.props.tasks[1].done)
end

function TestReactiveList:test_remove_last()
    local state = State({ items = { "a", "b", "c" } })

    state.props.items:remove(3)

    lu.assertEquals(state.props.items:len(), 2)
    lu.assertEquals(state.props.items[1], "a")
    lu.assertEquals(state.props.items[2], "b")
end

function TestReactiveList:test_remove_from_middle_shifts_elements()
    local state = State({ items = { "a", "b", "c" } })

    state.props.items:remove(2)

    lu.assertEquals(state.props.items:len(), 2)
    lu.assertEquals(state.props.items[1], "a")
    lu.assertEquals(state.props.items[2], "c")
end

function TestReactiveList:test_remove_first()
    local state = State({ items = { "a", "b", "c" } })

    state.props.items:remove(1)

    lu.assertEquals(state.props.items:len(), 2)
    lu.assertEquals(state.props.items[1], "b")
    lu.assertEquals(state.props.items[2], "c")
end

function TestReactiveList:test_remove_returns_removed_value()
    local state = State({ items = { "x", "y", "z" } })

    local removed = state.props.items:remove(2)

    lu.assertEquals(removed, "y")
end

function TestReactiveList:test_remove_triggers_watcher()
    -- remove shifts elements one write at a time, so 2 items = 2 watcher calls
    local state = State({ items = { "a", "b" } })
    local callCount = 0
    state:watch("items", function() callCount = callCount + 1 end)

    state.props.items:remove(1)

    lu.assertEquals(callCount, 2)
end

function TestReactiveList:test_remove_updates_computed()
    local state = State({ items = { "a", "b", "c" } })

    local count = state:computedInline(function()
        return state.props.items:len()
    end)

    lu.assertEquals(count:get(), 3)
    state.props.items:remove(1)
    lu.assertEquals(count:get(), 2)
end

function TestReactiveList:test_forEach_receives_scope_and_index()
    local state = State({
        players = {
            { name = "Alice" },
            { name = "Bob" },
        }
    })

    local results = {}

    state:forEach("players", function(scope, i)
        results[i] = scope.props.name
    end)

    lu.assertEquals(results[1], "Alice")
    lu.assertEquals(results[2], "Bob")
end

function TestReactiveList:test_map_collects_return_values()
    local state = State({
        players = {
            { name = "Alice" },
            { name = "Bob" },
        }
    })

    local names = state:map("players", function(scope)
        return scope.props.name
    end)

    lu.assertEquals(#names, 2)
    lu.assertEquals(names[1], "Alice")
    lu.assertEquals(names[2], "Bob")
end

function TestReactiveList:test_len_on_empty_array()
    local state = State({ tasks = {} })

    lu.assertEquals(state.props.tasks:len(), 0)
end

function TestReactiveList:test_len_after_add()
    local state = State({ tasks = {} })
    state.props.tasks[1] = { id = "a", text = "Task 1", done = false }

    lu.assertEquals(state.props.tasks:len(), 1)
end

function TestReactiveList:test_add_item_via_indexed_assignment_triggers_watcher()
    local state = State({ tasks = {} })
    local callCount = 0
    state:watch("tasks", function() callCount = callCount + 1 end)

    local n = state.props.tasks:len()
    state.props.tasks[n + 1] = { id = State.newId(), text = "New task", done = false }

    lu.assertEquals(state.props.tasks:len(), 1)
    lu.assertEquals(state.props.tasks[1].text, "New task")
    lu.assertEquals(callCount, 1)
end

function TestReactiveList:test_remove_via_getRawDeep_and_reassign()
    local state = State({
        tasks = {
            { id = "a", text = "Task A" },
            { id = "b", text = "Task B" },
            { id = "c", text = "Task C" },
        }
    })

    local plain = state:getRawDeep("tasks")
    table.remove(plain, 2)
    state.props.tasks = plain

    lu.assertEquals(state.props.tasks:len(), 2)
    lu.assertEquals(state.props.tasks[1].text, "Task A")
    lu.assertEquals(state.props.tasks[2].text, "Task C")
end

function TestReactiveList:test_nested_field_read()
    local state = State({
        tasks = {
            { id = "a", done = false, text = "x" },
        }
    })

    lu.assertIsFalse(state.props.tasks[1].done)
end

function TestReactiveList:test_nested_field_write_in_place()
    local state = State({
        tasks = {
            { id = "a", done = false, text = "x" },
        }
    })

    state.props.tasks[1].done = true
    lu.assertIsTrue(state.props.tasks[1].done)
end

function TestReactiveList:test_replace_whole_item()
    local state = State({
        tasks = {
            { id = "a", text = "Original", done = false },
        }
    })

    local existingId = state.props.tasks[1].id
    state.props.tasks[1] = { id = existingId, text = "Updated text", done = true }

    lu.assertEquals(state.props.tasks[1].text, "Updated text")
    lu.assertIsTrue(state.props.tasks[1].done)
end

function TestReactiveList:test_newId_used_in_list_items()
    local state = State({ tasks = {} })

    state.props.tasks[1] = { id = State.newId(), text = "Buy milk", done = false }

    lu.assertIsString(state.props.tasks[1].id)
    lu.assertEquals(state.props.tasks[1].text, "Buy milk")
end