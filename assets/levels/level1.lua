require "assets/tools/bouncyBalls"
require "assets/tools/npc"
require "assets/tools/utils"

Level1 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- dialogue time <:)
local dialogueStates
local endDialogue = false
local finalDialogueShown = false

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
local ballsDistracted = false

-- fourth puzzle stuff
local playerDog, cat, treeBase, treeBranch, box, kiddieSlide
local catTrapped = false

function Level1.init(world)
    dialogueStates = Utils.Dialogue.initStates(Utils.Dialogue.Level1)

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
    table.insert(bouncyBalls, BouncyBall(1015, WINDOWHEIGHT - 300, 15, {1, 0, 0}, world))
    table.insert(bouncyBalls, BouncyBall(1030, WINDOWHEIGHT - 300, 15, {0, 1, 0}, world))
    table.insert(bouncyBalls, BouncyBall(1045, WINDOWHEIGHT - 300, 15, {0, 0, 1}, world))

    -- create person
    person = NPC(1400, WINDOWHEIGHT - 380, 40, 80, {0.8, 0.6, 0.4}, 0) -- stationary for now...

    -- create dog
    dog = NPC(1350, WINDOWHEIGHT - 340, 50, 40, {0.6, 0.4, 0.2}, 100) -- moves a bit back and forth

    -- create tree base
    treeBase = {
        x = 1800,
        y = WINDOWHEIGHT - 600,
        width = 80,
        height = 300,
        color = {0.4, 0.2, 0.1}
    }
    -- tree branch
    treeBranch = {
        x = 1720,
        y = WINDOWHEIGHT - 500,
        width = 80,
        height = 20,
        color = {0.4, 0.2, 0.1}
    }

    -- create dog
    playerDog = {
        x = 1750,
        y = WINDOWHEIGHT - 530,
        width = 30,
        height = 30,
        color = {0.8, 0.6, 0.2},
        isRescued = false
    }

    -- catto
    cat = NPC(1750, WINDOWHEIGHT - 330, 35, 30, {0.3, 0.3, 0.3}, 80)

    -- create box
    box = SelectableObject(1650, WINDOWHEIGHT - 350, 50, 50, {0.6, 0.4, 0.2}, world)

    -- create kiddieSlide
    kiddieSlide = SelectableObject(1550, WINDOWHEIGHT - 370, 50, 70, {1, 0.2, 0.2}, world)
end

local function isLidOnSprinkler()
    local lidCenterX = trashCanLid.x + trashCanLid.width/2
    local sprinklerCenterX = sprinkler.x + sprinkler.width /2
    local horizDist = math.abs(lidCenterX - sprinklerCenterX)

    local verticalDist = math.abs((trashCanLid.y + trashCanLid.height) - sprinkler.y)

    return horizDist <= sprinkler.width / 2 + 10 and verticalDist <= 5
end

local function isCatTrapped()
    -- check if box is on top of cat
    local catCenterX = cat.x + cat.width/2
    local boxCenterX = box.x + box.width/2
    local horizDist = math.abs(catCenterX - boxCenterX)

    local horizontalOverlap = horizDist <= (cat.width + box.width)/2

    local boxBottom = box.y + box.height
    local catBottom = cat.y + cat.height
    local atSameLevel = math.abs(boxBottom - catBottom) <= 10

    return horizontalOverlap and atSameLevel
end

local function isSlideInPos()
    -- check if slide is near dog to help it get down
    local branchCenterX = treeBranch.x + treeBranch.width/2
    local slideCenterX = kiddieSlide.x + kiddieSlide.width/2
    local horizDist = math.abs(branchCenterX - slideCenterX)

    local slideTop = kiddieSlide.y
    local branchBot = treeBranch.y + treeBranch.height
    local verticalDist = math.abs(slideTop - branchBot)

    -- also check if scaled enough
    local isScaledUp = kiddieSlide.height >= 100

    return horizDist <= 30 and verticalDist <= 15 and isScaledUp
end

