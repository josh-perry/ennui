local ennui = require("ennui")

local Button = require("widgets.button")
local Computed = require("ennui.computed")
local HorizontalStackPanel = require("widgets.horizontalstackpanel")
local Image = require("widgets.image")
local MenuBar = require("widgets.menubar")
local StackPanel = require("widgets.stackpanel")
local Text = require("widgets.text")
local TextButton = require("widgets.textbutton")
local TextInput = require("widgets.textinput")
local Widget = require("ennui.widget")
local Window = require("widgets.window")

local DockSpace = require("ennui.docking.dockspace")
local DockableWindow = require("widgets.dockablewindow")

love.keyboard.setTextInput(true)
love.graphics.setDefaultFilter("nearest", "nearest")

local host

local gameState = {
    score = 0,
    clickCount = 0,
    username = "",
    password = "",
    secret = ""
}

local scoreLabel
local clickCountLabel

local function createSimpleTextButtonExample()
    local button = TextButton()
        :setId("simpleTextButton")
        :setText("Click Me!")
        :setSize(120, 40)
        :setPosition(700, 20)
        :onClick(function(self, event)
            gameState.clickCount = gameState.clickCount + 1
            clickCountLabel:setText("Clicks: " .. gameState.clickCount)
        end)

    clickCountLabel = Text()
        :setText("Clicks: 0")
        :setPosition(700, 70)
        :setSize(150, 30)

    return button, clickCountLabel
end

