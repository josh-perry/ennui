local ennui = require("ennui")

local DockSpace = ennui.Widgets.Dockspace
local DockableWindow = ennui.Widgets.Dockablewindow
local StackPanel = ennui.Widgets.Stackpanel
local Text = ennui.Widgets.Text
local Checkbox = ennui.Widgets.Checkbox
local Slider = ennui.Widgets.Slider
local TreeView = ennui.Widgets.Treeview
local TreeViewNode = ennui.Widgets.Treeviewnode
local Image = ennui.Widgets.Image

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local dockSpace = DockSpace()
    :setPosition(0, 0)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

host:addChild(dockSpace)

local editorWindow = DockableWindow()
    :setTitle("Editor")
    :setSize(ennui.Size.auto(), ennui.Size.auto())
    :setDockSpace(dockSpace)

local editorPanel = StackPanel()
    :setSpacing(8)
    :setPadding(8)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

editorPanel:addChild(Text("Main Editor Area"):setColor(1, 1, 0.5))
editorPanel:addChild(Text("Drag windows to dock/undock"):setColor(0.7, 0.7, 0.7))
editorPanel:addChild(Image()
    :setImagePath("examples/assets/img/frog.png")
    :setSize(ennui.Size.auto(), ennui.Size.auto()))

editorWindow:setContent(editorPanel)

local propertiesWindow = DockableWindow()
    :setTitle("Properties")
    :setSize(ennui.Size.auto(), ennui.Size.auto())
    :setDockSpace(dockSpace)

local propertiesPanel = StackPanel()
    :setSpacing(8)
    :setPadding(8)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

propertiesPanel:addChild(Text("Transform"):setColor(1, 1, 0.5))
propertiesPanel:addChild(Text("Position X:"):setColor(0.8, 0.8, 0.8))
propertiesPanel:addChild(Slider(0, 100, 50))
propertiesPanel:addChild(Text("Position Y:"):setColor(0.8, 0.8, 0.8))
propertiesPanel:addChild(Slider(0, 100, 50))
propertiesPanel:addChild(Text("Rotation:"):setColor(0.8, 0.8, 0.8))
propertiesPanel:addChild(Slider(0, 360, 0))

propertiesWindow:setContent(propertiesPanel)

local hierarchyWindow = DockableWindow()
    :setTitle("Hierarchy")
    :setSize(ennui.Size.auto(), ennui.Size.auto())
    :setDockSpace(dockSpace)

local treeView = TreeView()
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setRowHeight(24)

local root = TreeViewNode("Scene", "scene")
local camera = TreeViewNode("Main Camera", "camera")
local player = TreeViewNode("Player", "player")
local playerSprite = TreeViewNode("Sprite", "sprite")
local enemies = TreeViewNode("Enemies", "enemies")
local enemy1 = TreeViewNode("Enemy 1", "enemy1")
local enemy2 = TreeViewNode("Enemy 2", "enemy2")

player:addChild(playerSprite)
enemies:addChild(enemy1)
enemies:addChild(enemy2)
root:addChild(camera)
root:addChild(player)
root:addChild(enemies)
treeView:addChild(root)

hierarchyWindow:setContent(treeView)

local consoleWindow = DockableWindow()
    :setTitle("Console")
    :setSize(ennui.Size.auto(), ennui.Size.auto())
    :setDockSpace(dockSpace)

local consolePanel = StackPanel()
    :setSpacing(4)
    :setPadding(8)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

consolePanel:addChild(Text("[INFO] Application started"):setColor(0.7, 0.9, 0.7))
consolePanel:addChild(Text("[INFO] Loading assets..."):setColor(0.7, 0.9, 0.7))
consolePanel:addChild(Text("[WARN] Missing texture"):setColor(1, 0.9, 0.5))
consolePanel:addChild(Text("[INFO] Scene loaded"):setColor(0.7, 0.9, 0.7))

consoleWindow:setContent(consolePanel)

local dockTree = dockSpace.dockTree

dockTree:addWidget(editorWindow, false)
editorWindow.props.isDocked = true

dockTree:split("horizontal", 0.20)

dockTree.rightChild:addWidget(propertiesWindow, false)
propertiesWindow.props.isDocked = true

dockTree.rightChild:split("vertical", 0.70)

dockTree.rightChild.rightChild:addWidget(consoleWindow, false)
consoleWindow.props.isDocked = true

dockTree.leftChild:addWidget(hierarchyWindow, false)
hierarchyWindow.props.isDocked = true

dockSpace:addChild(editorWindow)
dockSpace:addChild(propertiesWindow)
dockSpace:addChild(hierarchyWindow)
dockSpace:addChild(consoleWindow)

local floatingWindow = DockableWindow()
    :setTitle("Floating Panel")
    :setPosition(500, 200)
    :setSize(220, 180)
    :setDockSpace(dockSpace)

local floatingPanel = StackPanel()
    :setSpacing(8)
    :setPadding(8)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

floatingPanel:addChild(Text("Drag me to dock!"):setColor(1, 1, 0.5))
floatingPanel:addChild(Checkbox("Option A"))
floatingPanel:addChild(Checkbox("Option B"):setChecked(true))

floatingWindow:setContent(floatingPanel)
host:addChild(floatingWindow)

return host
