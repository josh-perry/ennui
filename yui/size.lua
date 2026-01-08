---@alias SizeType "fixed"|"percent"|"auto"|"fill"

---@class Size
---@field type SizeType
---@field value number? Value for fixed/percent sizes
---@field weight number? Weight for fill sizes (default 1)

local Size = {}

---@param pixels number Fixed size in pixels
---@return Size
function Size.fixed(pixels)
    if type(pixels) ~= "number" then
        error(("Size.fixed expects a number, got %s"):format(type(pixels)))
    end
    if pixels ~= pixels then
        error("Size.fixed does not accept NaN")
    end
    if pixels < 0 then
        error(("Size.fixed expects non-negative number, got %s"):format(tostring(pixels)))
    end
    return {
        type = "fixed",
        value = pixels,
        weight = nil
    }
end

---@param ratio number Percentage as ratio (0.5 = 50%)
---@return Size
function Size.percent(ratio)
    if type(ratio) ~= "number" then
        error(("Size.percent expects a number, got %s"):format(type(ratio)))
    end
    if ratio ~= ratio then
        error("Size.percent does not accept NaN")
    end
    if ratio < 0 or ratio > 1 then
        error(("Size.percent expects a number between 0 and 1, got %s"):format(tostring(ratio)))
    end
    return {
        type = "percent",
        value = ratio,
        weight = nil
    }
end

---@return Size
function Size.auto()
    return {
        type = "auto",
        value = nil,
        weight = nil
    }
end

---@param weight number? Weight for distributing remaining space (default 1)
---@return Size
function Size.fill(weight)
    if weight ~= nil then
        if type(weight) ~= "number" then
            error(("Size.fill weight must be a number, got %s"):format(type(weight)))
        end
        if weight ~= weight then
            error("Size.fill weight does not accept NaN")
        end
        if weight <= 0 then
            error(("Size.fill weight must be positive, got %s"):format(tostring(weight)))
        end
    end
    return {
        type = "fill",
        value = nil,
        weight = weight or 1
    }
end

return Size
