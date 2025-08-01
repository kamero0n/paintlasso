Level1 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- first puzzle stuff
local dogPoop, trashCan, progressGate
local dogPoopCleaned = false
local PROGRESS_GATE_X = 800

function Level1.init(world)
    -- create ground collider
    ground = world:newRectangleCollider(0, WINDOWHEIGHT - 300, WINDOWWIDTH * 2, 300)
    ground:setType('static')

    -- create dog poop
    dogPoop = SelectableObject(300, WINDOWHEIGHT - 330, 25, 15, {0.4, 0.2, 0.1}, world)

    -- create trash can 
    trashCan = SelectableObject(500, WINDOWHEIGHT - 380, 60, 80, {0.3, 0.3, 0.3}, world)

    -- create invisible gate


end


function Level1.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)
    -- update dog poop
    local isPoopBeingDragged = false
    for j, selectedObj in ipairs(selectedObjects) do
        if selectedObj == dogPoop and lasso_state == "dragging" and isMouseDragging then
            isPoopBeingDragged = true
            break
        end
    end
    dogPoop:update(dt, isPoopBeingDragged, allObjects)

    -- update trash can 
    trashCan:update(dt, false, allObjects)
    
end


function Level1.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 2, 300)

    -- draw objects
    dogPoop:draw()
    trashCan:draw()


end

function Level1.getObjects()
    return {dogPoop, trashCan}
end