local ennui = require("ennui")

local Host = ennui.Widgets.Host
local Rectangle = ennui.Widgets.Rectangle
local Text = ennui.Widgets.Text
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local StackPanel = ennui.Widgets.Stackpanel

local host = Host()
host:setSize(love.graphics.getWidth(), love.graphics.getHeight())

local root = HorizontalStackPanel()
    :setPadding(20)
    :setSpacing(20)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local ghostColumn = StackPanel()
    :setSpacing(10)
    :setSize("fill", "fill")

local ghostTitle = Text()
    :setText("Ghost Mode (for kanban-style UIs)")
    :setSize("fill", "auto")

local ghostBox1 = Rectangle()
    :setSize(200, 80)
    :setColor(0.3, 0.6, 0.9)
    :setDraggable(true)
    :setDragMode("ghost")

local ghostText1 = Text()
    :setText("Drag me!\n(ghost mode)")
    :setSize("fill", "fill")
    :setTextHorizontalAlignment("center")
    :setTextVerticalAlignment("center")
    :setColor(1, 1, 1)

ghostBox1:addChild(ghostText1)

local ghostBox2 = Rectangle()
    :setSize(200, 80)
    :setColor(0.6, 0.3, 0.9)
    :setDraggable(true)
    :setDragMode("ghost")

local ghostText2 = Text()
    :setText("Or drag me!\n(stays in layout)")
    :setSize("fill", "fill")
    :setTextHorizontalAlignment("center")
    :setTextVerticalAlignment("center")
    :setColor(1, 1, 1)

ghostBox2:addChild(ghostText2)

ghostColumn:addChild(ghostTitle)
ghostColumn:addChild(ghostBox1)
ghostColumn:addChild(ghostBox2)

local posColumn = StackPanel()
    :setSpacing(10)
    :setSize("fill", "fill")

local posTitle = Text()
    :setText("Position Mode (for repositioning)")
    :setSize("fill", "auto")

local posBox = Rectangle()
    :setSize(200, 80)
    :setColor(0.9, 0.6, 0.3)
    :setDraggable(true)
    :setDragMode("position")

local posText = Text()
    :setText("Drag me!\n(position mode)")
    :setSize("fill", "fill")
    :setTextHorizontalAlignment("center")
    :setTextVerticalAlignment("center")
    :setColor(1, 1, 1)

posBox:addChild(posText)

local posBox2 = Rectangle()
    :setSize(200, 80)
    :setColor(0.3, 0.9, 0.6)
    :setDraggable(true)
    :setDragMode("position")

local posText2 = Text()
    :setText("Or drag me!\n(children follow)")
    :setSize("fill", "fill")
    :setTextHorizontalAlignment("center")
    :setTextVerticalAlignment("center")
    :setColor(1, 1, 1)

posBox2:addChild(posText2)

posColumn:addChild(posTitle)
posColumn:addChild(posBox)
posColumn:addChild(posBox2)

local deltaColumn = StackPanel()
    :setSpacing(10)
    :setSize("fill", "fill")

local deltaTitle = Text()
    :setText("Delta Mode (custom handling)")
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local deltaInfo = Text()
    :setText("Delta: 0, 0")
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local deltaBox = Rectangle()
    :setSize(200, 80)
    :setColor(0.9, 0.3, 0.6)
    :setDraggable(true)
    :setDragMode("delta")

local deltaText = Text()
    :setText("Drag me!\n(delta mode)")
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setTextHorizontalAlignment("center")
    :setTextVerticalAlignment("center")
    :setColor(1, 1, 1)

deltaBox:addChild(deltaText)

deltaBox.onDrag = function(event, dx, dy)
    deltaInfo:setText(string.format("Delta: %.1f, %.1f", dx or 0, dy or 0))
end

deltaBox.onDragEnd = function(event)
    deltaInfo:setText("Delta: 0, 0")
end

deltaColumn:addChild(deltaTitle)
deltaColumn:addChild(deltaInfo)
deltaColumn:addChild(deltaBox)

local dropColumn = StackPanel()
    :setSpacing(10)
    :setSize("fill", "fill")

local dropTitle = Text()
    :setText("Drop Zone")
    :setSize("fill", "auto")

local lastDroppedText = "Dropzone"

local dropZoneText = Text()
    :setText("Dropzone")
    :setSize("fill", "fill")
    :setTextHorizontalAlignment("center")
    :setTextVerticalAlignment("center")
    :setColor(0.4, 0.4, 0.4)

local dropZone = Rectangle()
    :setSize(200, 120)
    :setColor(0.85, 0.85, 0.85)
    :setDropTarget(true)

dropZone:addChild(dropZoneText)

dropZone.onDragOver = function(event, draggedWidget)
    dropZoneText:setText("Drop widget here!")
    dropZoneText:setColor(0.2, 0.6, 0.2)
    dropZone:setColor(0.75, 0.9, 0.75)
end

dropZone.onDragLeave = function(event, draggedWidget)
    dropZoneText:setText(lastDroppedText)
    dropZoneText:setColor(0.4, 0.4, 0.4)
    dropZone:setColor(0.85, 0.85, 0.85)
end

dropZone.onDrop = function(event, draggedWidget)
    for _, child in ipairs(draggedWidget.children) do
        if child.getText then
            lastDroppedText = child:getText()
            break
        end
    end

    if draggedWidget.parent then
        draggedWidget.parent:removeChild(draggedWidget)
    end
end

dropColumn:addChild(dropTitle)
dropColumn:addChild(dropZone)

root:addChild(ghostColumn)
root:addChild(posColumn)
root:addChild(deltaColumn)
root:addChild(dropColumn)

host:addChild(root)

return host
