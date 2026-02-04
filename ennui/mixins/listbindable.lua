---Mixin for reactive list-to-children binding.
---@class ListBindableMixin
local ListBindableMixin = {}

---Initialize list binding state. Call from the host widget's constructor.
---@param self table The widget instance
function ListBindableMixin.initListBindable(self)
    self.__listBindings = {}
end

---Bind a reactive list to child widgets.
---Idempotent: calling again with the same path updates the source and reconciles.
---@param source State|StateScope The reactive data source
---@param path string Dot-notation path to the array, relative to source
---@param config table
---@param config.key string Property name on each item to use as the unique key
---@param config.create function(data: table, index: number) → Widget Factory for new item widgets
---@param config.update function(widget: Widget, data: table, index: number)? Called to sync existing widgets
---@param config.onRemove function(widget: Widget, key: any)? Called just before a widget is removed
---@return self
function ListBindableMixin:bindChildren(source, path, config)
    config.key = config.key or "id"

    local existing = self.__listBindings[path]

    if existing then
        -- Re-bind: swap source, replace watcher, reconcile
        if existing.watcher then
            existing.watcher:unwatch()
        end
        existing.source = source
        existing.config = config

        local self_ref = self
        existing.watcher = source:watch(function()
            return source:get(path)
        end, function()
            self_ref:__reconcileList(existing)
        end)

        self:__reconcileList(existing)
        return self
    end

    local binding = {
        source = source,
        path = path,
        config = config,
        keyToWidget = {},
        watcher = nil,
    }

    local self_ref = self
    binding.watcher = source:watch(function()
        return source:get(path)
    end, function()
        self_ref:__reconcileList(binding)
    end)

    self.__listBindings[path] = binding
    self:__reconcileList(binding)

    return self
end

---Get the key -> widget map for a bound list path.
---Useful for looking up live widgets by data key (e.g. for hit-testing during drag).
---@param path string The path used in bindChildren
---@return table<any, Widget>
function ListBindableMixin:getBoundWidgets(path)
    local binding = self.__listBindings[path]
    return binding and binding.keyToWidget or {}
end

---@private
---Core reconciliation: diff current data against live widgets by key.
function ListBindableMixin:__reconcileList(binding)
    local config = binding.config
    local source = binding.source
    local keyToWidget = binding.keyToWidget
    local raw = source:getRawDeep(binding.path) or {}

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
