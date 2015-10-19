local splash = require "splash"
local draw_world = require "demos.draw_world"

local world = splash.new()
local destx, desty = 400, 200
local target = splash.seg(100, 200, 50, 300)
local sweeper = splash.circle(0, 0, 50, 40)

function love.update(dt)
    if love.keyboard.isDown("left") then destx = destx - 100 * dt end
    if love.keyboard.isDown("right") then destx = destx + 100 * dt end
    if love.keyboard.isDown("up") then desty = desty - 100 * dt end
    if love.keyboard.isDown("down") then desty = desty + 100 * dt end
end

function love.draw()
    local mx, my = love.mouse.getPosition()
    sweeper:update(mx, my)
    local c, t, nx, ny = sweeper:sweep(target, destx, desty)
    if c then
        local xto, yto = mx + (destx - mx) * t, my + (desty - my) * t
        sweeper:update(xto, yto)
        love.graphics.line(xto, yto, xto + 100 * nx, yto + 100 * ny)
    else
        sweeper:update(destx, desty)
    end
    love.graphics.line(mx, my, destx, desty)
    draw_world.shape(sweeper)
    draw_world.shape(target)
end
