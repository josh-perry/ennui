local ennui = require("ennui")

local TextInput = ennui.Widgets.Textinput
local StackPanel = ennui.Widgets.Stackpanel
local Text = ennui.Widgets.Text
local Window = ennui.Widgets.Window

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local window = Window("Text Input Example")
    :setSize(400, 320)
    :setPosition(100, 100)

local panel = StackPanel()
    :setSpacing(10)
    :setPadding(10)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local usernameLabel = Text("Username:"):setColor(1, 1, 1)
local usernameInput = TextInput()
    :setPlaceholder("Enter your username")
    :setSize(ennui.Size.fill(), 32)

local emailLabel = Text("Email:"):setColor(1, 1, 1)
local emailInput = TextInput()
    :setPlaceholder("user@example.com")
    :setSize(ennui.Size.fill(), 32)

local passwordLabel = Text("Password:"):setColor(1, 1, 1)
local passwordInput = TextInput()
    :setPlaceholder("Enter password")
    :setPassword(true)
    :setSize(ennui.Size.fill(), 32)

local previewText = Text("Preview: ")
    :setColor(0.7, 0.9, 1)

usernameInput:on("textInput", function(_, event)
    previewText:setText("Preview: " .. usernameInput:getText())
end)

usernameInput:on("keyPressed", function(_, event)
    if event.value then
        previewText:setText("Preview: " .. event.value)
    end
end)

panel:addChild(usernameLabel)
panel:addChild(usernameInput)
panel:addChild(emailLabel)
panel:addChild(emailInput)
panel:addChild(passwordLabel)
panel:addChild(passwordInput)
panel:addChild(previewText)

window:setContent(panel)
host:addChild(window)

return host
