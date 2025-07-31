Object = require ("assets/libraries/classic")

SelectableObject = Object:extend(Object)

function SelectableObject:new(x, y, width, height, color)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 50
    self.height = height or 50
    self.color = color or {1, 1, 1}
    self.isSelected = false

    -- simple physics
    self.velocityY = 0
    self.gravity = 800
    self.isGrounded = false
    self.groundY = love.graphics.getHeight() - 300
end

function SelectableObject:update(dt, isBeingDragged)
    if not self.isSelected and not isBeingDragged then
        -- check if above ground
        if self.y + self.height < self.groundY then
            self.isGrounded = false

            -- apply gravity
            self.velocityY = self.velocityY + self.gravity * dt
            self.y = self.y + self.velocityY * dt
        else
            if not self.isGrounded then
                self.y = self.groundY - self.height
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