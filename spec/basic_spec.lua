local splash = require "splash"

describe("Splash", function()

    it("can create a new World with splash.new()", function()
        local world = splash.new()
        assert.truthy(world)
        assert.are.equal(world.cellSize, 128)
    end)

    it("can create a new World with splash()", function()
        local world = splash.new()
        assert.truthy(world)
        assert.are.equal(world.cellSize, 128)
    end)

    it("can create a new World with splash.new(cellSize)", function()
        local world = splash.new(32)
        assert.truthy(world)
        assert.are.equal(world.cellSize, 32)
    end)

    it("can create a new World with splash(cellSize)", function()
        local world = splash(32)
        assert.truthy(world)
        assert.are.equal(world.cellSize, 32)
    end)

end)
