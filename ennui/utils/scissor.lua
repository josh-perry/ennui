---@class Scissor
local Scissor = {}

---Push a new scissor region, intersecting with any existing scissor
---@param x number X position of the scissor region
---@param y number Y position of the scissor region
---@param w number Width of the scissor region
---@param h number Height of the scissor region
---@return number? prevX Previous scissor X (nil if no previous scissor)
---@return number? prevY Previous scissor Y
---@return number? prevW Previous scissor width
---@return number? prevH Previous scissor height
function Scissor.push(x, y, w, h)
    local prevX, prevY, prevW, prevH = love.graphics.getScissor()

    local newX, newY, newW, newH = x, y, w, h

    if prevX then
        local right = math.min(newX + newW, prevX + prevW)
        local bottom = math.min(newY + newH, prevY + prevH)

        newX = math.max(newX, prevX)
        newY = math.max(newY, prevY)
        newW = math.max(0, right - newX)
        newH = math.max(0, bottom - newY)
    end

    love.graphics.setScissor(newX, newY, newW, newH)

    return prevX, prevY, prevW, prevH
end

---Pop the scissor region, restoring the previous state
---@param prevX number? Previous scissor X (nil if no previous scissor)
---@param prevY number? Previous scissor Y
---@param prevW number? Previous scissor width
---@param prevH number? Previous scissor height
function Scissor.pop(prevX, prevY, prevW, prevH)
    if prevX then
        assert(prevY and prevW and prevH, "All previous scissor parameters must be provided")
        love.graphics.setScissor(prevX, prevY, prevW, prevH)
    else
        love.graphics.setScissor()
    end
end

return Scissor
