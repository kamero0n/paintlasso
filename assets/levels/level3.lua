require "assets/tools/npc"
require "assets/tools/utils"

Level3 = {}

-- window stuff
local WINDOWWIDTH, WINDOWHEIGHT = love.graphics.getDimensions()

-- dialogue stuffs
local dialogueStates
local endDialogue = false
local finalDialogueShown = false
local solicitorTalkingChannel = nil
local guitarPlayingChannel = nil
local guySingingChannel = nil
local creepyGuyChannel = nil

-- first puzzle stuff
local solicitor, sign
local signSmushedSolicitor = false
local solicitorBlockRadius = 50
local solminHeight = 10
local smushSpeed = 150

-- second puzzle stuff
local guitarMan, guitar, sock
local guitarManSilenced = false
local guitarMadeBig = false
local guitarManSolved = false
local guitarManBlockRadius = 80
local requiredGuitarScale = 1.5
local mouthAreaSize = 30

-- crazy man
local crazyMan
local crazyManTimer = 5 -- only speak for like 10 seconds
local crazyManCurrTime = 0
local crazyManRadius = 80
local crazyManAround = false
local crazyManDone = false 
local crazyManTriggered = false
local crazyManMovingAway = false
local crazyManMoveSpeed = 100

-- LAST ONE!
local weirdGuy, mannequin
local basketballs = {}
local box, mopHead
local numBasketballs = 3
local guyBlockRadius = 80
local guyMoved = false
local mannequinComplete = false
local weirdGuyPuzzleDone = false
local mannequinZones = {}


function Level3.init(world)
    dialogueStates = Utils.Dialogue.initStates(Utils.Dialogue.Level3)

    defaultDrop = "assets/audio/sound_effects/defaultDrop.ogg"
    creepyGuy = "assets/audio/sound_effects/creep.ogg"
    guySinging = "assets/audio/sound_effects/guySinging.ogg"
    guitarPlaying = "assets/audio/sound_effects/guitarPlaying.ogg"
    solicitorTalking = "assets/audio/sound_effects/solicitorMan.ogg"
    frenchMan = "assets/audio/sound_effects/frenchMan.ogg"

    -- create ground collider
    ground = world:newRectangleCollider(0, WINDOWHEIGHT - 300, WINDOWWIDTH * 4, 300)
    ground:setType('static')

    -- solicitor
    solicitor = NPC(400, WINDOWHEIGHT - 380, 40, 80, {0.2, 0.5, 0.5}, 0)
    solicitor.originalY = solicitor.y
    solicitor.isSmushing = false
    
    -- sign 
    sign = SelectableObject(50, WINDOWHEIGHT - 480, 150, 50, {0.8, 0.2, 0.8}, world, defaultDrop)

    -- guitarMan
    guitarMan = NPC(1000, WINDOWHEIGHT - 400, 40, 100, {0.6, 0.1, 0.9}, 0)
    guitar = SelectableObject(guitarMan.x - 40, guitarMan.y + 50, 80, 20, {0.8, 0.4, 0.1}, world, defaultDrop)
    guitar.attachedToGuitarMan = true
    sock = SelectableObject(1150, WINDOWHEIGHT - 330, 25, 15, {0.3, 0.2, 0.1}, world, defaultDrop)

    --crazy man 
    crazyMan = NPC(1700, WINDOWHEIGHT - 380, 40, 80, {0.2, 0.1, 0.5}, 0)

    -- add that weirdo
    weirdGuy = NPC(2400, WINDOWHEIGHT - 380, 50, 80, {0.8, 0.1, 0.1}, 0)

    -- mannequin
    mannequin = {
        x = 2000,
        y = WINDOWHEIGHT - 450,
        width = 40,
        height = 150,
        color = {0.9, 0.9, 0.8}
    }

    -- basketballs for head/body
    for i = 1, numBasketballs do
        local ball = SelectableObject(
            2200 + (i * 40),
            WINDOWHEIGHT - 330,
            25,
            25,
            {0.8, 0.4, 0.1},
            world,
            defaultDrop
        )
        ball.isBasketball = true
        table.insert(basketballs, ball)
    end

    -- box for torso
    box = SelectableObject(2300, WINDOWHEIGHT - 350, 35, 40, {0.6, 0.4, 0.2}, world, defaultDrop)
    box.isBox = true

    -- mop head for hair
    mopHead = SelectableObject(2100, WINDOWHEIGHT - 330, 30 , 20, {0.3, 0.2, 0.1}, world, defaultDrop)
    mopHead.isMophead = true

    -- define zones for mannequin
    table.insert(mannequinZones, {
        x = mannequin.x + 5,
        y = mannequin.y + 10,
        width = 30,
        height = 25,
        partType = "head",
        filled = false
    })
    table.insert(mannequinZones, {
        x = mannequin.x + 2,
        y = mannequin.y + 40,
        width = 36,
        height = 40,
        partType = "torso",
        filled = false
    })
    table.insert(mannequinZones, {
        x = mannequin.x + 8,
        y = mannequin.y - 5,
        width = 24,
        height = 15,
        partType = "hair",
        filled = false
    })

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

