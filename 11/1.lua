local Animate = require "utils.Animate"
local Transform = require "utils.Transform"
local color = require "utils.color"

Seat = Seat or require "11.Seat"
Person = Person or require "11.Person"

local transform = Transform.new {x = 30, y = 0, size = {x = 800, y = 800}}

local time = 0
local activeSeat = nil
local seats
local result

local color_seat = color.hex("aaaaaa")
local color_person = color.hex("ff5555")

local function tick()
    Seat.scanSurrounding()
    local updated = Seat.tick()
    Person.walk()

    if not updated then
        print("DONE")
        result = 0
        for _, seat in ipairs(Seat.list) do
            if seat.occupied then
                result = result + 1
            end
        end
        return
    end

    Animate.timescale = Animate.timescale + 0.09

    Animate.new {duration = 1, done = tick}:start()
end

function love.load()
    love.window.setMode(800, 800, {resizable = false})

    love.graphics.setNewFont("fonts/SourceCodePro-Bold.ttf", 60)

    love.graphics.setBackgroundColor(color.hex("FFFFFF"))
    love.graphics.setColor(color.hex("000000"))

    seats = {}
    local rowIndex = 1
    for line in io.lines("11/input.txt") do
        local row = {}
        table.insert(seats, row)

        local colIndex = 1
        for val in string.gmatch(line, ".") do
            if val == "." then
                table.insert(row, {})
            else
                local seat = Seat.new {
                    col = colIndex,
                    row = rowIndex,
                    occupied = val == "#"
                }

                if colIndex > 1 then
                    seat:addNeighbor("L", seats[rowIndex][colIndex - 1])
                    if rowIndex > 1 then
                        seat:addNeighbor("FL", seats[rowIndex - 1][colIndex - 1])
                    end
                end
                if rowIndex > 1 then
                    seat:addNeighbor("F", seats[rowIndex - 1][colIndex])
                    if colIndex < line:len() then
                        seat:addNeighbor("FR", seats[rowIndex - 1][colIndex + 1])
                    end
                end

                table.insert(row, seat)
            end
            colIndex = colIndex + 1
        end
        rowIndex = rowIndex + 1
    end

    Person.setSize(#seats[1], #seats)

    for i = 1, #Seat.list do
        local angle = math.random() * math.pi * 2
        Person.new {
            x = 400 + math.cos(angle) * 600,
            y = 400 + math.sin(angle) * 600
        }
    end

    Person.walk()

end

function love.update(dt)
    time = time + dt

    -- local x, y = love.mouse.getPosition()
    -- x = math.floor(x / 8)
    -- y = math.floor(y / 8)
    -- if seats[y] and seats[y][x] and seats[y][x].seat then
    --     activeSeat = seats[y][x]
    -- else
    --     activeSeat = nil
    -- end

    Animate.update(dt)
end

function love.draw()
    local size = Seat.size
    local space = 1
    local innersize = size - space * 2

    transform:draw(function()
        for _, seat in ipairs(Seat.list) do
            -- if seat.occupied then
            --     if seat.waitingForPerson then
            --         love.graphics.setColor(1, 0, 1)
            --     else
            --         love.graphics.setColor(0, 0, 0)
            --     end
            -- else
            -- end
            love.graphics.setColor(color_seat)
            love.graphics.rectangle("fill", seat.col * size + space,
                                    seat.row * size + space, innersize,
                                    innersize)

            -- if seat == activeSeat then
            --     love.graphics.setColor(0, 1, 1)
            --     for dir in pairs(seat.neighbors) do
            --         local s = seat.neighbors[dir]
            --         love.graphics.rectangle("line", s.col * size, s.row * size,
            --                                 size, size)
            --     end
            -- end
        end

        for _, person in ipairs(Person.list) do
            person.transform:draw(function()
                love.graphics.setColor(0.9 + 0.1 * person.transform.shade,
                                       0.9 * (1 - person.transform.shade),
                                       0.9 * (1 - person.transform.shade))
                love.graphics.rectangle("fill", -innersize / 2, -innersize / 2,
                                        innersize, innersize)
            end)
        end
    end)

    if result then
        love.graphics.setColor(0, 0, 0)
        love.graphics
            .printf("OCCUPIED SEATS: " .. result, 0, 350, 800, "center")
    end
end

function love.keypressed(key)
    if key == "space" then
        tick()
    end
end
