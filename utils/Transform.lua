local Animate = require "utils.Animate"

local Transform = {}

Transform.mt = {
    x = 0,
    y = 0,
    size = {x = 0, y = 0},
    origin = {x = 0, y = 0},
    scale = 1,
    rotation = 0
}
Transform.mt.__index = Transform.mt

Transform.new = function(o)
    o = o or {}

    setmetatable(o, Transform.mt)

    return o
end

function Transform.mt.setOrigin(o, x, y)
    o.origin.x = o.size.x * x
    o.origin.y = o.size.y * y
    return o
end

function Transform.mt.translate(o, x, y)
    o.x = o.x + x
    o.y = o.y + y
    return o
end

function Transform.mt.set(o, x, y)
    o.x = x
    o.y = y
    return o
end

function Transform.mt.animateTo(o, values, opts)
    local fromto = {}
    opts = opts or values.options or {}
    values.options = nil

    for key in pairs(values) do
        fromto[key] = {from = nil, to = values[key]}
    end

    opts.callback = function(t)
        for key in pairs(fromto) do
            local data = fromto[key]
            if not data.from then
                -- initialize from value
                data.from = o[key]
            end
            o[key] = data.from + (data.to - data.from) * t
        end
    end

    return Animate.new(opts)
end

function Transform.mt.draw(o, block)
    o:pushMatrix()
    block()
    o:popMatrix()
end

function Transform.mt.pushMatrix(o)
    love.graphics.push()
    love.graphics.translate(o.x, o.y)
    love.graphics.rotate(o.rotation)
    love.graphics.scale(o.scale)
    love.graphics.translate(-o.origin.x, -o.origin.y)
end

function Transform.mt.popMatrix(o)
    love.graphics.pop()
end

return Transform
