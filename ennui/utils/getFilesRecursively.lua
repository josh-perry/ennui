local function getFilesRecursively(directory)
    local files = {}

    local function scan(dir)
        local items = love.filesystem.getDirectoryItems(dir)

        for _, item in ipairs(items) do
            local path = dir .. "/" .. item
            local info = love.filesystem.getInfo(path)

            if info then
                if info.type == "file" and item:match("%.lua$") then
                    local modulePath = path:gsub("%.lua$", "")
                    modulePath = modulePath:gsub("/", ".")

                    table.insert(files, modulePath)
                elseif info.type == "directory" then
                    scan(path)
                end
            end
        end
    end

    scan(directory)
    return files
end

return getFilesRecursively
