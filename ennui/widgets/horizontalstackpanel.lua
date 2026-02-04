local Widget = require("ennui.widget")
local HorizontalLayout = require("ennui.layout.horizontal_layout_strategy")
local Mixin = require("ennui.utils.mixin")
local ListBindableMixin = require("ennui.mixins.listbindable")

---@class HorizontalStackPanel : Widget, ListBindableMixin
---@operator call:HorizontalStackPanel
local HorizontalStackPanel = {}
HorizontalStackPanel.__index = HorizontalStackPanel
setmetatable(HorizontalStackPanel, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

Mixin.extend(HorizontalStackPanel, ListBindableMixin)

function HorizontalStackPanel:__tostring()
    return "HorizontalStackPanel"
end

---Create a new horizontal stack panel
---@return HorizontalStackPanel
function HorizontalStackPanel.new()
    local self = setmetatable(Widget.new(), HorizontalStackPanel) ---@cast self HorizontalStackPanel

    self:setLayoutStrategy(HorizontalLayout())
    self:setSize("auto", "fill")
    self:initListBindable()

    return self
end

---Set spacing between children
---@param pixels number Spacing in pixels
---@return self
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

function HorizontalStackPanel:onUnmount()
    self:cleanupListBindable()
    Widget.onUnmount(self)
end

return HorizontalStackPanel
