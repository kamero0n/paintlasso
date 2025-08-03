require "assets/tools/npc"
require "assets/tools/utils"

Level2 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- dialog time
local dialogueStates
local endDialogue = false
local finalDialogueShown = false

-- first puzzle stuff
local employee
local shelfStacked = false
local employeeBlockRadius = 50
local items = {}
local targetZones = {}
local itemsStocked = 0
local totalItems = 3

-- second puzzle stuff
local child, mom
local cerealBoxes = {}
local numCerealBoxes = 5
local childVisHeight = 100
local childBlockRadius = 50
local childFound = false
local momAppeared = false

-- third puzzle stuff
local fatGuy, fridge
local fridgeDrinks = {}
local numDrinks = 5
local fatGuyBlockRadius = 50
local fatGuyMoved = false
local correctDrinkType = 3
local carriedDrink = nil

function Level2.init(world)
    dialogueStates = Utils.Dialogue.initStates(Utils.Dialogue.Level2)
    
    -- create ground collider
    ground = world:newRectangleCollider(0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)
    ground:setType('static')

    -- create employee
    employee = NPC(400, WINDOWHEIGHT - 380, 40, 80, {0.2, 0.4, 0.8}, 40)

    -- items to stock
    table.insert(items, SelectableObject(150, WINDOWHEIGHT - 330, 30, 30, {0.8, 0.2, 0.2}, world))
    table.insert(items, SelectableObject(200, WINDOWHEIGHT - 335, 25, 35, {0.2, 0.8, 0.2}, world))
    table.insert(items, SelectableObject(250, WINDOWHEIGHT - 340, 35, 40, {0.2, 0.2, 0.8}, world))

    -- zone for item placement
    table.insert(targetZones, {
        x = 365,
        y = WINDOWHEIGHT - 460,
        width = 30,
        height = 30,
        color = {0.8, 0.2, 0.2},
        itemType = 1,
        filled = false
    })
    table.insert(targetZones, {
        x = 530,
        y = WINDOWHEIGHT - 415,
        width = 25,
        height = 35,
        color = {0.2, 0.8, 0.2},
        itemType = 2,
        filled = false
    })
    table.insert(targetZones, {
        x = 460,
        y = WINDOWHEIGHT - 370,
        width = 35,
        height = 40,
        color = {0.2, 0.2, 0.8},
        itemType = 3,
        filled = false
    })

    -- items should not be stocked init
    for i, item in ipairs(items) do
        item.itemType = i
        item.isStocked = false
    end

    -- add the crying child
    child = NPC(1000, WINDOWHEIGHT - 350, 40, 50, {0.3, 0.4, 0.9}, 5)
    child.velocityY = 0
    child.gravity = 800
    child.groundY = WINDOWHEIGHT - 300
    child.isGrounded = false

    -- add cereal boxes
    for i = 1, numCerealBoxes do
        local box = SelectableObject(
            880 + (i * 60),
            WINDOWHEIGHT - 460,
            50,
            30,
            {0.9, 0.7, 0.3},
            world
        )
        box.isCerealBox = true
        table.insert(cerealBoxes, box)
    end

    -- mom npc
    mom = NPC(1800, WINDOWHEIGHT - 380, 40, 80, {0.8, 0.3, 0.6}, 0)
    mom.isVisible = false
    mom.speed = 200 -- RUN to the child

    -- fat guy 
    fatGuy = NPC(1600, WINDOWHEIGHT - 380, 60, 80, {0.4, 0.2, 0.7}, 0)

    -- fridge
    fridge = {
        x = 1700,
        y = WINDOWHEIGHT - 430,
        width = 150,
        height = 130
    }

    -- fridge drinks
    local drinkColors = {
        {0.8, 0.2, 0.2},
        {0.2, 0.8, 0.2},
        {0.2, 0.2, 0.8},
        {1, 1, 1},
        {0.6, 0.3, 0.1}
    }

    for i = 1, numDrinks do 
        local drink = SelectableObject(
            fridge.x + 10 + ((i - 1) * 25),
            fridge.y + 10,
            20,
            35,
            drinkColors[i],
            world
        )

        drink.drinkType = i
        drink.isFridgeDrink = true
        table.insert(fridgeDrinks, drink)
    end
