c_clear = {1, 1, 1}
c_white = {1, 1, 1}
c_green = {0, 1, 0}
c_red = {1, 0, 0}

function love.load()
    love.graphics.setNewFont("fonts/SourceCodePro-Bold.ttf", 20)
    love.graphics.setColor(c_clear)

    local input = love.filesystem.read("2/input.txt")
    local chunks = {"min", "max", "char", "password"}
    passwords = {}

    -- read input
    for line in input:gmatch("(.-)\n") do
        local pass = {}
        -- match "min-max char: password"
        for min, max, char, password in line:gmatch("(%d+)%-(%d+) (%a): (.*)") do
            pass.min = tonumber(min)
            pass.max = tonumber(max)
            pass.char = char
            pass.password = password
        end
        table.insert(passwords, pass)
    end

    running = false
    curPass = {
        pass = nil,
        char = 1,
        index = 0,
        checking = true,
        str_formatted = {}
    }

    pass_passed = 0
    pass_failed = 0
    pass_checked = {}

    animate = {
        x = 40,
        _x_first = 40,
        y = 140,
        _y = 140,
        y_first = 110,
        _y_first = 110,
        tick = 0,
        speed = 1,
        speedIncrease = 0,
        offset = 26
    }

    setNext()
end

function setNext()
    local index = curPass.index + 1
    if index > #passwords then
        running = false
    end

    curPass.pass = passwords[index]
    curPass.index = index
    curPass.tick = 0
    curPass.char = 1
    curPass.chars_ok = 0
    curPass.str_ok = ""
    curPass.str_error = ""
    curPass.str_formatted = {c_white, ""}
end

function tickChar()
    if not running then
        return true
    end

    local char = curPass.pass.password:sub(curPass.char, curPass.char)
    if char == curPass.pass.char and
        (curPass.char == curPass.pass.min or curPass.char == curPass.pass.max) then
        -- add green char
        table.insert(curPass.str_formatted, c_green)
        table.insert(curPass.str_formatted, char)
        table.insert(curPass.str_formatted, c_white)
        table.insert(curPass.str_formatted, "")

        curPass.chars_ok = curPass.chars_ok + 1
    else
        -- add white char
        curPass.str_formatted[#curPass.str_formatted] =
            curPass.str_formatted[#curPass.str_formatted] .. char
    end

    curPass.str_ok = curPass.str_ok .. char

    curPass.char = curPass.char + 1
    if curPass.char > curPass.pass.password:len() then
        local passed = false

        if curPass.chars_ok == 1 then
            pass_passed = pass_passed + 1
            passed = true

            curPass.str_formatted = {
                c_green, "✓ ", unpack(curPass.str_formatted)
            }
        else
            pass_failed = pass_failed + 1

            curPass.str_formatted = {c_red, "x ", unpack(curPass.str_formatted)}
        end

        table.insert(pass_checked, 1,
                     {password = curPass.str_formatted, passed = passed})

        animate._y = animate.y - animate.offset
        animate._x_first = animate.x + animate.offset
        animate._y_first = animate.y_first - animate.offset
        animate.tick = 0

        setNext()
        return true
    end
    return false
end

function love.update(dt)
    if running then
        if animate.speed < 100000 then
            animate.speedIncrease = animate.speedIncrease + dt * 1
            animate.speed = animate.speed + (animate.speedIncrease) ^ 2 * dt *
                                10
        end

        local _tick = curPass.tick
        curPass.tick = curPass.tick + dt * animate.speed

        if curPass.tick >= 1 then
            if _tick == 0 then
                if animate.speed > 3000 then
                    -- do two at a time
                    for i = 1, 2 do
                        while not tickChar() do
                        end
                    end
                else
                    local diff = curPass.tick - _tick
                    while diff > 1 and not tickChar() do
                        diff = diff - 1
                    end
                end
            else
                tickChar()
            end
            curPass.tick = 0
        end
    end

    if animate.tick < 1 then
        animate.tick = animate.tick + dt * 1
        if animate.tick > 1 then
            animate.tick = 1
        end

        animate._y = animate._y + (animate.y - animate._y) * animate.tick
        animate._x_first = animate._x_first + (animate.x - animate._x_first) *
                               animate.tick
        animate._y_first = animate._y_first +
                               (animate.y_first - animate._y_first) *
                               animate.tick
    end
end

function love.draw()
    love.graphics.print({c_green, "✓ " .. pass_passed}, 40, 20)
    love.graphics.print({c_red, "x " .. pass_failed}, 200, 20)

    love.graphics.print({c_green, "> ", unpack(curPass.str_formatted)},
                        animate.x, animate.y - animate.offset * 2)

    for i, p in ipairs(pass_checked) do
        local x = i > 1 and animate.x or animate._x_first
        local y = i > 1 and animate._y + (i - 2) * animate.offset or
                      animate._y_first

        if p.passed then
            love.graphics.print(p.password, x, y)
        else
            love.graphics.print(p.password, x, y)
        end
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "space" then
        running = true
    end
end
