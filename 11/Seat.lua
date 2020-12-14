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
    world = {width = 0, height = 0},
    seats = nil,
    list = {},
    rules = {iterative = false, occupied = {0, 0}, free = {4, 8}}
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

function Seat.setSeats(seats)
    Seat.seats = seats
    Seat.world.width = #seats[1]
    Seat.world.height = #seats
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
    local occupiedSeats = 0

    -- print("-= scan =-")
    -- print(string.format("seat (%d,%d)", o.col, o.row))

    for _, dir in ipairs(Seat.directions) do
        local seat

        if Seat.rules.iterative then
            seat = o:search(dir)
        else
            seat = o.neighbors[dir]
        end

        if seat and seat.occupied then
            occupiedSeats = occupiedSeats + 1
        end
    end

    o._next = nil -- no change
    if o.occupied then
        if occupiedSeats >= Seat.rules.free[1] and occupiedSeats <=
            Seat.rules.free[2] then
            o._next = {occupied = false}
        end
    else
        if occupiedSeats >= Seat.rules.occupied[1] and occupiedSeats <=
            Seat.rules.occupied[2] then
            o._next = {occupied = true}
        end
    end
end

function Seat.mt.search(o, dir)
    -- if o.occupied then
    --     return o
    -- end
    local seat = o.neighbors[dir]
    if seat then
        return seat
    else
        return o:jumpSearch(dir)
    end
end

function Seat.mt.jumpSearch(o, dir)
    local col = o.col
    local row = o.row
    local x = 0
    local y = 0

    if string.match(dir, "F") then
        y = -1
    elseif string.match(dir, "B") then
        y = 1
    end
    if string.match(dir, "L") then
        x = -1
    elseif string.match(dir, "R") then
        x = 1
    end

    -- print(string.format("- jump %s (%d, %d)", dir, col, row))
    col = col + x
    row = row + y
    local seat = nil
    repeat
        seat = Seat.seats[row] and Seat.seats[row][col]
        -- print(string.format("  - %s (%d, %d)",
        --                     seat and seat.seat and "seat" or "floor", col, row))

        col = col + x
        row = row + y
    until not seat or seat.seat

    -- found a seat
    return seat

    -- if seat.occupied then
    --     return seat
    -- end
    -- continue normal search
    -- return seat:search(dir)
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
