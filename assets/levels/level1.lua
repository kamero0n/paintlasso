Level1 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- test objects
local testObjects = {}

function Level1.init()
    testObjects = {}

    -- create objects
    table.insert(testObjects, SelectableObject(400, WINDOWHEIGHT - 350, 40, 40, {1, 0, 0}))
    table.insert(testObjects, SelectableObject(400, WINDOWHEIGHT - 350, 60, 30, {0, 1, 0}))
    table.insert(testObjects, SelectableObject(450, WINDOWHEIGHT - 400, 30, 60, {0, 0, 1}))
    table.insert(testObjects, SelectableObject(600, 200, 50, 50, {0, 1, 1}))
end

function Level1.play(player, dt)
   -- update all test objects
   for i, obj in ipairs(testObjects) do
        local isBeingDragged = false
        obj:update(dt, isBeingDragged)
   end

   -- simple
   love.graphics.setColor(1, 1, 1, 1)
   
end

function Level1.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 2, 300)

    for i, obj in ipairs(testObjects) do 
        obj:draw()
    end
end

function Level1.getObjects()
    return testObjects
end