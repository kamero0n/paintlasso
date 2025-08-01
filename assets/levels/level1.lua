Level1 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- first puzzle stuff
local dogPoop, trashCan, invisibleWall
local dogPoopCleaned = false
local PROGRESS_GATE_X = 600
local trashThreshold = 40

function Level1.init(world)
    -- create ground collider
    ground = world:newRectangleCollider(0, WINDOWHEIGHT - 300, WINDOWWIDTH * 2, 300)
    ground:setType('static')

    -- create dog poop
    dogPoop = SelectableObject(300, WINDOWHEIGHT - 330, 25, 15, {0.4, 0.2, 0.1}, world)

    -- create trash can 
    trashCan = {
        x = 500,
        y = WINDOWHEIGHT - 380,
        width = 60,
        height = 80,
        color = {0.3, 0.3, 0.3}
    }

    -- create invisible gate
    invisibleWall = world:newRectangleCollider(PROGRESS_GATE_X, 0, 10, WINDOWHEIGHT - 300)
    invisibleWall:setType('static')

end

local function checkPoopToTrash(poop, trash)
    local poopCenterX = poop.x + poop.width/2
    local poopCenterY = poop.y + poop.height/2
    local trashCenterX = trash.x + trash.width/2
    local trashCenterY = trash.y + trash.height/2

    local dist = math.sqrt((poopCenterX - trashCenterX)^2 + (poopCenterY - trashCenterY)^2)

    if dist < trashThreshold then
        dogPoopCleaned = true

        -- remove invisibleWall
        if invisibleWall then
            invisibleWall:destroy()
            invisibleWall = nil
        end

        -- remove poop
        if dogPoop.body then
            dogPoop.body:destroy()
            dogPoop.body = nil
        end
    end
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

    -- check if poop has been picked up
    if not dogPoopCleaned then
        checkPoopToTrash(dogPoop, trashCan)
    end

    -- limit player movement if dog poop not solved
    if not dogPoopCleaned and player.x > PROGRESS_GATE_X - player.width then
        player.x = PROGRESS_GATE_X - player.width
    end
end


function Level1.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 2, 300)

    -- draw objects
    if not dogPoopCleaned then
        dogPoop:draw()
    end

    -- draw trash can
    love.graphics.setColor(trashCan.color[1], trashCan.color[2], trashCan.color[3], 1)
    love.graphics.rectangle("fill", trashCan.x, trashCan.y, trashCan.width, trashCan.height)

    if not dogPoopCleaned then
        love.graphics.setColor(1, 0, 0, 0.3)
        love.graphics.rectangle("fill", PROGRESS_GATE_X, 0, 10, WINDOWHEIGHT - 300)
    end

end

function Level1.getObjects()
    -- only return selectableObjects
    if dogPoopCleaned then
        return {}
    else
        return {dogPoop}
    end
end

function Level1.isPuzzleSolved()
    return dogPoopCleaned
end

function Level1.getProgressGateX()
    return PROGRESS_GATE_X
end