local function updateCrazyManTimer(dt, player)
    -- chceck if player is near
    local playerNearCrazy = Utils.checkDist(player, crazyMan, crazyManRadius)

    -- trigger timer when player first approaches
    if playerNearCrazy and not crazyManTriggered and not crazyManDone then
        crazyManTriggered = true
        crazyManAround = true
    end

    -- once triggered keep timer running 
    if crazyManTriggered and crazyManAround and not crazyManDone then
        crazyManCurrTime = crazyManCurrTime  + dt

        -- check if timer is complete
        if crazyManCurrTime >= crazyManTimer then
            crazyManDone = true
            crazyManAround = false
            crazyManMovingAway = true
        end
    end

    -- move crazy man off screen
    if crazyManMovingAway then
        crazyMan.x = crazyMan.x - crazyManMoveSpeed * dt
    end
end

local function checkItemInMannequinZone(item, zone)
    local itemCenterX = item.x + item.width / 2
    local itemCenterY = item.y + item.height /2 

    local inHoriz = itemCenterX >= zone.x and itemCenterX <= zone.x + zone.width
    local inVert = itemCenterY >= zone.y and itemCenterY <= zone.y + zone.height

    return inHoriz and inVert
end

local function updateMannequinAssembly()
    local headFilled = false
    local torsoFilled = false
    local hairFilled = false

    -- check basketballs
    for _, ball in ipairs(basketballs) do
        if ball.isAttachedToMannequin then
            headFilled = true
            break
        end
    end

    -- check box for torso
    if box.isAttachedToMannequin then
        torsoFilled = true
    end

    -- check mop head for hair
    if mopHead.isAttachedToMannequin then
        hairFilled = true
    end

    -- completed
    mannequinComplete = headFilled and torsoFilled and hairFilled

    if mannequinComplete and not guyMoved then
        guyMoved = true
        weirdGuy.speed = 80
        weirdGuy.dir = -1
        weirdGuy.isMoving = true
        weirdGuy.targetX = mannequin.x - 20
    end
end

