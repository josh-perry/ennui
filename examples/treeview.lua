local ennui = require("ennui")

local TreeView = ennui.Widgets.Treeview
local TreeViewNode = ennui.Widgets.Treeviewnode
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window
local ScrollArea = ennui.Widgets.Scrollarea

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("TreeView Example")
    :setSize(350, 600)
    :setPosition(100, 100)

local treeView = TreeView()
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setRowHeight(26)
    :setIndentSize(20)

local scrollArea = ScrollArea()
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local function sortFiles(a, b)
    local aInfo = love.filesystem.getInfo(a)
    local bInfo = love.filesystem.getInfo(b)

    if not aInfo or not bInfo then
        return a < b
    end

    if aInfo.type == "directory" and bInfo.type ~= "directory" then
        return true
    elseif bInfo.type == "directory" and aInfo.type ~= "directory" then
        return false
    end
end

local function recursivelyGetFileList(path, node)
    local files = love.filesystem.getDirectoryItems(path)

    table.sort(files, sortFiles)

    for _, file in ipairs(files) do
        local fullPath = path .. "/" .. file
        local info = love.filesystem.getInfo(fullPath)
        local childNode = TreeViewNode(file)

        node:addChild(childNode)

        if info.type == "directory" then
            recursivelyGetFileList(fullPath, childNode)
        end
    end

    return node
end

local root = TreeViewNode("ennui")
recursivelyGetFileList("ennui", root)

treeView:addChild(root)

scrollArea:addChild(treeView)
window:setContent(scrollArea)
host:addChild(window)

return host
