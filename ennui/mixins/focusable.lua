---Mixin for focus management
---@class FocusableMixin
---@field focusable boolean Whether this can receive focus
---@field tabIndex number Tab order for focus navigation
local FocusableMixin = {}

---Initialize focusable fields on an instance
---Call this from the constructor of classes using this mixin
---@param self table The instance to initialize
function FocusableMixin.initFocusable(self)
    self.focusable = false
    self.tabIndex = 0
end

---Set whether widget can receive focus
---@generic T
---@param self T
---@param focusable boolean Whether widget can receive focus
---@return T
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
---@generic T
---@param self T
---@param index number Tab order (lower = earlier)
---@return T
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
        local host = self:__getHost()

        if host then
            host:setFocusedWidget(self)
        end
    end
end

---Blur (unfocus) this widget
function FocusableMixin:blur()
    local host = self:__getHost()

    if host and host:getFocusedWidget() == self then
        host:setFocusedWidget(nil)
    end
end

---Check if this widget is focused
---@return boolean
function FocusableMixin:isFocused()
    return self.state.isFocused
end

return FocusableMixin
