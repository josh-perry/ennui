local EnnuiRoot = (...):sub(1, (...):len() - (".widgets.menubar"):len())
local Widget = require(EnnuiRoot .. ".widget")
local Size = require(EnnuiRoot .. ".size")
local HorizontalStackPanel = require(EnnuiRoot .. ".widgets.horizontalstackpanel")
local TextButton = require(EnnuiRoot .. ".widgets.textbutton")
local DropdownMenu = require(EnnuiRoot .. ".widgets.dropdownmenu")

local MENU_WIDTH = 160
local MENU_HEIGHT = 32
local MENU_PADDING = 2

---@class MenubarEntry
---@field button TextButton
---@field menu DropdownMenu

---@class Menubar : Widget
---@field __entries MenubarEntry[]
---@field __openMenu DropdownMenu?
---@field __openEntry MenubarEntry?
---@field __host table?
---@field __buttonRow HorizontalStackPanel
local Menubar = {}
Menubar.__index = Menubar
setmetatable(Menubar, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end,
})

function Menubar:__tostring()
    return "Menubar"
end

---Create a new Menubar widget
---@return Menubar
function Menubar.new()
    local self = setmetatable(Widget(), Menubar) ---@cast self Menubar

    self.__entries = {}
    self.__openMenu = nil
    self.__openEntry = nil
    self.__host = nil

    self.__buttonRow = HorizontalStackPanel()
        :setSize(Size.fill(), Size.fill())
        :setSpacing(0)

    Widget.addChild(self, self.__buttonRow)

    self:setSize(Size.fill(), MENU_HEIGHT)
    self:setPadding(MENU_PADDING, MENU_PADDING, MENU_PADDING, MENU_PADDING)

    return self
end

---Add a top-level menu with the given label
---@param label string Button label
---@return DropdownMenu menu The dropdown menu to populate with items
function Menubar:addMenu(label)
    local menu = DropdownMenu()
        :setSize(MENU_WIDTH, Size.auto())

    local button = TextButton(label)
        :setSize(Size.auto(), Size.fill())
        :setCornerRadius(0)
        :setFocusable(false)

    local entry = { button = button, menu = menu }
    table.insert(self.__entries, entry)

    self.__buttonRow:addChild(button)

    menu.onItemClicked = function()
        self:closeAll()
    end

    menu.onRequestClose = function()
        self:closeAll()
    end

    menu.onRequestNext = function()
        local index = self:__entryIndex(entry)
        local next = self.__entries[index + 1] or self.__entries[1]
        self:__openAt(next, next.button)
    end

    menu.onRequestPrevious = function()
        local index = self:__entryIndex(entry)
        local previous = self.__entries[index - 1] or self.__entries[#self.__entries]
        self:__openAt(previous, previous.button)
    end

    local host = self:__ensureHost()
    if host then
        host:registerOverlay(menu)
        menu.__host = host
    end

    button:onClick(function(buttonSelf)
        if self.__openMenu == menu then
            self:closeAll()
        else
            self:__openAt(entry, buttonSelf)
        end
    end)

    button:onMouseEntered(function(buttonSelf)
        if self.__openMenu and self.__openMenu ~= menu then
            self:__openAt(entry, buttonSelf)
        end
    end)

    self:addChild(menu)

    return menu
end

---Close all open menus
function Menubar:closeAll()
    if self.__openMenu then
        local host = self.__host
        if host then
            local focused = host:getFocusedWidget()
            if focused then
                local current = focused.parent
                while current do
                    if current == self.__openMenu then
                        host:setFocusedWidget(nil)
                        break
                    end
                    current = current.parent
                end
            end
        end
        self.__openMenu:setVisible(false)
        self.__openMenu = nil
        if self.__openEntry then
            self.__openEntry.button.props.isPressed = false
            self.__openEntry = nil
        end
    end
end

---@private
function Menubar:__entryIndex(entry)
    for i, e in ipairs(self.__entries) do
        if e == entry then return i end
    end
end

---@private
function Menubar:__ensureHost()
    if self.__host then return self.__host end

    local current = self:getHost()
    if current and current.__overlayWidgets then
        self.__host = current
        for _, entry in ipairs(self.__entries) do
            self.__host:registerOverlay(entry.menu)
            entry.menu.__host = self.__host
        end
    end

    return self.__host
end

---@private
function Menubar:__openAt(entry, button)
    self:__ensureHost()
    self:closeAll()
    local menu = entry.menu
    menu:measure(MENU_WIDTH, 1000)
    menu:arrange(button.x, button.y + button.height, MENU_WIDTH, menu.desiredHeight)
    menu:setVisible(true)
    self.__openMenu = menu
    self.__openEntry = entry
    entry.button.props.isPressed = true

    local host = self.__host
    if host then
        for _, child in ipairs(menu.__itemPanel.children) do
            if not child.__isSeparator and child.focusable and child:isVisible() then
                host:setFocusedWidget(child)
                break
            end
        end
    end
end

function Menubar:arrangeChildren(contentX, contentY, contentWidth, contentHeight)
    self.__buttonRow:arrange(contentX, contentY, contentWidth, contentHeight)
end

---@private
function Menubar:__onAfterRemoveChild(child)
    for i, entry in ipairs(self.__entries) do
        if entry.menu == child then
            if self.__host then
                self.__host:unregisterOverlay(child)
            end
            self.__buttonRow:removeChild(entry.button)
            table.remove(self.__entries, i)
            break
        end
    end
    Widget.__onAfterRemoveChild(self, child)
end

function Menubar:unmount()
    if self.__host then
        for _, entry in ipairs(self.__entries) do
            self.__host:unregisterOverlay(entry.menu)
        end
        self.__host = nil
    end

    Widget.unmount(self)
end

function Menubar:render()
    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    Widget.render(self)
end

return Menubar
