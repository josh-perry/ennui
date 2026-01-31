---Mixin for focus management
---@class FocusableMixin
---@field focusable boolean Whether this can receive focus
---@field tabIndex number Tab order for focus navigation
local FocusableMixin = {}

local Mixin = require("ennui.utils.mixin")
local ParentableMixin = require("ennui.mixins.parentable")

---Initialize focusable fields on an instance
---Call this from the constructor of classes using this mixin
---@param self table The instance to initialize
function FocusableMixin.initFocusable(self)
    self.focusable = false
    self.tabIndex = 0
end

---Set whether widget can receive focus
---@param focusable boolean Whether widget can receive focus
---@return self
function FocusableMixin:setFocusable(focusable)
    self.focusable = focusable
    return self
end

---Get whether widget can receive focus
---@return boolean
function FocusableMixin:getFocusable()
    return self.focusable
end

---Set the tab index for focus navigation
---@param index number Tab order (lower = earlier)
---@return self
function FocusableMixin:setTabIndex(index)
    self.tabIndex = index
    return self
end

---Get the tab index
---@return number
function FocusableMixin:getTabIndex()
    return self.tabIndex
end

---Focus this widget
function FocusableMixin:focus()
    if self.focusable then
        if not Mixin.hasMixin(self, ParentableMixin) then
            return
        end

        ---@cast self ParentableMixin | FocusableMixin
        local host = self:getHost()

        if host then
            host:setFocusedWidget(self)
        end
    end
end

---Blur (unfocus) this widget
function FocusableMixin:blur()
    if not Mixin.hasMixin(self, ParentableMixin) then
        return
    end

    ---@cast self ParentableMixin | FocusableMixin
    local host = self:getHost()

    if host and host:getFocusedWidget() == self then
        host:setFocusedWidget(nil)
    end
end

---Check if this widget is focused
---@return boolean
function FocusableMixin:isFocused()
    ---@diagnostic disable-next-line: undefined-field
    if self.props then
        ---@diagnostic disable-next-line: undefined-field
        return self.props.isFocused
    end

    return false
end

return FocusableMixin
