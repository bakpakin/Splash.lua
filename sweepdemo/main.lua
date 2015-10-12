local splash = require "splash"

local world = splash.new()
local shapeMouse, Mouse
local shapeTarget, Target
local camx, camy = 0, 0

function love.load()
    love.window.setMode(900, 600, {resizable = true})
    shapeMouse = splash.circle(0, 0, 100, 200)
    Mouse = world:add({}, shapeMouse)
    shapeTarget = splash.circle(-24, -57, 400, 250)
    Target = world:add({}, shapeTarget)
end

function love.update(dt)
    if love.keyboard.isDown("a") then camx = camx - 200 * dt end
    if love.keyboard.isDown("d") then camx = camx + 200 * dt end
    if love.keyboard.isDown("w") then camy = camy - 200 * dt end
    if love.keyboard.isDown("s") then camy = camy + 200 * dt end
end

local shape_draws = {
    circle = function(s, m) love.graphics.circle(m, s:unpack()) end,
    aabb = function(s, m) love.graphics.rectangle(m, s:unpack()) end,
    seg = function(s, m)
        local x, y, dx, dy = s:unpack()
        love.graphics.line(x, y, x + dx, y + dy) end
}

local function draw_shape(shape, mode)
    mode = mode or "line"
    shape_draws[shape.type](shape, mode)
end

function love.draw()
    -- Apply camera translation
    love.graphics.translate(-camx, -camy)

    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(255, 255, 255)

    love.graphics.line(mx + camx, my + camy, 0, 0)
    world:update(Mouse, mx + camx, my + camy)
    local c, t, nx, ny = world:shape(Mouse):sweep(world:shape(Target), 0, 0)
    if c then
        t = 1 - t
        local cx, cy = world:shape(Mouse):pos()
        world:update(Mouse, cx * t, cy * t)
        love.graphics.line(mx + camx, my + camy, mx + camx + 100 * nx, my + camy + 100 * ny)
    end

    -- Draw Visible Shapes
    love.graphics.setColor(255, 255, 255)
    for thing in world:iterAll() do
        draw_shape(world:shape(thing))
    end

    -- Simple HUD
    love.graphics.origin()
    love.graphics.setColor(0, 0, 0, 180)
    love.graphics.rectangle("fill", 0, 0, 200, 85)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print("WASD to move camera.", 5, 5)
end
