local Animate = require "utils.Animate"
local Transform = require "utils.Transform"

local Boat = {
    sprites = {
        front = love.graphics.newImage("12/boat-front.png"),
        back = love.graphics.newImage("12/boat-back.png"),
        side = love.graphics.newImage("12/boat-side.png")
    }
}

Boat.mt = {
    x = 0,
    y = 0,
    rotation = 0,
    windRotation = 0,
    currentInstruction = nil,
    instructions = nil,
    instructionIndex = 0,
    sprite = "side",
    flip = false,
    ripples = {}
}
Boat.mt.__index = Boat.mt

function Boat.new(o)
    o = o or {}
    setmetatable(o, Boat.mt)

    o.transform = Transform.new()

    return o
end

--

function Boat.mt.draw(o)
    o.transform:draw(function()
        local scale = 1 / 30
        local x = Boat.sprites[o.sprite]:getWidth() * scale
        local y = Boat.sprites[o.sprite]:getHeight() * scale

        -- ripples
        for _, ripple in ipairs(o.ripples) do
            love.graphics.setColor(1, 1, 1, (1 - ripple.tick) * 0.7)
            love.graphics.setLineWidth((1 - ripple.tick) * 16 * scale)

            love.graphics.circle("line", o.transform.x - ripple.x,
                                 o.transform.y - ripple.y,
                                 (2 + 100 * ripple.tick) * 2 * scale)
            love.graphics.circle("line", o.transform.x - ripple.x,
                                 o.transform.y - ripple.y,
                                 (6 + 100 * ripple.tick) * 3 * scale)
            love.graphics.circle("line", o.transform.x - ripple.x,
                                 o.transform.y - ripple.y,
                                 (10 + 100 * ripple.tick) * 4 * scale)
        end

        -- boat
        love.graphics.setColor(1, 1, 1)
        if o.flip then
            love.graphics.draw(Boat.sprites[o.sprite], x / 2, -y / 2, 0, -scale,
                               scale)
        else
            love.graphics.draw(Boat.sprites[o.sprite], -x / 2, -y / 2, 0, scale,
                               scale)
        end
    end)
end

function Boat.mt.readNextInstruction(o, callback)
    o.instructionIndex = o.instructionIndex + 1
    local instruction = o.instructions[o.instructionIndex]

    if not instruction then
        return true
    end

    o.currentInstruction = instruction

    local cmd = instruction.command
    local val = instruction.value
    local x = o.x
    local y = o.y

    if cmd == "N" then
        o.y = o.y - val
        o.windRotation = 270
    elseif cmd == "S" then
        o.y = o.y + val
        o.windRotation = 90
    elseif cmd == "W" then
        o.x = o.x - val
        o.windRotation = 180
    elseif cmd == "E" then
        o.x = o.x + val
        o.windRotation = 0
    elseif cmd == "F" then
        o:move(val)
        o.windRotation = o.rotation
    elseif cmd == "L" then
        o.rotation = (o.rotation - val) % 360
    elseif cmd == "R" then
        o.rotation = (o.rotation + val) % 360
    end

    o.flip = false
    if o.rotation == 0 or o.rotation == 180 then
        o.sprite = "side"
        o.flip = o.rotation == 180
    elseif o.rotation == 90 then
        o.sprite = "front"
    elseif o.rotation == 270 then
        o.sprite = "back"
    end

    -----

    local duration = 2

    if cmd ~= "L" and cmd ~= "R" then
        o:addRipple()

        local distance = math.max(math.abs(x - o.x), math.abs(y - o.y))
        local steps = math.floor(distance / 5)
        for i = 1, steps do
            Animate.new {
                duration = i * duration / steps,
                done = function()
                    o:addRipple()
                end
            }:start()
        end
    else
        duration = 1
    end

    o.transform:animateTo{
        x = o.x,
        y = o.y,
        -- rotation = o.rotation * math.pi / 180,
        options = {
            duration = duration,
            easing = Animate.easing.cubicInOut,
            done = callback
        }
    }:start()

    return false
end

function Boat.mt.move(o, distance)
    if o.rotation == 0 then
        o.x = o.x + distance
    elseif o.rotation == 90 then
        o.y = o.y + distance
    elseif o.rotation == 180 then
        o.x = o.x - distance
    elseif o.rotation == 270 then
        o.y = o.y - distance
    end
end

function Boat.mt.addRipple(o)
    local ripple = {x = o.transform.x, y = o.transform.y, tick = 0}
    table.insert(o.ripples, ripple)

    Animate.new {
        duration = 2,
        -- easing = Animate.easing.cubicOut,
        callback = function(t)
            ripple.tick = t
        end,
        done = function()
            for i, r in ipairs(o.ripples) do
                if r == ripple then
                    table.remove(o.ripples, i)
                    return
                end
            end
        end
    }:start()
end

return Boat
