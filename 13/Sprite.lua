local Sprite = {list = {}}

Sprite.mt = {
    frame = 1,
    image = nil,
    size = 1,
    speed = 1,
    tick = 0,
    quad = nil,
    sequence = nil,
    _init = function(o)
        o.width = o.image:getWidth()
        o.height = o.image:getHeight()
        o.x = o.width / o.size
        o.y = o.height / o.size
        o.frames = o.x * o.y

        o:setFrame(1)
    end,
    loop = function(o, sequence)
        if sequence then
            o.sequence = sequence
        end

        o:setFrame(1)
        return o
    end,
    setFrame = function(o, frame)
        if o.sequence then
            frame = (frame - 1) % #o.sequence
            o.frame = frame + 1
            frame = o.sequence[frame + 1] - 1
        else
            frame = (frame - 1) % o.frames
            o.frame = frame + 1
        end

        local y = math.floor(frame / o.x)
        local x = frame - y * o.x
        o.quad = love.graphics.newQuad(x * o.size, y * o.size, o.size, o.size,
                                       o.width, o.height)
        return o
    end,
    draw = function(o, x, y, r)
        love.graphics.draw(o.image, o.quad, x, y, r or 0)
        return o
    end,
    update = function(o, dt)
        o.tick = o.tick + dt

        if o.tick >= o.speed then
            o:setFrame(o.frame + 1)
            o.tick = 0
        end
        return o
    end
}
Sprite.mt.__index = Sprite.mt

function Sprite.new(o)
    o = o or {}
    setmetatable(o, Sprite.mt)
    o:_init()
    table.insert(Sprite.list, o)
    return o
end

function Sprite.update(dt)
    for _, s in ipairs(Sprite.list) do
        s:update(dt)
    end
end

return Sprite
