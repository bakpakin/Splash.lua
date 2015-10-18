local splash = require "splash"
local draw_world = require "demos.draw_world"

local world = splash(128)
local camx, camy = 0, 0
local player = {}
local dir = 0
local mx, my
local time = 0
local spinners = {}

local function r() return math.random(-1600, 1600) end

function love.load()
    love.window.setMode(900, 600, {resizable = true})
    for i = 1, 150 do
        world:add({}, splash.aabb(r(), r(), 50, 50))
        world:add({}, splash.circle(r(), r(), 25))
        local x, y = r(), r()
        local dir = math.random(2*math.pi)
        world:add({}, splash.seg(x, y, 300 * math.cos(dir), 300 * math.sin(dir)))
    end
    for i = 1, 45 do
        local spinner = {x = r(), y = r()}
        spinners[i] = world:add(spinner, splash.aabb(spinner.x + 100, spinner.y, 100, 100))
    end
end

function love.update(dt)
    time = time + dt
    local dx, dy = 0, 0

    if love.keyboard.isDown("a") then camx = camx - 200 * dt end
    if love.keyboard.isDown("d") then camx = camx + 200 * dt end
    if love.keyboard.isDown("w") then camy = camy - 200 * dt end
    if love.keyboard.isDown("s") then camy = camy + 200 * dt end

    if love.keyboard.isDown("e") then dir = dir + 2 * dt end
    if love.keyboard.isDown("q") then dir = dir - 2 * dt end

    mx, my = love.mouse.getPosition()
    mx, my = mx + camx, my + camy

    for _, spinner in ipairs(spinners) do
        world:update(spinner, spinner.x + 100 * math.cos(time), spinner.y + 100 * math.sin(time))
    end
end

function love.draw()
    -- Apply camera translation
    love.graphics.translate(-camx, -camy)

    -- Cast a ray and highlight the hit object
    love.graphics.setColor(255, 0, 0)
    local item, ex, ey = world:castRay(mx, my, mx + math.cos(dir) * 2000, my + math.sin(dir) * 2000)
    love.graphics.line(mx, my, ex, ey)
    if item then draw_world.shape(world:shape(item), "fill") end
    love.graphics.setColor(80, 80, 80, 255)

    draw_world(world)

    -- Simple HUD
    love.graphics.origin()
    love.graphics.setColor(0, 0, 0, 180)
    love.graphics.rectangle("fill", 0, 0, 200, 85)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print("WASD to move camera.", 5, 5)
    love.graphics.print("Mouse to move lazer.", 5, 35)
    love.graphics.print("Q and E to rotate lazer.", 5, 65)
end
