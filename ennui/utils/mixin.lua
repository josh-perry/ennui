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
    objectA.__mixins = objectA.__mixins or {}

    for _, objectB in ipairs({...}) do
        Mixins.shallow(objectA, objectB, false)
        objectA.__mixins[objectB] = true
    end

    return objectA
end

---Check if an object has a specific mixin applied
---@param object table The object to check
---@param mixin table The mixin to check for
---@return boolean
function Mixins.hasMixin(object, mixin)
    return object.__mixins and object.__mixins[mixin] or false
end

return Mixins