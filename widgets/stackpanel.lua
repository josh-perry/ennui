local ennui = require("ennui")
local Widget = require("ennui.widget")

---@class StackPanel : Widget
---@operator call:StackPanel
local StackPanel = {}
StackPanel.__index = StackPanel
setmetatable(StackPanel, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

function StackPanel:__tostring()
    return "StackPanel"
end

---Create a new vertical stack panel
---@return StackPanel
function StackPanel.new()
    local self = setmetatable(Widget(), StackPanel) ---@cast self StackPanel

    self:setLayoutStrategy(ennui.Layout.Vertical())
    self:setSize("fill", "auto")

    return self
end

---Set spacing between children
---@param pixels number Spacing in pixels
---@return self
function StackPanel:setSpacing(pixels)
    if self.layoutStrategy then
        self.layoutStrategy.spacing = pixels
        self:invalidateLayout()
    end

    return self
end

---Get spacing between children
---@return number spacing
function StackPanel:getSpacing()
    return self.layoutStrategy and self.layoutStrategy.spacing or 0
end

return StackPanel
