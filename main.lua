require "assets/tools/lassoObjects"
require "assets/levels/testLevel"
require "assets/levels/level1"
anim8 = require 'assets/libraries/anim8'
wf = require "assets/libraries/windfield"

local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- check if mouse is being dragged
local isMouseDragging = false

-- positions for lasso loop
local firstCorner, secondCorner

-- scale start pos
local scaleStartPos = {x = 0, y = 0}

-- offset values for selected object vs mouse
local offsetX, offsetY

-- check the lasso tool state
-- are we "selecting", "dragging", or "scaling"
local lasso_state = "selecting"

local selectedObjects = {} -- store selected objects
local groupOffsets = {} -- store offset for selected objects
local allObjects = {}

-- CAMERA
local camera = {
    x = 0,
    y = 0
}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    world = wf.newWorld(0, 800) -- gravity down
    world:setGravity(0, 800)

    firstCorner = {
        x = 0,
        y = 0
    }

    secondCorner = {
        x = 0,
        y = 0
    }

    -- create canvas
    gameCanvas = love.graphics.newCanvas(WINDOWWIDTH, WINDOWHEIGHT)

    -- player
    playerVars = {
        x = 200,
        y = WINDOWHEIGHT - 350,
        width = 30, 
        height = 50,
        speed = 400
    }

    player = world:newRectangleCollider(playerVars.x, playerVars.y, playerVars.width, playerVars.height)
    player:setType('dynamic')
    player.x = playerVars.x
    player.y = playerVars.y
    player.width = playerVars.width
    player.height = playerVars.height
    player.speed = playerVars.speed

    --cursor properties
    cursor = {}
        cursor.x = 0
        cursor.y = 0
        cursor.sparkle = love.graphics.newImage('assets/art/animations/cursorSparklesB.png')
        cursor.grid = anim8.newGrid(32,32, cursor.sparkle:getWidth(), cursor.sparkle:getHeight())
        cursor.animationPlay = false
        cursor.animations = {}
            cursor.animations.leftClick = anim8.newAnimation(cursor.grid('1-4', 1), 0.2)
    cursor.x, cursor.y =  love.mouse.getPosition()

    Level1.init(world)

    for i, obj in ipairs(Level1.getObjects()) do
        table.insert(allObjects, obj)
    end

end

function updateCamera()
    -- camera follows player
    local targetX = player.x - WINDOWWIDTH / 2
    local targetY = player.y - WINDOWHEIGHT / 2

    -- keep camera w/in bounds
    if targetX < 0 then
        targetX= 0
    end

    if not Level1.isPuzzleSolved() then
        local maxCameraX = Level1.getProgressGateX() - WINDOWWIDTH /2
        if targetX > maxCameraX then
            targetX = maxCameraX
        end
    end

    camera.x = targetX
    camera.y = targetY
end

function love.update(dt)
    -- world update
    world:update(dt)

    -- store player pos
    local prevPos = player.x

    -- player movement
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    end

    -- update player windfield collider
    player:setPosition(player.x + player.width/2, player.y + player.height/2)

    --cursor left click animation
    cursor.animations.leftClick:update(dt)

    -- update camera
    updateCamera()

    -- first level
    Level1.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)

    -- update allObjects list
    allObjects = {}
    for i, obj in ipairs(Level1.getObjects()) do
        table.insert(allObjects, obj)
    end
end

