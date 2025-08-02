require "assets/tools/bouncyBalls"
require "assets/tools/npc"

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
local sprinklerBlockRadius = 80

-- third puzzle stuff
local person, dog
local bouncyBalls = {}
local PROGRESS_GATE_X3 = 1600
local ballsDistracted = false

function Level1.init(world)
    -- create ground collider
    ground = world:newRectangleCollider(0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)
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

    -- create some balls
    table.insert(bouncyBalls, BouncyBall(1000, WINDOWHEIGHT - 300, 15, {1, 0, 0}, world))
    table.insert(bouncyBalls, BouncyBall(1000, WINDOWHEIGHT - 300, 15, {0, 1, 0}, world))
    table.insert(bouncyBalls, BouncyBall(1000, WINDOWHEIGHT - 300, 15, {0, 0, 1}, world))

    -- create person
    person = NPC(1400, WINDOWHEIGHT - 380, 40, 80, {0.8, 0.6, 0.4}, 0) -- stationary for now...

    -- create dog
    dog = NPC(1350, WINDOWHEIGHT - 340, 50, 40, {0.6, 0.4, 0.2}, 100) -- moves a bit back and forth

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

    -- update the poop!
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

    -- check water line collision and push player away
    if sprinkler.active and sprinkler.currentRadius > 0 and checkDist(player, sprinkler, sprinkler.currentRadius) then
        local sprinklerCenterX = sprinkler.x + sprinkler.width/2
        player.x = sprinklerCenterX - sprinkler.currentRadius - player.width / 2
    end
        
    -- limit player movemment if sprinker not solved
    if not sprinklerCovered and player.x > PROGRESS_GATE_X2 - player.width then
        player.x = PROGRESS_GATE_X2 - player.width
    end

    -- third puzzle --
    for _, ball in ipairs(bouncyBalls) do
        local isBallBeingDragged = checkIfObjIsDragged(ball, selectedObjects, lasso_state, isMouseDragging)
        ball:update(dt, isBallBeingDragged, allObjects)
    end

    person:update(dt)
    dog:update(dt)

    -- check if dog is distracted by balls
    local dogDistracted, closestBall = dog:isNearBalls(bouncyBalls, 50)
    if dogDistracted and not ballsDistracted then
        ballsDistracted = true

        -- move dog and person to the left
        dog.isChasing = true
        person.isFollowing = true
    end

    if dog.isChasing then
        dog.x = dog.x - 50 * dt
        person.x = person.x - 40 * dt
    end

    -- block player if the dog is in their way
    if not ballsDistracted then
        local dogBlockRadius = 60
        if checkDist(player, dog, dogBlockRadius) then
            local dogCenterX = dog.x + dog.width/2
            player.x = dogCenterX - dogBlockRadius - player.width / 2
        end
    end
end


function Level1.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)

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

    person:draw()
    dog:draw()

    -- draw balls
    for _, ball in ipairs(bouncyBalls) do
        ball:draw()
    end

    -- debug for doggie
    if not ballsDistracted then
        love.graphics.setColor(1, 0, 0, 0.1)
        love.graphics.circle("fill", dog.x + dog.width/2, dog.y + dog.height/2, 60)
    end

end

function Level1.getObjects()
    local objects = {}

    -- always include available selectable objects
    if not dogPoopCleaned then
        table.insert(objects, dogPoop)
    end

    table.insert(objects, trashCanLid)

    for _, ball in ipairs(bouncyBalls) do
        table.insert(objects, ball)
    end

    return objects
end

function Level1.getAllObjects()
    local objects = {}

    -- include selectables + non-selectables
    if not dogPoopCleaned then
        table.insert(objects, dogPoop)
    end

    table.insert(objects, trashCanLid)

    for _, ball in ipairs(bouncyBalls) do
        table.insert(objects, ball)
    end

    trashCan.isSelectable = false
    sprinkler.isSelectable = false
    person.isSelectable = false
    dog.isSelectable = false
    table.insert(objects, trashCan)
    table.insert(objects, sprinkler)
    table.insert(objects, person)
    table.insert(objects, dog)

    return objects
end

function Level1.isPuzzleSolved()
    return dogPoopCleaned and sprinklerCovered and ballsDistracted
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