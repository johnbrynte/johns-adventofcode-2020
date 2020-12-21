local Animate = require "utils.Animate"
local Transform = require "utils.Transform"
local color = require "utils.color"

local Boat = require "12.Boat"

local transform = Transform.new {x = 400, y = 400}
local boat
local targetScale = 16
local done = false
local compass = {
    angle = 0,
    _angle = 0,
    images = {
        frame = love.graphics.newImage("12/compass-frame.png"),
        needle = love.graphics.newImage("12/compass-needle.png")
    }
}

local function tick()
    Animate.timescale = Animate.timescale + 0.4
    if targetScale > 1 then
        targetScale = targetScale - 0.1
    end

    if boat:readNextInstruction(tick) then
        print("Done")
        done = true
        return
    end

    compass._angle = boat.windRotation * math.pi / 180
end

function love.load()
    local instructions = {}
    for line in io.lines("12/input.txt") do
        for command, value in line:gmatch("([A-Z])([0-9]+)") do
            table.insert(instructions,
                         {command = command, value = tonumber(value)})
        end
    end

    love.window.setMode(800, 800, {resizable = false})
    love.graphics.setBackgroundColor(color.hex("#83c0f0"))
    love.graphics.setNewFont("fonts/SourceCodePro-Bold.ttf", 60)

    boat = Boat.new({instructions = instructions})
    boat.transform.scale = targetScale
end

function love.update(dt)
    transform.x = transform.x + (-boat.transform.x + 400 - transform.x) * dt
    transform.y = transform.y + (-boat.transform.y + 400 - transform.y) * dt

    boat.transform.scale = boat.transform.scale +
                               (targetScale - boat.transform.scale) * dt

    compass.angle = compass.angle + (compass._angle - compass.angle) * dt * 2

    Animate.update(dt)
end

function love.draw()
    transform:draw(function()
        -- draw grid
        local scale = 1 / 30
        local gridSize = 100
        local gridScale = 20 * boat.transform.scale
        local x = (boat.transform.x / scale) % gridScale
        local y = (boat.transform.y / scale) % gridScale

        love.graphics.setColor(1, 1, 1, 0.5)
        -- love.graphics.setLineWidth(scale)

        for i = -gridSize, gridSize do
            love.graphics.line(x + i * gridScale, y + -gridSize * gridScale,
                               x + i * gridScale, y + gridSize * gridScale)
            love.graphics.line(x - gridSize * gridScale, y + i * gridScale,
                               x + gridSize * gridScale, y + i * gridScale)
        end

        boat:draw()
    end)

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(compass.images.frame, 550, 50, 0, 0.5, 0.5)
    love.graphics.draw(compass.images.needle,
                       550 + compass.images.needle:getWidth() / 4,
                       50 + compass.images.needle:getHeight() / 4,
                       compass.angle, 0.5, 0.5,
                       compass.images.needle:getWidth() / 2,
                       compass.images.needle:getHeight() / 2)

    if boat.currentInstruction then
        local s = string.format("%s %s", boat.currentInstruction.command,
                                boat.currentInstruction.value)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", 30, 680, 60 + 36 * s:len(), 100, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(s, 60, 690)

        if done then
            local s2 = string.format("DIST: %d",
                                     (math.abs(boat.x) + math.abs(boat.y)))
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", 120 + 36 * s:len(), 680,
                                    60 + 36 * s2:len(), 100, 20)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(s2, 150 + 36 * s:len(), 690)
        end
    end
end

function love.keypressed(key)
    if key == "space" then
        tick()
    end
end
