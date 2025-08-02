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
    local isBeingDragged = false
    for j, selectedOBj in ipairs(selectedObjects) do
        if selectedOBj == obj and lasso_state == "dragging" and isMouseDragging then
                isBeingDragged = true
        end
    end

    return isBeingDragged
end


return Utils