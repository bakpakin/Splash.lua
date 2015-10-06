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
local assert = assert

local SPACE_KEY_CONST = 2^25

local splash = {}
splash.__index = splash

local function assert_aabb(x, y, w, h)
    if w <= 0 or h <= 0 then
        error "Width and Height of an AABB must be greater than 0."
    end
end

local function array_copy(x)
    local ret = {}
    if not x then return nil end
    for i = 1, #x do ret[i] = x[i] end
    return ret
end

local function to_cell(cs, x, y)
    return floor(x / cs), floor(y / cs)
end

local function to_cell_box(cs, x, y, w, h)
    local x1, y1 = floor(x / cs), floor(y / cs)
    local x2, y2 = floor((x + w) / cs), floor((y + h) / cs)
    return x1, y1, x2, y2
end

local function add_item_to_cell(self, item, cx, cy)
    local key = SPACE_KEY_CONST * cx + cy
    local l = self[key]
    if not l then l = {x = cx, y = cy}; self[key] = l end
    l[#l + 1] = item
end

local function remove_item_from_cell(self, item, cx, cy)
    local key = SPACE_KEY_CONST * cx + cy
    local l = self[key]
    if not l then return end
    for i = 1, #l do
        if l[i] == item then
            l[#l], l[i] = nil, l[#l]
            if #l == 0 then
                self[key] = nil
            end
            break
        end
    end
end

local function aabb_overlap(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and
           y1 < y2 + h2 and y2 < y1 + h1
end

local function aabb_seg_intersect(x1, y1, x2, y2, x, y, w, h)
    local idx, idy = 1 / (x2 - x1), 1 / (y2 - y1)
    local rx, ry = x - x1, y - y1
    local tx1, tx2, ty1, ty2
    if idx > 0 then
        tx1, tx2 = rx * idx, (rx + w) * idx
    else
        tx2, tx1 = rx * idx, (rx + w) * idx
    end
    if idy > 0 then
        ty1, ty2 = ry * idy, (ry + h) * idy
    else
        ty2, ty1 = ry * idy, (ry + h) * idy
    end
    local t1, t2 = max(tx1, ty1), min(tx2, ty2)
    return t1 <= t2 and t1 <= 1 and t2 >= 0, t1, t2
end

-- Splash functions

local function splash_new(cellSize)
    cellSize = cellSize or 128
    return setmetatable({
        cellSize = cellSize,
        count = 0,
        info = {}
    }, splash)
end

function splash:add(item, x, y, w, h)
    assert_aabb(x, y, w, h)
    local info = {x, y, w or 0, h or 0}
    assert(not self.info[item], "Item is already in world.")
    self.count = self.count + 1
    self.info[item] = info
    local cs = self.cellSize
    local cxstart, cystart, cxend, cyend = to_cell_box(cs, x, y, w, h)
    for cx = cxstart, cxend do
        for cy = cystart, cyend do
            add_item_to_cell(self, item, cx, cy)
        end
    end
    return item
end

function splash:remove(item)
    local info = self.info[item]
    local x, y, w, h = unpack(info)
    assert(self.info[item], "Item is not in world.")
    self.count = self.count - 1
    self.info[item] = nil
    local cs = self.cellSize
    local cxstart, cystart, cxend, cyend = to_cell_box(cs, x, y, w, h)
    for cx = cxstart, cxend do
        for cy = cystart, cyend do
            remove_item_from_cell(self, item, cx, cy)
        end
    end
    return item
end

function splash:update(item, x, y, w, h)
    local info = self.info[item]
    assert(info, "Item is not in world.")
    local oldx, oldy, oldw, oldh = unpack(info)
    w, h = w or oldw, h or oldh
    assert_aabb(x, y, w, h)
    if x ~= oldx or y ~= oldy or w ~= oldw or h ~= oldh then
        local cs = self.cellSize
        local ox1, oy1, ox2, oy2 = to_cell_box(cs, oldx, oldy, oldw, oldh)
        local cx1, cy1, cx2, cy2 = to_cell_box(cs, x, y, w, h)
        for cx = ox1, ox2 do
            local xpass = cx > cx2 or cx < cx1
            for cy = oy1, oy2 do
                if xpass or cy > cy2 or cy < cy1 then
                    remove_item_from_cell(self, item, cx, cy)
                end
            end
        end
        for cx = cx1, cx2 do
            local xpass = cx > ox2 or cx < ox1
            for cy = cy1, cy2 do
                if xpass or cy > oy2 or cy < oy1 then
                    add_item_to_cell(self, item, cx, cy)
                end
            end
        end
        info[1], info[2], info[3], info[4] = x, y, w, h
    end
    return item, unpack(info)
end

-- Utility functions

function splash:aabb(item)
    return unpack(self.info[item])
end

function splash:toCell(x, y)
    local cs = self.cellSize
    return floor(x / cs), floor(y / cs)
end

function splash:cellAabb(cx, cy)
    local cs = self.cellSize
    return cx * cs, cy * cs, cs, cs
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

-- Grid functions

local function grid_rect(x, y, w, h, cs, f, ...)
    assert_aabb(x, y, w, h)
    local x1, y1, x2, y2 = to_cell_box(cs, x, y, w, h)
    for gx = x1, x2 do
        for gy = y1, y2 do
            local ret = f(gx, gy, ...)
            if ret then return ret end
        end
    end
end

local function grid_segment(x1, y1, x2, y2, cs, f, ...)
    local sx, sy = x2 >= x1 and 1 or -1, y2 >= y1 and 1 or -1
    local x, y = to_cell(cs, x1, y1)
    local xf, yf = to_cell(cs, x2, y2)
    if x == xf and y == yf then
        return f(x, y, ...)
    end
    local dx, dy = x2 - x1, y2 - y1
    local dtx, dty = abs(cs / dx), abs(cs / dy)
    local tx = abs((floor(x1 / cs) * cs + (sx > 0 and cs or 0) - x1) / dx)
    local ty = abs((floor(y1 / cs) * cs + (sy > 0 and cs or 0) - y1) / dy)
    while x ~= xf or y ~= yf do
        local ret, xt, yt, t = f(x, y, ...)
        if ret then return ret, xt, yt, t end
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

-- Ray casting

local function ray_trace_helper(cx, cy, self, x1, y1, x2, y2)
    local list = self[SPACE_KEY_CONST * cx + cy]
    local info = self.info
    if not list then return nil, x2, y2, 1 end
    local ret, t = nil, 1
    for i = 1, #list do
        local item = list[i]
        local c, t1 = aabb_seg_intersect(x1, y1, x2, y2, unpack(info[item]))
        if c and t1 <= t then
            ret, t = item, t1
        end
    end
    t = max(t, 0)
    local it = 1 - t
    return ret, x1 * it + x2 * t, y1 * it + y2 * t, t
end

function splash:castRay(x1, y1, x2, y2)
    return grid_segment(x1, y1, x2, y2, self.cellSize,
        ray_trace_helper, self, x1, y1, x2, y2)
end

-- Map helper functions

local function map_rect_helper(cx, cy, self, seen, f, x, y, w, h)
    local list = self[SPACE_KEY_CONST * cx + cy]
    local info = self.info
    if not list then return end
    for i = 1, #list do
        local item = list[i]
        if not seen[item] and
            aabb_overlap(x, y, w, h, unpack(info[item])) then
            f(item)
        end
        seen[item] = true
    end
end

local function map_segment_helper(cx, cy, self, seen, f, x1, y1, x2, y2)
    local list = self[SPACE_KEY_CONST * cx + cy]
    local info = self.info
    if not list then return end
    for i = 1, #list do
        local item = list[i]
        if (not seen[item]) then
            local c, t1, t2 = aabb_seg_intersect(x1, y1, x2, y2,
                unpack(info[item]))
            if c then
                f(item, t1, t2)
            end
        end
        seen[item] = true
    end
end

-- Map functions

function splash:mapPopulatedCells(f)
    for k, list in pairs(self) do
        if type(k) == "number" then
            f(list.x, list.y)
        end
    end
end

function splash:mapRect(f, x, y, w, h)
    local seen = {}
    return grid_rect(x, y, w, h, self.cellSize,
        map_rect_helper, self, seen, f, x, y, w, h)
end

function splash:mapSegment(f, x1, y1, x2, y2)
    local seen = {}
    return grid_segment(x1, y1, x2, y2, self.cellSize,
        map_segment_helper, self, seen, f, x1, y1, x2, y2)
end

function splash:mapPoint(f, x, y)
    local cx, cy = to_cell(self.cellSize, x, y)
    local list = self[SPACE_KEY_CONST * cx + cy]
    if not list then return end
    local info = self.info
    for i = 1, #list do
        local item = list[i]
        local x1, y1, w1, h1 = unpack(info[item])
        if x >= x1 and y >= y1 and x <= x1 + w1 and y <= y1 + h1 then
            f(item)
        end
    end
end

function splash:mapCell(f, cx, cy)
    local list = self[SPACE_KEY_CONST * cx + cy]
    if not list then return end
    for i = 1, #list do f(list[i]) end
end

function splash:mapAll(f)
    local seen, ret = {}, {}
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

-- Generate the query and iter versions of Map functions
local query_map_fn = function(n) ret[#ret + 1] = n end
local query_box_map_fn = function(...) ret[#ret + 1] = {...} end
local function generate_query_iter(name, box_query)
    local mapName = "map" .. name
    local queryName = "query" .. name
    local iterName = "iter" .. name
    local query_fn = box_query and query_box_map_fn or query_map_fn
    splash[queryName] = function(self, ...)
        local ret = {}
        self[mapName](self, query_map_fn, ...)
        return ret
    end
    -- Little hack to avoid packing and unpacking varargs - a, b, c, d
    splash[iterName] = function(self, a, b, c, d)
        return coroutine.wrap(function()
            self[mapName](self, function(...)
                coroutine.yield(...)
            end, a, b, c, d)
        end)
    end
end

generate_query_iter("Cell")
generate_query_iter("Point")
generate_query_iter("Rect")
generate_query_iter("Segment")
generate_query_iter("All")
generate_query_iter("PopulatedCells", true)

return splash_new
