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
end

function love.update(dt)
end

function love.mousepressed(x, y, button, istouch)
    isMouseDragging = true

    if button == 1 then
        firstCorner.x = x
        firstCorner.y = y
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
end

function love.draw()
    -- set target canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear()

    love.graphics.setColor(0, 0, 0, 1) -- set to black
    love.graphics.rectangle("fill", 0, 0, WINDOWWIDTH, WINDOWHEIGHT) 

    love.graphics.setColor(1, 1, 1, 1) -- set to white

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
