---Validation utilities for input checking
local Validation = {}

---Validate that a value is a number and optionally check if it's non-negative
---@param value number The value to validate
---@param name string The parameter name (for error messages)
---@param allowNegative boolean? Whether to allow negative values (default: false)
---@return boolean true if valid
function Validation.validateNumber(value, name, allowNegative)
    if value ~= value then
        error(("%s must not be NaN"):format(name))
    end

    if not allowNegative and value < 0 then
        error(("%s must be non-negative, got %s"):format(name, tostring(value)))
    end

    return true
end

---Validate that a value is a valid alignment string
---@param value string The value to validate
---@param name string The parameter name (for error messages)
---@param isHorizontal boolean Whether this is horizontal alignment (true) or vertical (false)
---@return boolean true if valid
function Validation.validateAlignment(value, name, isHorizontal)
    local valid

    if isHorizontal then
        valid = value == "left" or value == "center" or value == "right" or value == "stretch"
    else
        valid = value == "top" or value == "center" or value == "bottom" or value == "stretch"
    end

    if not valid then
        local expected = isHorizontal and '"left", "center", "right", or "stretch"'
            or '"top", "center", "bottom", or "stretch"'
        error(('%s must be %s, got "%s"'):format(name, expected, value))
    end
    return true
end

---Validate that a value is a valid size (number or Size object)
---@param value number|SizeType The value to validate
---@param name string The parameter name (for error messages)
---@return boolean true if valid
function Validation.validateSize(value, name)
    if type(value) == "number" then
        return Validation.validateNumber(value, name, false)
    end

    return true
end

return Validation
