love.keyboard.setTextInput(true)
love.graphics.setDefaultFilter("nearest", "nearest")
--love.graphics.setLineStyle("rough")

local buttonExampleHost = require("examples.button")
local jrpg = require("examples.jrpg")
local jrpgExampleHost, jrpgExampleState = jrpg.host, jrpg.gameState

local debugger = require("ennui.debug")

local examples = {
    { host = buttonExampleHost, state = nil },
    { host = jrpgExampleHost, state = jrpgExampleState }
}

local exampleIndex = 1

local smallCanvas = love.graphics.newCanvas(320, 288)
local smallCanvasExamples = {
    [examples[2]] = true
}

local function drawToSmallCanvas(example)
    if smallCanvasExamples[example] then
        return true
    end

    return false
end

local function transformMouseCoords(x, y)
    if not drawToSmallCanvas(examples[exampleIndex]) then
        return x, y
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local scale = math.floor(math.min(
        windowWidth / smallCanvas:getWidth(),
        windowHeight / smallCanvas:getHeight()
    ))

    local scaledWidth = smallCanvas:getWidth() * scale
    local scaledHeight = smallCanvas:getHeight() * scale
    local offsetX = (windowWidth - scaledWidth) / 2
    local offsetY = (windowHeight - scaledHeight) / 2

    local canvasX = (x - offsetX) / scale
    local canvasY = (y - offsetY) / scale

    return canvasX, canvasY
end

function love.update(dt)
    local example = examples[exampleIndex]

    example.host:update(dt)
    debugger.host:update(dt)

    if example.state then
        example.state.props.time = example.state.props.time + dt
        example.state.props.steps = example.state.props.steps + (2 * dt)

        -- updateTimer = updateTimer + dt
        -- if updateTimer >= 1 then
        --     updateTimer = 0

        --     local frogEmployment = gameState.props.characters[1].employment
        --     local job = jobs[love.math.random(1, #jobs)]

        --     frogEmployment.jobTitle = job
        -- end
    end
end

function love.draw()
    local example = examples[exampleIndex]

    if drawToSmallCanvas(example) then
        love.graphics.setCanvas(smallCanvas)
        love.graphics.clear()
    end

    love.graphics.setColor(1, 1, 1)
    example.host:draw()

    if debugger.inspectingWidget then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle(
            "line",
            debugger.inspectingWidget.x,
            debugger.inspectingWidget.y,
            debugger.inspectingWidget.width,
            debugger.inspectingWidget.height
        )
    end

    love.graphics.setCanvas()

    if drawToSmallCanvas(example)then
        local windowWidth, windowHeight = love.graphics.getDimensions()
        local scale = math.floor(math.min(
            windowWidth / smallCanvas:getWidth(),
            windowHeight / smallCanvas:getHeight()
        ))

        local scaledWidth = smallCanvas:getWidth() * scale
        local scaledHeight = smallCanvas:getHeight() * scale
        local offsetX = (windowWidth - scaledWidth) / 2
        local offsetY = (windowHeight - scaledHeight) / 2

        love.graphics.clear()
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(smallCanvas, offsetX, offsetY, 0, scale, scale)
    end

    debugger.host:draw()
end

function love.mousepressed(x, y, button, isTouch)
    if debugger.host:mousepressed(x, y, button, isTouch) then
        return
    end

    local canvasX, canvasY = transformMouseCoords(x, y)
    examples[exampleIndex].host:mousepressed(canvasX, canvasY, button, isTouch)
end

function love.mousereleased(x, y, button, isTouch)
    if debugger.host:mousereleased(x, y, button, isTouch) then
        return
    end

    local canvasX, canvasY = transformMouseCoords(x, y)
    examples[exampleIndex].host:mousereleased(canvasX, canvasY, button, isTouch)
end

function love.mousemoved(x, y, dx, dy, isTouch)
    if debugger.host:mousemoved(x, y, dx, dy, isTouch) then
        return
    end

    local canvasX, canvasY = transformMouseCoords(x, y)
    examples[exampleIndex].host:mousemoved(canvasX, canvasY, dx, dy, isTouch)
end

function love.wheelmoved(dx, dy)
    if debugger.host:wheelmoved(dx, dy) then
        return
    end

    examples[exampleIndex].host:wheelmoved(dx, dy)
end

function love.keypressed(key, scancode, isRepeat)
    if key == "escape" then
        love.event.quit()
    elseif key == "f1" then
        debugger:setTargetHost(examples[exampleIndex].host)
    elseif key == "f4" then
        exampleIndex = exampleIndex + 1

        if exampleIndex > #examples then
            exampleIndex = 1
        end

        local example = examples[exampleIndex]

        debugger:setTargetHost(example.host)

        if drawToSmallCanvas(example)then
            example.host:setSize(smallCanvas:getWidth(), smallCanvas:getHeight())
        else
            local w, h = love.graphics.getDimensions()
            example.host:setSize(w, h)
            debugger.host:setSize(w, h)
        end
    end

    if debugger.host:keypressed(key, scancode, isRepeat) then
        return
    end

    examples[exampleIndex].host:keypressed(key, scancode, isRepeat)
end

function love.keyreleased(key, scancode)
    if debugger.host:keyreleased(key, scancode) then
        return
    end

    examples[exampleIndex].host:keyreleased(key, scancode)
end

function love.textinput(text)
    if debugger.host:textinput(text) then
        return
    end

    examples[exampleIndex].host:textinput(text)
end

function love.resize(w, h)
    local example = examples[exampleIndex]

    if drawToSmallCanvas(example)then
        example.host:setSize(smallCanvas:getWidth(), smallCanvas:getHeight())
        return
    end

    example.host:setSize(w, h)
    debugger.host:setSize(w, h)
end