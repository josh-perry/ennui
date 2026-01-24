local ennui = require("ennui")

local CollapseableHeader = require("widgets.collapseableheader")
local StackPanel = require("widgets.stackpanel")
local ScrollArea = require("widgets.scrollarea")
local Text = require("widgets.text")
local Checkbox = require("widgets.checkbox")
local Slider = require("widgets.slider")
local Window = require("widgets.window")

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Collapseable Header Example")
    :setSize(380, 450)
    :setPosition(100, 100)

local scrollArea = ScrollArea()
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local panel = StackPanel()
    :setSpacing(2)
    :setSize(ennui.Size.fill(), ennui.Size.auto())

local audioSection = CollapseableHeader("Audio Settings", true)
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setPadding(10, 10, 10, 10)

local musicVolume = Slider(0, 100, 80)
local sfxVolume = Slider(0, 100, 100)
local muteCheckbox = Checkbox("Mute all audio")

audioSection:addChild(Text("Music Volume:"):setColor(0.8, 0.8, 0.8))
audioSection:addChild(musicVolume)
audioSection:addChild(Text("SFX Volume:"):setColor(0.8, 0.8, 0.8))
audioSection:addChild(sfxVolume)
audioSection:addChild(muteCheckbox)

local videoSection = CollapseableHeader("Video Settings", false)
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setPadding(10, 10, 10, 10)

local brightness = Slider(0, 100, 50)
local fullscreenCheckbox = Checkbox("Fullscreen")
local vsyncCheckbox = Checkbox("V-Sync"):setChecked(true)

videoSection:addChild(Text("Brightness:"):setColor(0.8, 0.8, 0.8))
videoSection:addChild(brightness)
videoSection:addChild(fullscreenCheckbox)
videoSection:addChild(vsyncCheckbox)

local controlsSection = CollapseableHeader("Controls", false)
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setPadding(10, 10, 10, 10)

controlsSection:addChild(Text("Move: WASD"):setColor(0.8, 0.8, 0.8))
controlsSection:addChild(Text("Jump: Space"):setColor(0.8, 0.8, 0.8))
controlsSection:addChild(Text("Attack: Left Click"):setColor(0.8, 0.8, 0.8))
controlsSection:addChild(Text("Interact: E"):setColor(0.8, 0.8, 0.8))
controlsSection:addChild(Text("Inventory: I"):setColor(0.8, 0.8, 0.8))

local accessSection = CollapseableHeader("Accessibility", false)
    :setSize(ennui.Size.fill(), ennui.Size.auto())
    :setPadding(10, 10, 10, 10)
    :setAnimationSpeed(12)

accessSection:addChild(Checkbox("High Contrast Mode"))
accessSection:addChild(Checkbox("Screen Reader"))
accessSection:addChild(Checkbox("Reduce Motion"))
accessSection:addChild(Checkbox("Large Text"))

panel:addChild(audioSection)
panel:addChild(videoSection)
panel:addChild(controlsSection)
panel:addChild(accessSection)

scrollArea:addChild(panel)
window:setContent(scrollArea)
host:addChild(window)

return host
