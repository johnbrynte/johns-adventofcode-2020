local Animate = require "utils.Animate"
local Transform = require "utils.Transform"

local Sprite = require "13.Sprite"
local Path = require "13.Path"

local canvas = love.graphics.newCanvas()

local man = Sprite.new {
    image = love.graphics.newImage("13/walk.png"),
    size = 16,
    speed = 1 / 4
}

local boat = Sprite.new {
    image = love.graphics.newImage("13/boat.png"),
    size = 16,
    speed = 1 / 4
}:loop({1, 2, 3})

local bus = Sprite.new {
    image = love.graphics.newImage("13/bus.png"),
    size = 16,
    speed = 1 / 4
}:loop({1, 2})

local busPath = Path.new()
for i = 1, 41 do
    local angle = (i - 1) * math.pi * 2 / 40
    busPath:add(80 + 30 * math.cos(angle), 50 + 30 * math.sin(angle))
end
-- :add(50, 50, 70, 50, 80, 60, 80, 80, 70, 90, 50, 90, 40, 80, 40, 60, 50, 50)

local busTransform = Transform.new {size = {x = 16, y = 16}}:setOrigin(0.5,
                                                                       15 / 16)
local width = 800 / 5
local height = 800 / 5

local landpath = Path.new():add(60, 0, 65, 40, 58, 80, 63, 120, 60, 160)
local landpath2 = Path.new():add(63, 0, 67, 40, 62, 80, 69, 120, 64, 160)

local time = 0
local start = false
local done = false
local buses = {}
local busPaths = {}
local timetable = {
    time = 1,
    tick = 0,
    speed = 0,
    maxspeed = 100000,
    acceleration = 4,
    start = 0,
    target = 0,
    simulation = 3878,
    timescale = 1
}

local BusMeta = {
    update = function(o, t)
        o.time = (o.time + 1) % o.id
        if o.time == 0 then
            return true
        else
            return false
        end
    end
}
BusMeta.__index = BusMeta

function love.load()
    love.window.setMode(800, 800, {resizable = false})
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setNewFont("fonts/SourceCodePro-Bold.ttf", 80)

    canvas:setFilter('nearest', 'nearest')
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")

    local index = 1
    for line in io.lines("13/input.txt") do
        if index == 1 then
            timetable.target = tonumber(line)
        else
            for b in line:gmatch("([0-9]+)") do
                local bus = {
                    id = tonumber(b),
                    line = #buses + 1,
                    time = 0,
                    cars = {}
                }
                setmetatable(bus, BusMeta)
                table.insert(buses, bus)
                addBusLine(bus.line)
            end
        end
        index = index + 1
    end

    timetable.start = timetable.target - timetable.simulation
    timetable.time = timetable.start
    timetable.tick = timetable.time
    timetable.hours = math.floor((timetable.time % (60 * 24)) / 60)
    timetable.minutes = timetable.time % (60)

    local waiting = 9999
    for _, bus in ipairs(buses) do
        bus.time = timetable.time % bus.id

        local departure = timetable.target % bus.id
        local wait = math.abs(departure - bus.id)

        if wait < waiting then
            waiting = wait
            timetable.targetbus = bus
            timetable.targettime = timetable.target + wait
            timetable.targetwaiting = wait
        end
    end

    print("answer: " .. (timetable.targetwaiting * timetable.targetbus.id))

end

function addBusLine(index)
    local x1, x2, y1, y2
    local path = Path.new()
    local radius = 20
    local padding = 10
    local spacing = 16

    x1 = width + 20
    y1 = height - padding - (index - 1) * spacing
    x2 = width / 2 + radius -- + (i - 1) * spacing
    y2 = y1

    path:add(x1, y1, x2, y2)

    x1 = x2
    y1 = y2
    x2 = x1 - radius
    y2 = y1 - radius
    for j = 1, 4 do
        local angle = math.pi / 2 + j * (math.pi / 2) / 5
        path:add(x1 + radius * math.cos(angle),
                 y1 - radius + radius * math.sin(angle))
    end

    x1 = x2
    y1 = y2
    x2 = x1
    y2 = -padding

    path:add(x1, y1, x2, y2)

    table.insert(busPaths, path)
end

