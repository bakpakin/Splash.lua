local shape_draws = {
    circle = function(s, m)
        love.graphics.circle(m, s:unpack())
        love.graphics.line(s[1], s[2] - s[3], s[1], s[2])
    end,
    aabb = function(s, m) love.graphics.rectangle(m, s:unpack()) end,
    seg = function(s, m)
        local x, y, dx, dy = s:unpack()
        love.graphics.line(x, y, x + dx, y + dy) end
}

local function draw_shape(shape, mode)
    mode = mode or "line"
    shape_draws[shape.type](shape, mode)
end

local function draw_world(world)
    love.graphics.setColor(255, 255, 255)
    for thing in world:iterAll() do
        draw_shape(world:shape(thing))
    end
end

return setmetatable({
    world = draw_world,
    shape = draw_shape
}, {__call = function(_, ...) return draw_world(...) end})
