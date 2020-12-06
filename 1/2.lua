-- Uppgift 2
------------------
AnimatedText = require("1.AnimatedText")

function love.load()
    love.graphics.setBackgroundColor({0.8, 0.8, 0.8})

    local input = love.filesystem.read("1/input.txt")
    data = {}
    for line in string.gmatch(input, "%d+") do
        table.insert(data, line)
    end

    speedIncrease = 0
    speed = 1
    sum = data[1] + data[1]
    answerA = nil
    answerB = nil
    answerC = nil
    running = false

    list3 = AnimatedText:new{x = 175, y = 100, speed = 1}
    list2 = AnimatedText:new{x = 100, y = 100, syncWith = list3}
    list1 = AnimatedText:new{x = 25, y = 100, syncWith = list2}

    function list1:check()
        local a = data[self.yOffset]
        local b = data[self.syncWith.yOffset]
        local c = data[self.syncWith.syncWith.yOffset]

        sum = a + b + c
        if sum == 2020 then
            answerA = a
            answerB = b
            answerC = c
            AnimatedText.done = true
            return true
        else
            if self.yOffset == #data and self.syncWith.yOffset == #data and
                self.syncWith.syncWith.yOffset == #data then
                AnimatedText.done = true
                return true
            end
            return false
        end
    end

    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(love.graphics.newFont(16))
end

function love.update(dt)
    if not running then
        return
    end

    if speed < 2000000 then
        speedIncrease = speedIncrease + dt
        speed = speed + (speedIncrease * 2) ^ 3 * dt * 10
    end
    list3.speed = speed

    for _, list in ipairs(AnimatedText.lists) do
        list:update(dt)
    end
end

function love.draw()
    love.graphics.setColor(1, 0, 0, 0.2)
    love.graphics.rectangle("fill", 0, 100 - 3, 400, 30)

    love.graphics.setColor(0, 0, 0)
    for _, list in ipairs(AnimatedText.lists) do
        list:draw()
    end

    love.graphics.print("+", 76, 99)
    love.graphics.print("+", 152, 99)
    love.graphics.print("=", 240, 99)
    if sum then
        love.graphics.print(sum, 270, 100)
        if AnimatedText.done then
            love.graphics.setColor(0, 0.2, 0)
            love.graphics.print(answerA, 270, 130)
            love.graphics.print(answerB, 270, 160)
            love.graphics.print(answerC, 270, 190)
            love.graphics.print("*", 250, 193)
            love.graphics.line(245, 216, 340, 216)
            love.graphics.setColor(0, 0.6, 0)
            love.graphics.print(answerA * answerB * answerC, 270, 220)
        end
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit()
    end

    if key == "space" then
        running = true
    end
end
