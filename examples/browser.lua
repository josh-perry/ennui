local Widget = require("ennui.widget")
local ennui = require("ennui")
local Size = ennui.Size

local debugger = require("ennui.debug")

local Host = ennui.Widgets.Host
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local StackPanel = ennui.Widgets.Stackpanel
local ScrollArea = ennui.Widgets.Scrollarea
local TreeView = ennui.Widgets.Treeview
local TreeViewNode = ennui.Widgets.Treeviewnode
local TextInput = ennui.Widgets.Textinput
local Text = ennui.Widgets.Text
local Splitter = ennui.Widgets.Splitter

local examples = require("examples")

---@class ExamplePreview : Widget
---@field __canvas love.Canvas? Offscreen canvas for rendering the example
---@field __widgetW number Last known width of the widget
---@field __widgetH number Last known height of the widget
local ExamplePreview = {}
ExamplePreview.__index = ExamplePreview
setmetatable(ExamplePreview, {
    __index = Widget,
    __call = function(class, ...)
        return class.new(...)
    end
})

function ExamplePreview:__tostring()
    return "ExamplePreview"
end

local smallCanvasWidth, smallCanvasHeight = 320, 288

function ExamplePreview.new()
    local self = setmetatable(Widget(), ExamplePreview) ---@cast self ExamplePreview
    self.__canvas = nil
    self.__widgetW = 0
    self.__widgetH = 0

    self:addProperty("example", nil)

    self:watch("example", function(example)
        debugger:setTargetHost(example.host)
    end)

    self:setFocusable(true)
    self:setSize(Size.fill(), Size.fill())
    return self
end

function ExamplePreview:setExample(example)
    if self.props.example == example then
        return
    end

    self.props.example = example

    if example then
        if example.smallCanvas then
            if not self.__canvas or self.__canvas:getWidth() ~= smallCanvasWidth or self.__canvas:getHeight() ~= smallCanvasHeight then
                self.__canvas = love.graphics.newCanvas(smallCanvasWidth, smallCanvasHeight)
            end

            example.host:setSize(smallCanvasWidth, smallCanvasHeight)
        elseif self.__widgetW > 0 and self.__widgetH > 0 then
            local cw = math.max(1, self.__widgetW)
            local ch = math.max(1, self.__widgetH)

            if not self.__canvas or self.__canvas:getWidth() ~= cw or self.__canvas:getHeight() ~= ch then
                self.__canvas = love.graphics.newCanvas(cw, ch)
            end

            example.host:setSize(cw, ch)
        end
    end

    self:invalidateRender()
end

function ExamplePreview:arrange(x, y, w, h)
    Widget.arrange(self, x, y, w, h)

    local newW, newH = self.width, self.height
    local sizeChanged = (newW ~= self.__widgetW or newH ~= self.__widgetH)

    self.__widgetW = newW
    self.__widgetH = newH

    if self.props.example and self.props.example.smallCanvas then
        if not self.__canvas then
            self.__canvas = love.graphics.newCanvas(smallCanvasWidth, smallCanvasHeight)
            self.props.example.host:setSize(smallCanvasWidth, smallCanvasHeight)
        end
    elseif sizeChanged or not self.__canvas then
        local cw = math.max(1, newW)
        local ch = math.max(1, newH)

        if not self.__canvas or self.__canvas:getWidth() ~= cw or self.__canvas:getHeight() ~= ch then
            self.__canvas = love.graphics.newCanvas(cw, ch)

            if self.props.example then
                self.props.example.host:setSize(cw, ch)
            end
        end
    end
end

function ExamplePreview:onUpdate(dt)
    if self.props.example then
        self.props.example.host:update(dt)
    end
end

function ExamplePreview:onRender()
    if not self.props.example or not self.__canvas then
        return
    end

    local example = self.props.example

    love.graphics.setCanvas(self.__canvas)
    love.graphics.clear(0.08, 0.08, 0.08, 1)
    love.graphics.setColor(1, 1, 1, 1)

    example.host:draw()
    debugger:drawOverlay()

    love.graphics.setCanvas()

    love.graphics.setColor(1, 1, 1, 1)
    if example.smallCanvas then
        local scale = math.floor(math.min(self.width / smallCanvasWidth, self.height / smallCanvasHeight))

        local sw = smallCanvasWidth * scale
        local sh = smallCanvasHeight * scale
        local ox = self.x + (self.width - sw) / 2
        local oy = self.y + (self.height - sh) / 2

        love.graphics.draw(self.__canvas, ox, oy, 0, scale, scale)
    else
        love.graphics.draw(self.__canvas, self.x, self.y)
    end
end

local function transformCoords(self, x, y)
    if not self._example or not self._example.smallCanvas then
        return x - self.x, y - self.y
    end

    local scale = math.floor(math.min(self.width / smallCanvasWidth, self.height / smallCanvasHeight))
    local ox = self.x + (self.width - smallCanvasWidth * scale) / 2
    local oy = self.y + (self.height - smallCanvasHeight * scale) / 2

    return (x - ox) / scale, (y - oy) / scale
end

function ExamplePreview:onMousePressed(event)
    if not self.props.example then return end

    local lx, ly = transformCoords(self, event.x, event.y)
    return self.props.example.host:mousepressed(lx, ly, event.button, event.isTouch)
end

