Level1 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- first puzzle stuff
local dogPoop, trashCan, invisibleWall
local dogPoopCleaned = false
local PROGRESS_GATE_X = 750
local trashThreshold = 40
local poopThreshold = 50

-- second puzzle stuff
local trashCanLid, sprinkler
local sprinklerCovered = false
local PROGRESS_GATE_X2 = 1200
local lidThreshold = 30
local sprinklerBlockRadius = 80


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

    -- create trashCanLid
    trashCanLid = SelectableObject(PROGRESS_GATE_X + 50, WINDOWHEIGHT - 395, 70, 10, {0.5, 0.5, 0.5}, world)

    -- create sprinkler
    sprinkler = {
        x = 900,
        y = WINDOWHEIGHT - 330,
        width = 20,
        height = 30,
        color = {0.6, 0.6, 0.6},
        waterAngle = 0,
        waterRange = 120,
        active = true,
        currentRadius = sprinklerBlockRadius
    }

    -- create invisible gate
    invisibleWall = world:newRectangleCollider(PROGRESS_GATE_X, 0, 10, WINDOWHEIGHT - 300)
    invisibleWall:setType('static')
end

local function checkDist(obj1, obj2, threshold)
    local obj1CenterX = obj1.x + obj1.width/2
    local obj1CenterY = obj1.y + obj1.height/2
    local obj2CenterX = obj2.x + obj2.width/2
    local obj2CenterY = obj2.y + obj2.height/2

    local dist = math.sqrt((obj1CenterX - obj2CenterX)^2 + (obj1CenterY - obj2CenterY)^2)

    return dist < threshold
end

local function checkIfObjIsDragged(obj, selectedObjects, lasso_state, isMouseDragging)
    local isBeingDragged = false
    for j, selectedOBj in ipairs(selectedObjects) do
        if selectedOBj == obj and lasso_state == "dragging" and isMouseDragging then
                isBeingDragged = true
        end
    end

    return isBeingDragged
end

local function isLidOnSprinkler()
    local lidCenterX = trashCanLid.x + trashCanLid.width/2
    local sprinklerCenterX = sprinkler.x + sprinkler.width /2
    local horizDist = math.abs(lidCenterX - sprinklerCenterX)

    local verticalDist = math.abs((trashCanLid.y + trashCanLid.height) - sprinkler.y)

    return horizDist <= sprinkler.width / 2 + 10 and verticalDist <= 5
end

function Level1.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)
    -- first puzzle --
    -- update dog poop
    local isPoopBeingDragged = checkIfObjIsDragged(dogPoop, selectedObjects, lasso_state, isMouseDragging)

    -- check if poop has been picked up
    if not dogPoopCleaned and not isPoopBeingDragged then
        -- check horizontal dist
        local poopCenterX = dogPoop.x + dogPoop.width/2
        local trashCenterX = trashCan.x + trashCan.width/2
        local horizDist = math.abs(poopCenterX - trashCenterX)

        local poopBottom = dogPoop.y + dogPoop.height
        local trashTop = trashCan.y
        local verticalDist = math.abs(poopBottom - trashTop)

        if verticalDist <= 5 and horizDist <= 30 then
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

    if not dogPoopCleaned then
        dogPoop:update(dt, isPoopBeingDragged, allObjects)
    end

    -- check if the player is trying to go over the poop
    if not dogPoopCleaned and checkDist(dogPoop, player, poopThreshold) then
        -- push back player
        local poopCenterX = dogPoop.x + dogPoop.width / 2
        player.x = poopCenterX - poopThreshold - player.width / 2
    end

    -- limit player movement if dog poop not solved
    if not dogPoopCleaned and player.x > PROGRESS_GATE_X - player.width then
        player.x = PROGRESS_GATE_X - player.width
    end

    -- second puzzle -- 
    -- update trash can lid
    local isLidBeingDragged = checkIfObjIsDragged(trashCanLid, selectedObjects, lasso_state, isMouseDragging)
    trashCanLid:update(dt, isLidBeingDragged, allObjects)

    if isLidOnSprinkler() and not isLidBeingDragged then
        if not sprinklerCovered then
            -- gradually decrease sprinkler
            sprinkler.currentRadius = sprinkler.currentRadius - 60 * dt -- rate of 60% ish.. i think
            if sprinkler.currentRadius <= 0 then
                sprinkler.currentRadius = 0
                sprinkler.active = false
                sprinklerCovered = true
            end
        end
    else
        -- reset sprinkler if we move the lid
        if not isLidBeingDragged then
            sprinkler.active = true
            sprinkler.currentRadius = sprinklerBlockRadius
            sprinklerCovered = false
        end
    end

    -- chcheck water line collision and push player away
    if sprinkler.active and sprinkler.currentRadius > 0 and checkDist(player, sprinkler, sprinkler.currentRadius) then
        local sprinklerCenterX = sprinkler.x + sprinkler.width/2
        player.x = sprinklerCenterX - sprinkler.currentRadius - player.width / 2
    end
        
    -- limit player movemment if sprinker not solved
    if not sprinklerCovered and player.x > PROGRESS_GATE_X2 - player.width then
        player.x = PROGRESS_GATE_X2 - player.width
    end
