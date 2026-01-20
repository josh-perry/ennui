---@class SizeConstraint
---Size constraint definitions for widgets
local SizeConstraint = {}

-- Width cannot exceed height
SizeConstraint.widthByHeight = { type = "width_by_height" }

-- Height cannot exceed width
SizeConstraint.heightByWidth = { type = "height_by_width" }

-- Both dimensions equal the minimum of width and height
SizeConstraint.square = { type = "square" }

---Create a constraint that limits both dimensions to a maximum value
---@param value number Maximum size in pixels for both dimensions
---@return table constraint
function SizeConstraint.maxBoth(value)
    return { type = "max_both", value = value }
end

---Create an aspect ratio constraint (alternative to widget.aspectRatio)
---@param widthToHeight number Aspect ratio as width/height
---@return table constraint
function SizeConstraint.ratio(widthToHeight)
    return { type = "ratio", value = widthToHeight }
end

return SizeConstraint
