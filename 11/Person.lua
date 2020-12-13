local Animate = require "utils.Animate"
local Transform = require "utils.Transform"

Person = {
    world = {width = 0, height = 0},
    list = {},
    queue = {},
    seatQueue = {}
}

Person.mt = {x = 0, y = 0, seat = nil, transform = nil}
Person.mt.__index = Person.mt

Seat = Seat or require "11.Seat"

function Person.new(o)
    o = o or {}

    setmetatable(o, Person.mt)
    table.insert(Person.list, o)
    table.insert(Person.queue, o)

    o.transform = Transform.new {x = o.x, y = o.y, rotation = math.pi / 4}
    o.transform.shade = 1

    return o
end

function Person.walk()
    for _, person in ipairs(Person.list) do
        person:walk()
    end
end

function Person.getClosestPerson(seat)
    -- check the seat memory first
    for _, person in ipairs(seat.memory) do
        if not person.seat then
            for i, p in ipairs(Person.queue) do
                if p == person then
                    return i, person
                end
            end
        end
    end

    -- check distance to other persons (very slow)
    local seatX = Seat.size * seat.col
    local seatY = Seat.size * seat.row
    local closest = {distance = 999999999, index = nil, person = nil}
    for i, person in ipairs(Person.queue) do
        local distance = (seatX - person.transform.x) ^ 2 +
                             (seatY - person.transform.y) ^ 2
        if distance < closest.distance then
            closest.distance = distance
            closest.index = i
            closest.person = person
        end
    end
    return closest.index, closest.person
end

function Person.setSize(width, height)
    Person.world.width = width
    Person.world.height = height
end

function Person.requestPerson(seat)
    if #Person.queue > 0 then
        local index, person = Person.getClosestPerson(seat)
        table.remove(Person.queue, index)
        seat:addPerson(person)
        person.seat = seat
    else
        table.insert(Person.seatQueue, seat)
        seat.waitingForPerson = true
    end
end

function Person.mt.free(o)
    if #Person.seatQueue > 0 then
        local seat = table.remove(Person.seatQueue)
        seat:addPerson(o)
        o.seat = seat
    else
        table.insert(Person.queue, o)
        o.seat = nil
    end
end

function Person.mt.walk(o)
    local x
    local y
    local shade

    if o.seat then
        x = (o.seat.col + 0.5) * Seat.size
        y = (o.seat.row + 0.5) * Seat.size
        shade = 1
    else
        x = o.transform.x + (math.random() > 0.5 and 0.5 or -0.5) * Seat.size
        y = o.transform.y + (math.random() > 0.5 and 0.5 or -0.5) * Seat.size
        shade = 0
        -- x = o.transform.x - Seat.size * Person.world.width / 2
        -- y = o.transform.y - Seat.size * Person.world.height / 2

        -- if math.abs(x) / math.abs(y) > 1 then
        --     y = o.transform.y

        --     if x < 0 then
        --         x = 0.5 * Seat.size
        --     else
        --         x = Seat.size * (Person.world.width + 1.5)
        --     end
        -- else
        --     x = o.transform.x

        --     if y < 0 then
        --         y = 0.5 * Seat.size
        --     else
        --         y = Seat.size * (Person.world.height + 1.5)
        --     end
        -- end
    end

    o.transform:animateTo{
        x = x,
        y = y,
        shade = shade,
        options = {
            duration = 0.5 + 0.5 * math.random(),
            easing = Animate.easing.cubicInOut
        }
    }:start()
end

return Person
