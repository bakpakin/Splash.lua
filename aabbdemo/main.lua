local splash = require "splash"

local world = splash.new()
local player

function love.load()
    love.window.setMode(900, 600, {resizable = true})
    player = world:add({}, splash.aabb(100, 100, 20, 20))
    for i = 1, 20 do
        world:add({}, splash.aabb(math.random(600), math.random(600), 20, 20))
    end
end

function love.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("left") then dx = dx - 100 end
    if love.keyboard.isDown("right") then dx = dx + 100 end
    if love.keyboard.isDown("up") then dy = dy - 100 end
    if love.keyboard.isDown("down") then dy = dy + 100 end
    local x, y = world:pos(player)
    world:move(player, x + dx * dt, y + dy * dt)
end

local function draw_thing(thing)
    local t, x, y, a, b = world:unpackShape(thing)
    love.graphics.rectangle("fill", x, y, a, b)
end

function love.draw()
    world:mapAll(draw_thing)
    love.graphics.print(collectgarbage("count"), 5, 5)
end
