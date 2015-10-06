# Splash.lua - 2D Spacial Hashing in Lua

![Demo GIF](https://github.com/bakpakin/Splash.lua/raw/master/res/demo.gif)

## About
Splash.lua is a Lua module for storing objects in 2d space in way that is
efficient for collision detection, rendering, and ray-casting. It is similar
in many ways to bump.lua, but focuses more on storing objects and querying the
world rather than performing collision resolution for you.

## Demo
There is a LÖVE demo in the `lovedemo` subdirectory that shows only some of
Splash's capabilities. Run it from the main project folder like so:
```bash
love ./lovedemo
```

## What does this do that bump.lua doesn't?
Well, nothing yet. The interface is slightly more flexible, and you don't have
to create a large table when querying a large rectangle.
I plan to add support for more shapes, especially circles and line segments.
Full polygonal support is a maybe. Also, one thing I wanted to do with this is
implement some simple verlet physics. Although physics might complicate the API,
I could make Splash much easier, simpler, and maybe faster than a full physics
engine. If I do add physics, I probably won't add full polygon support.
Clearly, this is still a Work In Progress.

## API

### Creating a new Splash World
Splash works with the concept of the World, a manager that keeps track of all
things in it.
```lua
local splash = require "splash"
local world = splash(cellSize)
```
Creates a new Splash world with a given cellSize. Leave `cellSize` as nil to get
the default of 128.

### Editing Things in the World
Currently, all items in Splash are represented by AABBs, or Axis Aligned
Bounding Boxes. In Splash, these are specified by four numbers, (x, y, w, h).
(x, y) is the top left most coordinate, and w and h are positive numbers
representing the width and height of the AABB.

```lua
local thing = world:add({}, x, y, w, h)
```
Adds a Lua table to the world in the given bounding box. Returns the first
parameter for convenience.

```lua
thing = world:remove(thing)
```
Removes a Lua table from the world. Returns the thing removed for convenience.

```lua
local newx, newy, neww, newh
thing, newx, newy, neww, newh = world:update(thing, x, y, [w, h])
```
Changes the position and optionally the size of an object in the World. w and h
must be positive if given. Returns the thing for convenience, along with the new
AABB of the thing.

### Checking the World

This is currently the core functionality of Splash. Splash offers three
different ways of checking the World. Mapping, Querying, and Iterating.
Mapping applies a function over every object found in the searched area.
Querying returns a sequence of all objects in the searched area. Iterating
returns an iterator over all objects in the searched area. All `query` functions
have a corresponding `map` and `iter` function of a similar name. The `map` and
`iter` functions, however, give extra information to the user in some cases.

#### Mapping
```lua
world:mapAll(f(thing))
world:mapPopulatedCells(f(cx, cy))
world:mapRect(f(thing), x, y, w, h)
world:mapPoint(f(thing), x, y)
world:mapCell(f(thing), cx, cy)
world:mapSegment(f(thing, t1, t2), x1, y1, x2, y2)
```

#### Querying
```lua
local things = world:queryAll()
local cellPairs = world:queryPopulatedCells()
local things = world:queryRect(x, y, w, h)
local things = world:queryPoint(x, y)
local things = world:queryCell(cx, cy)
local things = world:querySegment(x1, y1, x2, y2)
```

#### Iterating
```lua
for thing in world:iterAll() do ... end
for cx, cy in world:iterPopulatedCells() do ... end
for thing in world:iterRect(x, y, w, h) do ... end
for thing in world:iterPoint(x, y) do ... end
for thing in world:iterCell(cx, cy) do ... end
for thing, t1, t2 in world:iterSegment(x1, y1, x2, y2) do ... end
```

Besides these general functions, Splash also has a fast, early exit
ray-casting function that returns a thing, point of intersection, and time
of intersection (parameter from 0 to 1).
```lua
local thing, endx, endy, t1 = world:castRay(x1, y1, x2, y2)
```

### Utility Functions
```lua
local x, y, w, h = world:aabb(thing)
```
Returns the AABB associated with `thing`.

```lua
local cellx, celly = world:toCell(x, y)
```
Converts a world coordinate to a cell coordinate. This is useful mainly for
debugging, as cells are really more part of the implementation than the
interface.

```lua
local cx, cy, cw, ch = world:cellAabb(cellx, celly)
```
Returns the AABB of a cell. Again, useful mainly for debugging.

```lua
local count = world:cellThingCount(cx, cy)
```
Returns the number of things in a cell.

```lua
local cellCount = world:countCells()
```
Returns the number of populated cells in the world.

## Use it
Use splash.lua like any other Lua module. It's a single file, so just copy
splash.lua to your project source folder.

## Todo
* Add tests (busted)
* Add more shapes (circles, line segments, polygons)
* Add CI (travis)
* Add optional verlet physics? (A bit of a challenge, but a very good fit with
    static collision checking). Might complicate API
* Whatever features seem useful
* Better, more fully featured demo(s)
* Fix typos and other issues in this README
* Cell coordinates are currently limited to 2^25. That should be big enough for
anyone, but it's an unnecessary limitation.
* Bug squashing
