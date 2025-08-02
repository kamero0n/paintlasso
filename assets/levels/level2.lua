require "assets/tools/npc"

Level2 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- first puzzle stuff
local employee, shelf
local shelfStacked = false
local employeeBlockRadius = 50
local items = {}
local targetZones = {}
local itemsStocked = 0
local totalItems = 3

function Level2.init(world)
    -- create ground collider
    ground = world:newRectangleCollider(0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)
    ground:setType('static')

    -- create employee
    employee = NPC(400, WINDOWHEIGHT - 380, 40, 80, {0.2, 0.4, 0.8}, 0)

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

function Level2.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)
    -- update employee
    employee:update(dt)

    -- block player with employee until items are stocked
    if not shelfStacked and checkDist(player, employee, employeeBlockRadius) then
        local employeeCenterX = employee.x + employee.width/2
        player.x = employeeCenterX - employeeBlockRadius - player.width / 2
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

    -- draw employee
    employee:draw()

    -- draw target zones for items
    for _, zone in ipairs(targetZones) do
        love.graphics.setColor(zone.color[1], zone.color[2], zone.color[3], zone.filled and 0.1 or 0.3)
        love.graphics.rectangle("fill", zone.x, zone.y, zone.width, zone.height)
    end

    -- draw items
    for _, item in ipairs(items) do
        item:draw()
    end



end


function Level2.getObjects()
    local objects = {}

    for _, item in ipairs(items) do
        if not item.itemsStocked then
            table.insert(objects, item)
        end
    end

    return objects
end

function Level2.getAllObjects()
    local objects = {}

    for _, item in ipairs(items) do
        if not item.itemsStocked then
            table.insert(objects, item)
        end
    end

    employee.isSelectable = false
    table.insert(objects, employee)

    return objects
end

function Level2.isLevelSolved()
end