end

-- check if item is placed in the right zone
local function checkItemInZone(item, zone)
    local itemCenterX = item.x + item.width/2
    local itemCenterY = item.y + item.height/2

    -- check if item center is w/in zone bounds
    local inHoriz = itemCenterX >= zone.x and itemCenterX <= zone.x + zone.width
    local inVert = itemCenterY >= zone.y and itemCenterY <= zone.y + zone.height

    return inHoriz and inVert
end

-- check if child is standing on box
local function getChildSupportingBox()
    local childBottom = child.y + child.height
    local childLeft = child.x
    local childRight = child.x + child.width
    local childCenterX = child.x + child.width/2

    local highestSupportingBox = nil
    local highestY = WINDOWHEIGHT

    -- check all cereal boxes
    for _, box in ipairs(cerealBoxes) do
        local boxTop = box.y
        local boxLeft = box.x
        local boxRight = box.x + box.width

        -- check if child overlaps horizontally with box
        local horizOverlap = (childRight > boxLeft and childLeft < boxRight)

        if horizOverlap and boxTop < highestY then
            -- this box could support child but check if it's the tallest one in the stack
            if boxTop < childBottom + 5 then
                highestY = boxTop
                highestSupportingBox = box
            end
        end
    end

    return highestSupportingBox, highestY
end

-- handle physics for child puzzle
local function updateChildPhysics(dt, allObjects)
    local supportingBox, supportY = getChildSupportingBox()

    if supportingBox then
        -- child supported by box
        child.y = supportY - child.height
        child.velocityY = 0
        child.isGrounded = true

        -- keep child on box if its moved
        local boxCenterX = supportingBox.x + supportingBox.width / 2
        local childCenterX = child.x + child.width / 2

        -- adjust
        local maxAdjust = 50 * dt
        local diff = boxCenterX - childCenterX
        if math.abs(diff) > 5 then
            if diff > 0 then
                child.x =  child.x + math.min(maxAdjust, diff)
            else
                child.x = child.x + math.max(-maxAdjust, diff)
            end
        end
    else
        -- child not supported
        child.isGrounded = false
        child.velocityY = child.velocityY + child.gravity * dt
        child.y = child.y + child.velocityY * dt

        -- check if hit ground
        if child.y + child.height >= child.groundY then
            child.y = child.groundY - child.height
            child.velocityY = 0
            child.isGrounded = true
        end
    end
end

-- check if all cereal boxes are stacked under kid
local function checkAllBoxesUnderChild()
    local childCenterX = child.x + child.width/2
    local childBottom = child.y + child.height

    local boxesUnderChild = {}
    for _, box in ipairs(cerealBoxes) do
        local boxLeft = box.x
        local boxRight = box.x + box.width

        local horizOverlap = (childCenterX >= boxLeft - 10 and childCenterX <= boxRight + 10)

        if horizOverlap then
            table.insert(boxesUnderChild, box)
        end
    end

    if #boxesUnderChild < numCerealBoxes then
        return false
    end

   -- sort boxes by Y pos
   table.sort(boxesUnderChild, function(a, b) return a.y < b.y end)

   -- check if boxes form continuous stack
   local expectedY = childBottom
   local tolerance = 15

   for i, box in ipairs(boxesUnderChild) do
        local boxTop = box.y
        local boxBottom = box.y + box.height

        -- check if box pos correctly
        if i == 1 then
            if boxTop > expectedY + tolerance then
                return false
            end
        else
            local prevBox = boxesUnderChild[i-1]
            local prevBoxBottom = prevBox.y + prevBox.height

            if boxTop > prevBoxBottom + tolerance then
                return false
            end
        end

        expectedY = boxBottom
   end

   return true
