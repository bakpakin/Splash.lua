# Splash.lua - 2D Spacial Hashing and Collision in Lua

[![Build Status](https://travis-ci.org/bakpakin/Splash.lua.svg?branch=master)](https://travis-ci.org/bakpakin/Splash.lua)

![Demo GIF](https://github.com/bakpakin/Splash.lua/blob/master/img/demo.gif)

## About
Splash.lua is a Lua module for making collisions easier and managing objects in
2D space. It enables ray casting, spatial querying, and collision resolution
of circles, rectangles, and line segments. It uses similar collision responses
to [bump.lua](https://github.com/kikito/bump.lua) to resolve collisions. In
fact, Splash.lua is very similar to bump.lua, but has more general collision
shapes. Splash.lua is still a work in progress.  

## Demos
There are a few LÖVE demos in the `demos` subdirectory that shows only some of
Splash's capabilities. Run a demo from the main project folder like so:
```bash
love demos/pick_a_demo
```

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
local seg = splash.seg(x1, y1, dx, dy)
```
Creates a line segment from `(x1, y1)` to `(x1 + dx, y1 + dy)`.

Shapes also have a few common methods.

```lua
local x, y, ... = shape:unpack() -- Unpacks all of the values used to construct the Shape
local x, y, ... - shape() -- Shortcut for unpacking the Shape
local newShape = shape:clone() -- Creates a copy of the Shape
local didIntersect = shape:intersect(otherShape) -- Checks if two Shapes intersect. For segments, returns the time of intersection between 0 and 1
local didCollide, t, nx, ny, cornerCollide = shape:sweep(other, xto, yto) -- Checks if a Shape would intersect another Shape when moving to point
-- (xto, yto). Returns information about the collision including when it happened, and the collision normal.
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

```lua
local shape = world:shape(thing)
```
Gets the Shape associated with a Thing.

```lua
local type, x, y, a, b = world:unpackShape(thing)
```
Gets the unpack data of a Shape associated with Thing. Equivalent to
`world:shape(thing):unpack()`, but doesn't create a new Shape.

```lua
local x, y = world:pos(thing)
```
Gets the position of a Thing in the World. Equivalent to
`world:shape(thing):pos()`.

### Collision Resolution

Splash.lua can collide Things with other Things in a World in an efficient and
general manner. Splash.lua works on the basis of collision responses that are
used to resolve collisions. Be default, three are built in: `'slide'`,
`'touch'`, and `'cross'`. These should work the same as they do in
[bump.lua](https://github.com/kikito/bump.lua).

```lua
xto, yto = world:move(thing, xgoal, ygoal, [filter, callback])
```
Moves a Thing in the world to (xto, yto), colliding with the collision method
based on filter. The filter is a function of two arguments, thing1 and thing2,
and returns a collision type to be used to resolve the collision. If a logical
false is returned, then no collision occurs between thing1 and thing2. If no
filter is provided, then the default response of 'slide' is used. If callback is
provided, then it is called on every collision with arguments:
`callback(thing, other, x, y, xgoal, ygoal, normalx, normaly)`.

```lua
xto, yto, collisions = world:moveExt(thing, xgoal, ygoal, [filter])
```
Similar to `world:move`, but returns a sequence of collisions instead of using a
callback. Every element of the `collision` sequence is a table containing the
following information about collisions.

* self: the Thing that was moved.
* other: the Thing that self collided with
* x, y: the position of self when the collision occurs.
* xgoal, ygoal: the position self is heading towards after the collision.
* nx, ny: the normal vector of the collision.  

There are also two functions `world:check` and `world:checkExt` that do exactly
the same things as the move functions, but don't update the position of the
Thing in the world. They are useful for checking if collisions *would* have
occurred had a Thing been moved to a location.

### Checking the World

Splash offers three different ways of checking the World. Mapping, Querying,
and Iterating. Mapping applies a function over every object found in the
searched area. Querying returns a sequence of all objects in the searched area.
Iterating returns an iterator over all objects in the searched area. All `query`
functions have a corresponding `map` and `iter` function of a similar name.
The `map` and `iter` functions, however, give extra information to the user in
some cases.

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
* More swept collisions - not all sweeps have been implemented.
* Whatever features seem useful
* Better, more fully featured demo(s)
* Fix typos and other issues in this README
* Cell coordinates are currently limited to 2^25. That should be big enough for
anyone, but it's an unnecessary limitation.
* Bug squashing
