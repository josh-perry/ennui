local ennui = require("ennui")

local Host = ennui.Widgets.Host
local Rectangle = ennui.Widgets.Rectangle
local StackPanel = ennui.Widgets.Stackpanel
local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local Text = ennui.Widgets.Text

local host = Host():setSize(love.graphics.getDimensions())

local font = love.graphics.newFont("examples/assets/fonts/OpenCherry-Regular.otf", 16)

local COL_KEY     = {0.22, 0.22, 0.25}
local COL_PRESSED = {0.9,  0.8,  0.2 }
local COL_TEXT    = {0.9,  0.9,  0.9 }

local rows = {
    {
        { "`", "`" },
        { "1", "1" }, { "2", "2" }, { "3", "3" },
        { "4", "4" }, { "5", "5" }, { "6", "6" },
        { "7", "7" }, { "8", "8" }, { "9", "9" },
        { "0", "0" }, { "-", "-" }, { "=", "=" },
        { "backspace", "BS", 58 },
    },
    {
        { "tab", "Tab", 50 },
        { "q",   "Q" }, { "w", "W" }, { "e", "E" }, { "r", "R" }, { "t", "T" },
        { "y", "Y" }, { "u", "U" }, { "i", "I" }, { "o", "O" }, { "p", "P" },
        { "[", "[" }, { "]", "]" },
        { "\\", "\\", 42 },
    },
    {
        { "capslock", "Caps", 58 },
        { "a", "A" }, { "s", "S" }, { "d", "D" }, { "f", "F" }, { "g", "G" },
        { "h", "H" }, { "j", "J" }, { "k", "K" }, { "l", "L" }, { ";", ";" },
        { "'", "'" },
        { "return", "Return", 64 },
    },
    {
        { "lshift", "LShift", 76 },
        { "z",      "Z" }, { "x", "X" }, { "c", "C" }, { "v", "V" }, { "b", "B" },
        { "n",      "N" }, { "m", "M" }, { ",", "," }, { ".", "." }, { "/", "/" },
        { "rshift", "RShift", 76 },
    },
    {
        { "lctrl", "Ctrl",  76 / 2 },
        { "lgui",  "Win",   76 / 2 },
        { "lalt",  "Alt",   48 },
        { "space", "Space", 240 },
        { "ralt",  "Alt",   48 },
        { "rgui",  "Win",   76 / 2 },
        { "rctrl", "Ctrl",  76 / 2 },
    },
}

local keyWidgets = {}

local function makeKey(keyName, label, w)
    local keyW = w or 34
    local rect = Rectangle()
        :setSize(ennui.Size.fixed(keyW), ennui.Size.fixed(34))
        :setColor(COL_KEY[1], COL_KEY[2], COL_KEY[3])
        :setRadius(3)

    local lbl = Text(label)
        :setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3])
        :setFont(font)
        :setTextHorizontalAlignment("center")
        :setTextVerticalAlignment("center")
        :setSize(ennui.Size.fill(), ennui.Size.fill())

    rect:addChild(lbl)
    keyWidgets[keyName] = rect
    return rect
end

local root = StackPanel()
    :setSpacing(8)
    :setPadding(14)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local lastKeyLabel = Text("Press any key...")
    :setColor(0.9, 0.9, 0.5)
    :setFont(font)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local keyboardPanel = StackPanel()
    :setFocusable(true)
    :setSpacing(4)
    :setSize(ennui.Size.auto(), ennui.Size.auto())

for _, row in ipairs(rows) do
    local rowPanel = HorizontalStackPanel()
        :setSpacing(3)
        :setSize(ennui.Size.auto(), ennui.Size.auto())

    for _, keyDef in ipairs(row) do
        rowPanel:addChild(makeKey(keyDef[1], keyDef[2], keyDef[3]))
    end

    keyboardPanel:addChild(rowPanel)
end

root:addChild(lastKeyLabel)
root:addChild(keyboardPanel)

host:addChild(root)
keyboardPanel:focus()

keyboardPanel:onKeyPressed(function(_, event)
    if event.isRepeat then
        return
    end

    lastKeyLabel:setText(("Last key: %s  (scancode: %s)"):format(event.key, event.scancode))

    local w = keyWidgets[event.key]
    if w then
        w:setColor(COL_PRESSED[1], COL_PRESSED[2], COL_PRESSED[3])
    end
end)

keyboardPanel:onKeyReleased(function(_, event)
    local w = keyWidgets[event.key]
    if w then
        w:setColor(COL_KEY[1], COL_KEY[2], COL_KEY[3])
    end
end)

return host
