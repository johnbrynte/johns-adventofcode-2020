-- Animation test with transforms
--------------------------------------
local Animate = require "utils.Animate"
local Transform = require "utils.Transform"

local transform =
    Transform.new {x = 400, y = 400, size = {x = 200, y = 200}}:setOrigin(0.5,
                                                                          0.5)

local time = 0

local function loopAnimation()
    local _ = transform:animateTo{
        x = 600,
        y = 400,
        rotation = math.pi / 2,
        options = {delay = 0.5, easing = Animate.easing.cubicOut}
    }:start() + transform:animateTo{
        x = 400,
        y = 600,
        scale = 1.3,
        rotation = math.pi,
        options = {easing = Animate.easing.cubicOut}
    } + transform:animateTo{
        y = 400,
        scale = 1,
        rotation = math.pi * 2,
        options = {
            easing = Animate.easing.cubicInOut,
            done = function()
                -- reset rotation
                transform.rotation = 0
                loopAnimation()
            end
        }
    }
end

function love.load()
    love.window.setMode(800, 800, {resizable = false})
    love.graphics.setBackgroundColor(1, 1, 1)

    loopAnimation()
end

function love.update(dt)
    time = time + dt

    Animate.update(dt)
end

function love.draw()
    transform:draw(function()
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", 100 - 20, 100 - 20, 40, 40)
        love.graphics.line(0, 0, 100, 100)
        love.graphics.rectangle("line", 0, 0, 200, 200)
    end)
end