function Level3.play(player, dt, selectedObj, lasso_state, isMouseDragging, allObjects)
    Utils.Dialogue.showOnce(dialogueStates, "opening", Utils.Dialogue.Level3, "You")
    
    -- first puzzle --
    solicitor:update(dt)

    -- solicitor audio
    if not signSmushedSolicitor and Utils.checkDist(player, solicitor, solicitorBlockRadius) then
        if not solicitorTalkingChannel then
            solicitorTalkingChannel = TEsound.playLooping(solicitorTalking, "static", "sfx", nil, 0.3)
        end
    else
            if solicitorTalkingChannel and TEsound.channels[solicitorTalkingChannel] then
                TEsound.stop(solicitorTalkingChannel)
                solicitorTalkingChannel = nil
            end
    end

    -- block player if solicitor not gone
    if not signSmushedSolicitor and Utils.checkDist(player, solicitor, solicitorBlockRadius) then
        if Utils.Dialogue.showOnce(dialogueStates, "solicitor", Utils.Dialogue.Level3, "Solicitor") then
            dialogueStates["solicitorResponsePending"] = true
        end

        local solicitorCenterX = solicitor.x + solicitor.width / 2
        player.x = solicitorCenterX - solicitorBlockRadius - player.width / 2
    end

    if dialogueStates["solicitorResponsePending"] and dialogManager:getActiveDialog() == nil then
        dialogueStates["solicitorResponsePending"] = false
        dialogManager:show({text = Utils.Dialogue.Level3.afterSolicitor, title = "You"})
    end

    -- update sign
    local isSignBeingDragged = Utils.checkIfObjIsDragged(sign, selectedObj, lasso_state, isMouseDragging, allObjects)
    sign:update(dt, isSignBeingDragged, allObjects)

    -- check if sign has smushed solictor
    if not signSmushedSolicitor and not isSignBeingDragged then
        if isSignOnSolicitor() then
            solicitor.isSmushing = true
        end
    end

    if signSmushedSolicitor and not dialogueStates["solicitorSmushPlayed"] then
        Utils.Dialogue.showOnce(dialogueStates, "solicitorSmushed", Utils.Dialogue.Level3, "You")
        dialogueStates["solicitorSmushPlayed"] = true
    end

    updateSolicitorSmushing(dt)

    -- second puzzle --
    if signSmushedSolicitor then
        guitarMan:update(dt)

        if Utils.checkDist(player, guitarMan, guitarManBlockRadius) and not dialogueStates["metGuitarMan"] then
            if Utils.Dialogue.showOnce(dialogueStates, "singingMan", Utils.Dialogue.Level3, "Guitar Man") then
                dialogueStates["singingManResponsePending"] = true
                dialogueStates["metGuitarMan"] = true
            end
        end

        -- Show response after guitar man dialogue
        if dialogueStates["singingManResponsePending"] and dialogManager:getActiveDialog() == nil then
            dialogueStates["singingManResponsePending"] = false
            dialogManager:show({text = Utils.Dialogue.Level3.singingManResponse, title = "You"})
        end

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
            if guitarManSilenced and guitarMadeBig then
                Utils.Dialogue.showOnce(dialogueStates, "leaveSingingMan", Utils.Dialogue.Level3, "You")
            elseif guitarManSilenced then
                if Utils.Dialogue.showOnce(dialogueStates, "singingManWithSock", Utils.Dialogue.Level3, "Guitar Man") then
                    TEsound.play(guitarPlaying, "static", "sfx", 0.3)
                end
            elseif guitarMadeBig then
                if Utils.Dialogue.showOnce(dialogueStates, "singingManWithBigGuitar", Utils.Dialogue.Level3, "Guitar Man") then
                    TEsound.play(guySinging, "static", "sfx", 0.3)
                end
            else
                if Utils.Dialogue.showOnce(dialogueStates, "singingManFree", Utils.Dialogue.Level3, "Guitar Man") then
                    TEsound.play(guySinging, "static", "sfx", 0.3)
                    TEsound.play(guitarPlaying, "static", "sfx", 0.3)
                end
            end

            -- only block the player if they haven't solved both parts of the puzzle
            if not (guitarManSilenced and guitarMadeBig) then
                local guitarManCenterX = guitarMan.x + guitarMan.width / 2
                player.x = guitarManCenterX - guitarManBlockRadius - player.width / 2
            end
        else
            dialogueStates["singingManFree"] = false
            dialogueStates["singingManWithSock"] = false
            dialogueStates["singingManWithBigGuitar"] = false
        end


    end

    -- third event --
    if guitarManSolved then
        crazyMan:update(dt)

        -- update crazy man timer and block player
        updateCrazyManTimer(dt, player)

        -- block player if crazy man is active
        if crazyManAround and not crazyManDone and Utils.checkDist(player, crazyMan, crazyManRadius) then 
            if Utils.Dialogue.showOnce(dialogueStates, "afterFrenchManLeaves", Utils.Dialogue.Level3, "You") then
                TEsound.play(frenchMan, "static", "sfx", 0.4)
            end
            local crazyManCenterX = crazyMan.x + crazyMan.width/2
            player.x = crazyManCenterX - crazyManRadius - player.width / 2
        end

        if crazyManDone and not dialogueStates["afterFrenchPlayed"] then
            TEsound.stop("sfx")
            Utils.Dialogue.showOnce(dialogueStates, "afterFrenchManLeaves", Utils.Dialogue.Level3, "You")
            dialogueStates["afterFrenchPlayed"] = true
        end
    end

    -- fourth puzzle --
    if crazyManDone then
        weirdGuy:update(dt)

        if not guyMoved and Utils.checkDist(player, weirdGuy, guyBlockRadius) then
            if Utils.Dialogue.showOnce(dialogueStates, "creepTriesToHit", Utils.Dialogue.Level3, "Creep") then
                TEsound.play(creepyGuy, "static", "sfx", 0.3)

                dialogueStates["creepResponsePending"] = true
            end

            local guyCenterX = weirdGuy.x + weirdGuy.width / 2
            player.x = guyCenterX - guyBlockRadius - player.width / 2
        else
            dialogueStates["creepTriesToHit"] = false
        end

        if dialogueStates["creepResponsePending"] and dialogManager:getActiveDialog() == nil then
            dialogueStates["creepResponsePending"] = false
            dialogManager:show({text = Utils.Dialogue.Level3.afterCreep, title = "You"})
        end

        if guyMoved then
            if weirdGuy.x > weirdGuy.targetX then
                weirdGuy.x = weirdGuy.x - weirdGuy.speed * dt
                -- stop when get to mannequin
                if weirdGuy.x <= weirdGuy.targetX then
                    weirdGuy.x = weirdGuy.targetX
                    weirdGuy.isMoving = false
                    weirdGuyPuzzleDone = true
                end
            end
        end

        -- update items
        for _, ball in ipairs(basketballs) do
            if not ball.isAttachedToMannequin then
                local isBallBeingDragged = Utils.checkIfObjIsDragged(ball, selectedObj, lasso_state, isMouseDragging)
                ball:update(dt, isBallBeingDragged, allObjects)

                -- check if ball should attach to head zone
                if not isBallBeingDragged then
                    for _, zone in ipairs(mannequinZones) do
                        if zone.partType == "head" and not zone.filled and checkItemInMannequinZone(ball, zone) then
                            ball.x = zone.x + zone.width / 2 - ball.width / 2
                            ball.y = zone.y + zone.height / 2 - ball.height / 2
                            ball.isAttachedToMannequin = true
                            zone.filled = true
                            if ball.body then
                                ball.body:destroy()
                                ball.body = nil
                            end
                        end
                    end
                end
            end
        end

        if not box.isAttachedToMannequin then
            local isBoxBeingDragged = Utils.checkIfObjIsDragged(box, selectedObj, lasso_state, isMouseDragging)
            box:update(dt, isBoxBeingDragged, allObjects)

            if not isBoxBeingDragged then
                for _, zone in ipairs(mannequinZones) do
                    if zone.partType == "torso" and not zone.filled and checkItemInMannequinZone(box, zone) then
                        box.x = zone.x + zone.width / 2 - box.width / 2
                        box.y = zone.y + zone.height /2 - box.height /2
                        box.isAttachedToMannequin = true
                        zone.filled = true
                        if box.body then
                            box.body:destroy()
                            box.body = nil
                        end
                        break
                    end
                end
            end
        end

        if not mopHead.isAttachedToMannequin then
            local isMopBeingDragged = Utils.checkIfObjIsDragged(mopHead, selectedObj, lasso_state, isMouseDragging)
            mopHead:update(dt, isMopBeingDragged, allObjects)

            if not isMopBeingDragged then
                for _, zone in ipairs(mannequinZones) do 
                    if zone.partType ==  "hair" and not zone.filled and checkItemInMannequinZone(mopHead, zone) then
                        mopHead.x = zone.x + zone.width / 2 - mopHead.width / 2
                        mopHead.y = zone.y + zone.height / 2 - mopHead.height / 2
                        mopHead.isAttachedToMannequin = true
                        zone.filled = true
                        if mopHead.body then
                            mopHead.body:destroy()
                            mopHead.body = nil
                        end
                    end
                end
            end
        end

        if  weirdGuy.isMoving and not dialogueStates["creepMannequinPlayed"] then
            Utils.Dialogue.showOnce(dialogueStates, "creepHitsOnMannequin", Utils.Dialogue.Level3, "Creep")
            TEsound.play(creepyGuy, "static", "sfx", 0.3)
            dialogueStates["creepMannequinPlayed"] = true
        end

        updateMannequinAssembly()
    end

    -- final dialogue
    if signSmushedSolicitor and guitarManSolved and crazyManDone and weirdGuyPuzzleDone then
        if Utils.Dialogue.showOnce(dialogueStates, "fin", Utils.Dialogue.Level3, "You") then
            finalDialogueShown = true
        end
        endDialogue = true
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

    -- draw crazy man
    if guitarManSolved and crazyMan.x > -crazyMan.width then
        crazyMan:draw()
    end

    -- draw mannequin base
    love.graphics.setColor(mannequin.color[1], mannequin.color[2], mannequin.color[3], 1)
    love.graphics.rectangle("fill", mannequin.x, mannequin.y, mannequin.width, mannequin.height)

    -- draw assembly items
    for _, ball in ipairs(basketballs) do
        ball:draw()
    end
    
    box:draw()
    mopHead:draw()

    if crazyManDone and weirdGuy.x > -weirdGuy.width then
        weirdGuy:draw()
    end
