# Splash.lua - 2D Spacial Hashing in Lua

[![Build Status](https://travis-ci.org/bakpakin/Splash.lua.svg?branch=master)](https://travis-ci.org/bakpakin/Splash.lua)

![Demo GIF](https://github.com/bakpakin/Splash.lua/blob/master/img/demo.gif)

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
Shapes are not just limited to rectangles. The interface is slightly more
flexible, and you don't have to create a large table when querying a large part
of the world. Currently, AABBs, circles and line segments are supported.
Full polygonal support is a maybe. Swept collisions and responses might also
be added in the future. Clearly, this is still a Work In Progress.

## API

### Creating a new Splash World
Splash works with the concept of the World, a manager that keeps track of all
things in it.
```lua
local splash = require "splash"
local world = splash.new(cellSize) -- or splash(cellSize)
```
Creates a new Splash world with a given cellSize. Leave `cellSize` as nil to get
the default of 128.

### Shapes
Splash associates **Things** in a World with **Shapes**. Currently, there are
three different types of Shapes: Circles, Segs, and AABBs.

```lua
local aabb = splash.aabb(x, y, w, h)
```
Creates an AABB at `(x, y)` with a width and height of `w` and `h`. AABBs are
just rectangles that cannot rotate. Both width and height must be positive.

```lua
local circle = splash.circle(x, y, r)
```
Creates a circle at `(x, y)` with a radius of `r`. The radius must be positive.

```lua
local seg = splash.seg(x1, y1, x2, y2)
```
Creates a line segment from `(x1, y1)` to `(x2, y2)`.

Shapes also have a few common methods.

```lua
local x, y, ... = shape:unpack() -- Unpacks all of the values used to construct the Shape
local x, y, ... - shape() -- Shortcut for unpacking the Shape
local newShape = shape:clone() -- Creates a copy of the Shape
local didIntersect = shape:intersect(otherShape) -- Checks if two Shapes intersect. For segments, returns the time of intersection between 0 and 1
local x, y = shape:pos() -- Unpacks only the first two values of the Shape, which are x and y.
local shape = shape:update(newx, newy, [...]) -- Updates the values of the Shape without creating a new Shape. Returns the Shape for convenience
```

### Things
Things are keys that are associated with Shapes in a Splash World. They can be
any Lua type, but should probably be tables.

```lua
local shape = splash.aabb(x, y, w, h)
local thing = world:add({}, shape)
```
Adds a Thing to the world with the Shape. Returns the Thing and the Shape for
convenience.

```lua
thing, shape = world:remove(thing)
```
Removes a Thing from the world. Returns the Thing removed and its associated
Shape for convenience.

```lua
thing, shape = world:setShape(thing, shape)
```
Changes the Shape of a Thing in the World. Returns the Thing for
convenience, along with the new Shape.

```lua
shape:update(100, 100)
thing, shape = world:update(thing)
```
Updates the Shape of a Thing in the World without creating a new Shape. Use this
to move Things around instead of creating a new Shape every step with
`setShape`. The above example sets the position of thing to (100, 100),
regardless of what kind of shape it is, and is equivalent to:
```lua
thing, shape = world:update(thing, 100, 100)
```

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
world:mapShape(f(thing), shape)
world:mapCell(f(thing), cx, cy)
world:mapPoint(f(thing), x, y)
```

#### Querying
```lua
local things = world:queryAll([filter])
local things = world:queryShape(shape, [filter])
local things = world:queryCell(cx, cy, [filter])
local things = world:queryPoint(x, y, [filter])
```

#### Iterating
```lua
for thing in world:iterAll() do ... end
for thing in world:iterShape(shape) do ... end
for thing in world:iterCell(cx, cy) do ... end
for thing in world:iterPoint(x, y) do ... end
```

Besides these general functions, Splash also has a fast, early exit
ray-casting function that returns a thing, point of intersection, and time
of intersection (parameter from 0 to 1).
```lua
local thing, endx, endy, t1 = world:castRay(x1, y1, x2, y2)
```

### Utility Functions
```lua
local shape = world:shape(thing)
```
Returns the Shape associated with `thing`.

### Debug Functions
These functions should be used mainly for debugging and inspecting what Splash
is doing. They deal mostly with how Splash puts objects into cells for fast
lookup.

```lua
local cellx, celly = world:toCell(x, y)
```
Converts a world coordinate to a cell coordinate.

```lua
local aabb = world:fromCell(cellx, celly)
```
Returns the world coordinates of a cell's most negative corner. Again, useful
mainly for debugging.

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
* Swept collisions
* Whatever features seem useful
* Better, more fully featured demo(s)
* Fix typos and other issues in this README
* Cell coordinates are currently limited to 2^25. That should be big enough for
anyone, but it's an unnecessary limitation.
* Bug squashing