local function createLoginWindow()
    local loginWindow = Window()
        :setTitle("Login Form")
        :setSize(ennui.Size.auto(), ennui.Size.auto())
        :setPosition(160, 20)

    local formPanel = StackPanel()
        :setPadding(16, 16, 16, 16)
        :setSpacing(12)
        :setSize(ennui.Size.fixed(300), ennui.Size.auto())
        :addChild(Text()
            :setText("Please enter your banks credentials")
            :setSize(ennui.Size.fill(), ennui.Size.auto())
        )
        :addChild(Text()
            :setText("Email:")
            :setSize(ennui.Size.fill(), ennui.Size.auto())
        )
        :addChild(TextInput()
            :setId("emailInput")
            :setPlaceholder("Email")
            :setSize(ennui.Size.fill(), 32)
            :on("textInput", function(self)
                gameState.username = self:getText()
            end))
        :addChild(Text()
            :setText("Password:")
            :setSize(ennui.Size.fill(), ennui.Size.auto())
        )
        :addChild(TextInput()
            :setId("passwordInput")
            :setPlaceholder("Password")
            :setPassword(true)
            :setSize(ennui.Size.fill(), 32)
            :on("textInput", function(self)
                gameState.password = self:getText()
            end))
        :addChild(Text()
            :setText("Secret Code:")
            :setSize(ennui.Size.fill(), ennui.Size.auto())
        )
        :addChild(TextInput()
            :setId("secretInput")
            :setPlaceholder("Secret Code")
            :setPassword(false)
            :setSize(ennui.Size.fill(), 32)
            :on("textInput", function(self)
                gameState.secret = self:getText()
            end)
        )

    local buttonRow = HorizontalStackPanel()
        :setSpacing(8)
        :setSize(ennui.Size.fill(), 40)

    buttonRow:addChild(
        TextButton()
            :setText("Login")
            :setSize(ennui.Size.fill(), ennui.Size.fill())
            :setBackgroundColor(0.2, 0.6, 0.2, 1)
            :setHoverColor(0.3, 0.7, 0.3, 1)
            :onClick(function()
                print("Login clicked: ", gameState.username, string.rep("*", #gameState.password))

                local usernameInput = loginWindow:findById("emailInput")
                local passwordInput = loginWindow:findById("passwordInput")
                local secretInput = loginWindow:findById("secretInput")

                usernameInput:setText("")
                passwordInput:setText("")
                secretInput:setText("")
            end)
    )

    buttonRow:addChild(
        TextButton()
            :setText("Cancel")
            :setSize(ennui.Size.fill(), ennui.Size.fill())
            :setBackgroundColor(0.6, 0.2, 0.2, 1)
            :setHoverColor(0.7, 0.3, 0.3, 1)
            :onClick(function()
                loginWindow:close()
            end)
    )

    formPanel:addChild(buttonRow)

    loginWindow:setContent(formPanel)
    return loginWindow
end

local function createNestedLayoutExample()
    local window = Window()
        :setTitle("Nested Layouts")
        :setSize(400, 300)
        :setPosition(500, 20)

    local mainPanel = StackPanel()
        :setPadding(16, 16, 16, 16)
        :setSpacing(8)
        :setSize(ennui.Size.fill(), ennui.Size.fill())

    local headerRow = HorizontalStackPanel()
        :setSpacing(8)
        :setSize(ennui.Size.fill(), 40)

    headerRow:addChild(
        Text()
            :setText("horizontal")
            :setSize(ennui.Size.fill(), ennui.Size.fill())
            :setColor(1, 1, 0.5, 1)
    )

    headerRow:addChild(
        Text()
            :setText("stuff")
            :setSize(ennui.Size.fill(), ennui.Size.fill())
            :setColor(1, 1, 0.5, 1)
    )

    headerRow:addChild(
        Text()
            :setText("here")
            :setSize(ennui.Size.fill(), ennui.Size.fill())
            :setColor(1, 1, 0.5, 1)
    )

    headerRow:addChild(
        TextButton()
            :setText("Help")
            :setSize(60, ennui.Size.fill())
            :onClick(function()
                print("Help clicked!")
            end)
    )

    mainPanel:addChild(headerRow)

    local buttonGrid = Widget()
        :setSize(ennui.Size.fill(), 120)
        :setLayoutStrategy(ennui.Layout.Grid(3, 3)
        :setSpacing(8))

    for i = 1, 9 do
        local button = TextButton(tostring(i))

        button:onClick(function()
            gameState.score = gameState.score + i
            scoreLabel:setText(("Score: %d"):format(gameState.score))
        end)

        local widget = button:getTextWidget()
        widget:setTextHorizontalAlignment("center")

        buttonGrid:addChild(button)
    end

    mainPanel:addChild(buttonGrid)

    scoreLabel = Text()
        :setText("Score: 0")
        :setSize(ennui.Size.fill(), ennui.Size.auto())
        :setColor(0.5, 1, 0.5, 1)

    mainPanel:addChild(scoreLabel)

    window:setContent(mainPanel)
    return window
end

local function createDebugWindow()
    local debugWindow = Window()
        :setTitle("Debug Info")
        :setSize(250, 200)
        :setPosition(20, 350)

    local debugPanel = StackPanel()
        :setPadding(12, 12, 12, 12)
        :setSpacing(8)
        :setSize(ennui.Size.fill(), ennui.Size.fill())

    local fpsLabel = Text()
        :setText("FPS: 0")
        :setSize(ennui.Size.fill(), ennui.Size.auto())
    debugPanel:addChild(fpsLabel)

    local memLabel = Text()
        :setText("Memory: 0 MB")
        :setSize(ennui.Size.fill(), ennui.Size.auto())
    debugPanel:addChild(memLabel)

    local mouseLabel = Text()
        :setText("Mouse: 0, 0")
        :setSize(ennui.Size.fill(), ennui.Size.auto())
    debugPanel:addChild(mouseLabel)

    debugPanel.onUpdate = function(self, dt)
        fpsLabel:setText("FPS: " .. love.timer.getFPS())
        local memMB = collectgarbage("count") / 1024
        memLabel:setText(string.format("Memory: %.2f MB", memMB))
        local mx, my = love.mouse.getPosition()
        mouseLabel:setText(string.format("Mouse: %d, %d", mx, my))
    end

    debugWindow:setContent(debugPanel)
    return debugWindow
end

local function createShowcaseWindow()
    local window = Window()
        :setTitle("Widget Showcase")
        :setSize(ennui.Size.auto(), ennui.Size.auto())
        :setPosition(300, 350)

    local panel = StackPanel()
        :setPadding(16, 16, 16, 16)
        :setSpacing(12)
        :setWidth(300)
        :setHeight(ennui.Size.auto())

    panel:addChild(
        Text()
            :setText("Text widget")
            :setSize(ennui.Size.fill(), ennui.Size.auto())
    )

    panel:addChild(
        Text()
            :setText("Coloured text widget")
            :setColor(1, 0.5, 0.5, 1)
            :setSize(ennui.Size.fill(), ennui.Size.auto())
    )

    panel:addChild(
        TextButton()
            :setText("TextButton")
            :setSize(ennui.Size.fill(), 40)
            :onClick(function()
                panel:addChild(
                    Text()
                        :setText("TextButton was clicked!")
                        :setColor(0.5, 1, 0.5, 1)
                        :setSize(ennui.Size.fill(), ennui.Size.auto())
                )
            end)
    )

    panel:addChild(
        TextButton()
            :setText("TextButton with colour")
            :setSize(ennui.Size.fill(), 40)
            :setBackgroundColor(0.4, 0.2, 0.6, 1)
            :setHoverColor(0.5, 0.3, 0.7, 1)
            :onClick(function()
                print("Custom button clicked")
            end)
    )

    panel:addChild(
        Image()
            :setImagePath("assets/img/frog.png")
            :setSize(ennui.Size.fill(), 100)
    )

    local disabledBtn = TextButton()
        :setText("Disabled TextButton")
        :setSize(ennui.Size.fill(), 40)
        :setDisabled(true)
    panel:addChild(disabledBtn)

    window:setContent(panel)
    return window
end

local function createReactivePropertiesExample()
    local window = Window()
        :setTitle("Watchers & Computed Properties")
        :setSize(400, ennui.Size.auto())
        :setPosition(20, 500)

    local panel = StackPanel()
        :setPadding(16, 16, 16, 16)
        :setSpacing(12)
        :setSize(ennui.Size.fill(), ennui.Size.auto())

    local function addDisplayGrid()
        local input = TextInput()
            :setPlaceholder("Enter a number")
            :setSize(ennui.Size.fill(), 32)
        panel:addChild(input)

        local gridContainer = Widget()
            :setSize(ennui.Size.fill(), ennui.Size.auto())
            :setLayoutStrategy(ennui.Layout.Grid(2, 2)
            :setSpacing(8))

        gridContainer:addChild(
            Text()
                :setText("Double it:")
                :setSize(ennui.Size.fill(), 24)
                :setColor(1, 0.7, 0.7, 1)
        )
        local doubleDisplay = Text()
            :setText("-")
            :setSize(ennui.Size.fill(), 24)
            :setColor(1, 0.7, 0.7, 1)
        gridContainer:addChild(doubleDisplay)

        gridContainer:addChild(
            Text()
                :setText("Square it:")
                :setSize(ennui.Size.fill(), 24)
                :setColor(1, 0.7, 0.7, 1)
        )

        local squareDisplay = Text()
            :setText("-")
            :setSize(ennui.Size.fill(), 24)
            :setColor(1, 0.7, 0.7, 1)

        gridContainer:addChild(squareDisplay)

        panel:addChild(gridContainer)
        return input, doubleDisplay, squareDisplay
    end

    local input1, doubleDisplay1, squareDisplay1 = addDisplayGrid()
    local input2, doubleDisplay2, squareDisplay2 = addDisplayGrid()

    local multiplyComputed = Computed(function()
        local n1 = tonumber(input1.props.value)
        local n2 = tonumber(input2.props.value)

        return n1 and n2 and tostring(n1 * n2) or "-"
    end)

    panel:addChild(Widget()
        :setSize(ennui.Size.fill(), ennui.Size.auto())
        :setLayoutStrategy(ennui.Layout.Grid(2, 1)
        :setSpacing(8))
        :addChild(Text()
            :setText("Multiply both:")
            :setSize(ennui.Size.fill(), 24)
            :setColor(1, 1.0, 0.7, 1)
        )
        :addChild(Text()
            :bindTo("text", multiplyComputed)
            :setSize(ennui.Size.fill(), 24)
            :setColor(1, 1.0, 0.7, 1)
        ))

    input1:watch("value", function(val)
        local num = tonumber(val)
        doubleDisplay1:setText(num and tostring(num * 2) or "-")
        squareDisplay1:setText(num and tostring(num * num) or "-")
    end)

    input2:watch("value", function(val)
        local num = tonumber(val)
        doubleDisplay2:setText(num and tostring(num * 2) or "-")
        squareDisplay2:setText(num and tostring(num * num) or "-")
    end)

    window:setContent(panel)
    return window
end

local function createMenuBarExample()
    local menuBar = MenuBar()
        :setSize(ennui.Size.fill(), 30)
        :setPosition(0, 0)

    local fileMenu = menuBar:addMenu("File")
    local fileDropdown = fileMenu._dropdownMenu
    fileDropdown:addItem("New"):onClick(function()
        print("File > New clicked")
    end)
    fileDropdown:addItem("Open"):onClick(function()
        print("File > Open clicked")
    end)
    fileDropdown:addItem("Save"):onClick(function()
        print("File > Save clicked")
    end)
    fileDropdown:addSeparator()
    fileDropdown:addItem("Exit"):onClick(function()
        print("File > Exit clicked")
        love.event.quit()
    end)

    local editMenu = menuBar:addMenu("Edit")
    local editDropdown = editMenu._dropdownMenu
    editDropdown:addItem("Undo"):onClick(function()
        print("Edit > Undo clicked")
    end)
    editDropdown:addItem("Redo"):onClick(function()
        print("Edit > Redo clicked")
    end)
    editDropdown:addSeparator()
    editDropdown:addItem("Cut"):onClick(function()
        print("Edit > Cut clicked")
    end)
    editDropdown:addItem("Copy"):onClick(function()
        print("Edit > Copy clicked")
    end)
    editDropdown:addItem("Paste"):onClick(function()
        print("Edit > Paste clicked")
    end)

    local helpMenu = menuBar:addMenu("Help")
    local helpDropdown = helpMenu._dropdownMenu
    helpDropdown:addItem("About"):onClick(function()
        print("Help > About clicked")
    end)
    helpDropdown:addItem("Documentation"):onClick(function()
        print("Help > Documentation clicked")
    end)

    return menuBar
end

local function createTextButtonWithImageExample()
    local window = Window()
        :setTitle("Button with Image")
        :setSize(ennui.Size.auto(), ennui.Size.auto())
        :setPosition(900, 300)
        :setPadding(16, 16, 16, 16)

    local stackPanel = StackPanel()
        :setSpacing(8)
        :setSize(ennui.Size.auto(), ennui.Size.auto())

    local button = Button()
        :setSize(120, 120)
        :setPosition(900, 100)
        :setBackgroundColor(0.15, 0.15, 0.2, 1)
        :setHoverColor(0.25, 0.25, 0.3, 1)
        :setPressedColor(0.1, 0.1, 0.15, 1)
        :setLayoutStrategy(ennui.Layout.Overlay())
        :setPadding(16)
        :setMargin(16)
        :onClick(function()
            print("Image button clicked!")
            gameState.score = gameState.score + 10
            scoreLabel:setText("Score: " .. gameState.score)
        end)
        :addChild(
            Image()
            :setImagePath("assets/img/frog.png")
            :setSize(100, 100)
        )

    stackPanel:addChild(button)
    window:setContent(stackPanel)

    return window
end

local function createDockingExample()
    -- Create a DockSpace with a complex multi-split layout
    local dockSpace = DockSpace()
        :setPosition(20, 120)
        :setSize(800, 500)

    local dockTree = dockSpace.dockTree

    -- Create DockableWindow widgets for the predocked panels
    local editorWindow = DockableWindow()
        :setTitle("Editor")
        :setId("EditorWindow")
        :setSize(ennui.Size.auto(), ennui.Size.auto())
        :setDockSpace(dockSpace)
    editorWindow:setContent(StackPanel()
        :setSpacing(8)
        :setPadding(8, 8, 8, 8)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :addChild(Text()
            :setText("Editor")
            :setSize(ennui.Size.fill(), ennui.Size.auto()))
        :addChild(Image()
            :setImagePath("assets/img/frog.png")
            :setSize(ennui.Size.fill(), ennui.Size.fill())))

    local inspectorWindow = DockableWindow()
        :setTitle("Inspector")
        :setId("InspectorWindow")
        :setSize(ennui.Size.auto(), ennui.Size.auto())
        :setDockSpace(dockSpace)
    inspectorWindow:setContent(StackPanel()
        :setSpacing(8)
        :setPadding(8, 8, 8, 8)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :addChild(Text()
            :setText("Inspector")
            :setSize(ennui.Size.fill(), ennui.Size.auto()))
        :addChild(Image()
            :setImagePath("assets/img/frog.png")
            :setSize(ennui.Size.fill(), ennui.Size.fill())))

    local sceneWindow = DockableWindow()
        :setTitle("Scene")
        :setId("SceneWindow")
        --:setSize(ennui.Size.auto(), ennui.Size.auto())
        :setSize(250, 150)
        :setDockSpace(dockSpace)
    sceneWindow:setContent(StackPanel()
        :setSpacing(8)
        :setPadding(8, 8, 8, 8)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :addChild(Text()
            :setText("Scene")
            :setSize(ennui.Size.fill(), ennui.Size.auto()))
        :addChild(Image()
            :setImagePath("assets/img/frog.png")
            :setSize(ennui.Size.fill(), ennui.Size.fill())))

    local consoleWindow = DockableWindow()
        :setTitle("Console")
        :setId("ConsoleWindow")
        :setSize(ennui.Size.auto(), ennui.Size.auto())
        :setDockSpace(dockSpace)
    consoleWindow:setContent(StackPanel()
        :setSpacing(8)
        :setPadding(8, 8, 8, 8)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :addChild(Text()
            :setText("Console")
            :setSize(ennui.Size.fill(), ennui.Size.auto()))
        :addChild(Image()
            :setImagePath("assets/img/frog.png")
            :setSize(ennui.Size.fill(), ennui.Size.fill())))

    -- Set up initial dock structure by directly manipulating the tree
    -- Then hide titlebars and mark as docked
    
    -- Start with root as leaf
    dockTree:addWidget(editorWindow, false)
    editorWindow.props.isDocked = true
    -- editorWindow:setTitleBarVisibility(false)

    -- Split root horizontally: [editor(20%) | rest(80%)]
    dockTree:split("horizontal", 0.20)

    -- Add inspector to right child, then split it
    dockTree.rightChild:addWidget(inspectorWindow, false)
    inspectorWindow.props.isDocked = true
    inspectorWindow:setTitleBarVisibility(false)

    -- Split right child vertically: [inspector(33%) | rest(67%)]
    dockTree.rightChild:split("vertical", 1/3)

    -- Add scene to right child, then split it
    dockTree.rightChild.rightChild:addWidget(sceneWindow, false)
    sceneWindow.props.isDocked = true
    sceneWindow:setTitleBarVisibility(false)

    -- Split again: [scene(50%) | console(50%)]
    dockTree.rightChild.rightChild:split("vertical", 0.5)

    dockSpace:updateTabBars()
    -- Add console to right child
    dockTree.rightChild.rightChild.rightChild:addWidget(consoleWindow, false)
    consoleWindow.props.isDocked = true
    consoleWindow:setTitleBarVisibility(false)

    -- Add all docked windows as children of the DockSpace
    -- This must be done BEFORE layout so they render in correct z-order
    dockSpace:addChild(editorWindow)
    dockSpace:addChild(inspectorWindow)
    dockSpace:addChild(sceneWindow)
    dockSpace:addChild(consoleWindow)

    -- Trigger initial layout
    -- dockSpace:invalidateLayout()
    -- Find the node containing consoleWindow
    local node = dockSpace.dockTree:findNodeContainingWidget(consoleWindow)

    if node and node.tabBar then
        local tabBar = node.tabBar
        tabBar:setActiveTab(1)
    else
        print("consoleWindow is not in a tabbed node or has no tabBar")
    end

    -- Create floating dockable windows that can be dragged into the dock space
    local window1 = DockableWindow()
        :setTitle("Floating Panel 1")
        :setPosition(850, 120)
        :setSize(250, 150)
        :setId("Window1")
    window1:setContent(StackPanel()
        :setSpacing(8)
        :setPadding(8, 8, 8, 8)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :addChild(Text()
            :setText("Floating Panel 1")
            :setSize(ennui.Size.fill(), ennui.Size.auto()))
        :addChild(Image()
            :setImagePath("assets/img/frog.png")
            :setSize(ennui.Size.fill(), ennui.Size.fill())))
    window1:setDockSpace(dockSpace)

    local window2 = DockableWindow()
        :setTitle("Floating Panel 2")
        :setPosition(850, 280)
        :setSize(250, 150)
        :setId("Window2")
    window2:setContent(StackPanel()
        :setSpacing(8)
        :setPadding(8, 8, 8, 8)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :addChild(Text()
            :setText("Floating Panel 2")
            :setSize(ennui.Size.fill(), ennui.Size.auto()))
        :addChild(Image()
            :setImagePath("assets/img/frog.png")
            :setSize(ennui.Size.fill(), ennui.Size.fill())))
    window2:setDockSpace(dockSpace)

    local window3 = DockableWindow()
        :setTitle("Floating Panel 3")
        :setPosition(850, 440)
        :setSize(250, 150)
        :setId("Window3")
    window3:setContent(StackPanel()
        :setSpacing(8)
        :setPadding(8, 8, 8, 8)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :addChild(Text()
            :setText("Floating Panel 3")
            :setSize(ennui.Size.fill(), ennui.Size.auto()))
        :addChild(Image()
            :setImagePath("assets/img/frog.png")
            :setSize(ennui.Size.fill(), ennui.Size.fill())))
    window3:setDockSpace(dockSpace)

    return dockSpace, window1, window2, window3
end

function love.load()
    host = ennui.Host()
    host:setSize(love.graphics.getDimensions())

    local button, label = createSimpleTextButtonExample()
    host:addChild(button)
    host:addChild(label)

    -- Add docking example
    local dockSpace, dockWindow1, dockWindow2, dockWindow3 = createDockingExample()
    host:addChild(dockSpace)
    host:addChild(dockWindow1)
    host:addChild(dockWindow2)
    host:addChild(dockWindow3)

    -- host:addChild(createLoginWindow())
    -- host:addChild(createNestedLayoutExample())
    -- host:addChild(createDebugWindow())
    -- host:addChild(createShowcaseWindow())
    -- host:addChild(createMenuBarExample())
    -- host:addChild(createTextButtonWithImageExample())
    -- host:addChild(createReactivePropertiesExample())
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.12)

    host:draw()
end

function love.update(dt)
    host:update(dt)
end

function love.mousepressed(x, y, button, isTouch)
    host:mousepressed(x, y, button, isTouch)
end

function love.mousereleased(x, y, button, isTouch)
    host:mousereleased(x, y, button, isTouch)
end

function love.mousemoved(x, y, dx, dy, isTouch)
    host:mousemoved(x, y, dx, dy, isTouch)
end

function love.wheelmoved(dx, dy)
    host:wheelmoved(dx, dy)
end

function love.keypressed(key, scancode, isRepeat)
    if key == "escape" then
        love.event.quit()
    end

    host:keypressed(key, scancode, isRepeat)
end

function love.keyreleased(key, scancode)
    host:keyreleased(key, scancode)
end

function love.textinput(text)
    host:textinput(text)
end

function love.resize(w, h)
    host:setSize(w, h)
end