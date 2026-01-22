local ennui = require("ennui")
local Widget = require("ennui.widget")

---@class HorizontalStackPanel : Widget
local HorizontalStackPanel = {}
HorizontalStackPanel.__index = HorizontalStackPanel
setmetatable(HorizontalStackPanel, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

function HorizontalStackPanel:__tostring()
    return "HorizontalStackPanel"
end

---Create a new horizontal stack panel
---@return HorizontalStackPanel
function HorizontalStackPanel.new()
    local self = setmetatable(Widget.new(), HorizontalStackPanel) ---@cast self HorizontalStackPanel

    local strategy = ennui.Layout.Horizontal()
    self:setLayoutStrategy(strategy)

    return self
end

---Set spacing between children
---@param pixels number Spacing in pixels
---@return HorizontalStackPanel self
function HorizontalStackPanel:setSpacing(pixels)
    if self.layoutStrategy then
        self.layoutStrategy.spacing = pixels
        self:invalidateLayout()
    end
    return self
end

---Get spacing between children
---@return number spacing
function HorizontalStackPanel:getSpacing()
    return self.layoutStrategy and self.layoutStrategy.spacing or 0
end

return HorizontalStackPanel