end

-- check if player is trying to give drink to fat guy
local function checkDrinkGivenToFatGuy(drink)
    if not drink.isFridgeDrink then
        return false
    end

    -- check if drink is close to fat guy
    local drinkCenterX = drink.x + drink.width/2
    local drinkCenterY = drink.y + drink.height /2 
    local fatGuyCenterX = fatGuy.x + fatGuy.width/2
    local fatGuyCenterY = fatGuy.y + fatGuy.height/2

    local dist = math.sqrt((drinkCenterX - fatGuyCenterX)^2 + (drinkCenterY - fatGuyCenterY)^2)

    return dist < 30
end

function Level2.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)
    -- opening dialogue
    Utils.Dialogue.showOnce(dialogueStates, "opening", Utils.Dialogue.Level2, "You")

    -- first puzzle --
    -- update employee
    employee:update(dt)

    -- block player with employee until items are stocked
    if not shelfStacked and Utils.checkDist(player, employee, employeeBlockRadius) then
        if Utils.Dialogue.showOnce(dialogueStates, "employee", Utils.Dialogue.Level2, "Employee") then
            --  flag to show the response after this dialogue finishes
            dialogueStates["employeeResponsePending"] = true
        end

        local employeeCenterX = employee.x + employee.width/2
        player.x = employeeCenterX - employeeBlockRadius - player.width / 2
    end

    if dialogueStates["employeeResponsePending"] and dialogManager:getActiveDialog() == nil then
        dialogueStates["employeeResponsePending"] = false
        dialogManager:show({text = Utils.Dialogue.Level2.afterEmployee, title = "You"})
    end

    itemsStocked = 0

    -- check stocking and if placed correctly
    for i, item in ipairs(items) do
        if not item.isStocked then
            local isItemBeingDragged = Utils.checkIfObjIsDragged(item, selectedObjects, lasso_state, isMouseDragging)
            item:update(dt, isItemBeingDragged, allObjects)

            -- check if item is in correct zone and not being dragged
            if not isItemBeingDragged then
                for j, zone in ipairs(targetZones) do
                    if zone.itemType == item.itemType and checkItemInZone(item, zone) then
                        -- snap item to zone center
                        item.x = zone.x + zone.width / 2 - item.width/2
                        item.y = zone.y + zone.height / 2 - item.height/2
                        item.isStocked = true
                        zone.filled = true

                        -- destroy physics body
                        if item.body then
                            item.body:destroy()
                            item.body = nil
                        end
                        break
                    end
                end
            end
        end

        if item.isStocked then
            itemsStocked = itemsStocked + 1
        end
    end

    -- check if all items are stocked
    if itemsStocked >= totalItems and not shelfStacked then
        shelfStacked = true
    end

    -- second puzzle --
    if shelfStacked then
        child:update(dt)

        -- Kid crying dialogue when near child or trying to leave
        local nearChild = Utils.checkDist(player, child, childBlockRadius)
        local tryingToLeave = not childFound and player.x + player.width > child.x + child.width + childBlockRadius
        
        if not childFound and (nearChild or tryingToLeave) then
            if Utils.Dialogue.showOnce(dialogueStates, "kidCrying", Utils.Dialogue.Level2, "Kid") then
                -- flag to show response after dialogue finishes
                dialogueStates["kidResponsePending"] = true
            end
        end

        if dialogueStates["kidResponsePending"] and dialogManager:getActiveDialog() == nil then
            dialogueStates["kidResponsePending"] = false
            dialogManager:show({text = Utils.Dialogue.Level2.afterKidCrying, title = "You"})
        end

        if not childFound and (nearChild or tryingToLeave) then 
            Utils.Dialogue.showOnce(dialogueStates, "kidCrying", Utils.Dialogue.Level2, "Kid")
        else
            dialogueStates["kidCrying"] = false
        end

        -- update cereal boxes
        for _, box in ipairs(cerealBoxes) do
            local isBoxBeingDragged = Utils.checkIfObjIsDragged(box, selectedObjects, lasso_state, isMouseDragging)
            box:update(dt, isBoxBeingDragged, allObjects)
        end

        -- update child physics to handle being pushed up by boxes
        updateChildPhysics(dt, allObjects)

        -- check if boxes are under child
        if not childFound and checkAllBoxesUnderChild() then
            childFound = true
            momAppeared = true
            mom.isVisible = true
        end

        -- block player if child is not found by mom 
        if not childFound then
            local childRightSide = child.x + child.width
            local barrierX = childRightSide + childBlockRadius
            
            if player.x + player.width > barrierX then
                player.x = barrierX - player.width
            end
        end

        -- mom dialogue when appear on screen
        if momAppeared and mom.isVisible and mom.x < 1700  then
            Utils.Dialogue.showOnce(dialogueStates, "momFindsKid", Utils.Dialogue.Level2, "Mom")
        end

        -- mom walks in from the right
        if momAppeared and mom.isVisible then
            if mom.x > child.x + 100 then
                mom.x = mom.x - mom.speed * dt
            end
        end
       
    end

    -- third puzzle
    if childFound then
        -- fat guy meet when close
        if Utils.checkDist(player, fatGuy, 100) then
            Utils.Dialogue.showOnce(dialogueStates, "meetFatGuy", Utils.Dialogue.Level2, "You")
        end

        if not fatGuyMoved and Utils.checkDist(player, fatGuy, fatGuyBlockRadius) then
            Utils.Dialogue.showOnce(dialogueStates, "fatGuyClues", Utils.Dialogue.Level2, "Random Guy")
        else
            -- reset
            dialogueStates["fatGuyClues"] = false
        end

        -- update drinks
        for i, drink in ipairs(fridgeDrinks) do
            local isDrinkBeingDragged = Utils.checkIfObjIsDragged(drink, selectedObjects, lasso_state, isMouseDragging)
            drink:update(dt, isDrinkBeingDragged, allObjects)

            -- check if drink is give to fat guy and not being dragged 
            if not isDrinkBeingDragged and checkDrinkGivenToFatGuy(drink) then
                if drink.drinkType == correctDrinkType then
                    -- correct drink! 
                    if not fatGuyMoved then
                        fatGuyMoved = true
                        
                        -- move fat guy to left
                        fatGuy.speed = 60
                        fatGuy.dir = -1
                        fatGuy.isMoving = true

                        carriedDrink = {
                            width = drink.width,
                            height = drink.height,
                            color = drink.color,
                            drinkType = drink.drinkType
                        }

                        -- remove drink
                        if drink.body then
                            drink.body:destroy()
                            drink.body = nil
                        end

                        drink.isConsumed = true
                    end
                else
                    -- give dialogue here if handed wrong drinnk
                end
            end
        end
    
        if fatGuyMoved then
            fatGuy.x = fatGuy.x - fatGuy.speed * dt
        end

        -- block player 
        if not fatGuyMoved and Utils.checkDist(player, fatGuy, fatGuyBlockRadius) then
             local fatGuyCenterX = fatGuy.x + fatGuy.width/2
            player.x = fatGuyCenterX - fatGuyBlockRadius - player.width / 2
        end
    end
    
    -- final dialogue
    if shelfStacked and childFound and momAppeared and fatGuyMoved and not endDialogue then
        if Utils.Dialogue.showOnce(dialogueStates, "fin", Utils.Dialogue.Level2, "You") then
            finalDialogueShown = true
        end
        endDialogue = true
    end
   
