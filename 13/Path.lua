local Path = {}

Path.mt = {distance = 0}
Path.mt.__index = Path.mt

function Path.new(o)
    o = o or {}
    setmetatable(o, Path.mt)
    o.points = {}
    o.pointslist = {}
    return o
end

function Path.newEdge(p1, p2)
    if not p1 or not p2 then
        return nil
    end
    -- angle
    -- distanace
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local distance = math.sqrt(dx ^ 2 + dy ^ 2)

    local angle = 0
    if dy >= 0 then
        angle = math.acos(dx / distance)
    elseif dx >= 0 then
        angle = math.asin(dy / distance)
    else
        angle = math.pi + math.acos(-dx / distance)
    end
    -- if dy <= 0 then
    --     angle = math.asin(dy / distance)
    -- elseif dx <= 0 then
    --     angle = math.acos(dx / distance)
    -- else
    --     angle = math.pi / 2 - math.acos(-dx / distance)
    -- end

    return {
        distance = distance,
        angle = angle,
        dir = {x = dx / distance, y = dy / distance}
    }
end

function Path.mt.add(o, ...)
    local arguments = {...}

    local points = #arguments == 1 and arguments[1] or arguments

    if not points then
        return o
    end

    local point
    for i, p in ipairs(points) do
        if type(p) == "number" and (i - 1) % 2 == 0 then
            point = {}
            point.x = p
        else
            if type(p) == "number" then
                point.y = p
            else
                point = {x = p[1], y = p[2]}
            end

            local index = #o.points
            local _p = index >= 1 and o.points[index] or nil

            if _p then
                _p.edge = Path.newEdge(_p, point)
            end

            table.insert(o.points, point)
            table.insert(o.pointslist, point.x)
            table.insert(o.pointslist, point.y)
        end
    end

    o.distance = o:getDistance()

    return o
end

function Path.mt.getPointReal(o, d)
    local length = d
    local distance = 0
    for index, p in ipairs(o.points) do
        if p.edge then
            if distance + p.edge.distance >= length then
                local _d = (length - distance) / p.edge.distance
                local x = p.x + p.edge.dir.x * _d * p.edge.distance
                local y = p.y + p.edge.dir.y * _d * p.edge.distance
                return {x = x, y = y, index = index, point = p}
            end
            distance = distance + p.edge.distance
        end
    end
    return nil
end

function Path.mt.getPoint(o, d)
    return o:getPointReal(d * o.distance)
end

function Path.mt.getDistance(o)
    local distance = 0
    for _, p in ipairs(o.points) do
        if p.edge then
            distance = distance + p.edge.distance
        end
    end
    return distance
end

function Path.mt.draw(o)
    love.graphics.line(o.pointslist)
end

return Path
