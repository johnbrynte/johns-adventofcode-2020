-- Animation test with transforms
--------------------------------------
local Animate = require "utils.Animate"
local Transform = require "utils.Transform"
local color = require "utils.color"

local transform = Transform.new {x = 0, y = 0, size = {x = 800, y = 800}}

local time = 0

function love.load()
    love.window.setMode(800, 800, {resizable = false})
    love.graphics.setBackgroundColor(color.hex("FFFFFF"))
end

function love.update(dt)
    time = time + dt

    Animate.update(dt)
end

function love.draw()
    transform:draw(function()
        -- draw your stuff here
    end)
end
