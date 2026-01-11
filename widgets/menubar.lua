local Widget = require("ennui.widget")
local HorizontalStackPanel = require("widgets.horizontalstackpanel")
local ennui = require("ennui")

---@class MenuBar : Widget
---@field __headerPanel HorizontalStackPanel Panel to hold menu headers
---@field __dropdowns table Array of dropdown menus
local MenuBar = {}
MenuBar.__index = MenuBar
setmetatable(MenuBar, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

---Create a new menu bar
---@return MenuBar
function MenuBar.new()
    local self = setmetatable(Widget(), MenuBar) ---@cast self MenuBar

    self.__headerPanel = HorizontalStackPanel()
        :setSize(require("ennui.size").fill(), require("ennui.size").auto())
        :setSpacing(0)

    self:addChild(self.__headerPanel)

    -- TODO: I think this should be added to the host? They should be rendered on top of everything.
    self.__dropdowns = {}

    return self
end

---Add a menu header with dropdown
---@param label string Menu label text
---@return TextButton headerButton The menu header button
function MenuBar:addMenu(label)
    local TextButton = require("widgets.textbutton")
    local DropdownMenu = require("widgets.dropdownmenu")

    local menuBar = self

    local headerButton = TextButton()
        :setText(label)
        :setSize(ennui.Size.auto(), ennui.Size.auto())
        :setMinWidth(80)
        :setPadding(4, 12, 4, 12)

    local dropdownMenu = DropdownMenu()
        :setSize(ennui.Size.auto(), require("ennui.size").auto())
        :setMinWidth(80)
        :setVisible(false)

    headerButton._dropdownMenu = dropdownMenu

    headerButton:onClick(function(self, event)
        local isVisible = dropdownMenu:isVisible()
        for _, dropdown in ipairs(menuBar.__dropdowns) do
            dropdown:setVisible(false)
        end
        dropdownMenu:setVisible(not isVisible)

        if not isVisible then
            local buttonWidth = math.max(headerButton.width, 120)
            local availableHeight = 600

            dropdownMenu:measure(buttonWidth, availableHeight)

            local dropdownY = menuBar.y + menuBar.height
            dropdownMenu:arrange(headerButton.x, dropdownY, dropdownMenu.desiredWidth, dropdownMenu.desiredHeight)
        end
    end)

    menuBar.__headerPanel:addChild(headerButton)
    table.insert(menuBar.__dropdowns, dropdownMenu)

    return headerButton
end

---Get the header panel
---@return HorizontalStackPanel
function MenuBar:getHeaderPanel()
    return self.__headerPanel
end

---Render the menu bar and its dropdowns
function MenuBar:onRender()
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    love.graphics.setColor(1, 1, 1)
    self.__headerPanel:onRender()

    for _, dropdown in ipairs(self.__dropdowns) do
        if dropdown:isVisible() then
            dropdown:onRender()
        end
    end
end

---Update dropdowns
function MenuBar:onUpdate(dt)
    self.__headerPanel:onUpdate(dt)

    for _, dropdown in ipairs(self.__dropdowns) do
        if dropdown:isVisible() then
            dropdown:onUpdate(dt)
        end
    end
end

---Hit test including dropdowns
function MenuBar:hitTest(x, y)
    if not self:isVisible() then
        return nil
    end

    if not self:containsPoint(x, y) then
        for _, dropdown in ipairs(self.__dropdowns) do
            if dropdown:isVisible() and dropdown:containsPoint(x, y) then
                return dropdown:hitTest(x, y)
            end
        end
        return nil
    end

    for i = #self.children, 1, -1 do
        local hit = self.children[i]:hitTest(x, y)
        if hit then
            return hit
        end
    end

    for _, dropdown in ipairs(self.__dropdowns) do
        if dropdown:isVisible() then
            local hit = dropdown:hitTest(x, y)
            if hit then
                return hit
            end
        end
    end

    return self
end

return MenuBar