function animateBus(line, timescale, targetbus)
    local firstStop = busPaths[line].points[1].edge.distance - 4
    local car = {delta = 0}
    table.insert(buses[line].cars, car)

    Animate.new {
        duration = 2 * timescale,
        callback = function(d)
            car.delta = firstStop * d
        end,
        done = function()
            if targetbus then
                print("done!")
                done = true
            end
            Animate.new {
                delay = targetbus and 1 or 0,
                duration = 2 * timescale * (busPaths[line].distance - firstStop) /
                    height,
                callback = function(d)
                    car.delta = firstStop +
                                    (busPaths[line].distance - firstStop) * d
                end,
                done = function()
                    -- remove car
                    for index, _car in ipairs(buses[line].cars) do
                        if _car == car then
                            table.remove(buses[line].cars, index)
                            return
                        end
                    end
                end,
                easing = Animate.easing.cubicInOut
            }:start()
        end,
        easing = Animate.easing.cubicInOut
    }:start()
end

function love.update(dt)
    if not start then
        return
    end

    time = time + dt

    local tspeed = 10
    local tscale = 1

    if timetable.time < timetable.start + 40 then
        tspeed = 5
        tscale = 1
    elseif timetable.time < timetable.start + 100 then
        tspeed = 20
        tscale = 0.8
    elseif timetable.time < timetable.start + 500 then
        tspeed = 80
        tscale = 0.7
    elseif timetable.time < timetable.targettime - 500 then
        tspeed = 500
        tscale = 0.2
    elseif timetable.time < timetable.targettime - 200 then
        tspeed = 140
        tscale = 0.5
    elseif timetable.time < timetable.targettime - 100 then
        tspeed = 80
        tscale = 0.7
    elseif timetable.time < timetable.targettime - 14 then
        tspeed = 10
        tscale = 1
    else
        tspeed = 1
        tscale = 1
    end

    timetable.speed = timetable.speed + (tspeed - timetable.speed) * dt * 2
    timetable.timescale = timetable.timescale + (tscale - timetable.timescale) *
                              dt * 2

    if timetable.time < timetable.targettime then
        timetable.tick = timetable.tick + dt * timetable.speed

        local t = math.floor(timetable.tick)
        while t > timetable.time do
            timetable.time = timetable.time + 1

            for _, bus in ipairs(buses) do
                if bus:update(t) then
                    animateBus(bus.line, timetable.timescale, timetable.time ==
                                   timetable.targettime and timetable.targetbus ==
                                   bus)
                end
            end

            timetable.hours = math.floor((timetable.time % (60 * 24)) / 60)
            timetable.minutes = timetable.time % (60)
        end
    end

    Sprite.update(dt)
    Animate.update(dt)
end

function love.draw()
    canvas:renderTo(function()
        love.graphics.clear(0, 0, 0)
        love.graphics.setColor(1, 1, 1)
        -- love.graphics.line(0, 0, 50, 30)

        landpath:draw()
        landpath2:draw()

        for i = 1, #buses do
            busPaths[i]:draw()

            for _, car in ipairs(buses[i].cars) do
                local p = busPaths[i]:getPointReal(car.delta)
                busTransform:set(math.floor(p.x), math.floor(p.y))
                busTransform.rotation = p.point.edge.angle + math.pi
                busTransform:draw(function()
                    bus:draw(0, 0)
                end)
            end
        end

        -- love.graphics.print(timetable.time, 4, 24)
        -- love.graphics.print(math.floor(timetable.speed), 4, 34)
        -- love.graphics.print(math.floor(timetable.timescale * 100) / 100, 4, 44)

        local boatx = width / 2 - 35
        local boatdelta = math.min((timetable.time - timetable.start) /
                                       (timetable.targettime - timetable.start),
                                   1)
        boat:draw(math.floor(-100 + (boatx - (-100)) * boatdelta),
                  math.floor(height / 2))
        if timetable.time >= timetable.target and not done then
            local mandelta = (timetable.tick - timetable.target) /
                                 (timetable.targettime - timetable.target)
            local point = busPaths[timetable.targetbus.line].points[2]
            man:draw(math.floor(boatx + (point.x - boatx) * mandelta),
                     math.floor(height / 2 + (point.y - 16 - (height / 2)) *
                                    mandelta))
        end
    end)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, 0, 0, 0, 5)

    local h = tostring(timetable.hours)
    h = h:len() == 1 and "0" .. h or h
    local m = tostring(timetable.minutes)
    m = m:len() == 1 and "0" .. m or m
    love.graphics.print(string.format("%s:%s", h, m), 40, 680)
end

function love.keypressed(key)
    if key == "space" then
        start = true
    end
end
