Object = require ("assets/libraries/classic")

SelectableObject = Object:extend(Object)

function SelectableObject:new(x, y, width, height, color)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 50
    self.height = height or 50
    self.ogWidth = self.width
    self.ogHeight = self.height
    self.color = color or {1, 1, 1}
    self.isSelected = false

    -- simple physics
    self.velocityY = 0
    self.gravity = 800
    self.isGrounded = false
    self.groundY = love.graphics.getHeight() - 300
end

function SelectableObject:update(dt, isBeingDragged, allObjects)
    if not self.isSelected and not isBeingDragged then
        -- check if above ground or other objects
        local landingY = self.groundY
        
        for i, otherObj in ipairs(allObjects) do
            if otherObj ~= self then
                -- check horizontal overlap
                local horizontalOverlap = (self.x < otherObj.x + otherObj.width) and
                                            (self.x + self.width > otherObj.x)
                if horizontalOverlap then
                    local otherTop = otherObj.y

                    if otherTop < landingY and self.y < otherTop then
                        landingY = otherTop
                    end
                end
            end
        end

        -- check if we're above landing spot
        if self.y + self.height < landingY then
            self.isGrounded = false

            -- apply gravity
            self.velocityY = self.velocityY + self.gravity * dt
            self.y = self.y + self.velocityY * dt

            if self.y + self.height > landingY then
                self.y = landingY - self.height 
                self.velocityY  = 0
                self.isGrounded = true
            end
        else
            if not self.isGrounded then
                self.y = landingY - self.height
                self.velocityY = 0
                self.isGrounded = true
            end
        end

    else
        -- reset velocity
        self.velocityY = 0
        self.isGrounded = false
    end
end

function SelectableObject:draw()
    if self.isSelected then
        -- draw selection outline

        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.rectangle("line", self.x - 2, self.y - 2, self.width + 4, self.height + 4)
    end

    -- draw object
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

function check_collision(a, b)
    local a_left = a.x
    local a_right = a.x + a.width
    local a_top = a.y
    local a_bottom = a.y + a.height

    local b_left = b.x
    local b_right = b.x + b.width
    local b_top = b.y
    local b_bottom = b.y + b.height

    return a_right > b_left 
        and a_left < b_right 
        and a_bottom > b_top
        and a_top < b_bottom
end