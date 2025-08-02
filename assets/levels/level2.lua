require "assets/tools/npc"
require "assets/tools/utils"

Level2 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- first puzzle stuff
local employee
local shelfStacked = false
local employeeBlockRadius = 50
local items = {}
local targetZones = {}
local itemsStocked = 0
local totalItems = 3

-- second puzzle stuff
local child, cerealBox
local numCerealBoxes

function Level2.init(world)
    -- create ground collider
    ground = world:newRectangleCollider(0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)
    ground:setType('static')

    -- create employee
    employee = NPC(400, WINDOWHEIGHT - 380, 40, 80, {0.2, 0.4, 0.8}, 30)

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
    

end


local function checkItemInZone(item, zone)
    local itemCenterX = item.x + item.width/2
    local itemCenterY = item.y + item.height/2

    -- check if item center is w/in zone bounds
    local inHoriz = itemCenterX >= zone.x and itemCenterX <= zone.x + zone.width
    local inVert = itemCenterY >= zone.y and itemCenterY <= zone.y + zone.height

    return inHoriz and inVert
end

function Level2.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)
    -- update employee
    employee:update(dt)

    -- block player with employee until items are stocked
    if not shelfStacked and Utils.checkDist(player, employee, employeeBlockRadius) then
        local employeeCenterX = employee.x + employee.width/2
        player.x = employeeCenterX - employeeBlockRadius - player.width / 2
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
end


function Level2.getObjects()
    local objects = {}

    for _, item in ipairs(items) do
        if not item.isStocked then
            table.insert(objects, item)
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

    employee.isSelectable = false
    table.insert(objects, employee)

    return objects
end

function Level2.isLevelSolved()
    return shelfStacked
end