end

function Level2.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)

    -- create shelves
    love.graphics.setColor(0.6, 0.4, 0.2, 1)
    love.graphics.rectangle("fill", 360, WINDOWHEIGHT - 430, 200, 20)
    love.graphics.rectangle("fill", 360, WINDOWHEIGHT - 380, 200, 20)
    love.graphics.rectangle("fill", 360, WINDOWHEIGHT - 330, 200, 20)

    -- draw target zones for items
    for _, zone in ipairs(targetZones) do
        love.graphics.setColor(zone.color[1], zone.color[2], zone.color[3], zone.filled and 0.1 or 0.3)
        love.graphics.rectangle("fill", zone.x, zone.y, zone.width, zone.height)
    end

    -- draw items
    for _, item in ipairs(items) do
        item:draw()
    end

    -- draw employee
    employee:draw()

    -- create MORE shelves
    love.graphics.setColor(0.6, 0.4, 0.2, 1)
    love.graphics.rectangle("fill", 880, WINDOWHEIGHT - 430, 300, 20)
    love.graphics.rectangle("fill", 880, WINDOWHEIGHT - 380, 300, 20)
    love.graphics.rectangle("fill", 880, WINDOWHEIGHT - 330, 300, 20)

    -- draw cereal boxes
    if shelfStacked then
        for _,box in ipairs(cerealBoxes) do 
            box:draw()
        end
    end

    -- draw child
    child:draw()

    -- draw mom if visible
    if mom.isVisible then
        mom:draw()
    end
    
    -- fat guy
    if fatGuy.x + fatGuy.width > 0 then
        fatGuy:draw()

        -- draw carried drink
        if carriedDrink and fatGuyMoved then
            love.graphics.setColor(carriedDrink.color[1], carriedDrink.color[2], carriedDrink.color[3], 1)
            local drinkX = fatGuy.x + fatGuy.width - carriedDrink.width - 5
            local drinkY = fatGuy.y + 10
            love.graphics.rectangle("fill", drinkX, drinkY, carriedDrink.width, carriedDrink.height)
        end
    end

    -- draw fridge
    if childFound then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.rectangle("fill", fridge.x, fridge.y, fridge.width, fridge.height)
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("line", fridge.x, fridge.y, fridge.width, fridge.height)

        -- draw fridge shelves
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.rectangle("fill", fridge.x + 5, fridge.y + 20, fridge.width - 10, 3)
        love.graphics.rectangle("fill", fridge.x + 5, fridge.y + 50, fridge.width - 10, 3)

        
        -- draw da drinks
        for _, drink in ipairs(fridgeDrinks) do
            if not drink.isConsumed then
                drink:draw()
            end
        end
    end

