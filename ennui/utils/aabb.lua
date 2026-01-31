--- AABB utilities
local AABB = {}

---Check if a point is inside a box
---@param pointX number X coordinate of the point
---@param pointY number Y coordinate of the point
---@param boxX number X coordinate of box top-left corner
---@param boxY number Y coordinate of box top-left corner
---@param boxWidth number Width of the box
---@param boxHeight number Height of the box
---@return boolean contained True if point is inside the box (inclusive)
function AABB.containsPoint(pointX, pointY, boxX, boxY, boxWidth, boxHeight)
    return pointX >= boxX and pointX <= boxX + boxWidth and
           pointY >= boxY and pointY <= boxY + boxHeight
end

---Check if two boxes intersect
---@param box1X number X coordinate of first box top-left corner
---@param box1Y number Y coordinate of first box top-left corner
---@param box1Width number Width of first box
---@param box1Height number Height of first box
---@param box2X number X coordinate of second box top-left corner
---@param box2Y number Y coordinate of second box top-left corner
---@param box2Width number Width of second box
---@param box2Height number Height of second box
---@return boolean intersects True if the boxes overlap
function AABB.intersects(box1X, box1Y, box1Width, box1Height, box2X, box2Y, box2Width, box2Height)
    return box1X < box2X + box2Width and
           box1X + box1Width > box2X and
           box1Y < box2Y + box2Height and
           box1Y + box1Height > box2Y
end

---Check if one box fully contains another
---@param outerX number X coordinate of outer box top-left corner
---@param outerY number Y coordinate of outer box top-left corner
---@param outerWidth number Width of outer box
---@param outerHeight number Height of outer box
---@param innerX number X coordinate of inner box top-left corner
---@param innerY number Y coordinate of inner box top-left corner
---@param innerWidth number Width of inner box
---@param innerHeight number Height of inner box
---@return boolean contains True if outer box fully contains inner box
function AABB.contains(outerX, outerY, outerWidth, outerHeight, innerX, innerY, innerWidth, innerHeight)
    return innerX >= outerX and
           innerY >= outerY and
           innerX + innerWidth <= outerX + outerWidth and
           innerY + innerHeight <= outerY + outerHeight
end

return AABB
