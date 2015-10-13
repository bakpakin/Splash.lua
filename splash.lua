--[[
Copyright (c) 2015 Calvin Rose

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local floor = math.floor
local pairs = pairs
local setmetatable = setmetatable
local unpack = unpack
local type = type
local abs = math.abs
local min = math.min
local max = math.max
local sqrt = math.sqrt
local assert = assert
local select = select
local wrap = coroutine.wrap
local yield = coroutine.yield

local SPACE_KEY_CONST = 2^25
local EPSILON = 2^(-15)

local splash = {}
splash.__index = splash

-- Helper functions

local function to_cell(cs, x, y)
    return floor(x / cs), floor(y / cs)
end

local function to_cell_box(cs, x, y, w, h)
    local x1, y1 = floor(x / cs), floor(y / cs)
    local x2, y2 = floor((x + w) / cs), floor((y + h) / cs)
    return x1, y1, x2, y2
end

-- Intersection Testing

-- Shapes are implemented as arrays, which is slightly harder ro read, but
-- better optimized by LuaJIT (and Lua).

local function aabb_aabb_intersect(a, b)
    return a[1] + EPSILON < b[1] + b[3] and b[1] + EPSILON < a[1] + a[3] and
           a[2] + EPSILON < b[2] + b[4] and b[2] + EPSILON < a[2] + a[4]
end

local function aabb_circle_intersect(aabb, circle)
    local x, y, w, h = aabb[1], aabb[2], aabb[3], aabb[4]
    local xc, yc, r = circle[1], circle[2], circle[3]
    if xc + EPSILON < x - r then return false end
    if xc + EPSILON > x + w + r then return false end
    if yc + EPSILON < y - r then return false end
    if yc + EPSILON > y + h + r then return false end
    if xc < x then
        if yc < y then
            return r ^ 2 > (yc - y) ^ 2 + (xc - x) ^ 2 + EPSILON
        elseif yc > y + h then
            return r ^ 2 > (yc - y - h) ^ 2 + (xc - x) ^ 2 + EPSILON
        end
    elseif xc > x + w then
        if yc < y then
            return r ^ 2 > (yc - y) ^ 2 + (xc - x - w) ^ 2 + EPSILON
        elseif yc > y + h then
            return r ^ 2 > (yc - y - h) ^ 2 + (xc - x - w) ^ 2 + EPSILON
        end
    end
    return true
end

local function circle_circle_intersect(c1, c2)
    return (c2[1] - c1[1])^2 + (c2[2] - c1[2])^2 + EPSILON < (c1[3] + c2[3])^2
    -- return distance^2 <= (radius1 + radius2)^2
end

-- Segment intersections should also return one or two times of intersection
-- from 0 to 1 for ray-casting
local function circle_sweep_impl(x1, y1, dx, dy, xc, yc, r)
    local cx, cy = xc - x1, yc - y1
    local pcx, pcy = dx - cx, dy - cy
    local pdotp = dx * dx + dy * dy
    local r2 = r^2
    local d2 = (dx * cy - cx * dy)^2 / pdotp
    local dt2 = (r2 - d2)
    if dt2 < EPSILON then return false end
    local dt = sqrt(dt2 / pdotp)
    local tbase = (dx * cx + dy * cy) / pdotp
    return tbase - dt <= 1 and tbase + dt >= 0, tbase - dt, tbase + dt
end

local function seg_circle_intersect(seg, circle)
    return circle_sweep_impl(seg[1], seg[2],seg[3], seg[4],
        circle[1], circle[2], circle[3])
end

local function seg_sweep_impl(x1, y1, dx1, dy1, x2, y2, dx2, dy2)
    local d = dx1 * dy2 - dy1 * dx2
    if d == 0 then return false end -- collinear
    local dx, dy = x1 - x2, y1 - y2
    local t1 = (dx2 * dy - dy2 * dx) / d
    if t1 < 0 or t1 > 1 then return false end
    local t2 = (dx1 * dy - dy1 * dx) / d
    if t2 < 0 or t2 > 1 then return false end
    return true, t1, t2
end

local function seg_seg_intersect(s1, s2)
    return seg_sweep_impl(s1[1], s1[2], s1[3], s1[4],
        s2[1], s2[2], s2[3], s2[4])
end

-- Replace with liang-barsky?
local function aabb_sweep_impl(x1, y1, dx, dy, x, y, w, h)
    local rx, ry = x - x1, y - y1
    local tx1, tx2, ty1, ty2, nx, ny
    if dx >= 0 then
        tx1, tx2 = rx / dx, (rx + w) / dx
    else
        tx2, tx1 = rx / dx, (rx + w) / dx
    end
    if dy >= 0 then
        ty1, ty2 = ry / dy, (ry + h) / dy
    else
        ty2, ty1 = ry / dy, (ry + h) / dy
    end
    local t1, t2 = max(tx1, ty1), min(tx2, ty2)
    local c = ((t1 + EPSILON < t2) and (t1 < 1) and (t2 > 0))
    if c then
        if ty1 < tx1 then
            nx, ny = dx >= 0 and -1 or 1, 0
        else
            nx, ny = 0, dy >= 0 and -1 or 1
        end
    end
    return c, t1, nx, ny
end

local function seg_aabb_intersect(seg, aabb)
    return aabb_sweep_impl(seg[1], seg[2], seg[3], seg[4],
        aabb[1], aabb[2], aabb[3], aabb[4])
end

local intersections = {
    circle = {
        circle = circle_circle_intersect,
    },
    aabb = {
        aabb = aabb_aabb_intersect,
        circle = aabb_circle_intersect
    },
    seg = {
        seg = seg_seg_intersect,
        aabb = seg_aabb_intersect,
        circle = seg_circle_intersect
    }
}

-- Static collisions
-- Returns boolean, plus times of collision for segments
local function shape_intersect(a, b)
    local f = intersections[a.type][b.type]
    if f then
        return f(a, b)
    else
        return intersections[b.type][a.type](b, a)
    end
end

-- Swept collisions
-- Function should return boolean for intersection, time of intersection,
-- and normal like so: didCollide, t, nx, ny

-- Minkowski difference is another aabb
local function aabb_aabb_sweep(a, b, xto, yto)
    local x1, y1, w1, h1 = a:unpack()
    local x2, y2, w2, h2 = b:unpack()
    -- Calculate Minkowski Difference
    local x, y, w, h = x2 - x1 - w1, y2 - y1 - h1, w1 + w2, h1 + h2
    return aabb_sweep_impl(0, 0, xto - x1, yto - y1, x, y, w, h)
end

-- Minkowksi Difference is another circle
local function circle_circle_sweep(a, b, xto, yto)
    local x1, y1, r1 = a:unpack()
    local x2, y2, r2 = b:unpack()
    -- Minkowski Difference
    local x, y, r = x2 - x1, y2 - y1, r1 + r2
    local c, t, nx, ny = circle_sweep_impl(0, 0, xto - x1, yto - y1, x, y, r)
    if c then
        nx, ny = x1 + x * t, y1 + y * t
        local d = sqrt(nx * nx + ny * ny)
        nx, ny = nx / d, ny / d
    end
    return c, t, nx, ny
end

local function seg_seg_sweep(a, b, xto, yto)

end

local function seg_circle_sweep(seg, circle, xto, yto)

end

local function seg_aabb_sweep(seg, aabb, xto, yto)

end

local function aabb_circle_sweep(aabb, circle, xto, yto)

end

local sweeps = {
    circle = {
        circle = circle_circle_sweep,
    },
    aabb = {
        aabb = aabb_aabb_sweep,
        circle = aabb_circle_sweep
    },
    seg = {
        seg = seg_seg_sweep,
        aabb = seg_aabb_sweep,
        circle = seg_circle_sweep
    }
}

local function shape_sweep(a, b, xto, yto)
    local f = sweeps[a.type][b.type]
    if f then
        return f(a, b, xto, yto)
    else
        local c, t, nx, ny = sweeps[b.type][a.type](a, b, xto, yto)
        if c then
            t, nx, ny = 1 - t, -nx, -ny
        end
        return c, t, nx, ny
    end
end

-- Grid functions

local function grid_aabb_impl(x1, y1, x2, y2, cs, f, ...)
    x1, y1, x2, y2 = to_cell_box(cs, x1, y1, x2, y2)
    for gx = x1, x2 do
        for gy = y1, y2 do
            local a = f(gx, gy, ...)
            if a then return a end
        end
    end
end

local function grid_segment_impl(x1, y1, dx, dy, cs, f, ...)
    local sx, sy = dx >= 0 and 1 or -1, dy >= 0 and 1 or -1
    local x, y = to_cell(cs, x1, y1)
    local xf, yf = to_cell(cs, x1 + dx, y1 + dy)
    if x == xf and y == yf then
        local a = f(x, y, ...)
        if a then return a end
    end
    local dtx, dty = abs(cs / dx), abs(cs / dy)
    local tx = abs((floor(x1 / cs) * cs + (sx > 0 and cs or 0) - x1) / dx)
    local ty = abs((floor(y1 / cs) * cs + (sy > 0 and cs or 0) - y1) / dy)
    while x ~= xf or y ~= yf do
        local a = f(x, y, ...)
        if a then return a end
        if tx > ty then
            ty = ty + dty
            y = y + sy
        else
            tx = tx + dtx
            x = x + sx
        end
    end
    return f(xf, yf, ...)
end

local function grid_segment(seg, cs, f, ...)
    return grid_segment_impl(seg[1], seg[2], seg[3], seg[4], cs, f, ...)
end

local function grid_aabb(aabb, cs, f, ...)
    return grid_aabb_impl(aabb[1], aabb[2], aabb[3], aabb[4], cs, f, ...)
end

-- For now, just use aabb grid code. Large circles will be in extra cells.
local function grid_circle(circle, cs, f, ...)
    local x, y, r = circle[1], circle[2], circle[3]
    return grid_aabb_impl(x - r, y - r, 2 * r, 2 * r, cs, f, ...)
end

local grids = {
    circle = grid_circle,
    aabb = grid_aabb,
    seg = grid_segment
}

local function shape_grid(shape, cs, f, ...)
    return grids[shape.type](shape, cs, f, ...)
end

-- Shapes

local shape_mt

local function shape_clone(s)
    return setmetatable({
        type = s.type,
        s[1], s[2], s[3], s[4]
    }, shape_mt)
end

local function shape_clone_to(s, d)
    d[1], d[2], d[3], d[4] = s[1], s[2], s[3], s[4]
    d.type = s.type
    return d
end

local function shape_update(s, x, y, a, b)
    s[1], s[2], s[3], s[4] = x, y, a or s[3], b or s[4]
    return s
end

shape_mt = {
    __index = {
        unpack = unpack,
        intersect = shape_intersect,
        sweep = shape_sweep,
        pos = function(self) return self[1], self[2] end,
        update = shape_update,
        clone = shape_clone
    },
    __call = function(self) return unpack(self) end
}

local function make_circle(x, y, r)
    return setmetatable({type = "circle", x, y, r}, shape_mt)
end

local function make_aabb(x, y, w, h)
    return setmetatable({type = "aabb", x, y, w, h}, shape_mt)
end

local function make_seg(x1, y1, dx, dy)
    return setmetatable({type = "seg", x1, y1, dx, dy}, shape_mt)
end

-- Splash functions

local function splash_new(cellSize)
    cellSize = cellSize or 128
    return setmetatable({
        cellSize = cellSize,
        count = 0,
        shapes = {}, -- Internal shapes
        shapes2 = {} -- Shapes that users can modify
    }, splash)
end

local function add_thing_to_cell(cx, cy, self, thing)
    local key = SPACE_KEY_CONST * cx + cy
    local l = self[key]
    if not l then l = {x = cx, y = cy}; self[key] = l end
    l[#l + 1] = thing
end

local function remove_thing_from_cell(cx, cy, self, thing)
    local key = SPACE_KEY_CONST * cx + cy
    local l = self[key]
    if not l then return end
    for i = 1, #l do
        if l[i] == thing then
            l[#l], l[i] = nil, l[#l]
            if #l == 0 then
                self[key] = nil
            end
            break
        end
    end
end

function splash:add(thing, shape)
    assert(not self.shapes[thing], "Thing is already in world.")
    self.count = self.count + 1
    local clone = shape_clone(shape)
    self.shapes[thing] = clone
    self.shapes2[thing] = shape
    shape_grid(shape, self.cellSize, add_thing_to_cell, self, thing)
    return thing, shape
end

function splash:remove(thing)
    local shape = self.shapes[thing]
    assert(shape, "Thing is not in world.")
    self.count = self.count - 1
    self.shapes[thing] = nil
    self.shape2[thing] = nil
    shape_grid(shape, self.cellSize, remove_thing_from_cell, self, thing)
    return thing, shape
end

function splash:setShape(thing, shape)
    local oldshape = self.shapes[thing]
    assert(oldshape, "Thing is not in world.")
    -- Maybe optimize this later to avoid updating cells that haven't moved.
    -- In practice for small objects this probably works fine. It's certainly
    -- shorter than the more optimized version would be.
    shape_grid(oldshape, self.cellSize, remove_thing_from_cell, self, thing)
    shape_grid(shape, self.cellSize, add_thing_to_cell, self, thing)
    shape_clone_to(shape, oldshape)
    self.shapes2[thing] = shape
    return thing, shape
end

function splash:update(thing, ...)
    local modifiedShape = self.shapes2[thing]
    assert(modifiedShape, "Could not find a Shape.")
    if ... then shape_update(modifiedShape, ...) end
    local shape = self.shapes[thing]
    assert(shape, "Thing is not in world.")
    shape_grid(shape, self.cellSize, remove_thing_from_cell, self, thing)
    shape_grid(modifiedShape, self.cellSize, add_thing_to_cell, self, thing)
    shape_clone_to(modifiedShape, shape)
    return thing, modifiedShape
end

-- Utility functions

function splash:shape(thing)
    return shape_clone(self.shapes[thing])
end

-- Debug functions

function splash:toCell(x, y)
    local cs = self.cellSize
    return floor(x / cs), floor(y / cs)
end

function splash:fromCell(cx, cy)
    local cs = self.cellSize
    return cx * cs, cy * cs
end

function splash:cellThingCount(cx, cy)
    local list = self[SPACE_KEY_CONST * cx + cy]
    if not list then return 0 end
    return #list
end

function splash:countCells()
    local count = 0
    for k, v in pairs(self) do
        if type(k) == "number" then count = count + 1 end
    end
    return count
end

-- Ray casting

local function ray_trace_helper(cx, cy, self, seg, ref)
    local list = self[SPACE_KEY_CONST * cx + cy]
    local shapes = self.shapes
    if not list then return false end
    for i = 1, #list do
        local thing = list[i]
        -- Segment intersections should always return a time of intersection
        local c, t1 = shape_intersect(seg, shapes[thing])
        if c and t1 <= ref[2] then
            ref[1], ref[2] = thing, t1
        end
    end
    local tcx, tcy = to_cell(self.cellSize,
                             seg[1] + ref[2] * seg[3],
                             seg[2] + ref[2] * seg[4])
    if cx == tcx and cy == tcy then return true end
end

function splash:castRay(x1, y1, x2, y2)
    local ref = {false, 1}
    local seg = make_seg(x1, y1, x2 - x1, y2 - y1)
    grid_segment(seg, self.cellSize, ray_trace_helper, self, seg, ref)
    local t = max(0, ref[2])
    return ref[1], (1 - t) * x1 + t * x2, (1 - t) * y1 + t * y2, t
end

-- Map functions

local function map_shape_helper(cx, cy, self, seen, f, shape)
    local list = self[SPACE_KEY_CONST * cx + cy]
    if not list then return end
    local shapes = self.shapes
    for i = 1, #list do
        local thing = list[i]
        if not seen[thing] then
            local c, t1, t2 = shape_intersect(shape, shapes[thing])
            if c then
                f(thing, t1, t2)
            end
            seen[thing] = true
        end
    end
end

function splash:mapShape(f, shape)
    local seen = {}
    return shape_grid(shape, self.cellSize,
        map_shape_helper, self, seen, f, shape)
end

function splash:mapPoint(f, x, y)
    return splash:mapShape(f, make_circle(x, y, 0))
end

function splash:mapCell(f, cx, cy)
    local list = self[SPACE_KEY_CONST * cx + cy]
    if not list then return end
    for i = 1, #list do f(list[i]) end
end

function splash:mapAll(f)
    local seen = {}
    for k, list in pairs(self) do
        if type(k) == "number" then
            for i = 1, #list do
                local thing = list[i]
                if not seen[thing] then
                    seen[thing] = true
                    f(thing)
                end
            end
        end
    end
end

-- Generate the iter versions of Map functions
local default_filter = function() return true end
local function generate_query_iter(name, filter_index)
    local mapName = "map" .. name
    local iterName = "iter" .. name
    local queryName = "query" .. name
    splash[queryName] = function(self, ...)
        local ret = {}
        local filter = select(filter_index, ...) or default_filter
        for thing in self[iterName](self, ...) do
            if filter(thing, ...) then
                ret[#ret + 1] = thing
            end
        end
        return ret
    end
    splash[iterName] = function(self, a, b)
        return wrap(function() self[mapName](self, yield, a, b) end)
    end
end

generate_query_iter("Shape", 2)
generate_query_iter("All", 1)
generate_query_iter("Cell", 3)
generate_query_iter("Point", 3)

-- Make the module
return setmetatable({
    new = splash_new,
    circle = make_circle,
    aabb = make_aabb,
    seg = make_seg
}, { __call = function(_, ...) return splash_new(...) end })
