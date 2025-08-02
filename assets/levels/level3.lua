require "assets/tools/npc"
require "assets/tools/utils"

Level3 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

function Level3.init(world)
    -- create ground collider
    ground = world:newRectangleCollider(0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)
    ground:setType('static')

end

function Level3.play(player, dt, selectedObj, lasso_state, isMouseDragging, allObjects)
end

function Level3.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)

end

function Level3.getObjects()
    local objects = {}
    return objects
end

function Level3.getAllObjects()
    local objects = {}
    return objects
end

function Level3.isLevelSolved()
end