local Animate = require "utils.Animate"
local color = require "utils.color"
local Section = require "5.Section"

local data = {}
local data_cur = {
    dataIndex = 1,
    rawIndex = nil,
    data = nil,
    current = "row",
    index = 1
}
local camera = {
    scale = 1,
    _scale = 1,
    size = 6,
    x = 0,
    y = 0,
    _x = 0,
    _y = 0,
    done = false
}
local image_plane

function countRow(row, step)
    step = step or 7

    local min = 0
    local max = 127
    for i = 1, step do
        if row[i] then
            min = min + (max - min + 1) / 2
        else
            max = max - (max - min + 1) / 2
        end
    end

    return min, max
end

function countCol(col, step)
    step = step or 3

    local min = 0
    local max = 7
    for i = 1, step do
        if col[i] then
            min = min + (max - min + 1) / 2
        else
            max = max - (max - min + 1) / 2
        end
    end

    return min, max
end

local function updateCamera(size)
    camera._x = 400 -
                    (current_seat.x + current_seat.offsetX + current_seat.width /
                        2) * size
    camera._y = 400 -
                    (current_seat.y + current_seat.offsetY + current_seat.height /
                        2) * size
end

local function initSeat()
    print("new seat", data_cur.dataIndex)
    seats = Section.new {width = 128, height = 8, x = 0, y = 0, valid = true}
    current_seat = seats

    updateCamera(6)
end

local function setNext()
    -- set next
    if not data_cur.rawIndex then
        data_cur.rawIndex = 0
    end
    data_cur.rawIndex = data_cur.rawIndex + 1

    data_cur.index = data_cur.index + 1

    if data_cur.index > table.getn(data_cur.data[data_cur.current]) then
        if data_cur.current == "row" then
            data_cur.current = "col"
        else
            return true
        end

        data_cur.index = 1
    end

    return false
end

local function proceed()
    if data_cur.done then
        initSeat()

        data_cur.done = false
        data_cur.rawIndex = nil

        camera._scale = 1

        updateCamera(6)
        camera._x = -1200

        local _ = Animate.new {
            duration = 1.2,
            done = function()
                camera.x = 1000

                updateCamera(6)
            end
        }:start() + Animate.new {duration = 1.2, done = proceed}
        return
    end

    local first = data_cur.current == "row" and data_cur.index == 1

    local code = data_cur.data[data_cur.current][data_cur.index]
    if data_cur.current == "row" then
        current_seat = current_seat:splitHorizontal(code)
    else
        current_seat = current_seat:splitVertical(code)
    end

    if setNext() then
        print("set next true")
        Animate.new {
            duration = 1,
            done = function() -- set next
                data_cur.dataIndex = data_cur.dataIndex + 1
                data_cur.data = data[data_cur.dataIndex]
                data_cur.current = "row"
                data_cur.rawIndex = 1
                data_cur.index = 1

                proceed()
            end
        }:start()
        data_cur.done = true
        return
    end

    -- camera.size = 6 * camera.scale
    local size = 6 * (first and camera.scale or camera.scale + 1)
    updateCamera(size)

    if not first then
        camera._scale = camera.scale + 1
    end

    Animate.new {duration = 0.5, done = proceed}:start()
end

function love.load()
    love.window.setMode(800, 800, {resizable = false})
    love.graphics.setBackgroundColor(unpack(color.hex("BDDFFF")))

    image_plane = love.graphics.newImage("5/plane.png")

    FontSmall = love.graphics.newFont("fonts/SourceCodePro-Bold.ttf", 22)
    FontBig = love.graphics.newFont("fonts/SourceCodePro-Bold.ttf", 60)

    love.graphics.setFont(FontSmall)

    local maxId = 0
    local ids = {}
    for line in io.lines("5/input.txt") do
        local row = {}
        local col = {}
        for val in string.gmatch(line, ".") do
            if val == "B" then
                table.insert(row, true)
            elseif val == "F" then
                table.insert(row, false)
            elseif val == "R" then
                table.insert(col, true)
            elseif val == "L" then
                table.insert(col, false)
            end
        end

        local id = countRow(row) * 8 + countCol(col)
        maxId = id > maxId and id or maxId
        ids[id] = true
        table.insert(data, {raw = line, col = col, row = row, id = id})
    end

    -- print(maxId)

    -- for i = 0, maxId do
    --     if not ids[i] then
    --         print("id " .. i .. " missing")
    --     end
    -- end

    initSeat()

    local size = 6
    camera._x = 1000
    camera._y = 400 -
                    (current_seat.y + current_seat.offsetY + current_seat.height /
                        2) * size
    camera.x = camera._x
    camera.y = camera._y

    -- set next
    data_cur.data = data[data_cur.dataIndex]

    time = 0
end

function love.update(dt)
    time = time + dt

    Animate.update(dt)

    camera.x = camera.x + (camera._x - camera.x) * dt * 5
    camera.y = camera.y + (camera._y - camera.y) * dt * 5
    camera.scale = camera.scale + (camera._scale - camera.scale) * dt * 5
    camera.size = 6 * camera.scale
end

function love.draw()
    local w = image_plane:getWidth()
    local h = image_plane:getHeight()
    local scale = camera.scale / 3.7

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image_plane, camera.x - 0.09 * w * scale,
                       camera.y - h * scale / 2 + 8 * camera.size / 2, 0, scale,
                       scale)

    love.graphics.setFont(FontSmall)
    local section = seats
    repeat
        if section.next then
            for _, child in ipairs(section) do
                if not child.next then
                    child:draw(camera.size, camera.x, camera.y)
                end
            end
        else
            section:draw(camera.size, camera.x, camera.y)
        end

        section = section.next
    until (not section)

    love.graphics.setFont(FontBig)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 30, 680, 640, 100, 20)
    love.graphics.setColor(1, 1, 1)
    local str = data_cur.data.raw
    local fstring = str
    if data_cur.rawIndex then
        fstring = {
            {1, 1, 1}, str:sub(1, data_cur.rawIndex - 1), {0, 1, 0},
            str:sub(data_cur.rawIndex, data_cur.rawIndex), {0.6, 0.6, 0.6},
            str:sub(data_cur.rawIndex + 1, str:len())
        }
        if data_cur.done then
            table.insert(fstring, {1, 1, 1})
            table.insert(fstring, " = " .. data_cur.data.id)
        end
    end
    love.graphics.print(fstring, 60, 690)
end

function love.keypressed(key)
    if key == "space" then
        updateCamera(6)

        Animate.new {done = proceed}:start()
    end
end
