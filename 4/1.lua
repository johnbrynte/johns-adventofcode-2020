io.stdout:setvbuf 'no'
math.randomseed(os.time())

local color = require "4.color"
local Passport = require "4.Passport"
local Animate = require "4.Animate"

local time = 0
local running = false

local color_bg = color.hex("352D49")
local color_green = color.hex("48DE30")
local color_red = color.hex("F27373")
local font_big = love.graphics.newFont("fonts/SourceCodePro-Bold.ttf", 24)

local passports = {}
local current_passports = {}
local valid_passports = 0
local invalid_passports = 0
local timeacceleration = 0

-- Handle next passport
local function setNextPassport()
    if #passports == 0 then
        running = false
        return
    end

    local targetRotation = 0.2 - math.random() * 0.5

    local pp = table.remove(passports, 1)

    table.insert(current_passports, pp)

    if Animate.timescale >= 10 then
        pp.x = 200
        pp.y = 200
        pp.rotation = targetRotation

        -- fasten up the process
        local valid = pp:isValid()

        pp:setStamp(valid and "approved" or "denied")

        if valid then
            valid_passports = valid_passports + 1
        else
            invalid_passports = invalid_passports + 1
        end

        if #passports > 100 then
            Animate.new {done = setNextPassport}:start()
        else
            setNextPassport()
        end

        return
    end

    local attributes = {unpack(Passport.attributes)}

    local checkAttribute
    local setStamp
    local fromRotation = targetRotation + 0.4

    -- check the next attribute
    function checkAttribute()
        local attr = table.remove(attributes, 1)
        local valid = true

        if pp:isValid(attr) then
            pp:setCheck(attr, true)
        else
            valid = false
            pp:setCheck(attr, false)
        end

        -- add a bit of delay before checking the next attribute
        Animate.new {
            duration = valid and 0.1 or 0.3,
            done = function()
                if not valid then
                    setStamp(false)
                    return
                end

                if #attributes > 0 then
                    checkAttribute()
                elseif pp:isValid() then
                    setStamp(true)
                end
            end
        }:start()
    end

    -- stamp the passport with "approved" or "denied"
    function setStamp(valid)
        pp:setStamp(valid and "approved" or "denied")

        if valid then
            valid_passports = valid_passports + 1
        else
            invalid_passports = invalid_passports + 1
        end

        -- prepare next passport
        -- Animate.new {duration = 0.9, done = setNextPassport}:start()

        -- animate stamp impact and then "swish" away
        local _ = Animate.new {
            duration = 1,
            callback = function(t)
                pp.scale = 0.5 + 0.5 * t
            end,
            done = setNextPassport,
            easing = Animate.easing.elasticOut
        }:start() + Animate.new {
            duration = 0.6,
            callback = function(t)
                pp.x = 200
                pp.y = 200 + (valid and -1 or 1) * 400 * t
                pp.scale = 1 + t * (0.6 - 1)
                pp.alpha = 1 - 0.6 * t
            end,
            done = function()
                -- remove from list
                for i, val in ipairs(current_passports) do
                    if val == pp then
                        table.remove(current_passports, i)
                        break
                    end
                end
            end,
            easing = Animate.easing.cubicIn
        }
    end

    -- animate the passport in view
    Animate.new {
        duration = 1.4,
        callback = function(t)
            pp.x = 200 + 700 * (1 - t)
            pp.y = 200
            pp.rotation = fromRotation * (1 - t) + targetRotation * t
        end,
        done = checkAttribute,
        easing = Animate.easing.cubicOut
    }:start()
end

--------------------------

-- Love loaded
function love.load()
    love.graphics.setBackgroundColor(unpack(color_bg))

    local input = ""
    for line in io.lines("4/input.txt") do
        if line ~= "" then
            input = input .. line .. " "
        else
            local pp = Passport.new()
            for _, attr, val in input:gmatch("(([a-z]+):([A-z0-9#]+))") do
                pp[attr] = val
            end
            table.insert(passports, pp)

            input = ""
        end
    end
end

-- Update loop
function love.update(dt)
    time = time + dt

    if running then
        if Animate.timescale < 10 then
            timeacceleration = timeacceleration + dt * 0.04
            Animate.timescale = Animate.timescale + (timeacceleration) * dt * 1
        end
    end

    Animate.update(dt)
end

-- Draw loop
function love.draw()
    for _, pp in ipairs(current_passports) do
        pp:draw()
    end

    love.graphics.setFont(font_big)
    love.graphics.setColor(color_green)
    love.graphics.print("Approved: " .. valid_passports, 20, 16)

    love.graphics.setFont(font_big)
    love.graphics.setColor(color_red)
    love.graphics.print("Declined: " .. invalid_passports, 20, 350)
end

-- Key events
function love.keypressed(key)
    if key == "space" then
        if not running then
            running = true

            setNextPassport()
        end
    end
end
