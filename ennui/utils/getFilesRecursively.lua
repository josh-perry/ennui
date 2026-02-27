local function getFilesRecursively(directory)
    local files = {}

    local function scan(dir)
        local items = love.filesystem.getDirectoryItems(dir)

        for _, item in ipairs(items) do
            local EnnuiRoot = dir .. "/" .. item
            local info = love.filesystem.getInfo(EnnuiRoot)

            if info then
                if info.type == "file" and item:match("%.lua$") then
                    local moduleEnnuiRoot = EnnuiRoot:gsub("%.lua$", "")
                    moduleEnnuiRoot = moduleEnnuiRoot:gsub("/", ".")

                    table.insert(files, moduleEnnuiRoot)
                elseif info.type == "directory" then
                    scan(EnnuiRoot)
                end
            end
        end
    end

    scan(directory)
    return files
end

return getFilesRecursively
