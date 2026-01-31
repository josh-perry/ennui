---Mixin for parent/child tree management
---Optional hooks:
---  - __onAfterAddChild(child) - called after child is added
---  - __onAfterRemoveChild(child) - called after child is removed
---  - onMount() - called on child when added to tree
---  - onUnmount() - called on child when removed from tree

---@class ParentableMixin
---@field parent any Parent widget or host
---@field children any[] Child widgets
local ParentableMixin = {}

---Initialize parentable fields on an instance
---Call this from the constructor of classes using this mixin
---@param self table The instance to initialize
function ParentableMixin.initParentable(self)
    self.parent = nil
    self.children = {}
end

---Add a child to this widget
---Calls optional hooks: __onAfterAddChild (on parent), onMount (on child)
---@param child any Child to add
---@return self
function ParentableMixin:addChild(child)
    table.insert(self.children, child)
    child.parent = self

    ---@diagnostic disable-next-line: undefined-field
    if self.__onAfterAddChild then
        ---@diagnostic disable-next-line: undefined-field
        self:__onAfterAddChild(child)
    end

    if child.onMount then
        child:onMount()
    end

    return self
end

---Remove a child from this widget
---Calls optional hooks: __onAfterRemoveChild (on parent), onUnmount (on child)
---@param child any Child to remove
---@return self
function ParentableMixin:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil

            ---@diagnostic disable-next-line: undefined-field
            if self.__onAfterRemoveChild then
                ---@diagnostic disable-next-line: undefined-field
                self:__onAfterRemoveChild(child)
            end

            if child.onUnmount then
                child:onUnmount()
            end

            break
        end
    end

    return self
end

---Remove a child by index
---Calls optional hooks: __onAfterRemoveChild (on parent), onUnmount (on child)
---@param index number Index of child to remove
---@return self
function ParentableMixin:removeChildAt(index)
    local child = self.children[index]
    if child then
        table.remove(self.children, index)
        child.parent = nil

        ---@diagnostic disable-next-line: undefined-field
        if self.__onAfterRemoveChild then
            ---@diagnostic disable-next-line: undefined-field
            self:__onAfterRemoveChild(child)
        end

        if child.onUnmount then
            child:onUnmount()
        end
    end

    return self
end

---Clear all children
---Calls optional hooks: __onAfterRemoveChild (on parent), onUnmount (on each child)
---@return self
function ParentableMixin:clearChildren()
    for _, child in ipairs(self.children) do
        child.parent = nil

        ---@diagnostic disable-next-line: undefined-field
        if self.__onAfterRemoveChild then
            ---@diagnostic disable-next-line: undefined-field
            self:__onAfterRemoveChild(child)
        end

        if child.onUnmount then
            child:onUnmount()
        end
    end

    self.children = {}
    return self
end

---Get a child by index
---@param index number Index of child
---@return any? child
function ParentableMixin:getChildByIndex(index)
    return self.children[index]
end

---Get all children
---@return any[]
function ParentableMixin:getChildren()
    return self.children
end

---Get the parent
---@return any? parent
function ParentableMixin:getParent()
    return self.parent
end

---Find a descendant by ID (recursive search)
---@param id string ID to search for
---@return any? found The found child, or nil
function ParentableMixin:findById(id)
    -- TODO: move id somewhere else?

    ---@diagnostic disable-next-line: undefined-field
    if self.id == id then
        return self
    end

    for _, child in ipairs(self.children) do
        local found = child:findById(id)

        if found then
            return found
        end
    end

    return nil
end

---Build a nested tree structure of this widget and its descendants
---@return table tree { widget: any, children: table[] }
function ParentableMixin:buildDescendantTree()
    local tree = {
        widget = self,
        children = {}
    }

    for _, child in ipairs(self.children) do
        table.insert(tree.children, child:buildDescendantTree())
    end

    return tree
end

---Get the root/host by traversing up the parent chain
---@return any? host The root widget/host, or nil if no parent
function ParentableMixin:getHost()
    local current = self

    while current and current.parent do
        current = current.parent
    end

    return current
end

return ParentableMixin
