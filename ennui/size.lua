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

---Normalize a value to a Size table
---Accepts multiple input formats for convenience:
--- - number -> Size.fixed(number)
--- - "fill" or "fill(2)" -> Size.fill() or Size.fill(2)
--- - "auto" -> Size.auto()
--- - "50%" -> Size.percent(0.5)
--- - Size table -> returned as-is
---@param value number|string|Size The value to normalize
---@return Size
function Size.normalize(value)
    if type(value) == "table" and value.type then
        return value
    end

    if type(value) == "number" then
        return Size.fixed(value)
    end

    if type(value) == "string" then
        if value == "auto" then
            return Size.auto()
        end

        if value == "fill" then
            return Size.fill()
        end

        local fillWeight = value:match("^fill%((%d+%.?%d*)%)$")
        if fillWeight then
            return Size.fill(tonumber(fillWeight))
        end

        local percent = value:match("^(%d+%.?%d*)%%$")

        if percent then
            return Size.percent(tonumber(percent) / 100)
        end

        error(("Size.normalize: unknown string format %q"):format(value))
    end

    error(("Size.normalize: expected number, string, or Size table, got %s"):format(type(value)))
end

return Size
