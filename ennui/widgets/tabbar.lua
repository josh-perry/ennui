local Widget = require("ennui.widget")

---@class Tab
---@field title string Tab title
---@field widget Widget Associated widget

---@class TabBar : Widget
---@field tabs Tab[] Array of tabs
---@field activeIndex number Currently active tab (1-based)
---@field height number Tab bar height
---@field showCloseButtons boolean Whether to show close buttons
---@field onTabChanged function? Callback when tab changes
---@field onTabClosed function? Callback when tab closed
---@field hoveredTabIndex number? Currently hovered tab
---@field draggedTabIndex number? Currently dragged tab
---@field isDraggingTab boolean Whether currently dragging a tab
local TabBar = setmetatable({}, Widget)
TabBar.__index = TabBar
setmetatable(TabBar, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end
})

---Creates a new TabBar
---@return TabBar
function TabBar.new()
    local self = setmetatable(Widget.new(), TabBar)

    self.tabs = {}
    self.activeIndex = 1
    self.height = 30

    self:addProperty("backgroundColor", {0.2, 0.2, 0.2})
    self:addProperty("activeTabColor", {0.3, 0.5, 0.8})
    self:addProperty("inactiveTabColor", {0.25, 0.25, 0.25})
    self:addProperty("hoverTabColor", {0.35, 0.35, 0.35})
    self:addProperty("textColor", {1, 1, 1})
    self:addProperty("closeButtonSize", 14)
    self:addProperty("canDragTabs", false)
    self:addProperty("tabBarHeight", 30)
    self:addProperty("activeIndex", 1)
    self:addProperty("showCloseButtons", false)

    self.onTabChanged = nil
    self.onTabClosed = nil
    self.hoveredTabIndex = nil
    self.draggedTabIndex = nil
    self.isDraggingTab = false

    return self
end

---Add a new tab
---@param title string Tab title
---@param widget Widget Associated widget
---@return self
function TabBar:addTab(title, widget)
    for _, tab in ipairs(self.tabs) do
        if tab.widget == widget then
            return self
        end
    end

    table.insert(self.tabs, {title = title, widget = widget})
    
    -- Add the widget as a child so it gets rendered
    self:addChild(widget)
    
    -- Hide it if it's not the active tab
    if #self.tabs ~= self.activeIndex then
        widget:setVisible(false)
    end
    
    self:invalidateRender()
    return self
end

---Clear all tabs
---@return self
function TabBar:clearTabs()
    if self.isDraggingTab then
        self.draggedTabIndex = nil
        self.isDraggingTab = false
        self._draggedWidget = nil
    end

    self.tabs = {}
    self.activeIndex = 1
    self:invalidateRender()
    return self
end

