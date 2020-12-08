local color = {
    hex = function(hex)
        for r, g, b in hex:gmatch(
                           "#?([A-z0-9][A-z0-9])([A-z0-9][A-z0-9])([A-z0-9][A-z0-9])") do
            return {
                tonumber(r, 16) / 255, tonumber(g, 16) / 255,
                tonumber(b, 16) / 255
            }
        end
    end
}

return color
