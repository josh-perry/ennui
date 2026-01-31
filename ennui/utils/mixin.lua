---@class util.Mixin
local Mixins = {}

function Mixins.shallow(objectA, objectB, replace)
    for k, v in pairs(objectB) do
        if objectA[k] == nil or replace then
            objectA[k] = v
        end
    end

    return objectA
end

function Mixins.extend(objectA, ...)
    for _, objectB in ipairs({...}) do
        Mixins.shallow(objectA, objectB, false)
    end

    return objectA
end

return Mixins