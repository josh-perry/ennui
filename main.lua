local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
	require("lldebugger").start()

	function love.errorhandler(msg)
		error(msg, 2)
	end
end

love.keyboard.setTextInput(true)
love.graphics.setDefaultFilter("nearest", "nearest")

local debugger = require("ennui.debug")
local browserHost = require("examples.browser")

function love.update(dt)
    browserHost:update(dt)
    debugger.host:update(dt)
end

function love.draw()
    browserHost:draw()
    debugger.host:draw()
end

function love.mousepressed(x, y, button, isTouch)
    if debugger.host:mousepressed(x, y, button, isTouch) then
        return
    end
    browserHost:mousepressed(x, y, button, isTouch)
end

function love.mousereleased(x, y, button, isTouch)
    if debugger.host:mousereleased(x, y, button, isTouch) then
        return
    end
    browserHost:mousereleased(x, y, button, isTouch)
end

function love.mousemoved(x, y, dx, dy, isTouch)
    if debugger.host:mousemoved(x, y, dx, dy, isTouch) then
        return
    end
    browserHost:mousemoved(x, y, dx, dy, isTouch)
end

function love.wheelmoved(dx, dy)
    if debugger.host:wheelmoved(dx, dy) then
        return
    end
    browserHost:wheelmoved(dx, dy)
end

function love.keypressed(key, scancode, isRepeat)
    if key == "escape" then
        love.event.quit()
    elseif key == "f1" then
        debugger:setTargetHost(browserHost)
    end

    if debugger.host:keypressed(key, scancode, isRepeat) then
        return
    end

    browserHost:keypressed(key, scancode, isRepeat)
end

function love.keyreleased(key, scancode)
    if debugger.host:keyreleased(key, scancode) then
        return
    end
    browserHost:keyreleased(key, scancode)
end

function love.textinput(text)
    if debugger.host:textinput(text) then
        return
    end
    browserHost:textinput(text)
end

function love.resize(w, h)
    browserHost:setSize(w, h)
    debugger.host:setSize(w, h)
end
