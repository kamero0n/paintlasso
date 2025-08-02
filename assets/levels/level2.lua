require "assets/tools/npc"

Level2 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- first puzzle stuff
local employee
local shelfStacked = false


function Level2.init(world)
    -- create ground collider
    ground = world:newRectangleCollider(0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)
    ground:setType('static')

    -- create employee
    employee = NPC(300, WINDOWHEIGHT - 330, 25, 15, {0.2, 0.2, 0.2}, 0)
end

function Level2.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)
end

function Level2.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)

end


function Level2.getObjects()
    local objects = {}

    return objects
end

function Level2.getAllObjects()
    local objects = {}

    return objects
end

function Level2.isLevelSolved()
end
