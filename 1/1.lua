-- Uppgift 1
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
    running = false

    rightList = AnimatedText:new{x = 175, y = 100, speed = 1}
    leftList = AnimatedText:new{x = 80, y = 100, syncWith = rightList}

    function leftList:check()
        sum = data[self.yOffset] + data[self.syncWith.yOffset]
        if sum == 2020 then
            answerA = data[self.yOffset]
            answerB = data[self.syncWith.yOffset]
            AnimatedText.done = true
            return true
        else
            return false
        end
    end

    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(love.graphics.newFont(20))
end

function love.update(dt)
    if not running then
        return
    end

    if speed < 100000 then
        speedIncrease = speedIncrease + dt
        speed = speed + (speedIncrease * 2) ^ 3 * dt * 10
    end
    rightList.speed = speed

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

    love.graphics.print("+", 145, 99)
    love.graphics.print("=", 240, 99)
    if sum then
        love.graphics.print(sum, 270, 100)
        if AnimatedText.done then
            love.graphics.setColor(0, 0.2, 0)
            love.graphics.print(answerA, 270, 130)
            love.graphics.print(answerB, 270, 160)
            love.graphics.print("*", 250, 163)
            love.graphics.line(245, 186, 340, 186)
            love.graphics.setColor(0, 0.6, 0)
            love.graphics.print(answerA * answerB, 270, 190)
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
