local splash = require "splash"
local draw_world = require "demos.draw_world"

local world = splash.new()
local player
local camx, camy = 0, 0

function love.load()
    love.window.setMode(900, 600, {resizable = true})
    player = world:add({}, splash.aabb(100, 100, 20, 20))
    for i = 1, 200 do
        world:add({}, splash.aabb(
            math.random(2000) - 1000,
            math.random(2000) - 1000,
            math.random(50) + 10,
            math.random(50) + 10))
    end
end

function love.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("a") then camx = camx - 200 * dt end
    if love.keyboard.isDown("d") then camx = camx + 200 * dt end
    if love.keyboard.isDown("w") then camy = camy - 200 * dt end
    if love.keyboard.isDown("s") then camy = camy + 200 * dt end
    if love.keyboard.isDown("left") then dx = dx - 100 end
    if love.keyboard.isDown("right") then dx = dx + 100 end
    if love.keyboard.isDown("up") then dy = dy - 100 end
    if love.keyboard.isDown("down") then dy = dy + 100 end
    local x, y = world:pos(player)
    world:move(player, x + dx * dt, y + dy * dt)
end

function love.draw()
    love.graphics.translate(-camx, -camy)
    draw_world(world)
    love.graphics.setColor(255, 0, 0)
    draw_world.shape(world:shape(player))
    -- Simple HUD
    love.graphics.origin()
    love.graphics.setColor(0, 0, 0, 180)
    love.graphics.rectangle("fill", 0, 0, 200, 85)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print("WASD to move camera.", 5, 5)
    love.graphics.print("Arrow Keys to move red box.", 5, 35)
end
