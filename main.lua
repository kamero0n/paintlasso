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
    object1 = SelectableObject(WINDOWWIDTH/2, WINDOWHEIGHT/2)

    -- player
    player = {
        x = 0,
        y = WINDOWHEIGHT - 350,
        width = 30, 
        height = 50,
        speed = 400
    }
end

function love.update(dt)
    -- player movement
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    end

    -- first level
    Level1.play(player, dt)
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 and object1.isSelected == false then
        isMouseDragging = true

        firstCorner.x = x
        firstCorner.y = y

        secondCorner.x = x
        secondCorner.y = y
    end

    -- check if we have an object selected
    if object1.isSelected == true then
        -- check if we click inside
        if object1.x <= x and x <= object1.x + object1.width
            and object1.y <= y and y <= object1.y + object1.height
        then
            lasso_state = "dragging"
            isMouseDragging = true

            offsetX = x - object1.x
            offsetY = y - object1.y
        else
            object1.isSelected = false
            lasso_state = "selecting"
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if isMouseDragging and lasso_state == "selecting" then
        secondCorner.x = x
        secondCorner.y = y
    end

    if isMouseDragging and lasso_state == "dragging" then
        object1.x = x - offsetX
        object1.y = y - offsetY
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

            if pos.x <= object1.x and object1.x + object1.width <= pos.x + pos.width
                and pos.y <= object1.y and object1.y + object1.height <= pos.y + pos.height then

                object1.isSelected = true
            end
    end
    
    isMouseDragging = false
end

function love.draw()
    -- set target canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(0, 0, 0, 1)

    -- test object
    -- object1.draw(object1)

    -- draw player
    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)

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

    Level1.draw()

    love.graphics.setCanvas()
    -- draw the canvas
    love.graphics.draw(gameCanvas, 0, 0);
end


