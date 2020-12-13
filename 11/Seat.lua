Seat = {
    size = 8,
    directions = {"L", "R", "F", "B", "FL", "FR", "BL", "BR"},
    opposite = {
        L = "R",
        R = "L",
        F = "B",
        B = "F",
        FL = "BR",
        FR = "BL",
        BL = "FR",
        BR = "FL"
    },
    list = {}
}

Seat.mt = {
    col = 0,
    row = 0,
    occupied = false,
    neighbors = nil,
    memory = nil,
    seat = true,
    person = nil,
    waitingForPerson = false,
    _next = nil
}
Seat.mt.__index = Seat.mt

Person = Person or require "11.Person"

function Seat.new(o)
    o = o or {}

    setmetatable(o, Seat.mt)
    table.insert(Seat.list, o)

    o.neighbors = {}
    o.memory = {}

    return o
end

function Seat.scanSurrounding()
    for _, seat in ipairs(Seat.list) do
        seat:scanSurrounding()
    end
end

function Seat.tick()
    local updated = false
    for _, seat in ipairs(Seat.list) do
        local _updated = seat:tick()
        updated = _updated or updated
    end
    return updated
end

function Seat.mt.addNeighbor(o, dir, seat)
    if not seat.seat then
        return
    end

    o.neighbors[dir] = seat

    seat.neighbors[Seat.opposite[dir]] = o
end

function Seat.mt.scanSurrounding(o)
    local freeSeats = 0
    local occupiedSeats = 0

    for _, dir in ipairs(Seat.directions) do
        local seat = o.neighbors[dir]
        if seat then
            if seat.occupied then
                occupiedSeats = occupiedSeats + 1
            else
                freeSeats = freeSeats + 1
            end
        end
    end

    o._next = nil -- no change
    if o.occupied then
        if occupiedSeats >= 4 then
            o._next = {occupied = false}
        end
    else
        if occupiedSeats == 0 then
            o._next = {occupied = true}
        end
    end
end

function Seat.mt.addPerson(o, person)
    o.person = person
    o.waitingForPerson = false

    table.insert(o.memory, person)
    if #o.memory > 10 then
        table.remove(o.memory, 1)
    end
end

function Seat.mt.tick(o)
    if o._next then
        if o.occupied and not o._next.occupied then
            o.person:free()
            o.person = nil
            o.occupied = false
        elseif not o.occupied and o._next.occupied then
            Person.requestPerson(o)
            o.occupied = true
        else
            error("Seat tried to move to a state it was already in")
        end
        return true
    end
    return false -- no change
end

return Seat