end

function Level2.getObjects()
    local objects = {}

    for _, item in ipairs(items) do
        if not item.isStocked then
            table.insert(objects, item)
        end
    end

    if shelfStacked then
        for _, box in ipairs(cerealBoxes) do
            table.insert(objects, box)
        end
    end
    
    if childFound then
        for _, drink in ipairs(fridgeDrinks) do
            if not drink.isConsumed then
                table.insert(objects, drink)
            end
        end
    end
    return objects
end

function Level2.getAllObjects()
    local objects = {}

    for _, item in ipairs(items) do
        if not item.isStocked then
            table.insert(objects, item)
        end
    end

    if shelfStacked then
        for _, box in ipairs(cerealBoxes) do
            table.insert(objects, box)
        end
    end

    if childFound then
        for _, drink in ipairs(fridgeDrinks) do
            if not drink.isConsumed then
                table.insert(objects, drink)
            end
        end
    end

    employee.isSelectable = false
    child.isSelectable = false
    table.insert(objects, employee)
    table.insert(objects, child)

    if mom.isVisible then
        mom.isSelectable = false
        table.insert(objects, mom)
    end

    if childFound then
        fatGuy.isSelectable = false
        table.insert(objects, fatGuy)
    end

    return objects
end

function Level2.isLevelSolved()
    local allPuzzlesSolved = shelfStacked and childFound and momAppeared and fatGuyMoved
    local dialogueComplete = finalDialogueShown and (dialogManager:getActiveDialog() == nil)
    
    return allPuzzlesSolved and dialogueComplete
end