function Level1.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)
    Utils.Dialogue.showOnce(dialogueStates, "opening", Utils.Dialogue.Level1, "You")
    
    -- first puzzle --
    local isPoopBeingDragged = false
    if dogPoop then
        isPoopBeingDragged = Utils.checkIfObjIsDragged(dogPoop, selectedObjects, lasso_state, isMouseDragging)
    end
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

    if not dogPoopCleaned and Utils.checkDist(dogPoop, player, poopThreshold) then 
        Utils.Dialogue.showOnce(dialogueStates, "poopWarning", Utils.Dialogue.Level1, "You")
    else
        -- Reset dialogue state when player moves away
        dialogueStates["poopWarning"] = false
    end

    -- update the poop!
    if not dogPoopCleaned and dogPoop then
        dogPoop:update(dt, isPoopBeingDragged, allObjects)
    end

    -- check if the player is trying to go over the poop
    if not dogPoopCleaned and Utils.checkDist(dogPoop, player, poopThreshold) then
        -- push back player
        local poopCenterX = dogPoop.x + dogPoop.width / 2
        player.x = poopCenterX - poopThreshold - player.width / 2
    end

    -- second puzzle -- 
    -- update trash can lid
    local isLidBeingDragged = Utils.checkIfObjIsDragged(trashCanLid, selectedObjects, lasso_state, isMouseDragging)
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

    -- sprinkler warning
    if sprinkler.active and sprinkler.currentRadius > 0 and Utils.checkDist(player, sprinkler, sprinklerBlockRadius) then
        Utils.Dialogue.showOnce(dialogueStates, "sprinklerWarning", Utils.Dialogue.Level1, "You")
    else
        -- reset state
        dialogueStates["sprinklerWarning"] = false
    end

    -- check water line collision and push player away
    if sprinkler.active and sprinkler.currentRadius > 0 and Utils.checkDist(player, sprinkler, sprinkler.currentRadius) then
        local sprinklerCenterX = sprinkler.x + sprinkler.width/2
        player.x = sprinklerCenterX - sprinkler.currentRadius - player.width / 2
    end
        
    -- limit player movemment if sprinker not solved
    if not sprinklerCovered and player.x > PROGRESS_GATE_X2 - player.width then
        player.x = PROGRESS_GATE_X2 - player.width
    end

    -- third puzzle --
    for _, ball in ipairs(bouncyBalls) do
        local isBallBeingDragged = Utils.checkIfObjIsDragged(ball, selectedObjects, lasso_state, isMouseDragging)
        ball:update(dt, isBallBeingDragged, allObjects)
    end

    person:update(dt)
    dog:update(dt)

    -- check if dog is distracted by balls
    local dogDistracted, closestBall = dog:isNearBalls(bouncyBalls, 100)
    if dogDistracted and not ballsDistracted then
        ballsDistracted = true

        if trashCanLid.body then
            trashCanLid.body:destroy()
            trashCanLid.body = nil
        end

        -- move the balls to the left
        for _, ball in ipairs(bouncyBalls) do
            if ball.body then
                ball.body:applyLinearImpulse(-300, -50)
            end
        end

        -- move dog and person to the left
        dog.isChasing = true
        person.isFollowing = true
    end

    if dog.isChasing then
        dog.x = dog.x - 80 * dt
        person.x = person.x - 80 * dt
    end

    if not ballsDistracted and Utils.checkDist(player, dog, 60) then
        Utils.Dialogue.showOnce(dialogueStates, "ownerWarning", Utils.Dialogue.Level1, "You")
    else
        -- reset dialogue state when player moves away from dog
        dialogueStates["ownerWarning"] = false
    end


    -- block player if the dog is in their way
    if not ballsDistracted then
        local dogBlockRadius = 60
        if Utils.checkDist(player, dog, dogBlockRadius) then
            local dogCenterX = dog.x + dog.width/2
            player.x = dogCenterX - dogBlockRadius - player.width / 2
        end
    end

    -- fourth puzzle --
    local isBoxBeingDragged = Utils.checkIfObjIsDragged(box, selectedObjects, lasso_state, isMouseDragging)
    local isSlideBeingDragged = Utils.checkIfObjIsDragged(kiddieSlide, selectedObjects, lasso_state, isMouseDragging)

    box:update(dt, isBoxBeingDragged, allObjects)
    kiddieSlide:update(dt, isSlideBeingDragged, allObjects)

    -- only update cat if not trapped
    if not catTrapped then
        cat:update(dt)
    end


    if not catTrapped and isCatTrapped() and not isBoxBeingDragged then
       catTrapped = true
       cat.isChasing = false

       -- keep box on the ground
       box.y = WINDOWHEIGHT - 300 - box.height

       box.isMoving = true
       box.moveSpeed = 30
       box.moveDir = 1
       box.startX = box.x
       box.moveRange = 60
    end

    if not playerDog.isRescued and Utils.checkDist(player, playerDog, 400) then
        Utils.Dialogue.showOnce(dialogueStates, "dogInTree", Utils.Dialogue.Level1, "You")
    end

    -- make box move if cat is trapped
    if catTrapped and box.isMoving then
        box.y = WINDOWHEIGHT - 300 - box.height

        box.x = box.x + box.moveSpeed * box.moveDir * dt
        if box.x > box.startX + box.moveRange or box.x < box.startX then
            box.moveDir = box.moveDir * -1
            box.x = math.max(box.startX, math.min(box.startX + box.moveRange, box.x))
        end
    end

    -- check if dog can be rescued
    if catTrapped and isSlideInPos() and not playerDog.isRescued then
        playerDog.isRescued = true
        -- move dog down slide
        playerDog.x  = kiddieSlide.x + kiddieSlide.width/2 - playerDog.width/2
        playerDog.y = WINDOWHEIGHT - 300 - playerDog.height
    end

    if not catTrapped then
         -- block player from getting past cat
        if Utils.checkDist(player, cat, 60) then
            local catCenterX = cat.x + cat.width / 2
            player.x = catCenterX - 60 - player.width / 2
        end

        -- push slide away 
        if Utils.checkDist(kiddieSlide, cat, 80) and not isSlideBeingDragged then
            local catCenterX = cat.x + cat.width/2
            local slideCenterX = kiddieSlide.x + kiddieSlide.width/2
            if slideCenterX > catCenterX then 
                kiddieSlide.x = catCenterX + 80
            else
                kiddieSlide.x = catCenterX - 80 - kiddieSlide.width
            end
        end
    end

    if dogPoopCleaned and sprinklerCovered and ballsDistracted and playerDog.isRescued and not endDialogue then
        if Utils.Dialogue.showOnce(dialogueStates, "fin", Utils.Dialogue.Level1, "You") then
            finalDialogueShown = true
        end
        endDialogue = true
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

        -- draw spray radius / debug
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

    -- draw tree
    love.graphics.setColor(treeBase.color[1], treeBase.color[2], treeBase.color[3], 1)
    love.graphics.rectangle("fill", treeBase.x, treeBase.y, treeBase.width, treeBase.height)

    -- draw branch
    love.graphics.setColor(treeBranch.color[1], treeBranch.color[2], treeBranch.color[3], 1)
    love.graphics.rectangle("fill", treeBranch.x, treeBranch.y, treeBranch.width, treeBranch.height)

    if not catTrapped then
        cat:draw()
    end
    box:draw()
    
    kiddieSlide:draw()
    -- draw dog
    love.graphics.setColor(playerDog.color[1], playerDog.color[2], playerDog.color[3], 1)
    love.graphics.rectangle("fill", playerDog.x, playerDog.y, playerDog.width, playerDog.height)
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

    table.insert(objects, box)
    table.insert(objects, kiddieSlide)

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
    
    table.insert(objects, box)
    table.insert(objects, kiddieSlide)

    trashCan.isSelectable = false
    sprinkler.isSelectable = false
    person.isSelectable = false
    dog.isSelectable = false
    treeBase.isSelectable = false
    playerDog.isSelectable = false
    cat.isSelectable = false
    table.insert(objects, trashCan)
    table.insert(objects, sprinkler)
    table.insert(objects, person)
    table.insert(objects, dog)
    table.insert(objects, treeBase)
    table.insert(objects, playerDog)
    table.insert(objects, cat)

    return objects
end

function Level1.isLevelSolved()
    local allPuzzlesSolved = dogPoopCleaned and sprinklerCovered and ballsDistracted and playerDog.isRescued
    local dialogueComplete = finalDialogueShown and (dialogManager:getActiveDialog() == nil)
    
    return allPuzzlesSolved and dialogueComplete
end
