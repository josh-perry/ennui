local ennui = require("ennui")

local HorizontalStackPanel = require("widgets.horizontalstackpanel")
local StackPanel = require("widgets.stackpanel")
local TextButton = require("widgets.textbutton")
local Text = require("widgets.text")
local Rectangle = require("widgets.rectangle")
local Image = require("widgets.image")

local BorderBox = function()
    local rectangle = Rectangle()
        :setColor(0, 0, 0.35)
        :setBorderColor(0.7, 0.7, 0.7)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :setPadding(4, 4, 4, 4)
        :setRadius(0)

    return rectangle
end

local font = love.graphics.newFont("examples/assets/fonts/m5x7.ttf", 16)

local HeaderText = function(text)
    return Text(text)
        :setColor(0.4, 0.8, 1)
        :setFont(font)
end

local NormalText = function(text)
    return Text(text)
        :setColor(1, 1, 1)
        :setFont(font)
end

local state = {
    characters = {
        {
            name = "Frog",
            stats = {
                level = 15,
                currentHp = 320,
                maxHp = 350,
                currentMp = 45,
                maxMp = 60
            },
            image = "examples/assets/img/frog.png"
        },
        {
            name = "Lucca",
            stats = {
                level = 14,
                currentHp = 280,
                maxHp = 300,
                currentMp = 20,
                maxMp = 30
            },
            image = "examples/assets/img/lucca.png"
        },
        {
            name = "Crono",
            stats = {
                level = 13,
                currentHp = 200,
                maxHp = 220,
                currentMp = 80,
                maxMp = 100
            },
            image = "examples/assets/img/crono.png"
        },
        {
            name = "Graggle Simpson",
            stats = {
                level = 14,
                currentHp = 180,
                maxHp = 180,
                currentMp = 80,
                maxMp = 100
            },
            image = "examples/assets/img/graggle.png"
        }
    }
}

local host = ennui.Widgets.Host()
    :setSize(love.graphics.getDimensions())

local horizontalStackPanel = HorizontalStackPanel()
    :setSpacing(4)
    :setPadding(4)
    :setSize(ennui.Size.fill(), ennui.Size.fill())

local leftStackPanel = StackPanel()
    :setSpacing(5)
    :setSize(ennui.Size.percent(0.66), ennui.Size.fill())

local rightStackPanel = StackPanel()
    :setSpacing(5)
    :setSize(ennui.Size.percent(0.33), ennui.Size.fill())

-- Left stack panel
-- Characters
do
    local characterStackPanel = StackPanel()
        :setSpacing(5)
        :setSize(ennui.Size.fill(), ennui.Size.fill())

    for _, character in ipairs(state.characters) do
        local characterBox = BorderBox()
            :setSize(ennui.Size.fill(), ennui.Size.fill())
            :setPadding(4, 8, 4, 8)

        local characterHorizontalPanel = HorizontalStackPanel()
            :setSpacing(10)
            :setSize(ennui.Size.fill(), ennui.Size.auto())

        local characterImage = Image(love.graphics.newImage(character.image))
            :setSize(ennui.Size.auto(), ennui.Size.fill())
            :setSizeConstraint(ennui.SizeConstraint.square)
            :setVerticalAlignment("center")

        characterHorizontalPanel:addChild(characterImage)

        local characterInfoStackPanel = StackPanel()
            :setSpacing(0)
            :setSize(ennui.Size.fill(), ennui.Size.auto())

        characterInfoStackPanel:addChild(NormalText(character.name))

        local statsGrid = ennui.Widget()
            :setSize(ennui.Size.fill(), ennui.Size.auto())
            :setLayoutStrategy(ennui.Layout.Grid(2, 3)
            :setSpacing(0))

        statsGrid:addChild(HeaderText("Level:"))
        statsGrid:addChild(NormalText(tostring(character.stats.level)))
        statsGrid:addChild(HeaderText("HP:"))
        statsGrid:addChild(NormalText(("%d / %d"):format(
            character.stats.currentHp,
            character.stats.maxHp
        )))

        statsGrid:addChild(HeaderText("MP:"))
        statsGrid:addChild(NormalText(("%d / %d"):format(
            character.stats.currentMp,
            character.stats.maxMp
        )))

        characterInfoStackPanel:addChild(statsGrid)

        characterHorizontalPanel:addChild(characterInfoStackPanel)
        characterBox:addChild(characterHorizontalPanel)
        characterStackPanel:addChild(characterBox)
    end

    leftStackPanel:addChild(characterStackPanel)
end

-- Right stack panel
-- Menu - Location - Stats
do
    local menuStackPanel = StackPanel()
        :setSpacing(5)
        :setSize(ennui.Size.fill(), ennui.Size.fill())

    for _, v in ipairs({
        "Items",
        "Magic",
        "Equip",
        "Status",
        "Formation",
        "Config",
    }) do
        local buttonBox = BorderBox()
            :setSize(ennui.Size.fill(), ennui.Size.fill())
            :setPadding(4, 8, 4, 8)

        local button = TextButton(v)
            :setSize(ennui.Size.fill(), 50)
            :setBackgroundColor(0, 0, 0, 0)
            :setFont(font)

        buttonBox:addChild(button)
        menuStackPanel:addChild(buttonBox)
    end

    local statsBox = BorderBox()
        :setSize(ennui.Size.fill(), ennui.Size.auto())
        :setLayoutStrategy(ennui.Layout.Vertical():setSpacing(5))
        :setPadding(4, 8, 4, 8)

    statsBox:addChild(NormalText("Town Square")
        :setSize(ennui.Size.auto(), ennui.Size.auto())
        :setHorizontalAlignment("center"))

    local statsGrid = ennui.Widget()
        :setSize(ennui.Size.fill(), ennui.Size.auto())
        :setLayoutStrategy(ennui.Layout.Grid(2, 3):setSpacing(5))

    timeWidget = ennui.Widget()
        :addProperty("time", 0)

    local timeComputed = timeWidget:computed("time", function()
        return tostring(math.floor(timeWidget.props.time))
    end)

    statsGrid:addChild(HeaderText("Time:"))
    statsGrid:addChild(NormalText()
        :bindTo("text", timeComputed)
    )

    statsGrid:addChild(HeaderText("Gold:"))
    statsGrid:addChild(NormalText("45190"))

    statsGrid:addChild(HeaderText("Steps:"))
    statsGrid:addChild(NormalText("66902"))

    statsBox:addChild(statsGrid)

    rightStackPanel:addChild(menuStackPanel)
    rightStackPanel:addChild(statsBox)
end

horizontalStackPanel:addChild(leftStackPanel)
horizontalStackPanel:addChild(rightStackPanel)

local hostBackground = BorderBox()
    :setSize(ennui.Size.fill(), ennui.Size.fill())
    :setColor(0, 0, 0.15)
    :setRadius(0)

hostBackground:addChild(horizontalStackPanel)
host:addChild(hostBackground)

return host