local Widget = require("ennui.widget")
local Size = require("ennui.size")
local Text = require("ennui.widgets.text")
local VerticalLayout = require("ennui.layout.vertical_layout_strategy")

---@class Group : Widget
---@field title string Group title text
---@field borderColor number[] RGBA color for the border
---@field titleColor number[] RGBA color for the title
---@field backgroundColor number[] RGBA color for the background
---@field cornerRadius number Corner radius for rounded corners
---@field borderWidth number Width of the border
---@field titlePadding number Horizontal padding around title
---@field __titleWidget Text Internal Text widget for title
local Group = {}
Group.__index = Group
setmetatable(Group, {
    __index = Widget,
    __call = function(class, title)
        return class.new(title)
    end,
})

function Group:__tostring()
    return string.format("Group(%q)", self.props.title or "")
end

---Create a new group widget
---@param title string? Group title (optional)
---@return Group
function Group.new(title)
    local self = setmetatable(Widget(), Group) ---@cast self Group

    self:addProperty("title", title or "")
    self:addProperty("borderColor", {0.4, 0.4, 0.4, 1})
    self:addProperty("titleColor", {0.8, 0.8, 0.8, 1})
    self:addProperty("backgroundColor", {0, 0, 0, 0})
    self:addProperty("cornerRadius", 4)
    self:addProperty("borderWidth", 1)
    self:addProperty("titlePadding", 8)

    self.__titleWidget = Text()
        :setSize(Size.auto(), Size.auto())

    self:watch("title", function(newTitle)
        self.__titleWidget.props.text = newTitle
        self:invalidateLayout()
    end, { immediate = true })

    self:watch("titleColor", function(newColor)
        self.__titleWidget.props.color = newColor
        self:invalidateRender()
    end, { immediate = true })

    -- Set default layout strategy
    local strategy = VerticalLayout()
    self:setLayoutStrategy(strategy)

    -- Default padding
    self:setPadding(16)

    return self
end

---Set the group title
---@param title string Title text
---@return Group self
function Group:setTitle(title)
    self.props.title = title
    return self
end

---Get the group title
---@return string title
function Group:getTitle()
    return self.props.title
end

---Set border color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Group self
function Group:setBorderColor(r, g, b, a)
    self.props.borderColor = {r, g, b, a or 1}
    return self
end

---Set title color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Group self
function Group:setTitleColor(r, g, b, a)
    self.props.titleColor = {r, g, b, a or 1}
    return self
end

---Set background color
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number? Alpha component (0-1, default 1)
---@return Group self
function Group:setBackgroundColor(r, g, b, a)
    self.props.backgroundColor = {r, g, b, a or 1}
    return self
end

---Set corner radius
---@param radius number Corner radius in pixels
---@return Group self
function Group:setCornerRadius(radius)
    self.props.cornerRadius = radius
    return self
end

---Set border width
---@param width number Border width in pixels
---@return Group self
function Group:setBorderWidth(width)
    self.props.borderWidth = width
    return self
end

---Set spacing between children
---@param pixels number Spacing in pixels
---@return Group self
function Group:setSpacing(pixels)
    if self.layoutStrategy then
        self.layoutStrategy.spacing = pixels
        self:invalidateLayout()
    end

    return self
end

---Get title height (accounts for title presence)
---@return number titleHeight
function Group:__getTitleHeight()
    if self.props.title == "" then
        return 0
    end

    return self.__titleWidget.desiredHeight
end

---Override measure to account for title
function Group:measure(availableWidth, availableHeight)
    self.__titleWidget:measure(availableWidth, availableHeight)

    local titleHeight = self:__getTitleHeight()

    local adjustedHeight = availableHeight - titleHeight - self.padding.top / 2

    if self.layoutStrategy then
        local desiredWidth, desiredHeight = self.layoutStrategy:measure(self, availableWidth, adjustedHeight)

        desiredWidth = desiredWidth
        desiredHeight = desiredHeight + titleHeight + self.padding.top / 2

        local constrainedWidth, constrainedHeight = self:__applyConstraints(desiredWidth, desiredHeight)

        self.desiredWidth = constrainedWidth
        self.desiredHeight = constrainedHeight
        self.isLayoutDirty = false

        return constrainedWidth, constrainedHeight
    end

    return Widget.measure(self, availableWidth, availableHeight)
end

---Override arrange to position children below title
function Group:arrange(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    local titleHeight = self:__getTitleHeight()

    local contentX = x + self.padding.left
    local contentY = y + self.padding.top + titleHeight + (titleHeight > 0 and 4 or 0)
    local contentWidth = width - self.padding.left - self.padding.right
    local contentHeight = height - self.padding.top - self.padding.bottom - titleHeight - (titleHeight > 0 and 4 or 0)

    self:arrangeChildren(contentX, contentY, contentWidth, contentHeight)
end

---Render the group
function Group:onRender()
    local titleHeight = self:__getTitleHeight()
    local borderY = self.y + titleHeight / 2

    if self.props.backgroundColor[4] > 0 then
        love.graphics.setColor(self.props.backgroundColor)
        love.graphics.rectangle("fill", self.x, borderY, self.width, self.height - titleHeight / 2,
            self.props.cornerRadius, self.props.cornerRadius)
    end

    love.graphics.setColor(self.props.borderColor)
    love.graphics.setLineWidth(self.props.borderWidth)

    if titleHeight > 0 then
        local titleWidth = self.__titleWidget.desiredWidth + self.props.titlePadding * 2
        local titleX = self.x + 12

        love.graphics.line(
            self.x + self.props.cornerRadius, borderY,
            titleX, borderY
        )

        love.graphics.line(
            titleX + titleWidth, borderY,
            self.x + self.width - self.props.cornerRadius, borderY
        )

        love.graphics.line(
            self.x + self.width, borderY + self.props.cornerRadius,
            self.x + self.width, self.y + self.height - self.props.cornerRadius
        )

        love.graphics.line(
            self.x + self.width - self.props.cornerRadius, self.y + self.height,
            self.x + self.props.cornerRadius, self.y + self.height
        )

        love.graphics.line(
            self.x, self.y + self.height - self.props.cornerRadius,
            self.x, borderY + self.props.cornerRadius
        )

        -- Corners
        love.graphics.arc("line", "open",
            self.x + self.props.cornerRadius, borderY + self.props.cornerRadius,
            self.props.cornerRadius, math.pi, math.pi * 1.5)

        love.graphics.arc("line", "open",
            self.x + self.width - self.props.cornerRadius, borderY + self.props.cornerRadius,
            self.props.cornerRadius, math.pi * 1.5, math.pi * 2)

        love.graphics.arc("line", "open",
            self.x + self.width - self.props.cornerRadius, self.y + self.height - self.props.cornerRadius,
            self.props.cornerRadius, 0, math.pi * 0.5)

        love.graphics.arc("line", "open",
            self.x + self.props.cornerRadius, self.y + self.height - self.props.cornerRadius,
            self.props.cornerRadius, math.pi * 0.5, math.pi)

        self.__titleWidget:arrange(
            titleX + self.props.titlePadding,
            self.y,
            self.__titleWidget.desiredWidth,
            titleHeight)
        
        self.__titleWidget:onRender()
    else
        love.graphics.rectangle(
            "line",
            self.x,
            self.y,
            self.width,
            self.height,
            self.props.cornerRadius,
            self.props.cornerRadius)
    end

    -- Render children
    for _, child in ipairs(self.children) do
        if child:isVisible() then
            child:onRender()
        end
    end
end

return Group