---Remove a tab by index
---@param index number Tab index (1-based)
---@return self
function TabBar:removeTab(index)
    if index < 1 or index > #self.tabs then
        return self
    end

    local closedTab = self.tabs[index]
    table.remove(self.tabs, index)

    if self.activeIndex > #self.tabs then
        self.activeIndex = math.max(1, #self.tabs)
    end

    self:invalidateRender()

    if self.onTabClosed then
        self.onTabClosed(index, closedTab.widget)
    end

    return self
end

---Set the active tab
---@param index number Tab index (1-based)
---@return self
function TabBar:setActiveTab(index)
    if index < 1 or index > #self.tabs then
        return self
    end

    self.activeIndex = index
    
    -- Update visibility of all tab content widgets
    for i, tab in ipairs(self.tabs) do
        if tab.widget then
            tab.widget:setVisible(i == index)
        end
    end
    
    self:invalidateLayout()
    self:invalidateRender()

    if self.onTabChanged then
        self.onTabChanged(index)
    end

    return self
end

---Get tab at point (for hit testing)
---@param x number
---@param y number
---@return number? Tab index
function TabBar:getTabAtPoint(x, y)
    -- Only check within the tab bar header area, not the full height
    if y < self.y or y > self.y + self.tabBarHeight or
       x < self.x or x > self.x + self.width then
        return nil
    end

    local tabX = self.x
    for i, tab in ipairs(self.tabs) do
        local tabWidth = self:calculateTabWidth(i)
        if x >= tabX and x < tabX + tabWidth then
            return i
        end
        tabX = tabX + tabWidth
    end

    return nil
end

---Calculate width of a tab
---@param index number Tab index
---@return number Tab width
function TabBar:calculateTabWidth(index)
    if #self.tabs == 0 then
        return 0
    end

    local minTabWidth = 80
    local maxTabWidth = 200
    local totalAvailable = self.width

    local idealWidth = totalAvailable / #self.tabs
    local tabWidth = math.min(maxTabWidth, math.max(minTabWidth, idealWidth))

    return tabWidth
end

---Handle mouse moved
---@param event MouseEvent
function TabBar:onMouseMoved(event)
    local tabIndex = self:getTabAtPoint(event.x, event.y)

    if tabIndex ~= self.hoveredTabIndex then
        self.hoveredTabIndex = tabIndex
        self:invalidateRender()
    end

    if not self.props.canDragTabs then
        return
    end

    if self.draggedTabIndex and not self.isDraggingTab then
        self.isDraggingTab = true
        local widget = self.tabs[self.draggedTabIndex].widget
        if widget then
            self._draggedWidget = widget
            self._draggedTabIndex = self.draggedTabIndex

            if widget.undock and widget.props.isDocked then
                widget:undock()
            end

            if not widget.isDraggable then
                widget:setDraggable(true)
            end

            if widget.isDraggable then
                local host = widget.parent
                while host and host.parent do
                    host = host.parent
                end

                if host and type(host.__initDrag) == "function" then
                    if type(host.__ensureLayout) == "function" then
                        host:__ensureLayout()
                    end

                    local titleBarHeight = widget.props and widget.props.titleBarHeight or 30
                    widget:setPosition(event.x - 30, event.y - titleBarHeight / 2)

                    host:__initDrag(widget, event.x, event.y, 1)
                    host.__dragStarted = true
                end
            end
        end
    end
end

---Handle mouse exited
---@param event MouseEvent
function TabBar:onMouseExited(event)
    if self.hoveredTabIndex then
        self.hoveredTabIndex = nil
        self:invalidateRender()
    end

    self.draggedTabIndex = nil
    self.isDraggingTab = false
    self._draggedWidget = nil
end

---Handle mouse pressed
---@param event MouseEvent
function TabBar:onMousePressed(event)
    local tabIndex = self:getTabAtPoint(event.x, event.y)
    if not tabIndex then
        return
    end

    if self.showCloseButtons and self.hoveredTabIndex == tabIndex then
        local closeButtonX = self:calculateTabCloseButtonPosition(tabIndex)
        if math.abs(event.x - closeButtonX) < self.props.closeButtonSize then
            self:removeTab(tabIndex)
            event:consume()
            return
        end
    end

    self.draggedTabIndex = tabIndex
    self.isDraggingTab = false

    self:setActiveTab(tabIndex)
    event:consume()
end

---Handle mouse released
---@param event MouseEvent
function TabBar:onMouseReleased(event)
    self.draggedTabIndex = nil
    self.isDraggingTab = false
    self._draggedWidget = nil
end

---Calculate close button position for a tab
---@param index number Tab index
---@return number Close button X position
function TabBar:calculateTabCloseButtonPosition(index)
    local tabX = self.x
    for i = 1, index - 1 do
        tabX = tabX + self:calculateTabWidth(i)
    end

    local tabWidth = self:calculateTabWidth(index)
    return tabX + tabWidth - 10 - self.props.closeButtonSize / 2
end

---Measure the tab bar
---@param availableWidth number
---@param availableHeight number
---@return number, number
function TabBar:measure(availableWidth, availableHeight)
    -- Tab bar needs the full available height: 30px for the bar + remaining for content
    local contentHeight = availableHeight - self.height
    
    -- Measure the active tab's content if it exists
    if #self.tabs > 0 and self.activeIndex >= 1 and self.activeIndex <= #self.tabs then
        local activeTab = self.tabs[self.activeIndex]
        if activeTab and activeTab.widget then
            activeTab.widget:measure(availableWidth, contentHeight)
        end
    end
    
    return availableWidth, availableHeight
end

---Arrange children (position active tab content)
---@param contentX number
---@param contentY number
---@param contentWidth number
---@param contentHeight number
function TabBar:arrangeChildren(contentX, contentY, contentWidth, contentHeight)
    -- Position the active tab's content widget below the tab bar
    if #self.tabs > 0 and self.activeIndex >= 1 and self.activeIndex <= #self.tabs then
        local activeTab = self.tabs[self.activeIndex]
        if activeTab and activeTab.widget then
            -- Content starts below the tab bar header (use tabBarHeight, not self.height)
            local tabContentY = self.y + self.tabBarHeight
            -- Available height is what's left after the tab bar header
            local tabContentHeight = self.height - self.tabBarHeight
            
            -- Hide all inactive tabs and show/arrange only the active one
            for i, tab in ipairs(self.tabs) do
                if i == self.activeIndex then
                    tab.widget:setVisible(true)
                    tab.widget:arrange(self.x, tabContentY, self.width, tabContentHeight)
                else
                    tab.widget:setVisible(false)
                end
            end
        end
    end
end

---Render the tab bar
function TabBar:onRender()
    -- Only draw the tab bar header, not the full height
    love.graphics.setColor(self.props.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.tabBarHeight)

    local tabX = self.x
    for i, tab in ipairs(self.tabs) do
        local tabWidth = self:calculateTabWidth(i)
        local isActive = (i == self.activeIndex)
        local isHovered = (i == self.hoveredTabIndex)

        local color
        if isActive then
            color = self.props.activeTabColor
        elseif isHovered then
            color = self.props.hoverTabColor
        else
            color = self.props.inactiveTabColor
        end

        love.graphics.setColor(color)
        love.graphics.rectangle("fill", tabX, self.y, tabWidth, self.tabBarHeight)

        love.graphics.setColor(self.props.textColor)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(tab.title)
        local textX = tabX + math.max(8, (tabWidth - textWidth) / 2)
        local textY = self.y + (self.tabBarHeight - font:getHeight()) / 2
        love.graphics.print(tab.title, textX, textY)

        if self.showCloseButtons and isHovered and #self.tabs > 1 then
            self:drawCloseButton(
                self:calculateTabCloseButtonPosition(i),
                self.y + self.tabBarHeight / 2,
                self.props.closeButtonSize
            )
        end

        tabX = tabX + tabWidth
    end

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.tabBarHeight)
    
    -- Render child widgets (the tab content)
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            child:onRender()
        end
    end
end

---Draw a close button
---@param x number Center X
---@param y number Center Y
---@param size number Button size
function TabBar:drawCloseButton(x, y, size)
    local halfSize = size / 2

    love.graphics.setColor(self.props.textColor)
    love.graphics.circle("fill", x, y, halfSize - 2)

    love.graphics.setColor(self.props.inactiveTabColor)
    love.graphics.setLineWidth(1.5)
    local offset = halfSize * 0.6
    love.graphics.line(x - offset, y - offset, x + offset, y + offset)
    love.graphics.line(x + offset, y - offset, x - offset, y + offset)
    love.graphics.setLineWidth(1)
end

return TabBar