function ExamplePreview:onMouseReleased(event)
    if not self.props.example then return end

    local lx, ly = transformCoords(self, event.x, event.y)
    return self.props.example.host:mousereleased(lx, ly, event.button, event.isTouch)
end

function ExamplePreview:onMouseMoved(event)
    if not self.props.example then return end

    local lx, ly = transformCoords(self, event.x, event.y)
    return self.props.example.host:mousemoved(lx, ly, event.dx, event.dy, event.isTouch)
end

function ExamplePreview:onMouseWheel(event)
    if not self.props.example then return end

    return self.props.example.host:wheelmoved(event.dx, event.dy)
end

function ExamplePreview:onKeyPressed(event)
    if not self.props.example then return end

    return self.props.example.host:keypressed(event.key, event.scancode, event.isRepeat)
end

function ExamplePreview:onKeyReleased(event)
    if not self.props.example then return end

    return self.props.example.host:keyreleased(event.key, event.scancode)
end

function ExamplePreview:onTextInput(event)
    if not self.props.example then return end

    return self.props.example.host:textinput(event.text)
end

local exampleByName = {}

for _, example in ipairs(examples) do
    exampleByName[example.name] = example
end

local allItems = {}

for _, example in ipairs(examples) do
    table.insert(allItems, {
        name = example.name,
        tags = example.tags or {},
        description = example.description or "",
    })
end

local browserState = ennui.State({
    allItems = allItems,
    filteredItems = allItems,
    selectedName = nil,
})

local w, h = love.graphics.getDimensions()
local browserHost = Host.new(w, h)

local leftWidth = 280

-- Left panel
local leftPanel = StackPanel()
    :setSpacing(0)
    :setSize(Size.fixed(leftWidth), Size.fill())

local filterInput = TextInput()
    :setSize(Size.fill(), Size.fixed(30))
    :setPlaceholder("Filter...")

local scrollArea = ScrollArea()
    :setSize(Size.fill(), Size.fill())

local treeView = TreeView()
    :setSize(Size.fill(), Size.auto())

scrollArea:addChild(treeView)
leftPanel:addChild(filterInput)
leftPanel:addChild(scrollArea)

-- Splitter
local splitter = Splitter("horizontal")

splitter.onSplitterDrag = function(delta)
    leftWidth = math.max(150, math.min(600, leftWidth + delta))
    leftPanel:setSize(Size.fixed(leftWidth), Size.fill())
end

-- Right panel
local rightPanel = StackPanel()
    :setSpacing(0)
    :setSize(Size.fill(), Size.fill())

local infoBar = StackPanel()
    :setSpacing(4)
    :setPadding(8)
    :setSize(Size.fill(), Size.auto())

local nameText = Text("Select an example")
    :setFont(love.graphics.newFont(16))
    :setSize(Size.fill(), Size.auto())
    :bindTo("text", browserState:computedInline(function()
        return browserState.props.selectedName or "Select an example"
    end))

local tagsText = Text("")
    :setColor(0.5, 0.5, 0.5, 1)
    :setSize(Size.fill(), Size.auto())
    :bindTo("text", browserState:computedInline(function()
        local name = browserState.props.selectedName

        if not name then
            return ""
        end

        local example = exampleByName[name]

        local tagParts = {}

        for _, tag in ipairs(example.tags) do
            table.insert(tagParts, ("#%s"):format(tag))
        end

        return table.concat(tagParts, " ")
    end))

local descriptionText = Text("")
    :setSize(Size.fill(), Size.auto())
    :bindTo("text", browserState:computedInline(function()
        local name = browserState.props.selectedName

        if not name then
            return ""
        end

        return exampleByName[name].description or ""
    end))

local previewWidget = ExamplePreview.new()

browserState:watch("selectedName", function(name)
    if name then
        local example = exampleByName[name]

        if example then
            previewWidget:setExample(example)
        end
    end

    infoBar:invalidateLayout()
end)

treeView:bindChildren(browserState, "filteredItems", {
    key = "name",
    create = function(item)
        local example = exampleByName[item.name]
        local node = TreeViewNode(item.name, example)

        node:watch("selected", function(newSelection)
            if newSelection then
                browserState.props.selectedName = item.name
            end
        end)

        return node
    end,
    onRemove = function(widget)
        if treeView.selectedNode == widget then
            treeView.selectedNode = nil
        end
    end,
})

filterInput:watch("value", function(text)
    text = text:lower()

    if text == "" then
        browserState.props.filteredItems = allItems
        return
    end

    local filtered = {}

    for _, item in ipairs(allItems) do
        local nameMatch = item.name:lower():find(text, 1, true)
        local tagMatch = false

        if not nameMatch then
            for _, tag in ipairs(item.tags) do
                if tag:lower():find(text, 1, true) then
                    tagMatch = true
                    break
                end
            end
        end

        if nameMatch or tagMatch then
            table.insert(filtered, item)
        end
    end

    browserState.props.filteredItems = filtered
end)

infoBar:addChild(nameText)
infoBar:addChild(tagsText)
infoBar:addChild(descriptionText)

rightPanel:addChild(infoBar)
rightPanel:addChild(previewWidget)

local outerPanel = HorizontalStackPanel()
    :setSpacing(0)
    :setSize(Size.fill(), Size.fill())

outerPanel:addChild(leftPanel)
outerPanel:addChild(splitter)
outerPanel:addChild(rightPanel)

browserHost:addChild(outerPanel)

return browserHost