end

function Level3.getObjects()
    local objects = {}

    table.insert(objects, sign)

    if signSmushedSolicitor then
        table.insert(objects, guitar)
        table.insert(objects, sock)
    end

    if crazyManDone then
        for _, ball in ipairs(basketballs) do
            if not ball.isAttachedToMannequin then
                table.insert(objects, ball)
            end
        end
        
        if not box.isAttachedToMannequin then
            table.insert(objects, box)
        end

        if not mopHead.isAttachedToMannequin then
            table.insert(objects, mopHead)
        end
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

    if guitarManSolved and crazyMan.x > -crazyMan.width then
        crazyMan.isSelectable = false
        table.insert(objects, crazyMan)
    end

    if crazyManDone then
        for _, ball in ipairs(basketballs) do
            if not ball.isAttachedToMannequin then
                table.insert(objects, ball)
            end
        end
        
        if not box.isAttachedToMannequin then
            table.insert(objects, box)
        end

        if not mopHead.isAttachedToMannequin then
            table.insert(objects, mopHead)
        end
    end

    if crazyManDone and weirdGuy.x > -weirdGuy.width then
        weirdGuy.isSelectable = false
        table.insert(objects, weirdGuy)
    end

    return objects
end

function Level3.isLevelSolved()
    local allPuzzlesSolved = signSmushedSolicitor and guitarManSolved and crazyManDone and weirdGuyPuzzleDone
    local dialogueComplete = finalDialogueShown and (dialogManager:getActiveDialog() == nil)
    
    return allPuzzlesSolved and dialogueComplete
end