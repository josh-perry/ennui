local ennui = require("ennui")

local StackPanel           = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local TextButton           = ennui.Widgets.Textbutton
local Text                 = ennui.Widgets.Text
local ScrollArea           = ennui.Widgets.Scrollarea
local Window               = ennui.Widgets.Window

local state = ennui.State({
    log    = {},
    counts = { info = 0, warning = 0, error = 0 },
})

local LOG_LEVELS = {
    {
        label = "Info",
        key = "info",
        color = { 0.5, 0.8, 1, 1 }
    },
    {
        label = "Warning",
        key = "warning",
        color = { 1, 0.8, 0.3, 1 }
    },
    {
        label = "Error",
        key = "error",
        color = { 1, 0.4, 0.4, 1 }
    },
}

local messageNumber = 0

local function addMessage(level, prepend)
    messageNumber = messageNumber + 1

    local entry = {
        id    = ennui.State.newId(),
        text  = ("%s #%d"):format(level.label, messageNumber),
        level = level.key,
        color = level.color,
    }

    if prepend then
        state.props.log:insert(1, entry)
    else
        state.props.log:insert(entry)
    end

    state.props.counts[level.key] = state.props.counts[level.key] + 1
end

local host = ennui.Widgets.Host():setSize(love.graphics.getDimensions())

local window = Window("State - insert / ipairs / pairs / len")
    :setSize(440, ennui.Size.auto())
    :setPosition(60, 50)

local panel = StackPanel()
    :setSpacing(8)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local function levelButtonRow(prepend)
    local row = HorizontalStackPanel()
        :setSpacing(6)
        :setSize(ennui.Size.fill(), 30)

    for _, level in ipairs(LOG_LEVELS) do
        row:addChild(
            TextButton(level.label)
                :setSize(ennui.Size.fill(), ennui.Size.fill())
                :onClick(function() addMessage(level, prepend) end)
        )
    end

    return row
end

panel:addChild(Text("Proxy tables have equivilent methods to table.insert, table.update etc. that must be used instead of the table.* versions!"))
panel:addChild(Text(":insert"):setColor(1, 1, 0.5))
panel:addChild(levelButtonRow(false))
panel:addChild(Text(":insert(1, ...)"):setColor(1, 1, 0.5))
panel:addChild(levelButtonRow(true))

panel:addChild(
    TextButton("Clear")
        :setSize(ennui.Size.fill(), 28)
        :onClick(function()
            state.props.log    = {}
            state.props.counts = { info = 0, warning = 0, error = 0 }
            messageNumber      = 0
        end)
)

panel:addChild(Text(":remove"):setColor(1, 1, 0.5))
panel:addChild(
    HorizontalStackPanel()
        :setSpacing(6)
        :setSize(ennui.Size.fill(), 30)
        :addChild(
            TextButton("Remove first")
                :setSize(ennui.Size.fill(), ennui.Size.fill())
                :onClick(function()
                    if state.props.log:len() > 0 then
                        local removed = state.props.log:remove(1)
                        state.props.counts[removed.level] = state.props.counts[removed.level] - 1
                    end
                end)
        )
        :addChild(
            TextButton("Remove last")
                :setSize(ennui.Size.fill(), ennui.Size.fill())
                :onClick(function()
                    local length = state.props.log:len()
                    if length > 0 then
                        local removed = state.props.log:remove(length)
                        state.props.counts[removed.level] = state.props.counts[removed.level] - 1
                    end
                end)
        )
)

panel:addChild(Text(":len"):setColor(1, 1, 0.5))
panel:addChild(
    Text()
        :setColor(0.8, 0.8, 0.8)
        :bindTo("text", state:computedInline(function()
            return ("%d entries"):format(state.props.log:len())
        end))
)

panel:addChild(Text(":ipairs - error count"):setColor(1, 1, 0.5))
panel:addChild(
    Text()
        :setColor(1, 0.5, 0.5)
        :bindTo("text", state:computedInline(function()
            local errorCount = 0

            for _, entry in state:ipairs("log") do
                if entry.level == "error" then
                    errorCount = errorCount + 1
                end
            end

            return ("%d errors logged"):format(errorCount)
        end))
)

panel:addChild(Text(":pairs - counts by level"):setColor(1, 1, 0.5))
panel:addChild(
    Text()
        :setColor(0.7, 1, 0.7)
        :bindTo("text", state:computedInline(function()
            local parts = {}

            for key, count in state:pairs("counts") do
                parts[#parts + 1] = ("%s=%d"):format(key, count)
            end

            table.sort(parts)
            return table.concat(parts, "  ·  ")
        end))
)

panel:addChild(Text("Log"):setColor(1, 1, 0.5))

local logScroll = ScrollArea()
    :setSize(ennui.Size.fill(), 200)

logScroll:bindChildren(state, "log", {
    key    = "id",
    create = function(data)
        return Text(data.text)
            :setColor(unpack(data.color))
            :setSize(ennui.Size.fill(), ennui.Size.auto())
    end,
})

panel:addChild(logScroll)

window:setContent(panel)
host:addChild(window)

return host
