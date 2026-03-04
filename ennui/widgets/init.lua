local EnnuiRoot = (...):gsub("%.init$", "")
EnnuiRoot = string.sub(EnnuiRoot, 1, string.len(EnnuiRoot) - string.len(".widgets"))

local getFilesRecursively = require(EnnuiRoot .. ".utils.getFilesRecursively")
local widgetFiles = getFilesRecursively(EnnuiRoot:gsub("%.", "/") .. "/widgets")

local widgets = {}

for _, modulePath in ipairs(widgetFiles) do
    if modulePath:match("%.init$") then
        goto continue
    end

    local widgetName = modulePath:match("([^.]+)$")
    local capitalizedName = widgetName:sub(1, 1):upper() .. widgetName:sub(2)

    widgets[capitalizedName] = require(modulePath)
    ::continue::
end

return widgets