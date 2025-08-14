Object = require ("assets/libraries/classic")

NPC = Object:extend()

function NPC:new(x, y, width, height, color, moveRange, sprite)
    self.x = x
    self.y = y 
    self.width = width
    self.height = height
    self.color = color or {0.5, 0.5, 0.5}

    --sprite
    self.sprite = sprite or nil
    
    -- movement 
    self.startX = x
    self.moveRange = moveRange or 0
    self.speed = 30
    self.dir = 1
    self.moveTimer = 0

    -- chasing states
    self.isChasing = false
    self.isFollowing = false
end

function NPC:update(dt)
    if self.isChasing or self.isFollowing then
        -- don't do normal movement
        return
    end

    if self.moveRange > 0 then
        self.moveTimer = self.moveTimer + dt

        -- simple back and forth for now
        self.x = self.x + self.speed * self.dir * dt

        if self.x > self.startX + self.moveRange or self.x < self.startX then
            self.dir = self.dir * -1
            self.x = math.max(self.startX, math.min(self.startX + self.moveRange, self.x))
        end
    end
end

function NPC:draw()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
    
    --draw srpite
    if self.sprite then
        love.graphics.draw(self.sprite, self.x, self.y, 0, self.width/self.sprite:getWidth(), self.height/self.sprite:getHeight())
    else
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end
end

function NPC:isNearBalls(balls, threshold)
    threshold = threshold or 100
    for _, ball in ipairs(balls) do
        if ball.isBouncing then
            local ballCenterX = ball.x + ball.radius
            local ballCenterY = ball.y + ball.radius
            local npcCenterX = self.x + self.width/2
            local npcCenterY = self.y + self.height/2

            local dist = math.sqrt((npcCenterX - ballCenterX)^2 + (npcCenterY - ballCenterY)^2)

            if dist < threshold then
                return true, ball
            end
        end
    end

    return false
end