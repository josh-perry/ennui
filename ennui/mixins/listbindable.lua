---Mixin for reactive list-to-children binding.
---@class ListBindableMixin
local ListBindableMixin = {}

---@class ListBindingConfig
---@field key string? Property name on each item to use as the unique key (defaults to "id")
---@field create fun(data: table, index: number): Widget Factory for new item widgets
---@field update fun(widget: Widget, data: table, index: number)? Called to sync existing widgets
---@field onRemove fun(widget: Widget, key: any)? Called just before a widget is removed

---Initialize list binding state. Call from the host widget's constructor.
---@param self table The widget instance
function ListBindableMixin.initListBindable(self)
    self.__listBindings = {}
end

---Bind a reactive list to child widgets.
---Idempotent: calling again with the same EnnuiRoot updates the source and reconciles.
---@param source State|StateScope The reactive data source
---@param EnnuiRoot string Dot-notation EnnuiRoot to the array, relative to source
---@param config ListBindingConfig Configuration table for list binding
---@return self
function ListBindableMixin:bindChildren(source, EnnuiRoot, config)
    config.key = config.key or "id"

    local existing = self.__listBindings[EnnuiRoot]

    if existing then
        -- Re-bind: swap source, replace watcher, reconcile
        if existing.watcher then
            existing.watcher:unwatch()
        end

        existing.source = source
        existing.config = config

        local selfRef = self

        existing.watcher = source:watch(function()
            return source:get(EnnuiRoot)
        end, function()
            selfRef:__reconcileList(existing)
        end)

        self:__reconcileList(existing)
        return self
    end

    local binding = {
        source = source,
        EnnuiRoot = EnnuiRoot,
        config = config,
        keyToWidget = {},
        watcher = nil,
    }

    local selfRef = self
    binding.watcher = source:watch(function()
        return source:get(EnnuiRoot)
    end, function()
        selfRef:__reconcileList(binding)
    end)

    self.__listBindings[EnnuiRoot] = binding
    self:__reconcileList(binding)

    return self
end

---Alias for bindChildren.
---@param source State|StateScope The reactive data source
---@param EnnuiRoot string Dot-notation EnnuiRoot to the array, relative to source
---@param config ListBindingConfig Configuration table for list binding
---@return self
function ListBindableMixin:bindList(source, EnnuiRoot, config)
    return self:bindChildren(source, EnnuiRoot, config)
end

---Get the key -> widget map for a bound list EnnuiRoot.
---Useful for looking up live widgets by data key (e.g. for hit-testing during drag).
---@param EnnuiRoot string The EnnuiRoot used in bindChildren
---@return table<any, Widget>
function ListBindableMixin:getBoundWidgets(EnnuiRoot)
    local binding = self.__listBindings[EnnuiRoot]
    return binding and binding.keyToWidget or {}
end

---@private
---Core reconciliation: diff current data against live widgets by key.
function ListBindableMixin:__reconcileList(binding)
    local config = binding.config
    local source = binding.source
    local keyToWidget = binding.keyToWidget
    local raw = source:getRawDeep(binding.EnnuiRoot) or {}

    -- Build key -> index from current data
    local newKeys = {}
    for i, item in ipairs(raw) do
        newKeys[item[config.key]] = i
    end

    for key, widget in pairs(keyToWidget) do
        if not newKeys[key] then
            if config.onRemove then config.onRemove(widget, key) end
            self:removeChild(widget)
            keyToWidget[key] = nil
        end
    end

    local orderedWidgets = {}
    for i, item in ipairs(raw) do
        local key = item[config.key]
        local widget = keyToWidget[key]

        if not widget then
            widget = config.create(item, i)
            keyToWidget[key] = widget
            self:addChild(widget)
        elseif config.update then
            config.update(widget, item, i)
        end

        orderedWidgets[i] = widget
    end

    local boundSet = {}
    for _, w in pairs(keyToWidget) do
        boundSet[w] = true
    end

    local newChildren = {}
    for _, child in ipairs(self.children) do
        if not boundSet[child] then
            table.insert(newChildren, child)
        end
    end

    for _, widget in ipairs(orderedWidgets) do
        table.insert(newChildren, widget)
    end

    self.children = newChildren

    self:invalidateLayout()
end

---Tear down all list bindings and stop their watchers.
---Called automatically from onUnmount on containers that use this mixin.
function ListBindableMixin:cleanupListBindable()
    for _, binding in pairs(self.__listBindings) do
        if binding.watcher then
            binding.watcher:unwatch()
        end
    end

    self.__listBindings = {}
end

return ListBindableMixin
