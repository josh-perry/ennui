-- https://github.com/1bardesign/batteries/blob/master/identifier.lua
local uuid4Template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

local uuid = {}

function uuid.uuid4(rng)
    local out = uuid4Template:gsub("[xy]", function (c)
        return string.format(
			"%x",
			c == "x" and love.math.random(0x0, 0xf) or love.math.random(0x8, 0xb)
		)
    end)

	return out
end

return uuid