require "assets/tools/npc"
require "assets/tools/utils"

Level3 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- first puzzle stuff
local solicitor, sign
local signSmushedSolicitor = false
local solicitorBlockRadius = 50
local solOgHeight = 80
local solminHeight = 10
local smushSpeed = 150

function Level3.init(world)
    -- create ground collider
    ground = world:newRectangleCollider(0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)
    ground:setType('static')

    -- solicitor
    solicitor = NPC(400, WINDOWHEIGHT - 380, 40, 80, {0.2, 0.5, 0.5}, 0)
    solicitor.originalY = solicitor.y
    solicitor.isSmushing = false
    
    -- sign 
    sign = SelectableObject(50, WINDOWHEIGHT - 480, 150, 50, {0.8, 0.2, 0.8}, world)

end

local function isSignOnSolicitor()
    -- check if sign has fallen
    local signCenterX = sign.x + sign.width / 2
    local solicitorCenterX = solicitor.x + solicitor.width/2
    local horizDist = math.abs(signCenterX - solicitorCenterX)

    -- check vertical overlap
    local signBottom = sign.y + sign.height
    local solicitorTop = solicitor.y
    local verticalOverlap = signBottom >= solicitorTop and sign.y <= solicitor.y + solicitor.height

    return horizDist <= (solicitor.width + sign.width) /2 and verticalOverlap
end

local function updateSolicitorSmushing(dt)
    if solicitor.isSmushing and solicitor.height > solminHeight then
        -- decrease height
        local oldHeight = solicitor.height
        solicitor.height = math.max(solminHeight, solicitor.height - smushSpeed * dt)

        -- adjust Y to keep solicitor on ground
        local heightDiff = oldHeight - solicitor.height
        solicitor.y = solicitor.y + heightDiff

        -- check if fully smushed
        if solicitor.height <= solminHeight then
            signSmushedSolicitor = true
            solicitor.isGone = true
        end
    end
end

function Level3.play(player, dt, selectedObj, lasso_state, isMouseDragging, allObjects)
    -- first puzzle --
    solicitor:update(dt)

    -- update sign
    local isSignBeingDragged = Utils.checkIfObjIsDragged(sign, selectedObj, lasso_state, isMouseDragging, allObjects)
    sign:update(dt, isSignBeingDragged, allObjects)

    -- check if sign has smushed solictor
    if not signSmushedSolicitor and not isSignBeingDragged then
        if isSignOnSolicitor() then
            solicitor.isSmushing = true
        end
    end

    updateSolicitorSmushing(dt)

    -- block player if solicitor not gone
    if not signSmushedSolicitor and Utils.checkDist(player, solicitor, solicitorBlockRadius) then
        local solicitorCenterX = solicitor.x + solicitor.width / 2
        player.x = solicitorCenterX - solicitorBlockRadius - player.width / 2
    end
end

function Level3.draw()
    -- floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)

    -- draw solicitor
    if not solicitor.isGone then
        solicitor:draw()
    end

    -- draw sign
    sign:draw()
end

function Level3.getObjects()
    local objects = {}

    table.insert(objects, sign)

    return objects
end

function Level3.getAllObjects()
    local objects = {}

    table.insert(objects, sign)

    if not solicitor.isGone then
        solicitor.isSelectable = false
        table.insert(objects, solicitor)
    end

    return objects
end

function Level3.isLevelSolved()
end