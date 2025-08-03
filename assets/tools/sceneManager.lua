local sceneManager = {}

-- scene transition state
local scene_transition = {
    active = false,
    fade_alpha = 0,
    dir = "out",
    next_level = nil,
    fade_speed = 2.0
}

-- main menu state
local menu_state = {
    title_alpha = 1.0,
    pulse_speed = 0.5,
    pulse_dir = -1
}

local current_level = 0

function sceneManager.init()
    current_level = 0
    scene_transition.active = false
    scene_transition.fade_alpha = 0
end

function sceneManager.isTransitioning()
    return scene_transition.active
end

function sceneManager.getCurrentLevel()
    return current_level
end

function sceneManager.startTransition(nextLevel)
    scene_transition.active = true
    scene_transition.fade_alpha = 0
    scene_transition.dir = "out"
    scene_transition.next_level = nextLevel
end

function sceneManager.updateMenu(dt)
    -- simple effet
    menu_state.title_alpha = menu_state.title_alpha + menu_state.pulse_speed * menu_state.pulse_dir * dt
    if menu_state.title_alpha <= 0.3 then
        menu_state.title_alpha = 0.3
        menu_state.pulse_dir = 1
    elseif menu_state.title_alpha >= 1.0 then
        menu_state.title_alpha = 1.0
        menu_state.pulse_dir = -1
    end
end

function sceneManager.update(dt, world, player, WINDOWWIDTH, WINDOWHEIGHT, camera, allObjects)
    if not scene_transition.active then
        return false
    end

    if scene_transition.dir == "out" then
        -- fade to black
        scene_transition.fade_alpha = scene_transition.fade_alpha + scene_transition.fade_speed * dt

        if scene_transition.fade_alpha >= 1.0 then
            scene_transition.fade_alpha = 1.0

            -- switch levels
            sceneManager.switchToLevel(scene_transition.next_level, world, player, WINDOWWIDTH, WINDOWHEIGHT, camera, allObjects)
            scene_transition.dir = "in"
        end
    elseif scene_transition.dir == "in" then
        -- fade from black
        scene_transition.fade_alpha = scene_transition.fade_alpha - scene_transition.fade_speed * dt

        if scene_transition.fade_alpha <= 0.0 then
            scene_transition.fade_alpha = 0.0
            scene_transition.active = false
        end

    end

    return true
end

function sceneManager.switchToLevel(levelNum, world, player, WINDOWWIDTH, WINDOWHEIGHT, camera, allObjects)
    current_level = levelNum

    -- stop curr music before switching
    stopLevelMusic()

    -- reset player pos for new level
    player.x = 200
    player.y = WINDOWHEIGHT - 350
    player:setPosition(player.x + player.width/2, player.y + player.height/2)

    -- clear curr level objs from allObject tables
    for i=#allObjects, 1, -1 do
        allObjects[i] = nil
    end

    -- init new levels
    if levelNum == 3 then
        Level3.init(world)
        for i, obj in ipairs(Level3.getAllObjects()) do
            table.insert(allObjects, obj)
        end
        playLevelMusic(3)
    elseif levelNum == 2 then
        Level2.init(world)
        for i, obj in ipairs(Level2.getAllObjects()) do
            table.insert(allObjects, obj)
        end
        playLevelMusic(2)
    elseif levelNum == 1 then
        Level1.init(world)
        for i, obj in ipairs(Level1.getAllObjects()) do
            table.insert(allObjects, obj)
        end
        playLevelMusic(1)
    elseif levelNum == 0 then
        -- back to menuuu
        stopLevelMusic()
    end
end

function sceneManager.drawMenu(WINDOWWIDTH, WINDOWHEIGHT, font)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, WINDOWWIDTH, WINDOWHEIGHT)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(font)

    -- game title
    local title = "PIASSO"
    local title_width = font:getWidth(title)
    love.graphics.print(title, WINDOWWIDTH / 2 - title_width/2, WINDOWHEIGHT/3)

    -- pulsing "press any key"
    love.graphics.setColor(1, 1, 1, menu_state.title_alpha)
    love.graphics.setFont(smallerFont)
    local instruction = "press any key to start"
    local inst_width = font:getWidth(instruction)
    love.graphics.print(instruction, WINDOWWIDTH / 2 - 330, WINDOWHEIGHT/2)

    love.graphics.setColor(1, 1, 1, 1)
end

function sceneManager.draw(WINDOWWIDTH, WINDOWHEIGHT)
    if scene_transition.active and scene_transition.fade_alpha > 0 then
        love.graphics.setColor(0, 0, 0 ,scene_transition.fade_alpha)
        love.graphics.rectangle("fill", 0, 0, WINDOWWIDTH, WINDOWHEIGHT)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function sceneManager.getCurrentLevelObjects()
    if current_level == 1 then
        return Level1.getObjects()
    elseif current_level == 2 then
        return Level2.getObjects()
    elseif current_level == 3 then
        return Level3.getObjects()
    end

    return {}
end

function sceneManager.getCurrentLevelAllObjects()
    if current_level == 1 then
        return Level1.getAllObjects()
    elseif current_level == 2 then
        return Level2.getAllObjects()
    elseif current_level == 3 then
        return Level3.getAllObjects()
    end

    return {}
end

function sceneManager.updateCurrentLevel(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)
    if current_level == 0 then
        sceneManager.updateMenu(dt)
        return
    end

    if current_level == 1 then
        Level1.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)

        -- check if level 1 is complete
        if Level1.isLevelSolved() then
            sceneManager.startTransition(2)
        end
    elseif current_level == 2 then
        Level2.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)

        -- check if level 2 is complete
        if Level2.isLevelSolved() then
            sceneManager.startTransition(3)
        end
    elseif current_level == 3 then
        Level3.play(player, dt, selectedObjects, lasso_state, isMouseDragging, allObjects)

        -- check if level 3 is complete
        if Level3.isLevelSolved() then
            sceneManager.startTransition(0)
        end
    end

end

function sceneManager.drawCurrentLevel(WINDOWWIDTH, WINDOWHEIGHT, font)
    if current_level == 0 then
        sceneManager.drawMenu(WINDOWWIDTH, WINDOWHEIGHT, font)
        return
    end


    if current_level == 1 then
        Level1.draw()
    elseif current_level == 2 then
        Level2.draw()
    elseif current_level == 3 then
        Level3.draw()
    end
end

function sceneManager.startGame()
    if current_level == 0 then
        sceneManager.startTransition(2)
    end
end

return sceneManager