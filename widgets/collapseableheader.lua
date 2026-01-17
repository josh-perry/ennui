local ennui = require("ennui")
local Widget = require("ennui.widget")
local Size = require("ennui.size")
local Text = require("widgets.text")
local Scissor = require("ennui.utils.scissor")

---@class CollapseableHeader : Widget
---@field expanded boolean Whether the content is expanded
---@field title string Header title text
---@field headerHeight number Height of the header in pixels
---@field iconSize number Size of the expand/collapse icon
---@field headerColor number[] RGBA color for header background
---@field headerHoverColor number[] RGBA color for header hover state
---@field titleColor number[] RGBA color for the title text
---@field iconColor number[] RGBA color for the expand/collapse icon
---@field animationSpeed number Animation speed (0 for instant)
---@field __titleWidget Text Internal Text widget for title
---@field __currentHeight number Current animated height
---@field __targetHeight number Target height for animation
local CollapseableHeader = {}
CollapseableHeader.__index = CollapseableHeader
setmetatable(CollapseableHeader, {
    __index = Widget,
    __call = function(class, title, expanded)
        return class.new(title, expanded)
    end,
})

---Create a new collapseable header widget
---@param title string? Header title (optional)
---@param expanded boolean? Initial expanded state (default true)
---@return CollapseableHeader
function CollapseableHeader.new(title, expanded)
    local self = setmetatable(Widget(), CollapseableHeader) ---@cast self CollapseableHeader

    if expanded == nil then expanded = true end

    self:addProperty("expanded", expanded)
    self:addProperty("title", title or "")
    self:addProperty("headerHeight", 28)
    self:addProperty("iconSize", 12)
    self:addProperty("headerColor", {0.2, 0.2, 0.2, 1})
    self:addProperty("headerHoverColor", {0.25, 0.25, 0.25, 1})
    self:addProperty("titleColor", {1, 1, 1, 1})
    self:addProperty("iconColor", {0.7, 0.7, 0.7, 1})
    self:addProperty("animationSpeed", 8)

    self.__titleWidget = Text()
        :setTextVerticalAlignment("center")
        :setSize(Size.auto(), Size.auto())

    self.__currentHeight = expanded and 1000 or 0
    self.__targetHeight = expanded and 1000 or 0
    self.__headerHovered = false

    self:watch("title", function(newTitle)
        self.__titleWidget.props.text = newTitle
        self:invalidateLayout()
    end, { immediate = true })

    self:watch("titleColor", function(newColor)
        self.__titleWidget.props.color = newColor
        self:invalidateRender()
    end, { immediate = true })

    self:watch("expanded", function(isExpanded)
        self.__targetHeight = isExpanded and 1000 or 0
        self:invalidateLayout()
    end)

    local strategy = ennui.Layout.Vertical()
    self:setLayoutStrategy(strategy)

    self:setFocusable(true)

    return self
end

---Toggle expanded state
---@return CollapseableHeader self
function CollapseableHeader:toggle()
    self.props.expanded = not self.props.expanded
    return self
end

---Set expanded state
---@param expanded boolean Whether content is expanded
---@return CollapseableHeader self
function CollapseableHeader:setExpanded(expanded)
    self.props.expanded = expanded
    return self
end

---Get expanded state
---@return boolean expanded
function CollapseableHeader:isExpanded()
    return self.props.expanded
end

---Set the header title
---@param title string Title text
---@return CollapseableHeader self
function CollapseableHeader:setTitle(title)
    self.props.title = title
    return self
end

---Get the header title
---@return string title
function CollapseableHeader:getTitle()
    return self.props.title
end

---Set header color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return CollapseableHeader self
function CollapseableHeader:setHeaderColor(r, g, b, a)
    self.props.headerColor = {r, g, b, a or 1}
    return self
end

---Set title color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return CollapseableHeader self
function CollapseableHeader:setTitleColor(r, g, b, a)
    self.props.titleColor = {r, g, b, a or 1}
    return self
end

---Set icon color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return CollapseableHeader self
function CollapseableHeader:setIconColor(r, g, b, a)
    self.props.iconColor = {r, g, b, a or 1}
    return self
end

---Set header height
---@param height number Header height in pixels
---@return CollapseableHeader self
function CollapseableHeader:setHeaderHeight(height)
    self.props.headerHeight = height
    return self
end

---Set spacing between children
---@param pixels number Spacing in pixels
---@return CollapseableHeader self
function CollapseableHeader:setSpacing(pixels)
    if self.layoutStrategy then
        self.layoutStrategy.spacing = pixels
        self:invalidateLayout()
    end
    return self
end

