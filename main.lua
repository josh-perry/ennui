love.keyboard.setTextInput(true)
love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")

local buttonExampleHost = require("examples.button")
local jrpgExampleHost = require("examples.jrpg")

local host = jrpgExampleHost

local smallCanvas = love.graphics.newCanvas(320, 288)
local drawToSmallCanvas = true

local function transformMouseCoords(x, y)
    if not drawToSmallCanvas then
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

function love.load()
end

function love.update(dt)
    host:update(dt)
end

function love.draw()
    if drawToSmallCanvas then
        love.graphics.setCanvas(smallCanvas)
        love.graphics.clear()
    end

    host:draw()

    love.graphics.setCanvas()

    if drawToSmallCanvas then
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
        love.graphics.draw(smallCanvas, offsetX, offsetY, 0, scale, scale)
    end
end

function love.mousepressed(x, y, button, isTouch)
    local canvasX, canvasY = transformMouseCoords(x, y)
    host:mousepressed(canvasX, canvasY, button, isTouch)
end

function love.mousereleased(x, y, button, isTouch)
    local canvasX, canvasY = transformMouseCoords(x, y)
    host:mousereleased(canvasX, canvasY, button, isTouch)
end

function love.mousemoved(x, y, dx, dy, isTouch)
    local canvasX, canvasY = transformMouseCoords(x, y)
    host:mousemoved(canvasX, canvasY, dx, dy, isTouch)
end

function love.wheelmoved(dx, dy)
    host:wheelmoved(dx, dy)
end

function love.keypressed(key, scancode, isRepeat)
    if key == "escape" then
        love.event.quit()
    end

    host:keypressed(key, scancode, isRepeat)
end

function love.keyreleased(key, scancode)
    host:keyreleased(key, scancode)
end

function love.textinput(text)
    host:textinput(text)
end

function love.resize(w, h)
    if drawToSmallCanvas then
        host:setSize(smallCanvas:getWidth(), smallCanvas:getHeight())
        return
    end

    host:setSize(w, h)
end