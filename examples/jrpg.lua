local ennui = require("ennui")

local HorizontalStackPanel = ennui.Widgets.Horizontalstackpanel
local StackPanel = ennui.Widgets.Stackpanel
local TextButton = ennui.Widgets.Textbutton
local Text = ennui.Widgets.Text
local Rectangle = ennui.Widgets.Rectangle
local Image = ennui.Widgets.Image

-- Create a State object for reactive game data
-- Tables are automatically made nested-reactive with deep reactivity
local gameState = ennui.State({
    time = 0,
    gold = 0,
    steps = 0,
    characters = {
        {
            name = "Frog",
            job = "Amphibian",
            image = "examples/assets/img/frog.png",
            stats = {
                level = 15,
                currentHp = 320,
                maxHp = 350,
                currentMp = 45,
                maxMp = 60
            },
            row = "front"
        },
        {
            name = "Lucca",
            job = "Inventor",
            image = "examples/assets/img/lucca.png",
            stats = {
                level = 14,
                currentHp = 280,
                maxHp = 300,
                currentMp = 20,
                maxMp = 30
            },
            row = "back"
        },
        {
            name = "Crono",
            job = "Hero",
            image = "examples/assets/img/crono.png",
            stats = {
                level = 13,
                currentHp = 200,
                maxHp = 220,
                currentMp = 80,
                maxMp = 100
            },
            row = "front"
        },
        {
            name = "Graggle",
            job = "Creature",
            image = "examples/assets/img/graggle.png",
            stats = {
                level = 14,
                currentHp = 180,
                maxHp = 180,
                currentMp = 80,
                maxMp = 100
            },
            row = "back"
        }
    }
})

local BorderBox = function()
    local rectangle = Rectangle()
        :setColor(0, 0, 0.35)
        :setBorderColor(0.7, 0.7, 0.7)
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :setPadding(4, 4, 4, 4)
        :setRadius(4)

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

local CharacterInfo = function(characterState)
    local characterBox = BorderBox()
        :setSize(ennui.Size.fill(), ennui.Size.fill())
        :setPadding(4, 8, 4, 8)

    local characterHorizontalPanel = HorizontalStackPanel()
        :setSpacing(10)
        :setSize(ennui.Size.fill(), ennui.Size.auto())

    local imageContainer = ennui.Widget()
        :setSize(60, ennui.Size.fill())

    local characterImage = Image(love.graphics.newImage(characterState.props.image))
        :setSize(ennui.Size.auto(), ennui.Size.fill())
        :setSizeConstraint(ennui.SizeConstraint.square)
        :setVerticalAlignment("center")
        :setHorizontalAlignment(characterState.props.row == "front" and "left" or "right")

    characterState:watch("row", function(newRow)
        characterImage:setHorizontalAlignment(newRow == "front" and "left" or "right")
    end)

    imageContainer:addChild(characterImage)
    characterHorizontalPanel:addChild(imageContainer)

    local statsGrid = ennui.Widget()
        :setSize(ennui.Size.fill(), ennui.Size.auto())
        :setLayoutStrategy(ennui.Layout.Grid(2, 4)
            :setSpacing(0))

    statsGrid:addChild(NormalText(characterState.props.name))
    statsGrid:addChild(HeaderText()
        :bindTo("text", characterState:bind("job"))
        :setHorizontalAlignment("right")
    )

    local stats = characterState:scope("stats")

    statsGrid:addChild(HeaderText("Lvl:"))
    statsGrid:addChild(NormalText()
        :bindTo("text", stats:bind("level"))
    )

    statsGrid:addChild(HeaderText("HP:"))
    statsGrid:addChild(NormalText()
        :bindTo("text", stats:format("{currentHp} / {maxHp}"))
    )

    statsGrid:addChild(HeaderText("MP:"))
    statsGrid:addChild(NormalText()
        :bindTo("text", stats:format("{currentMp} / {maxMp}"))
    )

    -- characterInfoStackPanel:addChild(statsGrid)

    characterHorizontalPanel:addChild(statsGrid)
    characterBox:addChild(characterHorizontalPanel)

    return characterBox
end

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

    for i, _ in ipairs(gameState:getRaw("characters")) do
        local charState = gameState:scope("characters." .. i)
        local characterBox = CharacterInfo(charState)
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
            :onClick(function()
                if v == "Formation" then
                    print("Formation clicked")
                end

                for _, c in gameState:ipairs("characters") do
                    local charStats = c.stats
                    charStats.currentHp = math.min(charStats.currentHp + 20, charStats.maxHp)
                    charStats.currentMp = math.min(charStats.currentMp + 10, charStats.maxMp)
                    charStats.level = charStats.level + 1

                    if v == "Formation" then
                        if c.row == "front" then
                            c.row = "back"
                        else
                            c.row = "front"
                        end
                    end
                end
            end)

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

    local timeComputed = gameState:computed("time", function()
        return tostring(math.floor(gameState.props.time))
    end)

    local goldComputed = gameState:computed("gold", function()
        return tostring(math.floor(gameState.props.steps) * math.floor(gameState.props.time))
    end)

    local stepsComputed = gameState:computed("steps", function()
        return tostring(math.floor(gameState.props.steps))
    end)

    statsGrid:addChild(HeaderText("Time:"))
    statsGrid:addChild(NormalText()
        :bindTo("text", timeComputed)
        :setTextHorizontalAlignment("right")
    )

    statsGrid:addChild(HeaderText("Gold:"))
    statsGrid:addChild(NormalText()
        :bindTo("text", goldComputed)
        :setTextHorizontalAlignment("right")
        :setSize(ennui.Size.fill(), ennui.Size.auto())
    )

    statsGrid:addChild(HeaderText("Steps:"))
    statsGrid:addChild(NormalText()
        :bindTo("text", stepsComputed)
        :setTextHorizontalAlignment("right")
    )

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

return { host = host, gameState = gameState }