---Check if point is in header area
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean inHeader
function CollapseableHeader:__isInHeader(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.props.headerHeight
end

---Override hitTest
function CollapseableHeader:hitTest(x, y)
    if not self:isVisible() then
        return nil
    end

    if not self:containsPoint(x, y) then
        return nil
    end

    if self:__isInHeader(x, y) then
        return self
    end

    if self.props.expanded then
        for i = #self.children, 1, -1 do
            local hit = self.children[i]:hitTest(x, y)

            if hit then
                return hit
            end
        end
    end

    return self
end

---Calculate content height for children
---@return number contentHeight
function CollapseableHeader:__calculateChildrenHeight()
    local totalHeight = 0
    local spacing = self.layoutStrategy and self.layoutStrategy.spacing or 0

    for i, child in ipairs(self.children) do
        if child:isVisible() then
            totalHeight = totalHeight + child.desiredHeight
            if i > 1 then
                totalHeight = totalHeight + spacing
            end
        end
    end

    return totalHeight
end

---Override measure
function CollapseableHeader:measure(availableWidth, availableHeight)
    self.__titleWidget:measure(availableWidth, availableHeight)

    local contentHeight = self.props.headerHeight

    if self.layoutStrategy then
        local childAvailableHeight = availableHeight - self.props.headerHeight
        self.layoutStrategy:measure(self, availableWidth - self.padding.left - self.padding.right, childAvailableHeight)
    end

    local childrenHeight = self:__calculateChildrenHeight()

    local visibleChildHeight = self.props.expanded and childrenHeight or 0

    if self.props.animationSpeed > 0 then
        visibleChildHeight = math.min(childrenHeight, self.__currentHeight)
    end

    contentHeight = contentHeight + visibleChildHeight + (visibleChildHeight > 0 and self.padding.top + self.padding.bottom or 0)

    local desiredWidth = availableWidth
    local desiredHeight = contentHeight

    desiredWidth, desiredHeight = self:__applyConstraints(desiredWidth, desiredHeight)

    self.desiredWidth = desiredWidth
    self.desiredHeight = desiredHeight
    self.isLayoutDirty = false

    return desiredWidth, desiredHeight
end

---Override arrange
function CollapseableHeader:arrange(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    -- Arrange children below header
    if self.props.expanded or self.__currentHeight > 0 then
        local contentX = x + self.padding.left
        local contentY = y + self.props.headerHeight + self.padding.top
        local contentWidth = width - self.padding.left - self.padding.right
        local contentHeight = height - self.props.headerHeight - self.padding.top - self.padding.bottom

        self:arrangeChildren(contentX, contentY, contentWidth, contentHeight)
    end
end

---Update animation
function CollapseableHeader:onUpdate(dt)
    if self.props.animationSpeed > 0 then
        local childrenHeight = self:__calculateChildrenHeight()
        local target = self.props.expanded and childrenHeight or 0

        if math.abs(self.__currentHeight - target) > 0.5 then
            local delta = (target - self.__currentHeight) * self.props.animationSpeed * dt
            self.__currentHeight = self.__currentHeight + delta
            self:invalidateLayout()
        else
            self.__currentHeight = target
        end
    else
        local childrenHeight = self:__calculateChildrenHeight()
        self.__currentHeight = self.props.expanded and childrenHeight or 0
    end

    Widget.onUpdate(self, dt)
end

---Handle mouse events for header
function CollapseableHeader:onMouseMoved(event)
    self.__headerHovered = self:__isInHeader(event.x, event.y)
end

function CollapseableHeader:onMouseExited(event)
    self.__headerHovered = false
end

function CollapseableHeader:onClicked(event)
    if self:__isInHeader(event.x, event.y) then
        self:toggle()
        return true
    end
end

function CollapseableHeader:onKeyPressed(event)
    if event.key == "space" or event.key == "return" then
        self:toggle()
        return true
    end
end

---Render the collapseable header
function CollapseableHeader:onRender()
    local headerHeight = self.props.headerHeight

    local headerColor = self.__headerHovered and self.props.headerHoverColor or self.props.headerColor
    love.graphics.setColor(headerColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, headerHeight)

    local iconSize = self.props.iconSize
    local iconX = self.x + 8
    local iconY = self.y + (headerHeight - iconSize) / 2

    love.graphics.setColor(self.props.iconColor)
    if self.props.expanded then
        -- Pointing down
        love.graphics.polygon("fill",
            iconX, iconY,
            iconX + iconSize, iconY,
            iconX + iconSize / 2, iconY + iconSize
        )
    else
        -- Pointing right
        love.graphics.polygon("fill",
            iconX, iconY,
            iconX + iconSize, iconY + iconSize / 2,
            iconX, iconY + iconSize
        )
    end

    self.__titleWidget:arrange(
        self.x + 8 + iconSize + 8,
        self.y,
        self.width - 8 - iconSize - 16,
        headerHeight
    )

    self.__titleWidget:onRender()

    if self.state.isFocused then
        love.graphics.setColor(0.5, 0.7, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", self.x + 1, self.y + 1, self.width - 2, headerHeight - 2)
    end

    -- Render children if expanded (with clipping)
    if self.props.expanded or self.__currentHeight > 0 then
        local contentY = self.y + headerHeight
        local contentHeight = self.__currentHeight

        if contentHeight > 0 then
            local prevX, prevY, prevW, prevH = Scissor.push(self.x, contentY, self.width, contentHeight)

            for _, child in ipairs(self.children) do
                if child:isVisible() then
                    child:onRender()
                end
            end

            Scissor.pop(prevX, prevY, prevW, prevH)
        end
    end
end

return CollapseableHeader
