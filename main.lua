require "assets/lassoObjects"

local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- check if mouse is being dragged
local isMouseDragging = false

-- positions for lasso loop
local firstCorner
local secondCorner

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
end

function love.update(dt)
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        isMouseDragging = true

        firstCorner.x = x
        firstCorner.y = y

        secondCorner.x = x
        secondCorner.y = y
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if isMouseDragging then
        secondCorner.x = x
        secondCorner.y = y
    end

end

function love.mousereleased(x, y, button, istouch)
    isMouseDragging = false

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

function love.draw()
    -- set target canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(0, 0, 0, 1)

    love.graphics.setColor(1, 1, 1, 1) -- set to white

    object1.draw(object1)

    if isMouseDragging then
        local pos = {
            x = math.min(firstCorner.x, secondCorner.x),
            y = math.min(firstCorner.y, secondCorner.y)
        }

        local width = math.abs(firstCorner.x - secondCorner.x)
        local height = math.abs(firstCorner.y - secondCorner.y)

        love.graphics.rectangle("line", pos.x, pos.y, width, height)
    end

    love.graphics.setCanvas()

    -- draw the canvas
    love.graphics.draw(gameCanvas, 0, 0);
end


