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
    opening = "Aw frick Chompy got out... ugh I guess I'll go outside... maybe I can put this wand to use.",
    poopWarning = "I dont wanna step on that... I already did by accident last week.",
    sprinklerWarning = "I don't feel like getting wet.",
    ownerWarning = "... I dont think they're gonna stop talking to me",
    dogInTree = "Aw frick, in the tree!?"
}

function Utils.Dialogue.initStates(dialogueLines)
    local states = {}
    for key, _ in pairs(dialogueLines) do
        states[key] = false
    end

    return states
end

function Utils.Dialogue.showOnce(dialogueStates, dialogueKey, dialogueLines)
    if not dialogueStates[dialogueKey] then
        dialogueStates[dialogueKey] = true
        local message = dialogueLines[dialogueKey]
        if message then
            dialogManager:show(message)
            return true
        end
        return true
    end

    return false
end


return Utils