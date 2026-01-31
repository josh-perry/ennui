---Mixin for layout-related properties and behavior
---Expects the consuming class to implement:
---  - invalidateLayout()
---  - invalidateRender()
---@class LayoutableMixin
---@field preferredWidth number|Size Preferred width specification
---@field preferredHeight number|Size Preferred height specification
---@field desiredWidth number Measured desired width in pixels
---@field desiredHeight number Measured desired height in pixels
---@field minWidth number? Minimum width constraint
---@field maxWidth number? Maximum width constraint
---@field minHeight number? Minimum height constraint
---@field maxHeight number? Maximum height constraint
---@field aspectRatio number? Aspect ratio constraint (width/height)
---@field sizeConstraint table? Size constraint specification
---@field padding Padding Padding around content
---@field margin Margin Margin around widget
---@field horizontalAlignment "left"|"center"|"right"|"stretch" Horizontal alignment
---@field verticalAlignment "top"|"center"|"bottom"|"stretch" Vertical alignment
local LayoutableMixin = {}
local Size = require("ennui.size")
local Mixin = require("ennui.utils.mixin")
local ParentableMixin = require("ennui.mixins.parentable")
local PositionableMixin = require("ennui.mixins.positionable")

---Initialize layoutable fields on an instance
---Call this from the constructor of classes using this mixin
---@param self table The instance to initialize
function LayoutableMixin.initLayoutable(self)
    self.desiredWidth = 0
    self.desiredHeight = 0

    self.preferredWidth = Size.auto()
    self.preferredHeight = Size.auto()
    self.minWidth = nil
    self.maxWidth = nil
    self.minHeight = nil
    self.maxHeight = nil
    self.aspectRatio = nil
    self.sizeConstraint = nil
    self.padding = { top = 0, right = 0, bottom = 0, left = 0 }
    self.margin = { top = 0, right = 0, bottom = 0, left = 0 }
    self.horizontalAlignment = "stretch"
    self.verticalAlignment = "stretch"
end

---Set size (preferred width and height)
---@generic T
---@param self T
---@param width number|string|Size Preferred width specification
---@param height number|string|Size Preferred height specification
---@return T
function LayoutableMixin:setSize(width, height)
    ---@cast self LayoutableMixin
    self:setPreferredWidth(width)
    self:setPreferredHeight(height)
    return self
end

---Set preferred width
---@param width number|string|Size Preferred width specification
---@return self
function LayoutableMixin:setPreferredWidth(width)
    self.preferredWidth = Size.normalise(width)
    self:tryInvalidateLayout()
    return self
end

---Set preferred height
---@param height number|string|Size Preferred height specification
---@return self
function LayoutableMixin:setPreferredHeight(height)
    self.preferredHeight = Size.normalise(height)
    self:tryInvalidateLayout()
    return self
end

---Set width (alias for setPreferredWidth)
---@param width number|string|Size Preferred width specification
---@return self
function LayoutableMixin:setWidth(width)
    return self:setPreferredWidth(width)
end

---Set height (alias for setPreferredHeight)
---@param height number|string|Size Preferred height specification
---@return self
function LayoutableMixin:setHeight(height)
    return self:setPreferredHeight(height)
end

---Set padding
---@generic T
---@param self T
---@param top number Top padding (or all sides if only argument)
---@param right number? Right padding (or horizontal if 2 args)
---@param bottom number? Bottom padding
---@param left number? Left padding
---@return T
function LayoutableMixin:setPadding(top, right, bottom, left)
    ---@cast self LayoutableMixin
    if not right then
        -- 1 arg: all sides
        self.padding.top = top
        self.padding.right = top
        self.padding.bottom = top
        self.padding.left = top
    elseif not bottom then
        -- 2 args: vertical, horizontal
        self.padding.top = top
        self.padding.right = right
        self.padding.bottom = top
        self.padding.left = right
    elseif left then
        -- 4 args: top, right, bottom, left
        self.padding.top = top
        self.padding.right = right
        self.padding.bottom = bottom
        self.padding.left = left
    else
        error("setPadding requires 1, 2, or 4 arguments")
    end

    self:tryInvalidateLayout()
    return self
end

