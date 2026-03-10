-- need to clear this since luaunit uses it for test filtering, love puts the filename in it
arg = {}
local lu = require("lib.luaunit")
local ennui = require("ennui")

local Rectangle = ennui.Widgets.Rectangle
local Text = ennui.Widgets.Text
local ScrollArea = ennui.Widgets.Scrollarea

local COLORS = {
    pass  = {0.2,  0.75, 0.3,  1},
    fail  = {0.85, 0.2,  0.2,  1},
    error = {0.9,  0.5,  0.1,  1},
}

local font = love.graphics.newFont("examples/assets/fonts/m5x7.ttf", 22)
love.graphics.setFont(font)

local files = love.filesystem.getDirectoryItems("tests")
table.sort(files)

for _, filename in ipairs(files) do
    if filename:match("^test_.*%.lua$") then
        require("tests." .. filename:gsub("%.lua$", ""))
    end
end

local nameAndTestInstances = {}
for _, name in ipairs(lu.LuaUnit.collectTests()) do
    table.insert(nameAndTestInstances, { name, _G[name] })
end

local expanded = lu.LuaUnit.expandClasses(nameAndTestInstances)
local total = #expanded

local tests = {}
for i, v in ipairs(expanded) do
    tests[i] = { id = i, name = v[1], status = "pending" }
end

local testState = ennui.State({ tests = tests })

local passCount = testState:bind("tests"):map(function(tests)
    local n = 0
    for _, t in tests:ipairs() do
        if t.status == "pass" then n = n + 1 end
    end
    return n
end)

local failCount = testState:bind("tests"):map(function(tests)
    local n = 0
    for _, t in tests:ipairs() do
        if t.status == "fail" or t.status == "error" then n = n + 1 end
    end
    return n
end)

local barWidth = testState:bind("tests"):map(function(tests)
    if total == 0 then return ennui.Size.percent(0) end
    local done = 0

    for _, t in tests:ipairs() do
        if t.status ~= "pending" then done = done + 1 end
    end

    return ennui.Size.percent(math.min(1, done / total))
end)

local w, h = love.graphics.getDimensions()
local host = ennui.Host()
host:setSize(w, h)

-- Background
local root = Rectangle()
    :setColor(0.08, 0.08, 0.08)
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setLayoutStrategy(ennui.Layout.Vertical())
    :setPadding(20)
    :setBorderWidth(0)

-- Spacer
root:addChild(Rectangle()
    :setColor(0, 0, 0, 0)
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setBorderWidth(0))

local progressSection = Rectangle()
    :setColor(0, 0, 0, 0)
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setLayoutStrategy(ennui.Layout.Vertical())
    :setBorderWidth(0)

local progressLabel = Text(("0 / %d"):format(total))
    :setFont(font)
    :setColor(0.65, 0.65, 0.65)
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setTextHorizontalAlignment("center")
    :setPadding(0, 0, 10, 0)

progressSection:addChild(progressLabel)

-- Progress bar
local progressTrack = Rectangle()
    :setColor(0.18, 0.18, 0.18)
    :setRadius(4)
    :setSize(ennui.Size.fill(), 22)
local progressFill = Rectangle()
    :setColor(unpack(COLORS.pass))
    :setRadius(4)
    :setHorizontalAlignment("left")
    :setPreferredWidth(barWidth)
    :setPreferredHeight(ennui.Size.fill())

progressTrack:addChild(progressFill)
progressSection:addChild(progressTrack)
root:addChild(progressSection)

root:addChild(Rectangle()
    :setColor(0, 0, 0, 0)
    :setSize(ennui.Size.fill(), 16)
    :setBorderWidth(0))

local logScroll = ScrollArea()
    :setSize(ennui.Size.fill(), ennui.Size.fill())

logScroll:bindChildren(testState, "tests", {
    key = "id",
    create = function(data, _)
        local id   = data.id
        local name = data.name

        local textComputed = testState:computedInline(function()
            for _, t in testState:ipairs("tests") do
                if t.id == id then
                    local s = t.status
                    if s == "pass" then
                        return ("[PASS] %s"):format(name)
                    elseif s == "fail" then
                        return ("[FAIL] %s"):format(name)
                    elseif s == "error" then
                        return ("[ERR ] %s"):format(name)
                    end
                end
            end

            return ("[PEND] %s"):format(name)
        end)

        local colorComputed = testState:computedInline(function()
            for _, t in testState:ipairs("tests") do
                if t.id == id then
                    local s = t.status
                    if s == "pass" then
                        return COLORS.pass
                    elseif s == "fail" then
                        return COLORS.fail
                    elseif s == "error" then
                        return COLORS.error
                    end
                end
            end

            return {0.45, 0.45, 0.45, 1}
        end)

        return Text("")
            :setFont(font)
            :bindTo("text", textComputed)
            :bindTo("color", colorComputed)
            :setSize(ennui.Size.fill(), ennui.Size.auto())
            :setPadding(2, 6)
    end,
})

root:addChild(logScroll)

host:addChild(root)

local runner
local testCoroutine

local function buildTestCoroutine()
    runner = lu.LuaUnit.new()
    runner:registerSuite()
    runner:startSuite(#expanded, 0)

    return coroutine.create(function()
        for i, v in ipairs(expanded) do
            local name, instance = v[1], v[2]
            local className, methodName = lu.LuaUnit.splitClassMethod(name)

            runner:execOneFunction(className, methodName, instance, instance[methodName])
            coroutine.yield(i)
        end

        if runner.lastClassName ~= nil then
            runner:endClass()
        end

        runner:endSuite()
        runner:unregisterSuite()
    end)
end

testCoroutine = buildTestCoroutine()

function love.update(dt)
    host:update(dt)

    if not testCoroutine then return end

    local ok, testIndex = coroutine.resume(testCoroutine)

    if not ok then
        print("Test runner error: " .. tostring(testIndex))
        love.event.quit(1)
        return
    end

    if testIndex then
        local node = runner.result.allTests[testIndex]

        if node:isFailure() then
            testState.props.tests[testIndex].status = "fail"
        elseif node:isError() then
            testState.props.tests[testIndex].status = "error"
        else
            testState.props.tests[testIndex].status = "pass"
        end

        progressLabel:setText(("%d / %d"):format(testIndex, total))
        if failCount:get() > 0 then
            progressFill:setColor(unpack(COLORS.fail))
        end

        logScroll:scrollToBottom()
    end

    if coroutine.status(testCoroutine) == "dead" then
        testCoroutine = nil

        local passes = passCount:get()
        local fails = failCount:get()

        if fails == 0 then
            progressLabel:setText(("All %d tests passed"):format(passes))
        else
            progressLabel:setText(("%d tests passed, %d tests failed"):format(passes, fails))
        end
    end
end

function love.draw()
    host:draw()
end

function love.mousepressed(x, y, button, isTouch)
    host:mousepressed(x, y, button, isTouch)
end

function love.mousereleased(x, y, button, isTouch)
    host:mousereleased(x, y, button, isTouch)
end

function love.mousemoved(x, y, dx, dy, isTouch)
    host:mousemoved(x, y, dx, dy, isTouch)
end

function love.wheelmoved(dx, dy)
    host:wheelmoved(dx, dy)
end

function love.resize(w, h)
    host:setSize(w, h)
end
