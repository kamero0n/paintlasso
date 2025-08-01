Level1 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- first puzzle stuff
local dogPoop, trashCan, progressGate
local dogPoopCleaned = false
local PROGRESS_GATE_X = 800

function Level1.init()
    -- create dog poop
    dogPoop = SelectableObject(300, WINDOWHEIGHT - 330, 25, 15, {0.4, 0.2, 0.1})

end


function Level1.play(plaer, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)
    -- update dog poop
    local isPoopBeingDragged = false
    for j, selectedObj in ipairs(selectedObjects) do
        if selectedObj == dogPoop and lasso_state == "dragging" and isMouseDragging then
            isPoopBeingDragged = true
            break
        end
    end
    dogPoop:update(dt, isPoopBeingDragged, allObjects)
    
end


function Level1.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 2, 300)

    -- draw objects
    dogPoop:draw()


end

function Level1.getObjects()
    return {dogPoop}
end