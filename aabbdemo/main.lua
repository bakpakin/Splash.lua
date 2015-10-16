local splash = require "splash"

local world = splash.new()
local player = world:add({}, splash.aabb(100, 100, 20, 20))
for i = 1, 100 do
    world:add({}, splash.aabb(20, i*20, 20, 20))
end

function love.load()
    love.window.setMode(900, 600, {resizable = true})
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
    for thing in world:iterAll() do
        draw_shape(world:shape(thing))
    end
end
