local splash = require "...splash"

local world = splash(128)
local camx, camy = 0, 0
local player = {}
local dir = 0
local mx, my
local time = 0
local spinners = {}

function love.load()
    love.window.setMode(900, 600, {resizable = true})
    for i = 1, 300 do
        world:add({}, math.random(-800, 800), math.random(-800, 800), 25, 25)
    end
    for i = 1, 45 do
        local spinner = {x = math.random(-800, 800), y = math.random(-800, 800)}
        spinners[i] = world:add(spinner, spinner.x + 100, spinner.y, 50, 50)
    end
end

function love.update(dt)
    time = time + dt
    local dx, dy = 0, 0

    if love.keyboard.isDown("a") then camx = camx - 200 * dt end
    if love.keyboard.isDown("d") then camx = camx + 200 * dt end
    if love.keyboard.isDown("w") then camy = camy - 200 * dt end
    if love.keyboard.isDown("s") then camy = camy + 200 * dt end

    if love.keyboard.isDown("q") then dir = dir + 2 * dt end
    if love.keyboard.isDown("e") then dir = dir - 2 * dt end

    mx, my = love.mouse.getPosition()
    mx, my = mx + camx, my + camy

    for _, spinner in ipairs(spinners) do
        world:update(spinner, spinner.x + 100 * math.cos(time), spinner.y + 100 * math.sin(time))
    end
end

function love.draw()
    love.graphics.translate(-camx, -camy)
    love.graphics.setColor(255, 0, 0)
    local item, ex, ey = world:castRay(mx, my, mx + math.cos(dir) * 2000, my + math.sin(dir) * 2000)
    love.graphics.line(mx, my, ex, ey)
    if item then love.graphics.rectangle("fill", world:aabb(item)) end
    love.graphics.setColor(80, 80, 80, 255)
    for cx, cy in world:iterPopulatedCells() do
        local x, y, w, h = world:cellAabb(cx, cy)
        love.graphics.rectangle("line", x, y, w, h)
        love.graphics.printf(world:cellThingCount(cx, cy), x + 5, y + 5, 300, "left")
    end
    love.graphics.setColor(255, 255, 255)
    for thing in world:iterAll() do
        love.graphics.rectangle("line", world:aabb(thing))
    end
    love.graphics.origin()
    love.graphics.setColor(0, 0, 0, 230)
    love.graphics.rectangle("fill", 0, 0, 200, 85)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print("WASD to move camera.", 5, 5)
    love.graphics.print("Mouse to move lazer.", 5, 35)
    love.graphics.print("Q and E to rotate lazer.", 5, 65)
end