---Set margin
---@param top number Top margin (or all sides if only argument)
---@param right number? Right margin (or horizontal if 2 args)
---@param bottom number? Bottom margin
---@param left number? Left margin
---@return self
function LayoutableMixin:setMargin(top, right, bottom, left)
    if not right then
        -- 1 arg: all sides
        self.margin.top = top
        self.margin.right = top
        self.margin.bottom = top
        self.margin.left = top
    elseif not bottom then
        -- 2 args: vertical, horizontal
        self.margin.top = top
        self.margin.right = right
        self.margin.bottom = top
        self.margin.left = right
    elseif left then
        -- 4 args: top, right, bottom, left
        self.margin.top = top
        self.margin.right = right
        self.margin.bottom = bottom
        self.margin.left = left
    else
        error("setMargin requires 1, 2, or 4 arguments")
    end

    self:tryInvalidateLayout()
    return self
end

---Set minimum width
---@param width number Minimum width in pixels
---@return self
function LayoutableMixin:setMinWidth(width)
    self.minWidth = width
    self:tryInvalidateLayout()
    return self
end

---Set maximum width
---@param width number Maximum width in pixels
---@return self
function LayoutableMixin:setMaxWidth(width)
    self.maxWidth = width
    self:tryInvalidateLayout()
    return self
end

---Set minimum height
---@param height number Minimum height in pixels
---@return self
function LayoutableMixin:setMinHeight(height)
    self.minHeight = height
    self:tryInvalidateLayout()
    return self
end

---Set maximum height
---@param height number Maximum height in pixels
---@return self
function LayoutableMixin:setMaxHeight(height)
    self.maxHeight = height
    self:tryInvalidateLayout()
    return self
end

---Set aspect ratio
---@param ratio number Aspect ratio
---@return self
function LayoutableMixin:setAspectRatio(ratio)
    self.aspectRatio = ratio
    self:tryInvalidateLayout()
    return self
end

---Set size constraint
---@param constraint table Size constraint specification
---@return self
function LayoutableMixin:setSizeConstraint(constraint)
    self.sizeConstraint = constraint
    self:tryInvalidateLayout()
    return self
end

---Set horizontal alignment
---@param alignment "left"|"center"|"right"|"stretch" Horizontal alignment
---@return self
function LayoutableMixin:setHorizontalAlignment(alignment)
    self.horizontalAlignment = alignment
    self:tryInvalidateLayout()
    return self
end

---Set vertical alignment
---@param alignment "top"|"center"|"bottom"|"stretch" Vertical alignment
---@return self
function LayoutableMixin:setVerticalAlignment(alignment)
    self.verticalAlignment = alignment
    self:tryInvalidateLayout()
    return self
end

---Get padding
---@return table padding
function LayoutableMixin:getPadding()
    return {
        top = self.padding.top,
        right = self.padding.right,
        bottom = self.padding.bottom,
        left = self.padding.left
    }
end

---Get margin
---@return table margin
function LayoutableMixin:getMargin()
    return {
        top = self.margin.top,
        right = self.margin.right,
        bottom = self.margin.bottom,
        left = self.margin.left
    }
end

---Get horizontal alignment
---@return string alignment
function LayoutableMixin:getHorizontalAlignment()
    return self.horizontalAlignment
end

---Get vertical alignment
---@return string alignment
function LayoutableMixin:getVerticalAlignment()
    return self.verticalAlignment
end

---Calculate desired width based on available width
---@param availableWidth number Available width
---@return number desiredWidth
function LayoutableMixin:calculateDesiredWidth(availableWidth)
    local width = self.preferredWidth

    if type(width) == "number" then
        return width
    else
        if width.type == "fixed" then
            return width.value
        elseif width.type == "percent" then
            return availableWidth * width.value
        elseif width.type == "auto" then
            return self:__calculateContentWidth()
        elseif width.type == "fill" then
            return availableWidth
        end
    end

    return 100
end

---Calculate desired height based on available height
---@param availableHeight number Available height
---@return number desiredHeight
function LayoutableMixin:calculateDesiredHeight(availableHeight)
    local height = self.preferredHeight
    if type(height) == "number" then
        return height
    else
        if height.type == "fixed" then
            return height.value
        elseif height.type == "percent" then
            return availableHeight * height.value
        elseif height.type == "auto" then
            return self:__calculateContentHeight()
        elseif height.type == "fill" then
            return availableHeight
        end
    end

    return 100
end

