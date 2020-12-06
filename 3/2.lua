Movement = {
    tick = 0,
    globalTick = 0,
    step = 0,
    pattern = {right = 1, down = 1},
    rotation = 0,
    _rotation = 0,
    treesHit = 0,
    resolution = 1
}

function Movement:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.pos = {x = 1, y = 1}
    o.origin = {x = 1, y = 1}
    o.target = {x = 1, y = 1}
    o.animate = {
        tree = nil,
        tick = 0,
        lastTick = 0,
        progress = 0,
        speed = 0,
        acceleration = 0,
        duration = 20
    }

    return o
end

--------------

function love.load()
    love.graphics.setBackgroundColor(1, 1, 1)
    FontBig = love.graphics.newFont("fonts/SourceCodePro-Bold.ttf", 24)
    FontSmall = love.graphics.newFont("fonts/SourceCodePro-Regular.ttf", 15)

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
        pos = {x = 0, y = 0},
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
    Movements = {
        Movement:new{pattern = {right = 1, down = 1}},
        Movement:new{pattern = {right = 3, down = 1}, follow = true},
        Movement:new{pattern = {right = 5, down = 1}},
        Movement:new{pattern = {right = 7, down = 1}},
        Movement:new{pattern = {right = 1, down = 2}, resolution = 2}
    }

    -- animation
    -- Animate = {
    --     tree = nil,
    --     tick = 0,
    --     lastTick = 0,
    --     progress = 0,
    --     speed = 0,
    --     acceleration = 0,
    --     duration = 20
    -- }

    -- setup
    for _, m in ipairs(Movements) do
        setNextTarget(m)
    end
    updateCamera(Movements[1])

    time = 0
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

function updateCamera(movement)
    Camera.pos = movement.pos

    Camera.offset.x = -Camera.pos.x + Camera.target.x
    Camera.offset.y = -Camera.pos.y + Camera.target.y
end

function setNextTarget(m, i)
    m.pos.x = m.target.x
    m.pos.y = m.target.y
    m.origin.x = m.target.x
    m.origin.y = m.target.y
    m.target.x = m.origin.x + m.pattern.right
    m.target.y = m.origin.y + m.pattern.down

    -- check if we collided with a tree
    local x = (m.pos.x - 1) % Map.width + 1
    local y = (m.pos.y - 1) % Map.height + 1
    if Map[y][x] then
        m.treesHit = m.treesHit + 1

        m.animate.tree = {tick = 1, x = x, y = y, rotation = 0}
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

    for _, m in ipairs(Movements) do
        if m.animate.tree then
            if m.animate.tree.tick > 0 then
                m.animate.tree.tick = m.animate.tree.tick - dt * 1
                m.animate.tree.rotation =
                    0.3 * math.sin(time * 26) * m.animate.tree.tick ^ 2
            end
        end

        if not paused then

            local x = time - m.animate.duration / 2
            x = (x + m.animate.duration / 2) / m.animate.duration
            m.animate.tick = easeInOutQuintic(x) -- (math.cos(x * math.pi - math.pi) + 1) / 2

            local tick = m.animate.tick - m.animate.lastTick

            if x >= 1 then
                print("stop")
                paused = true
                return
            end

            m.tick = m.tick + tick * Map.height / m.resolution
            while m.tick >= 1 do
                setNextTarget(m, _)
                m.tick = m.tick - 1
                m.globalTick = m.globalTick + 1
            end

            -- if m.animate.speed
            -- m.animate.acceleration = m.animate.acceleration + dt * 0.3
            -- m.animate.speed = m.animate.speed + m.animate.acceleration * dt

            m.pos.x = m.origin.x + (m.target.x - m.origin.x) * m.tick
            m.pos.y = m.origin.y + (m.target.y - m.origin.y) * m.tick

            if m.follow then
                setCameraSize(30 - 26 *
                                  (math.cos(x * 2 * math.pi - math.pi) + 1) / 2)
                updateCamera(m)
            end

            m.animate.lastTick = m.animate.tick
        end
    end
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
                local rotation = 0

                for _, m in ipairs(Movements) do
                    if m.animate.tree and m.animate.tree.x == x and
                        m.animate.tree.y == y then
                        rotation = m.animate.tree.rotation
                        break
                    end
                end

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

    local treesHit = 0
    local treesValue = 1

    for _, m in ipairs(Movements) do
        -- print(_, m.pos.x, m.pos.y)
        local x = Camera.pos.x - m.pos.x
        local y = Camera.pos.y - m.pos.y
        love.graphics.draw(Image.toboggan, (Camera.target.x - 1 - x) *
                               Camera.size + Camera.size / 2,
                           (Camera.target.y - 1 - y) * Camera.size + Camera.size /
                               2, toboggan_rotation, Camera.scale_toboggan,
                           Camera.scale_toboggan, Camera.size_toboggan_og.x / 2,
                           Camera.size_toboggan_og.y / 2)

        treesHit = treesHit + m.treesHit
        treesValue = treesValue * m.treesHit
    end

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 20, 320, 300, 60)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(FontBig)
    love.graphics.print("Trees hit: " .. treesHit, 40, 326)
    love.graphics.setFont(FontSmall)
    love.graphics.print("Multiplied value: " .. treesValue, 40, 356)
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
