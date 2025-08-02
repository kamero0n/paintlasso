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

-- second puzzle stuff
local guitarMan, guitar, sock
local guitarManSilenced = false
local guitarMadeBig = false
local guitarManSolved = false
local guitarManBlockRadius = 80
local requiredGuitarScale = 2.0
local mouthAreaSize = 30

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

    -- guitarMan
    guitarMan = NPC(1000, WINDOWHEIGHT - 400, 40, 100, {0.6, 0.1, 0.9}, 0)
    guitar = SelectableObject(guitarMan.x - 40, guitarMan.y + 50, 80, 20, {0.8, 0.4, 0.1}, world)
    guitar.attachedToGuitarMan = true
    sock = SelectableObject(1150, WINDOWHEIGHT - 330, 25, 15, {0.3, 0.2, 0.1}, world)

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

local function isSockOnMouth()
    local sockCenterX = sock.x + sock.width / 2
    local sockCenterY = sock.y + sock.height / 2

    -- guitar man mouf area
    local mouthX = guitarMan.x + guitarMan.width / 2
    local mouthY = guitarMan.y + guitarMan.height * 0.2

    local dist = math.sqrt((sockCenterX - mouthX)^2 + (sockCenterY - mouthY)^2)
    return dist <= mouthAreaSize
end

local function isGuitarBigEnough()
    local currScale = guitar.width / guitar.ogWidth
    return currScale >= requiredGuitarScale
end

local function updateGuitarManState()
    guitarManSilenced = isSockOnMouth()
    guitarMadeBig = isGuitarBigEnough()
    guitarManSolved = guitarManSilenced and guitarMadeBig 
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

    -- second puzzle --
    if signSmushedSolicitor then
        guitarMan:update(dt)

        -- update second puzzle objects
        local isSockBeingDragged = Utils.checkIfObjIsDragged(sock, selectedObj, lasso_state, isMouseDragging)

        guitar.x = guitarMan.x - 40
        guitar.y = guitarMan.y + 50

        if guitarManSilenced then
            -- keep sock on mouth
            local mouthX = guitarMan.x + guitarMan.width / 2
            local mouthY = guitarMan.y + guitarMan.height * 0.2
            sock.x = mouthX - sock.width / 2
            sock.y = mouthY - sock.height / 2
            sock.attachedToMouth = true
        else
            sock.attachedToMouth = false
            sock:update(dt, isSockBeingDragged, allObjects)
        end

        guitar:update(dt, false, allObjects)

        -- update guitar man state
        updateGuitarManState()

        -- block player movement completely
        if not guitarManSolved and Utils.checkDist(player, guitarMan, guitarManBlockRadius) then
            local guitarManCenterX = guitarMan.x + guitarMan.width / 2
            player.x = guitarManCenterX - guitarManBlockRadius - player.width / 2
        end
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


    -- draw guitar man
    if signSmushedSolicitor then
        guitarMan:draw()

        guitar:draw()

        sock:draw()
    end
end

function Level3.getObjects()
    local objects = {}

    table.insert(objects, sign)

    if signSmushedSolicitor then
        table.insert(objects, guitar)
        table.insert(objects, sock)
    end

    return objects
end

function Level3.getAllObjects()
    local objects = {}

    table.insert(objects, sign)

    if not solicitor.isGone then
        solicitor.isSelectable = false
        table.insert(objects, solicitor)
    end

    if signSmushedSolicitor then
        table.insert(objects, guitar)
        table.insert(objects, sock)

        guitarMan.isSelectable = false
        table.insert(objects, guitarMan)
    end

    return objects
end

function Level3.isLevelSolved()
    return signSmushedSolicitor and guitarManSilenced
end