---Apply size constraints
---@protected
---@param desiredWidth number? Desired width before constraints
---@param desiredHeight number? Desired height before constraints
---@return number constrainedWidth, number constrainedHeight
function LayoutableMixin:__applyConstraints(desiredWidth, desiredHeight)
    if self.minWidth and self.minWidth > 0 then
        desiredWidth = math.max(self.minWidth, desiredWidth)
    end

    if self.maxWidth and self.maxWidth > 0 then
        desiredWidth = math.min(self.maxWidth, desiredWidth)
    end

    if self.minHeight and self.minHeight > 0 then
        desiredHeight = math.max(self.minHeight, desiredHeight)
    end

    if self.maxHeight and self.maxHeight > 0 then
        desiredHeight = math.min(self.maxHeight, desiredHeight)
    end

    if self.sizeConstraint then
        local c = self.sizeConstraint

        if not c then
            ---@diagnostic disable-next-line: return-type-mismatch
            return desiredWidth, desiredHeight
        end

        if c.type == "width_by_height" then
            ---@diagnostic disable-next-line: param-type-mismatch
            desiredWidth = math.min(desiredWidth, desiredHeight)
        elseif c.type == "height_by_width" then
            ---@diagnostic disable-next-line: param-type-mismatch
            desiredHeight = math.min(desiredHeight, desiredWidth)
        elseif c.type == "square" then
            ---@diagnostic disable-next-line: param-type-mismatch
            local minDim = math.min(desiredWidth, desiredHeight)
            desiredWidth = minDim
            desiredHeight = minDim
        elseif c.type == "max_both" then
            ---@diagnostic disable-next-line: param-type-mismatch
            desiredWidth = math.min(desiredWidth, c.value)

            ---@diagnostic disable-next-line: param-type-mismatch
            desiredHeight = math.min(desiredHeight, c.value)
        elseif c.type == "ratio" then
            local ratioWidth = desiredHeight * c.value
            local ratioHeight = desiredWidth / c.value
            if ratioWidth <= desiredWidth then
                desiredWidth = ratioWidth
            else
                desiredHeight = ratioHeight
            end
        end
    end

    if self.aspectRatio then
        local ratioWidth = desiredHeight * self.aspectRatio
        local ratioHeight = desiredWidth / self.aspectRatio

        if ratioWidth <= desiredWidth then
            desiredWidth = ratioWidth
        else
            desiredHeight = ratioHeight
        end
    end

    assert(desiredWidth, "Desired width not defined after constraints")
    assert(desiredHeight, "Desired height not defined after constraints")

    return desiredWidth, desiredHeight
end

---Calculate content width (override in consuming class if needed)
---@protected
---@return number contentWidth
function LayoutableMixin:__calculateContentWidth()
    -- Default implementation for classes with children
    if not Mixin.hasMixin(self, ParentableMixin) then
        return self.padding.left + self.padding.right
    end

    ---@cast self LayoutableMixin | ParentableMixin

    local maxWidth = 0
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            maxWidth = math.max(maxWidth, child.desiredWidth)
        end
    end
    return maxWidth + self.padding.left + self.padding.right
end

---Calculate content height (override in consuming class if needed)
---@protected
---@return number contentHeight
function LayoutableMixin:__calculateContentHeight()
    -- Default implementation for classes with children
    if not Mixin.hasMixin(self, ParentableMixin) then
        return self.padding.top + self.padding.bottom
    end

    ---@cast self LayoutableMixin | ParentableMixin

    local maxHeight = 0
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            maxHeight = math.max(maxHeight, child.desiredHeight)
        end
    end
    return maxHeight + self.padding.top + self.padding.bottom
end

---Get the content bounds (area inside padding)
---Requires PositionableMixin (x, y, width, height)
---@protected
---@return number contentX, number contentY, number contentWidth, number contentHeight
function LayoutableMixin:__getContentBounds()
    if not Mixin.hasMixin(self, PositionableMixin) then
        error("LayoutableMixin:__getContentBounds requires PositionableMixin")
    end

    ---@cast self LayoutableMixin | PositionableMixin
    return self.x + self.padding.left,
           self.y + self.padding.top,
           self.width - self.padding.left - self.padding.right,
           self.height - self.padding.top - self.padding.bottom
end

---Calculate Y position to vertically center an element within content bounds
---Requires PositionableMixin (x, y, width, height)
---@protected
---@param elementHeight number Height of the element to center
---@return number centerY The Y position that centers the element
function LayoutableMixin:__centerVertically(elementHeight)
    local contentX, contentY, contentW, contentH = self:__getContentBounds()
    return contentY + (contentH - elementHeight) / 2
end

function LayoutableMixin:tryInvalidateLayout()
    ---@diagnostic disable-next-line: undefined-field
    if self.invalidateLayout then
        ---@diagnostic disable-next-line: undefined-field
        self:invalidateLayout()
    end
end

return LayoutableMixin
