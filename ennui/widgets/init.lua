local EnnuiRoot = (...):gsub("%.init$", "")
EnnuiRoot = string.sub(EnnuiRoot, 1, string.len(EnnuiRoot) - string.len(".widgets"))

local getFilesRecursively = require(EnnuiRoot .. ".utils.getFilesRecursively")
local widgetFiles = getFilesRecursively("ennui/widgets")

local widgets = {}

for _, moduleEnnuiRoot in ipairs(widgetFiles) do
    if moduleEnnuiRoot:match("%.init$") then
        goto continue
    end

    local widgetName = moduleEnnuiRoot:match("([^.]+)$")
    local capitalizedName = widgetName:sub(1, 1):upper() .. widgetName:sub(2)

    widgets[capitalizedName] = require(moduleEnnuiRoot)
    ::continue::
end

return widgets