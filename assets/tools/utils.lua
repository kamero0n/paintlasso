Utils = {}

function Utils.checkDist(obj1, obj2, threshold)
    local obj1CenterX = obj1.x + obj1.width/2
    local obj1CenterY = obj1.y + obj1.height/2
    local obj2CenterX = obj2.x + obj2.width/2
    local obj2CenterY = obj2.y + obj2.height/2

    local dist = math.sqrt((obj1CenterX - obj2CenterX)^2 + (obj1CenterY - obj2CenterY)^2)

    return dist < threshold
end

function Utils.checkIfObjIsDragged(obj, selectedObjects, lasso_state, isMouseDragging)
    -- very specific case for guitar dude
    if obj.attachedToGuitarMan then
        return false
    end

    local isBeingDragged = false
    for j, selectedOBj in ipairs(selectedObjects) do
        if selectedOBj == obj and lasso_state == "dragging" and isMouseDragging then
                isBeingDragged = true
        end
    end

    return isBeingDragged
end

Utils.Dialogue = {}

-- level 1 lines
Utils.Dialogue.Level1 = {
    opening = "Aw frick Chompy got out, right when I needed to get milk... maybe I can put this wand to use.",
    poopWarning = "I dont wanna step on that... I already did by accident last week.",
    sprinklerWarning = "I don't feel like getting wet.",
    ownerWarning = "... I don't think they're gonna stop talking to me.",
    dogInTree = "Aw frick, in the tree!? Maybe I can help him if he stops seeing the cat...",
    fin = "Well, I guess this wands helps a ton. Might as well bring it to go and get some milk."
}

-- level 2 lines
Utils.Dialogue.Level2 = {
    opening = "I think the milk is all the way in the back.",
    employee = "Hrmmm, hgnhhh, uggghhh... where did this go again?",
    afterEmployee = "...Maybe I should help him.",
    kidCrying = "WAHHHHHHHHHHHHHH",
    afterKidCrying = "(I think I may be an awful person if I left this kid alone... I should help.)",
    momFindsKid = "BAABBYY!! Mommy was just in the bathroom!!!",
    meetFatGuy = "Excuse me sir. Sir? Sir??",
    fatGuyClues = "Ok Ok Ok. I could go for something creamy. BUT I want fizz to spice it up.",
    fin = "Finally, got the milk. I just wanna go home man... too many things happening today."
}

-- level 3 lines
Utils.Dialogue.Level3 = {
    opening = "Ok just gotta get home and I can chill. This wand has been saving me some trouble.",
    solicitor = "MAAM! Do you have one minute to spare, I think you really need to hear about our cause.",
    afterSolicitor = "(A solicitor... I gotta get away somehow.)",
    solicitorSmushed = "...",
    singingMan = "Hey! Come hear my song!!",
    singingManResponse = "He won't let me leave...",
    singingManFree = "La da deeeee dum dum pad da dummmmmmm...",
    singingManWithSock = "Hrwuoshuoeuhofeour *continues to strum guitar*",
    singingManWithBigGuitar = "I can still sing loud and clear!",
    leaveSingingMan = "Ok, gotta go, bye bye!",
    randomFrenchMan = "C'est une histoire vraie.",
    randomFrenchManCont = "Je me trouvais en France et un homme s'est approché de moi et a commencé à me parler en français.",
    randomFrenchManSPEAK = "Il était en état d'ébriété et semblait me trouver séduisante, car j'ai entendu...",
    afterFrenchManLeaves = "Ok.",
    creepTriesToHit = "Heyyyy cutie? Wanna let me get your number so you can get to know me?",
    afterCreep = "*internal screaming* (I gotta get out of this somehow with this wand and the stuff nearby...)",
    creepHitsOnMannequin = "Heeeyyyy baby! Didn't see you there...",
    fin = "Man, what a long day. I think this wand should probably be returned, but holy it saved my life today."
}

function Utils.Dialogue.initStates(dialogueLines)
    local states = {}
    for key, _ in pairs(dialogueLines) do
        states[key] = false
    end

    return states
end

function Utils.Dialogue.showOnce(dialogueStates, dialogueKey, dialogueLines, title)
    if not dialogueStates[dialogueKey] then
        dialogueStates[dialogueKey] = true
        local message = dialogueLines[dialogueKey]
        if message then
            dialogManager:show({text = message, title = title})
            return true
        end
        return true
    end

    return false
end


return Utils