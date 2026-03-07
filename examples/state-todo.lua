local ennui = require("ennui")

local StackPanel = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local TextButton = ennui.Widgets.Textbutton
local TextInput = ennui.Widgets.Textinput
local Checkbox = ennui.Widgets.Checkbox
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local state = ennui.State({
    filter = "all",
    tasks  = {},
})

state.props.tasks[1] = { id = ennui.State.newId(), text = "Buy groceries", done = false }
state.props.tasks[2] = { id = ennui.State.newId(), text = "Write tests", done = true }
state.props.tasks[3] = { id = ennui.State.newId(), text = "Fix that bug", done = false }

local function TaskRow(data)
    local taskId = data.id
    local taskText = data.text

    local doneComputed = state:computedInline(function()
        for _, task in state:ipairs("tasks") do
            if task.id == taskId then
                return task.done
            end
        end

        return false
    end)

    local colorComputed = doneComputed:map(function(done)
        return done and { 0.5, 0.5, 0.5, 1 } or { 1, 1, 1, 1 }
    end)

    local visibleComputed = state:computedInline(function()
        local filter = state.props.filter
        local done = false

        for _, task in state:ipairs("tasks") do
            if task.id == taskId then
                done = task.done
                break
            end
        end

        if filter == "all" then return true end
        if filter == "active" then return not done end
        return done
    end)

    local row = HorizontalStackPanel()
        :setSpacing(6)
        :setSize(ennui.Size.fill(), 28)
        :bindTo("isVisible", visibleComputed)

    local checkbox = Checkbox()
        :setSize(24, 24)
        :bindTo("checked", doneComputed)
        :onClick(function(widget)
            local newDone = widget.props.checked -- already toggled internally
            local n = state.props.tasks:len()
            for j = 1, n do
                if state.props.tasks[j].id == taskId then
                    state.props.tasks[j].done = newDone
                    break
                end
            end
        end)

    local label = Text(taskText)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :setTextVerticalAlignment("center")
        :bindTo("color", colorComputed)

    local deleteButton = TextButton("×")
        :setSize(22, ennui.Size.fill())
        :onClick(function()
            local tasks = state:getRawDeep("tasks")
            local newTasks = {}

            for _, task in ipairs(tasks) do
                if task.id ~= taskId then
                    newTasks[#newTasks + 1] = task
                end
            end

            state.props.tasks = newTasks
        end)

    row:addChild(checkbox)
    row:addChild(label)
    row:addChild(deleteButton)
    return row
end

local host = ennui.Widgets.Host():setSize(love.graphics.getDimensions())

local window = Window("Reactive Todo List")
    :setSize(380, ennui.Size.auto())
    :setPosition(80, 60)

local panel = StackPanel()
    :setSpacing(8)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local inputRow = HorizontalStackPanel()
    :setSpacing(6)
    :setSize(ennui.Size.fill(), 32)

local taskInput = TextInput()
    :setPlaceholder("New task…")
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local addBtn = TextButton("Add")
    :setSize(60, ennui.Size.fill())
    :onClick(function()
        local text = taskInput:getText()

        if text == "" then
            return
        end

        local n = state.props.tasks:len()
        state.props.tasks[n + 1] = { id = ennui.State.newId(), text = text, done = false }
        taskInput:setText("")
    end)

inputRow:addChild(taskInput)
inputRow:addChild(addBtn)

local filterRow = HorizontalStackPanel()
    :setSpacing(4)
    :setSize(ennui.Size.fill(), 28)

local function FilterButton(label, filterValue)
    return TextButton(label)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :onClick(function()
            state.props.filter = filterValue
        end)
end

filterRow:addChild(FilterButton("All", "all"))
filterRow:addChild(FilterButton("Active", "active"))
filterRow:addChild(FilterButton("Done", "done"))

local taskList = StackPanel()
    :setSpacing(4)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

taskList:bindChildren(state, "tasks", {
    key = "id",
    create = function(data) return TaskRow(data) end,
})

local statusComputed = state:computedInline(function()
    local active, done = 0, 0

    for _, task in state:ipairs("tasks") do
        if task.done then
            done = done + 1
        else
            active = active + 1
        end
    end

    return ("%d active · %d done"):format(active, done)
end)

local statusBar = Text()
    :setColor(0.5, 0.7, 0.9)
    :bindTo("text", statusComputed)

panel:addChild(inputRow)
panel:addChild(filterRow)
panel:addChild(taskList)
panel:addChild(statusBar)

window:setContent(panel)
host:addChild(window)

return host
