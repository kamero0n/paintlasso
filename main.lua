require "assets/tools/lassoObjects"
require "assets/levels/level1"

local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- check if mouse is being dragged
local isMouseDragging = false

-- positions for lasso loop
local firstCorner, secondCorner

-- offset values for selected object vs mouse
local offsetX, offsetY

-- check the lasso tool state
-- are we "selecting", "dragging", "scaling", or "rotating"
local lasso_state = "selecting"

local selectedObject = nil
local allObjects = {}

-- CAMERA
local camera = {
    x = 0,
    y = 0
}

function love.load()
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

    -- add an object
    object1 = SelectableObject(WINDOWWIDTH/2, WINDOWHEIGHT/2, 30, 30)

    -- player
    player = {
        x = WINDOWWIDTH/2,
        y = WINDOWHEIGHT - 350,
        width = 30, 
        height = 50,
        speed = 400
    }

    Level1.init()

    allObjects = {object1}
    for i, obj in ipairs(Level1.getObjects()) do
        table.insert(allObjects, obj)
    end

end

function updateCamera()
    -- camera follows player
    camera.x = player.x - WINDOWWIDTH / 2
    camera.y = player.y - WINDOWHEIGHT / 2

    -- keep camera w/in bounds
    if camera.x < 0 then
        camera.x = 0
    end
    if camera.x > WINDOWWIDTH then
        --camera.x = WINDOWWIDTH
    end
end

function love.update(dt)
    -- player movement
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    end

    -- update camera
    updateCamera()

    -- update obj w/ gravity 
    -- local isBeingDragged = (lasso_state == "dragging" and isMouseDragging)
    -- object1:update(dt, isBeingDragged, isSelected)
    -- update all objects
    for i, obj in ipairs(allObjects) do
        local isBeingDragged = (selectedObject == obj and lasso_state == "dragging" and isMouseDragging)
        obj:update(dt, isBeingDragged)
    end

    -- first level
    Level1.play(player, dt)
end

function love.mousepressed(x, y, button, istouch)
    local worldX = x + camera.x
    local worldY = y + camera.y

    if button == 1  then
        -- check if clicking on selected object first
        if selectedObject and selectedObject.isSelected then
            if selectedObject.x <= worldX and worldX <= selectedObject.x + selectedObject.width
                and selectedObject.y <= worldY and worldY <= selectedObject.y + selectedObject.height
            then
                lasso_state = "dragging"
                isMouseDragging = true
                offsetX = worldX - selectedObject.x
                offsetY = worldY - selectedObject.y

                return
            else
                -- clicking outside
                selectedObject.isSelected = false
                selectedObject = nil
                lasso_state = "selecting"
            end
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

    if isMouseDragging and lasso_state == "selecting" then
        secondCorner.x = worldX
        secondCorner.y = worldY
    end

    if isMouseDragging and lasso_state == "dragging" then
        selectedObject.x = worldX - offsetX
        selectedObject.y = worldY - offsetY
    end
end

function love.mousereleased(x, y, button, istouch)
    if isMouseDragging and lasso_state == "selecting" then
            local pos = {
                x = math.min(firstCorner.x, secondCorner.x),
                y = math.min(firstCorner.y, secondCorner.y),
                width = math.abs(firstCorner.x - secondCorner.x),
                height = math.abs(firstCorner.y - secondCorner.y),
            }
            
            -- check all objects for selection
            for i, obj in ipairs(allObjects) do 
                if pos.x <= obj.x and obj.x + obj.width <= pos.x + pos.width
                    and pos.y <= obj.y and obj.y + obj.height <= pos.y + pos.height
                then
                    -- deselect
                    if selectedObject then
                        selectedObject.isSelected = false
                    end

                    obj.isSelected = true
                    selectedObject = obj
                    break
                end
            end
    end
    
    isMouseDragging = false
end

function love.draw()
    -- set target canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(0, 0, 0, 1)

    -- apply camera transform
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- draw player
    love.graphics.setColor(0, 0, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)

    -- draw world elements
    Level1.draw()

    -- test object
    object1.draw(object1)

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

    -- remove camera transform
    love.graphics.pop()

    love.graphics.setCanvas()
    -- draw the canvas
    love.graphics.draw(gameCanvas, 0, 0);
end


