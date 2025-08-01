TestLevel = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- test objects
local testObjects = {}

function TestLevel.init()
    testObjects = {}

    -- create objects
    table.insert(testObjects, SelectableObject(400, WINDOWHEIGHT - 350, 40, 40, {1, 0, 0}))
    table.insert(testObjects, SelectableObject(400, WINDOWHEIGHT - 350, 60, 30, {0, 1, 0}))
    table.insert(testObjects, SelectableObject(450, WINDOWHEIGHT - 400, 30, 60, {0, 0, 1}))
    table.insert(testObjects, SelectableObject(600, 200, 50, 50, {0, 1, 1}))
end

function TestLevel.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)
   -- update all test objects
   for i, obj in ipairs(testObjects) do
        local isBeingDragged = false
        
        -- check if object is being dragged
        for j, selectedObj in ipairs(selectedObjects) do
            if selectedObj == obj and lasso_state == "dragging" and isMouseDragging then
                isBeingDragged = true
                break
            end
        end

        obj:update(dt, isBeingDragged, allObjects)
   end

   -- simple
   love.graphics.setColor(1, 1, 1, 1)
   
end

function TestLevel.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 2, 300)

    for i, obj in ipairs(testObjects) do 
        obj:draw()
    end
end

function TestLevel.getObjects()
    return testObjects
end