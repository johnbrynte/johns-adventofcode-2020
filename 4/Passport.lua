local color = require "4.color"

local color_clear = color.hex("ffffff")
local color_card = color.hex("fbe2c1")
local color_cardtext = color.hex("DDC7A9")
local color_cardborder = color.hex("6F532F")
local color_cardprofile = color.hex("857560")
local color_red = color.hex("D51920")
local color_green = color.hex("00A651")
local color_black = color.hex("000000")

local Passport = {
    attributes = {"byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid", "cid"},
    images = {
        approved = love.graphics.newImage("4/approved.png"),
        denied = love.graphics.newImage("4/denied.png"),
        ok = love.graphics.newImage("4/ok.png"),
        notok = love.graphics.newImage("4/notok.png")
    },
    fonts = {
        big = love.graphics.newFont("fonts/SourceCodePro-Bold.ttf", 24),
        small = love.graphics.newFont("fonts/SourceCodePro-Regular.ttf", 14)
    }
}

Passport.mt = {
    x = 600, -- create it outside of the screen
    y = 200,
    rotation = 0,
    scale = 1,
    alpha = 1,
    width = 340,
    height = 200
}
Passport.mt.__index = Passport.mt

function Passport.new(o)
    o = o or {}
    setmetatable(o, Passport.mt)
    return o
end

function Passport.mt.isValid(o, attr, rules)
    rules = rules or {}

    if attr ~= nil then
        -- skip "cid"
        if attr == "cid" then
            return true
        end

        if rules[attr] then
            if o[attr] == nil then
                return false
            end

            local rule = rules[attr]
            if rule["type"] == "year" then
                if o[attr]:len() ~= 4 then
                    return false
                end

                -- year
                local num = tonumber(o[attr])
                if num >= rule["min"] and num <= rule["max"] then
                    return true
                end
            elseif rule["type"] == "length" then
                -- length
                for num, unit in o[attr]:gmatch("([0-9]+)([a-z]+)") do
                    if not num or not rule[unit] then
                        return false
                    end

                    local r = rule[unit]
                    num = tonumber(num)
                    if num >= r["min"] and num <= r["max"] then
                        return true
                    end
                end
            elseif rule["type"] == "color" then
                -- color
                for color in o[attr]:gmatch(
                                 "(#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])") do
                    if color then
                        return true
                    end
                end
            elseif rule["type"] == "string" then
                -- string
                for _, val in ipairs(rule["list"]) do
                    if val == o[attr] then
                        return true
                    end
                end
            elseif rule["type"] == "id" then
                -- id
                for id in o[attr]:gmatch("([0-9]+)") do
                    if id and id:len() == rule["length"] then
                        return true
                    end
                end
            end
            return false
        end

        return o[attr] ~= nil
    end

    local valid = true
    for _, attr in ipairs(Passport.attributes) do
        valid = valid and Passport.mt.isValid(o, attr, rules)
    end
    return valid
end

function Passport.mt.setCheck(o, attr, valid)
    if not o.checked then
        o.checked = {}
    end

    o.checked[attr] = {valid = valid, x = math.random() * 0.3 * o.width / 2}
end

function Passport.mt.setStamp(o, _type)
    o.stamp = {
        type = _type,
        x = 50 + math.random() * 100,
        y = 60 + math.random() * 30,
        rotation = -0.2 + math.random() * 0.6
    }
end

function Passport.mt.draw(o)
    love.graphics.push()
    love.graphics.translate(o.x, o.y)
    love.graphics.rotate(o.rotation)
    love.graphics.scale(o.scale)
    love.graphics.translate(-o.width / 2, -o.height / 2)

    love.graphics.setColor(color_card[1], color_card[2], color_card[3], o.alpha)
    love.graphics.rectangle("fill", 0, 0, o.width, o.height, 20)
    love.graphics.setColor(unpack(color_cardborder))
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", 0, 0, o.width, o.height, 20)

    love.graphics.setFont(Passport.fonts.big)
    love.graphics.setColor(unpack(color_cardtext))

    love.graphics.print("Passport", 40, 120)

    love.graphics.setFont(Passport.fonts.small)
    love.graphics.setColor(unpack(color_black))

    for i = 1, 8 do
        local x = (i <= 3 or i == 7) and 20 or o.width / 2
        local y = i >= 7 and o.height - 30 or 16 + ((i - 1) % 3) * 30
        local attr = Passport.attributes[i]

        love.graphics.print(attr .. ": " .. (o[attr] or "-"), x, y)

        if o.checked and o.checked[attr] then
            x = x + o.checked[attr].x - 10

            love.graphics.setColor(unpack(color_clear))
            if o.checked[attr].valid then
                love.graphics.draw(Passport.images.ok, x, y, 0, 0.3, 0.3)
            else
                love.graphics.draw(Passport.images.notok, x, y, 0, 0.3, 0.3)
            end
            love.graphics.setColor(unpack(color_black))
        end
    end

    love.graphics.setColor(unpack(color_cardprofile))

    local profilex = 280
    local profiley = 100
    local profilesize = 18
    love.graphics.circle("fill", profilex, profiley + profilesize, profilesize)
    love.graphics.arc("fill", profilex, profiley + profilesize * 4,
                      profilesize * 1.7, math.pi, math.pi * 2)

    love.graphics.setColor(unpack(color_clear))
    if o.stamp then
        love.graphics.draw(Passport.images[o.stamp.type], o.stamp.x, o.stamp.y,
                           o.stamp.rotation, 0.5, 0.5)
    end

    love.graphics.pop()
end

return Passport
