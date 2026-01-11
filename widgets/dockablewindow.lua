local Window = require("widgets.window")
local DockSpace = require("ennui.docking.dockspace")
local Size = require("ennui.size")

---@class DockableWindow : Window
---@field isDockable boolean Whether this can be docked
---@field dockSpace DockSpace? Target dock space (external, for docking this window into)
---@field floatingBounds table Saved bounds when undocked {x, y, width, height}
---@field dockPreviewZone table? Current preview zone during drag
---@field dockPreviewTarget DockSpace? The dock space that owns the current preview zone
---@field internalDockSpace DockSpace Internal dock space for hosting docked content
local DockableWindow = setmetatable({}, Window)
DockableWindow.__index = DockableWindow
setmetatable(DockableWindow, {
    __index = Window,
    __call = function(class, ...)
        return class.new(...)
    end
})

---Creates a new DockableWindow
---@return DockableWindow
function DockableWindow.new()
    local self = setmetatable(Window.new(), DockableWindow)

    self:addProperty("isDockable", true)
    self.dockSpace = nil
    self.floatingBounds = {x = self.x, y = self.y, width = self.width, height = self.height}
    self.dockPreviewZone = nil
    self.dockPreviewTarget = nil

    self.internalDockSpace = DockSpace.new()
    self.internalDockSpace:setSize(Size.fill(), Size.fill())
    self.internalDockSpace.isDockable = true

    self:watch("isDocked", function(newValue)
        self.internalDockSpace.isDockable = not newValue
        self:setTitleBarVisibility(not newValue)
    end)

    self.onDrag = function(event)
        if self.dockSpace then
            local zone, targetDockSpace = self.dockSpace:getDropZoneAtPoint(event.x, event.y)

            if zone and targetDockSpace then
                if self.dockPreviewZone ~= zone or self.dockPreviewTarget ~= targetDockSpace then
                    if self.dockPreviewTarget and self.dockPreviewTarget ~= targetDockSpace then
                        self.dockPreviewTarget:hideZonePreview()
                    end
                    
                    self.dockPreviewZone = zone
                    self.dockPreviewTarget = targetDockSpace
                    targetDockSpace:showZonePreview(zone)
                end
            else
                if self.dockPreviewZone then
                    if self.dockPreviewTarget then
                        self.dockPreviewTarget:hideZonePreview()
                    end
                    self.dockPreviewZone = nil
                    self.dockPreviewTarget = nil
                end
            end
        end
    end

    self.onDragEnd = function(event)
        if self.dockPreviewZone and self.dockPreviewTarget then
            self:dockInto(self.dockPreviewTarget, self.dockPreviewZone)
            self.dockPreviewTarget:hideZonePreview()
            self.dockPreviewZone = nil
            self.dockPreviewTarget = nil
        elseif not self.props.isDocked then
            self:bringToFront()
        end

        if self.dockPreviewTarget then
            self.dockPreviewTarget:hideZonePreview()
            self.dockPreviewZone = nil
            self.dockPreviewTarget = nil
        end
    end

    return self
end

---Set whether this window is dockable
---@param dockable boolean
---@return self
function DockableWindow:setDockable(dockable)
    self.props.isDockable = dockable
    return self
end

---Set the target dock space (external, for docking this window into another dock space)
---@param dockSpace DockSpace
---@return self
function DockableWindow:setDockSpace(dockSpace)
    self.dockSpace = dockSpace
    return self
end

---Get the internal dock space (for docking widgets within this window)
---@return DockSpace
function DockableWindow:getInternalDockSpace()
    return self.internalDockSpace
end

---Dock a widget into this window's internal dock space
---@param widget Widget Widget to dock
---@param zone table? Optional drop zone, if nil docks to center
---@return boolean success
function DockableWindow:dockWidget(widget, zone)
    if not zone then
        self.internalDockSpace.dockTree:addWidget(widget, true)
        self.internalDockSpace:invalidateLayout()
        return true
    end
    return self.internalDockSpace:dock(widget, zone)
end

---Dock this window into a specific dock space at a zone
---@param targetDockSpace DockSpace The dock space to dock into
---@param zone table Drop zone {type, bounds, targetNode, previewBounds}
---@return boolean success
function DockableWindow:dockInto(targetDockSpace, zone)
    if not self.props.isDockable then
        return false
    end

    self.floatingBounds = {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height
    }

    if self.parent then
        self.parent:removeChild(self)
    end

    targetDockSpace:addChild(self)

    self:setVisible(true)

    local success = targetDockSpace:dock(self, zone)

    if success then
        self.props.isDocked = true
        self:setTitleBarVisibility(false)
    end

    return success
end

---Dock this window to a zone in the external dock space (legacy method)
---@param zone table Drop zone {type, bounds, targetNode, previewBounds}
---@return boolean success
function DockableWindow:dock(zone)
    if not self.dockSpace then
        return false
    end
    return self:dockInto(self.dockSpace, zone)
end

---Undock this window and restore floating state
---@return boolean success
function DockableWindow:undock()
    if not self.props.isDocked or not self.dockSpace then
        return false
    end

    if self.width and self.height and self.width > 50 and self.height > 50 then
        self.floatingBounds.width = self.width
        self.floatingBounds.height = self.height
    end

    if self.floatingBounds.width < 200 then
        self.floatingBounds.width = 300
    end

    if self.floatingBounds.height < 150 then
        self.floatingBounds.height = 250
    end

    local success = self.dockSpace:undock(self)

    if success then
        self:setTitleBarVisibility(true)

        self:setPosition(self.floatingBounds.x, self.floatingBounds.y)
        self:setSize(self.floatingBounds.width, self.floatingBounds.height)
        self.props.isDocked = false

        if self.parent then
            self.parent:removeChild(self)
        end

        if self.dockSpace.parent then
            self.dockSpace.parent:addChild(self)
        end
    end

    return success
end

---Set titlebar visibility
---@param visible boolean
---@return self
function DockableWindow:setTitleBarVisibility(visible)
    self.props.showTitleBar = visible

    if visible then
        local titleBarHeight = self.props.titleBarHeight or 30
        self:setDraggable(true)
        self:setDragHandle({x = 0, y = 0, width = 0, height = titleBarHeight})
    else
        self:setDraggable(false)
    end

    self:invalidateLayout()
    return self
end

---Override setContent to add content to internal dock space instead
---@param content Widget
---@return self
function DockableWindow:setContent(content)
    self.internalDockSpace.dockTree:addWidget(content, false)
    Window.setContent(self, self.internalDockSpace)
    
    return self
end

---Get the host widget
---@return Host?
function DockableWindow:__getHost()
    local current = self
    while current.parent do
        current = current.parent
    end

    if current.focusedWidget then
        return current
    end

    return nil
end

return DockableWindow
