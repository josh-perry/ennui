local lu = require("lib.luaunit")
local State = require("ennui.state")

TestComputedProperties = {}

function TestComputedProperties:test_computed_named_initial_value()
    local state = State({ firstName = "John", lastName = "Doe" })
    local fullName = state:computed("fullName", function()
        return state.props.firstName .. " " .. state.props.lastName
    end)

    lu.assertEquals(fullName:get(), "John Doe")
end

function TestComputedProperties:test_computed_named_updates_on_dep_change()
    local state = State({ firstName = "John", lastName = "Doe" })
    local fullName = state:computed("fullName", function()
        return state.props.firstName .. " " .. state.props.lastName
    end)

    state.props.firstName = "Jane"
    lu.assertEquals(fullName:get(), "Jane Doe")
end

function TestComputedProperties:test_computedInline_basic()
    local taskId = "task-1"
    local state = State({
        tasks = {
            { id = "task-1", done = false },
            { id = "task-2", done = true },
        }
    })

    local doneComputed = state:computedInline(function()
        for _, task in state:ipairs("tasks") do
            if task.id == taskId then
                return task.done
            end
        end

        return false
    end)

    lu.assertIsFalse(doneComputed:get())
end

function TestComputedProperties:test_computedInline_updates_when_deps_change()
    local taskId = "task-1"
    local state = State({
        tasks = {
            { id = "task-1", done = false },
            { id = "task-2", done = true },
            { id = "task-3", done = true },
        }
    })

    local allDoneComputed = state:computedInline(function()
        for _, task in state:ipairs("tasks") do
            if task.id == taskId then
                if not task.done then
                    return false
                end
            end
        end

        return true
    end)

    lu.assertIsFalse(allDoneComputed:get())
    state.props.tasks[1].done = true
    lu.assertIsTrue(allDoneComputed:get())
end

function TestComputedProperties:test_format_template_interpolation()
    local state = State({ health = 80, maxHealth = 100 })
    local label = state:format("HP: {health} / {maxHealth}")

    lu.assertEquals(label:get(), "HP: 80 / 100")
end

function TestComputedProperties:test_format_template_updates_on_change()
    local state = State({ health = 80, maxHealth = 100 })
    local label = state:format("HP: {health} / {maxHealth}")

    state.props.health = 60

    lu.assertEquals(label:get(), "HP: 60 / 100")
end

function TestComputedProperties:test_format_template_missing_prop_left_as_placeholder()
    local state = State({ health = 80 })
    local label = state:format("HP: {health} / {maxHealth}")

    lu.assertEquals(label:get(), "HP: 80 / {maxHealth}")
end

function TestComputedProperties:test_bind_format_printf_style()
    local state = State({ celsius = 37.0 })
    local celsiusLabel = state:bind("celsius"):format("%.1f °C")

    lu.assertEquals(celsiusLabel:get(), "37.0 °C")
end

function TestComputedProperties:test_bind_format_updates_on_change()
    local state = State({ celsius = 37.0 })
    local celsiusLabel = state:bind("celsius"):format("%.1f °C")

    state.props.celsius = 100.0

    lu.assertEquals(celsiusLabel:get(), "100.0 °C")
end

function TestComputedProperties:test_bind_map_format_chain_initial()
    local state = State({ celsius = 0.0 })
    local fahrenheitLabel = state:bind("celsius")
        :map(function(c) return c * 9 / 5 + 32 end)
        :format("%.1f °F")

    lu.assertEquals(fahrenheitLabel:get(), "32.0 °F")
end

function TestComputedProperties:test_bind_map_format_chain_updates()
    local state = State({ celsius = 0.0 })
    local fahrenheitLabel = state:bind("celsius")
        :map(function(c) return c * 9 / 5 + 32 end)
        :format("%.1f °F")

    state.props.celsius = 100.0

    lu.assertEquals(fahrenheitLabel:get(), "212.0 °F")
end

function TestComputedProperties:test_bind_is_cached()
    local state = State({ x = 1 })
    local b1 = state:bind("x")
    local b2 = state:bind("x")

    lu.assertIs(b1, b2)
end

function TestComputedProperties:test_computedInline_not_cached()
    local state = State({ x = 1 })
    local c1 = state:computedInline(function() return state.props.x end)
    local c2 = state:computedInline(function() return state.props.x end)

    lu.assertNotIs(c1, c2)
end

function TestComputedProperties:test_multiple_dependencies_tracked()
    local state = State({ health = 80, maxHealth = 100 })
    local percent = state:computedInline(function()
        return state.props.health / state.props.maxHealth
    end)

    lu.assertAlmostEquals(percent:get(), 0.8, 0.001)

    state.props.health = 50
    lu.assertAlmostEquals(percent:get(), 0.5, 0.001)

    state.props.maxHealth = 200
    lu.assertAlmostEquals(percent:get(), 0.25, 0.001)
end