function love.load()
    love.graphics.setBackgroundColor(1, 1, 1)
    love.graphics.setNewFont("fonts/SourceCodePro-Bold.ttf", 24)

    -- read input into a matrix
    Map = {}
    for line in io.lines("3/input.txt") do
        local map_row = {}
        for val in string.gmatch(line, ".") do
            table.insert(map_row, val == "#" and true or false)
        end
        table.insert(Map, map_row)
    end
    Map.width = #Map[1]
    Map.height = #Map

    -- images
    Image = {
        tree1 = love.graphics.newImage("3/tree1.png"),
        tree2 = love.graphics.newImage("3/tree2.png"),
        tree3 = love.graphics.newImage("3/tree3.png"),
        tree4 = love.graphics.newImage("3/tree4.png"),
        toboggan = love.graphics.newImage("3/toboggan.png")
    }

    -- camera
    Camera = {
        target = {x = 5, y = 5},
        offset = {x = 0, y = 0},
        size_tree_og = {x = Image.tree1:getWidth(), y = Image.tree1:getHeight()},
        size_toboggan_og = {
            x = Image.toboggan:getWidth(),
            y = Image.toboggan:getHeight()
        }
    }
    setCameraSize(30)

    -- movement
    Movement = {
        tick = 0,
        globalTick = 0,
        step = 0,
        pos = {x = 1, y = 1},
        origin = {x = 1, y = 1},
        target = {x = 1, y = 1},
        pattern = {right = 3, down = 1},
        rotation = 0,
        _rotation = 0
    }

    -- animation
    Animate = {
        tree = nil,
        tick = 0,
        lastTick = 0,
        progress = 0,
        speed = 0,
        acceleration = 0,
        duration = 20
    }

    -- setup
    setNextTarget()
    updateCamera()

    time = 0
    treesHit = 0
    running = false
    paused = true
end

function setCameraSize(size)
    Camera.size = size
    Camera.size_tree = {x = Camera.size * 1.8}
    Camera.scale_tree = Camera.size_tree.x / Camera.size_tree_og.x
    Camera.size_tree.y = Camera.scale_tree * Camera.size_tree_og.y

    Camera.size_toboggan = {x = Camera.size * 1.8}
    Camera.scale_toboggan = Camera.size_toboggan.x / Camera.size_toboggan_og.x
    Camera.size_toboggan.y = Camera.scale_toboggan * Camera.size_toboggan_og.y
end

function updateCamera()
    Camera.offset.x = -Movement.pos.x + Camera.target.x
    Camera.offset.y = -Movement.pos.y + Camera.target.y
end

function setNextTarget()
    Movement.pos.x = Movement.target.x
    Movement.pos.y = Movement.target.y
    Movement.origin.x = Movement.target.x
    Movement.origin.y = Movement.target.y
    Movement.target.x = Movement.origin.x + Movement.pattern.right
    Movement.target.y = Movement.origin.y + Movement.pattern.down

    -- check if we collided with a tree
    local x = (Movement.pos.x - 1) % Map.width + 1
    local y = (Movement.pos.y - 1) % Map.height + 1
    if Map[y][x] then
        treesHit = treesHit + 1

        Animate.tree = {tick = 1, x = x, y = y, rotation = 0}
    end
end

function easeInOutQuintic(x)
    x = x * 2
    if x < 1 then
        return 0.5 * x * x * x
    end
    x = x - 2
    return 0.5 * (x * x * x + 2)
end

function love.update(dt)
    if not running then
        return
    end

    time = time + dt

    if Animate.tree then
        if Animate.tree.tick > 0 then
            Animate.tree.tick = Animate.tree.tick - dt * 1
            Animate.tree.rotation = 0.3 * math.sin(time * 26) *
                                        Animate.tree.tick ^ 2
        end
    end

    if paused then
        return
    end

    local x = time - Animate.duration / 2
    x = (x + Animate.duration / 2) / Animate.duration
    Animate.tick = easeInOutQuintic(x) -- (math.cos(x * math.pi - math.pi) + 1) / 2

    local tick = Animate.tick - Animate.lastTick

    if x >= 1 then
        print("stop")
        paused = true
        return
    end

    Movement.tick = Movement.tick + tick * Map.height
    while Movement.tick >= 1 do
        setNextTarget()
        Movement.tick = Movement.tick - 1
        Movement.globalTick = Movement.globalTick + 1
    end

    -- if Animate.speed
    -- Animate.acceleration = Animate.acceleration + dt * 0.3
    -- Animate.speed = Animate.speed + Animate.acceleration * dt

    Movement.pos.x =
        Movement.origin.x + (Movement.target.x - Movement.origin.x) *
            Movement.tick
    Movement.pos.y =
        Movement.origin.y + (Movement.target.y - Movement.origin.y) *
            Movement.tick

    updateCamera()

    Animate.lastTick = Animate.tick
end

function love.draw()
    local steps = 400 / Camera.size
    local offset = {_x = -Camera.offset.x, _y = -Camera.offset.y}
    offset.x = math.floor(offset._x)
    offset.y = math.floor(offset._y)
    offset.x_diff = offset.x - offset._x
    offset.y_diff = offset.y - offset._y

    for _y = 1, steps + 3 do
        local y = (offset.y + _y - 1) % Map.height + 1
        for _x = 1, steps + 3 do
            local x = (offset.x + _x - 1) % Map.width + 1
            if Map[y][x] then
                -- something random to make each tree unique
                local tree = (x * 3 + y) % 4 + 1
                local rotation = Animate.tree and Animate.tree.x == x and
                                     Animate.tree.y == y and
                                     Animate.tree.rotation or 0

                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(Image["tree" .. tree], (offset.x_diff + _x -
                                       1) * Camera.size + Camera.size / 2,
                                   (offset.y_diff + _y - 1) * Camera.size +
                                       Camera.size, rotation, Camera.scale_tree,
                                   Camera.scale_tree, Camera.size_tree_og.x / 2,
                                   Camera.size_tree_og.y)

                -- love.graphics.setColor(0, 0, 0)
                -- love.graphics.print(x .. ", " .. y, (offset.x_diff + _x - 1) *
                --                         Camera.size + Camera.size / 2,
                --                     (offset.y_diff + _y - 1) * Camera.size +
                --                         Camera.size)
            else
                love.graphics.setColor(0.96, 0.96, 0.96)
                love.graphics.rectangle("fill", (offset.x_diff + _x - 1) *
                                            Camera.size + Camera.size / 3,
                                        (offset.y_diff + _y - 1) * Camera.size +
                                            Camera.size / 3, Camera.size / 3,
                                        Camera.size / 3)
            end
        end
    end

    local toboggan_rotation = not paused and 0.2 + math.sin(time * 33) * 0.03 or
                                  0.2
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(Image.toboggan,
                       (Camera.target.x - 1) * Camera.size + Camera.size / 2,
                       (Camera.target.y - 1) * Camera.size + Camera.size / 2,
                       toboggan_rotation, Camera.scale_toboggan,
                       Camera.scale_toboggan, Camera.size_toboggan_og.x / 2,
                       Camera.size_toboggan_og.y / 2)

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 20, 320, 240, 60)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Trees hit: " .. treesHit, 40, 335)
    -- " Y: " .. Movement.origin.y .. " Time: " .. (math.floor(time * 10) / 10)
end

function love.keypressed(key)
    if key == "space" then
        if not running then
            running = true
            paused = false
        end
    end
end