function love.mousepressed(x, y, button, istouch)
    local worldX = x + camera.x
    local worldY = y + camera.y

    if button == 1  then
        --cursor animation play
        cursor.animationPlay = true

        -- check if clicking on any selected object first
        local clickedSelectedObj = nil
        for i, obj in ipairs(selectedObjects) do
            if obj.x <= worldX and worldX <= obj.x + obj.width
                and obj.y <= worldY and worldY <= obj.y + obj.height
            then
                clickedSelectedObj = obj
                
                break
            end
        end

        if clickedSelectedObj then
            local cornerSize = 10
            if worldX >= (clickedSelectedObj.x + clickedSelectedObj.width - cornerSize) and worldX <= (clickedSelectedObj.x + clickedSelectedObj.width)
                and worldY >= clickedSelectedObj.y and worldY <= (clickedSelectedObj.y + cornerSize)
            then
                lasso_state = "scaling"
                isMouseDragging = true
                scaleStartPos.x = worldX
                scaleStartPos.y = worldY
                return
            end


            -- start draggin group
            lasso_state = "dragging"
            isMouseDragging = true

            -- calculate offset for each selected object
            groupOffsets = {}
            for i, obj in ipairs(selectedObjects) do
                groupOffsets[obj] = {
                    x = worldX - obj.x;
                    y = worldY - obj.y;
                }
            end
            return
        else
            -- clicking outside
            for i, obj in ipairs(selectedObjects) do
                obj.isSelected = false
            end
            selectedObjects = {}
            groupOffsets = {}
            lasso_state = "selecting"
        end

        -- start lasso
        isMouseDragging = true
        firstCorner.x = worldX
        firstCorner.y = worldY

        secondCorner.x = worldX
        secondCorner.y = worldY
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    local worldX = x + camera.x
    local worldY = y + camera.y

    --update cursor animation location
    cursor.x = x
    cursor.y = y

    if isMouseDragging and lasso_state == "selecting" then
        secondCorner.x = worldX
        secondCorner.y = worldY
    end

    if isMouseDragging and lasso_state == "dragging" then
        for i, obj in ipairs(selectedObjects) do
            local offset = groupOffsets[obj]
            if offset then
                obj.x = worldX - offset.x
                obj.y = worldY - offset.y
            end
        end
    end

    if isMouseDragging and lasso_state == "scaling" then
        -- calc dist from scale start pos
        local deltaX = worldX - scaleStartPos.x
        local deltaY = worldY - scaleStartPos.y
        local dist = math.sqrt(deltaX^2 + deltaY^2)

        -- check which dir for scaling
        local scaleDir = 1
        if deltaX < 0 and deltaY < 0 then
            scaleDir = -1
        end

        for i, obj in ipairs(selectedObjects) do
            -- calcualte scale factor
            local scaleFactor = 1 + (scaleDir * dist / 100)

            -- clamp scale
            scaleFactor = math.max(scaleFactor, 0.5)
            scaleFactor = math.min(scaleFactor, 3.0)

            -- apply
            local newWidth = obj.ogWidth * scaleFactor
            local newHeight = obj.ogHeight * scaleFactor

            local bottomY = obj.y + obj.height

            -- update
            obj.width = newWidth
            obj.height = newHeight

            -- keep bottom anchored 
            obj.y = bottomY - newHeight
        end
    end
end

function love.mousereleased(x, y, button, istouch)
    --end cursor animation
    cursor.animationPlay = false

    if isMouseDragging and lasso_state == "selecting" then
            local pos = {
                x = math.min(firstCorner.x, secondCorner.x),
                y = math.min(firstCorner.y, secondCorner.y),
                width = math.abs(firstCorner.x - secondCorner.x),
                height = math.abs(firstCorner.y - secondCorner.y),
            }

            -- clear previous selection
            for i, obj in ipairs(selectedObjects) do
                obj.isSelected = false
            end
            selectedObjects = {}
            
            -- check all objects for selection
            for i, obj in ipairs(allObjects) do 
                if pos.x <= obj.x and obj.x + obj.width <= pos.x + pos.width
                    and pos.y <= obj.y and obj.y + obj.height <= pos.y + pos.height
                then
                    obj.isSelected = true
                    table.insert(selectedObjects, obj)
                end
            end
    end
    
    isMouseDragging = false
end

function love.draw()
    world:draw()

    -- set target canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(0, 0, 0, 1)

    -- apply camera transform
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- draw world elements
    Level1.draw()

    love.graphics.setColor(1, 1, 1, 1) -- set to white
    if isMouseDragging and lasso_state == "selecting" then
        local pos = {
            x = math.min(firstCorner.x, secondCorner.x),
            y = math.min(firstCorner.y, secondCorner.y)
        }

        local width = math.abs(firstCorner.x - secondCorner.x)
        local height = math.abs(firstCorner.y - secondCorner.y)

        love.graphics.rectangle("line", pos.x, pos.y, width, height)
    end

    -- draw player
    love.graphics.setColor(0, 0, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)

    love.graphics.setColor(1, 1, 1, 1)
    -- remove camera transform
    love.graphics.pop()

    love.graphics.setCanvas()
    -- draw the canvas
    love.graphics.draw(gameCanvas, 0, 0);
    if cursor.animationPlay then
        cursor.animations.leftClick:draw(cursor.sparkle, cursor.x, cursor.y, nil, 2, 2)
    end
end