love.keyboard.setTextInput(true)
love.graphics.setDefaultFilter("nearest", "nearest")

local debugger = require("ennui.debug")
local examples = require("examples")

local exampleIndex = 1

local smallCanvas = love.graphics.newCanvas(320, 288)
local smallCanvasExamples = {
    [examples[2]] = true
}

local function transformMouseCoords(x, y)
    if not examples[exampleIndex].smallCanvas then
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

local function setExample(example)
    debugger:setTargetHost(example.host)

    if example.smallCanvas then
        example.host:setSize(smallCanvas:getWidth(), smallCanvas:getHeight())
    else
        local w, h = love.graphics.getDimensions()
        example.host:setSize(w, h)
        debugger.host:setSize(w, h)
    end
end

function love.update(dt)
    local example = examples[exampleIndex]

    example.host:update(dt)
    debugger.host:update(dt)
end

function love.draw()
    local example = examples[exampleIndex]

    if example.smallCanvas then
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

    if example.smallCanvas then
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

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(("Example: %s"):format(example.name), 10, 10, love.graphics.getWidth() - 20, "right")

    love.graphics.printf("FPS: " .. tostring(love.timer.getFPS()), 10, 10, love.graphics.getWidth() - 20, "left")
    love.graphics.printf("dt: " .. string.format("%.3f ms", love.timer.getDelta() * 1000), 10, 30, love.graphics.getWidth() - 20, "left")
    love.graphics.printf("Memory: " .. string.format("%.2f MB", collectgarbage("count") / 1024), 10, 50, love.graphics.getWidth() - 20, "left")
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
    elseif key == "f5" then
        exampleIndex = exampleIndex + 1

        if exampleIndex > #examples then
            exampleIndex = 1
        end

        setExample(examples[exampleIndex])
    elseif key == "f4" then
        exampleIndex = exampleIndex - 1

        if exampleIndex < 1 then
            exampleIndex = #examples
        end

        setExample(examples[exampleIndex])
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

    if example.smallCanvas then
        example.host:setSize(smallCanvas:getWidth(), smallCanvas:getHeight())
        return
    end

    example.host:setSize(w, h)
    debugger.host:setSize(w, h)
end