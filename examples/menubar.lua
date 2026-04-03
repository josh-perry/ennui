local ennui = require("ennui")

local Host = ennui.Widgets.Host
local Menubar = ennui.Widgets.Menubar
local Stackpanel = ennui.Widgets.Stackpanel
local Text = ennui.Widgets.Text
local Scrollarea = ennui.Widgets.Scrollarea
local Window = ennui.Widgets.Window
local Size = ennui.Size

local host = Host():setSize(love.graphics.getDimensions())
local menubar = Menubar()

local state = ennui.State({
    messages = {},
    colours = require("examples.data.colours"),
    numbers = {
        { value = 1 },
        { value = 2 },
        { value = 3 },
    }
})

local function createLogWindow()
    local logWindow = Window("Menu Messages")
        :setPosition(200, 200)
        :setSize(560, 320)
    local logContent = Stackpanel()
        :setSize(Size.fill(), Size.fill())
        :setPadding(10)
        :setSpacing(8)

    local logScroll = Scrollarea()
        :setSize(Size.fill(), Size.fill())

    local logLines = Stackpanel()
        :setSize(Size.fill(), Size.auto())
        :setSpacing(4)

    logLines:bindChildren(state, "messages", {
        key = "id",
        create = function(data)
            return Text(data.message)
                :setColor(data.colour or {0.85, 0.95, 1})
        end
    })

    logScroll:addChild(logLines)
    logContent:addChild(logScroll)
    logWindow:setContent(logContent)
    return logWindow
end

local logWindow = createLogWindow()

local function addLog(message, colour)
    state.props.messages:insert({
        id = ennui.State.newId(),
        message = message,
        colour = colour or nil
    })
end

local function menuItemOnClick(menuItemWidget)
    addLog(menuItemWidget:getText() .." clicked!")
end

local fileMenu = menubar:addMenu("File")
fileMenu:addItem("New"):onClick(menuItemOnClick)
fileMenu:addItem("Open"):onClick(menuItemOnClick)
fileMenu:addItem("Save"):onClick(menuItemOnClick)
fileMenu:addSeparator()
fileMenu:addItem("Exit"):onClick(function() love.event.quit() end)

local editMenu = menubar:addMenu("Edit")
editMenu:addItem("Undo"):onClick(menuItemOnClick)
editMenu:addItem("Redo"):onClick(menuItemOnClick)
editMenu:addSeparator()
editMenu:addItem("Cut"):onClick(menuItemOnClick)
editMenu:addItem("Copy"):onClick(menuItemOnClick)
editMenu:addItem("Paste"):onClick(menuItemOnClick)

local viewMenu = menubar:addMenu("View")
viewMenu:addItem("Zoom In"):onClick(menuItemOnClick)
viewMenu:addItem("Zoom Out"):onClick(menuItemOnClick)
viewMenu:addItem("Reset Zoom"):onClick(menuItemOnClick)
viewMenu:addSeparator()
viewMenu:addItem("Toggle Sidebar"):onClick(menuItemOnClick)

local helpMenu = menubar:addMenu("Help")
helpMenu:addItem("About"):onClick(menuItemOnClick)
helpMenu:addItem("Keyboard Shortcuts"):onClick(menuItemOnClick)

local function createWindowWithMenuBar()
    local windowWithMenuBar = Window("Menubar Example")
        :setSize(600, 400)
        :setPosition(400, 400)

    local contentPanel = Stackpanel()
        :setSize(Size.fill(), Size.fill())

    local windowMenuBar = Menubar()
    fileMenu = windowMenuBar:addMenu("File")
    fileMenu:addItem("New"):onClick(menuItemOnClick)
    fileMenu:addItem("Open"):onClick(menuItemOnClick)
    fileMenu:addItem("Save"):onClick(menuItemOnClick)
    fileMenu:addSeparator()
    fileMenu:addItem("Exit"):onClick(function() windowWithMenuBar:close() end)

    local colourMenu = windowMenuBar:addMenu("Colours")
    colourMenu:bindChildren(state, "colours", {
        key = "name",
        create = function(data)
            local menuItem = colourMenu:addItem(data.name)
            menuItem:onClick(function()
                addLog(menuItem:getText(), data.colour)
            end)

            return menuItem
        end
    })

    local numberMenu = windowMenuBar:addMenu("Numbers")
    numberMenu:bindChildren(state, "numbers", {
        key = "value",
        create = function(data)
            return numberMenu:addItem(tostring(data.value)):onClick(menuItemOnClick)
        end
    })

    local innerContentStackPanel = Stackpanel()
        :setSize(Size.fill(), Size.fill())
        :setPadding(10)
        :setSpacing(8)

    local addNumberButton = ennui.Widgets.Textbutton("Add number")
        :setBackgroundColor(0.1, 0.6, 0.1)
        :onClick(function()
            addLog(("Adding number %d to numbers menu!"):format(state.props.numbers:len() + 1))
            state.props.numbers:insert({
                value = state.props.numbers:len() + 1
            })
        end)

    local removeNumberButton = ennui.Widgets.Textbutton("Remove number")
        :setBackgroundColor(0.6, 0.1, 0.1)
        :onClick(function()
            addLog(("Removing number %d from numbers menu!"):format(state.props.numbers:len()))
            state.props.numbers:remove(state.props.numbers:len())
        end)

    innerContentStackPanel:addChild(ennui.Widgets.Text("This window has its own menubar!"))
    innerContentStackPanel:addChild(ennui.Widgets.Text("The Numbers menu is bound to state so you can add and remove items and the menu automatically reflects changes!"))
    innerContentStackPanel:addChild(addNumberButton)
    innerContentStackPanel:addChild(removeNumberButton)

    contentPanel:addChild(windowMenuBar)
    contentPanel:addChild(innerContentStackPanel)

    windowWithMenuBar:setContent(contentPanel)
    return windowWithMenuBar
end

local windowWithMenuBar = createWindowWithMenuBar()

host:addChild(menubar)
host:addChild(logWindow)
host:addChild(windowWithMenuBar)

return host