end


function Level1.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 2, 300)

    -- draw objects
    if not dogPoopCleaned then
        dogPoop:draw()

        -- show poop radius (for debug)
        love.graphics.setColor(1, 0, 0, 0.1)
        local poopCenterX = dogPoop.x + dogPoop.width/2
        local poopCenterY = dogPoop.y + dogPoop.height/2
        love.graphics.circle("fill", poopCenterX, poopCenterY, poopThreshold)
    end

    -- draw trash can
    love.graphics.setColor(trashCan.color[1], trashCan.color[2], trashCan.color[3], 1)
    love.graphics.rectangle("fill", trashCan.x, trashCan.y, trashCan.width, trashCan.height)

    -- this is invis wall (also for debug)
    if not dogPoopCleaned then
        love.graphics.setColor(1, 0, 0, 0.3)
        love.graphics.rectangle("fill", PROGRESS_GATE_X, 0, 10, WINDOWHEIGHT - 300)
    end

    -- draw trashCan lid
    trashCanLid:draw()

    -- draw sprinkler
    love.graphics.setColor(sprinkler.color[1], sprinkler.color[2], sprinkler.color[3])
    love.graphics.rectangle("fill", sprinkler.x, sprinkler.y, sprinkler.width, sprinkler.height)

    -- draw simple spray
    if sprinkler.active and sprinkler.currentRadius > 0.5 then
        love.graphics.setColor(0.3, 0.6, 1, 0.3)
        local sprinklerCenterX = sprinkler.x + sprinkler.width/2
        local sprinklerCenterY = sprinkler.y + sprinkler.height/2

        -- draw spray radius
        love.graphics.circle("fill", sprinklerCenterX, sprinklerCenterY, sprinklerBlockRadius)
    end

end

function Level1.getObjects()
    local objects = {}

    -- always include available selectable objects
    if not dogPoopCleaned then
        table.insert(objects, dogPoop)
    end

    table.insert(objects, trashCanLid)

    return objects
end

function Level1.getAllObjects()
    local objects = {}

    -- include selectables + non-selectables
    if not dogPoopCleaned then
        table.insert(objects, dogPoop)
    end

    table.insert(objects, trashCanLid)

    trashCan.isSelectable = false
    sprinkler.isSelectable = false
    table.insert(objects, trashCan)
    table.insert(objects, sprinkler)

    return objects
end

function Level1.isPuzzleSolved()
    return dogPoopCleaned and sprinkerCovered
end

function Level1.getProgressGateX()
    if not dogPoopCleaned then
        return PROGRESS_GATE_X
    elseif not sprinkerCovered then
        return PROGRESS_GATE_X2
    else
        return math.huge
    end
end