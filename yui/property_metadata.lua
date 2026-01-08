---Defines which properties trigger layout vs render invalidation
---@enum PropertyType
local PropertyType = {
    LAYOUT = "layout",
    RENDER = "render",
    INERT = "inert"
}

---@class PropertyMetadata
local PropertyMetadata = {}

---Property configuration for all widget properties
PropertyMetadata.properties = {
    -- Layout-affecting properties (trigger invalidateLayout)
    preferredWidth = { type = "layout" },
    preferredHeight = { type = "layout" },
    minWidth = { type = "layout" },
    maxWidth = { type = "layout" },
    minHeight = { type = "layout" },
    maxHeight = { type = "layout" },
    aspectRatio = { type = "layout" },
    padding = { type = "layout" },
    margin = { type = "layout" },
    horizontalAlignment = { type = "layout" },
    verticalAlignment = { type = "layout" },

    -- Inert properties (no invalidation)
    id = { type = "inert" },
    children = { type = "inert" },
    parent = { type = "inert" },
    layoutStrategy = { type = "inert" },
    state = { type = "inert" },

    --TODO: not this, I don't like it
    -- Button properties (render-affecting)
    backgroundColor = { type = "render" },
    hoverColor = { type = "render" },
    pressedColor = { type = "render" },
    disabledColor = { type = "render" },
    cornerRadius = { type = "render" },

    -- TextButton properties (render-affecting)
    textColor = { type = "render" },
    textSize = { type = "render" },
    hoverTextColor = { type = "render" },
    pressedTextColor = { type = "render" },
    disabledTextColor = { type = "render" },
    font = { type = "render" },
    text = { type = "render" },

    -- Text properties (render-affecting)
    content = { type = "render" },
    fontSize = { type = "render" },
    fontColor = { type = "render" },

    -- Image properties (render-affecting)
    image = { type = "render" },

    -- TextInput properties (render-affecting)
    placeholder = { type = "render" },
    value = { type = "render" },
    cursorPosition = { type = "render" },
    selectionStart = { type = "render" },
    selectionEnd = { type = "render" },
    inputTextColor = { type = "render" },
    inputBackgroundColor = { type = "render" },
    placeholderColor = { type = "render" },
}

---Get property configuration for a given key
---@param key string Property name
---@return table config Property configuration (or default inert config if not found)
function PropertyMetadata.getConfig(key)
    return PropertyMetadata.properties[key] or { type = "inert" }
end

---Check if property should trigger layout invalidation
---@param key string Property name
---@return boolean
function PropertyMetadata.isLayoutProperty(key)
    local config = PropertyMetadata.getConfig(key)
    return config.type == PropertyType.LAYOUT
end

---Check if property should trigger render invalidation
---@param key string Property name
---@return boolean
function PropertyMetadata.isRenderProperty(key)
    local config = PropertyMetadata.getConfig(key)
    return config.type == PropertyType.RENDER
end

return PropertyMetadata
