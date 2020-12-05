local AnimatedText = {
    x = 0,
    y = 0,
    index = 0,
    speed = 1,
    tick = 0,
    globalTick = 0,
    yOffset = 1,
    _yOffset = 1,
    lists = {},
    done = false
}

function AnimatedText:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    table.insert(AnimatedText.lists, o)
    o.index = #AnimatedText.lists

    if o.syncWith then
        function o.syncWith:check()
            return o:check()
        end
    end

    return o
end

function AnimatedText:check()
    return false
end

function AnimatedText:reset()
    self.tick = 0
    self.yOffset = 1
    self._yOffset = 1
end

function AnimatedText:update(dt)
    if not AnimatedText.done then
        if self.syncWith then
            if self.syncWith.globalTick >= 1 then
                while self.syncWith.globalTick >= 1 do
                    if self.yOffset < #data then
                        if self.yOffset < #data then
                            self.yOffset = self.yOffset + 1
                        end
                    end

                    self.syncWith.globalTick = self.syncWith.globalTick - 1
                end

                self.syncWith:reset()

                self.syncWith.globalTick = 0

                if self.yOffset == #data then
                    self.globalTick = self.globalTick + 1
                end
            end
        else
            self.tick = self.tick + dt * self.speed

            if self.tick >= 1 then
                while self.tick >= 1 do
                    if self.yOffset < #data then
                        self.yOffset = self.yOffset + 1

                        if self:check() then
                            return
                        end
                    end
                    self.tick = self.tick - 1
                end
                self.tick = 0

                if self.yOffset == #data then
                    self.globalTick = self.globalTick + 1
                end
            end
        end
    end

    self._yOffset = self._yOffset + (self.yOffset - self._yOffset) * dt * 10;
end

function AnimatedText:draw()
    local offset = self._yOffset

    if not AnimatedText.done then
        if self.speed > 10000 then
            -- offset = #data
            -- just show it at random positions since the speed is so high
            offset = #data * math.random()
        end
    end

    for i, num in ipairs(data) do
        love.graphics.print(num, self.x, self.y + (-offset + i) * 30)
    end
end

return AnimatedText
