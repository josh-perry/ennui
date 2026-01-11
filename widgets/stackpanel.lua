local ennui = require("ennui")
local Widget = require("ennui.widget")

---@class StackPanel : Widget
local StackPanel = {}
StackPanel.__index = StackPanel
setmetatable(StackPanel, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

---Create a new vertical stack panel
---@return StackPanel
function StackPanel.new()
    local self = setmetatable(Widget(), StackPanel) ---@cast self StackPanel

    local strategy = ennui.Layout.Vertical()
    self:setLayoutStrategy(strategy)

    return self
end

---Set spacing between children
---@param pixels number Spacing in pixels
---@return StackPanel self
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
