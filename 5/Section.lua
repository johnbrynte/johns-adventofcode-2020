local Animate = require "utils.Animate"

local Section = {}

Section.mt = {
    width = 1,
    height = 1,
    x = 0,
    y = 0,
    offsetX = 0,
    offsetY = 0,
    valid = false,
    next = nil
}

function Section.new(o)
    o = o or {}
    setmetatable(o, Section.mt)
    Section.mt.__index = Section.mt
    return o
end

function Section.mt.splitHorizontal(o, code)
    local index = code and 2 or 1
    local w = o.width / 2
    local h = o.height

    o[1] = Section.new {width = w, height = h, x = o.x, y = o.y}
    o[2] = Section.new {width = w, height = h, x = o.x + w, y = o.y}

    o[index].valid = true
    o.next = o[index]

    if index == 1 then
        o[2]:animateTo(1, 0)
    else
        o[1]:animateTo(-1, 0)
    end

    return o[index]
end

function Section.mt.splitVertical(o, code)
    local index = code and 1 or 2
    local w = o.width
    local h = o.height / 2

    o[1] = Section.new {width = w, height = h, x = o.x, y = o.y}
    o[2] = Section.new {width = w, height = h, x = o.x, y = o.y + h}

    o[index].valid = true
    o.next = o[index]

    if index == 1 then
        o[2]:animateTo(0, 1)
    else
        o[1]:animateTo(0, -1)
    end

    return o[index]
end

function Section.mt.split(o, code)
    if code == "F" or code == "B" then
        return o:splitHorizontal(code)
    else
        return o:splitVertical(code)
    end
end

function Section.mt.animateTo(o, x, y)
    local fromx = o.offsetX
    local fromy = o.offsetY

    Animate.new {
        duration = 0.6,
        callback = function(t)
            o.offsetX = fromx + (x - fromx) * t
            o.offsetY = fromy + (y - fromy) * t
        end,
        easing = Animate.easing.cubicOut
    }:start()

    return o
end

function Section.mt.draw(o, size, globalX, globalY)
    local space = size / 6

    if o.valid then
        love.graphics.setColor(1, 0, 0)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
    end

    for x = o.x, o.x + o.width - 1 do
        for y = o.y, o.y + o.height - 1 do
            love.graphics.rectangle("fill",
                                    globalX + (x + o.offsetX) * size + space,
                                    globalY + (y + o.offsetY) * size + space,
                                    size - 2 * space, size - 2 * space)
        end
    end

    if o.valid and not o.next then
        local wscale = 1.6
        local wscale_inner = 0.3
        local h = 30
        local str = tostring(o.x)
        local w = str:len() * 13
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", globalX + (o.x + o.offsetX) * size,
                                globalY + (o.y + o.offsetY) * size - h,
                                w * wscale, h, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(str, globalX + (o.x + o.offsetX) * size + w *
                                wscale_inner,
                            globalY + (o.y + o.offsetY) * size - h)

        str = tostring(o.y)
        w = str:len() * 13
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill",
                                globalX + (o.x + o.offsetX) * size - w * wscale,
                                globalY + (o.y + o.offsetY) * size + space,
                                w * wscale, h, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(str, globalX + (o.x + o.offsetX) * size - w *
                                (1 + wscale_inner),
                            globalY + (o.y + o.offsetY) * size + space)
    end
end

return Section
