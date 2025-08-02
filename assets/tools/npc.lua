Object = require ("assets/libraries/classic")

NPC = Object:extend()

function NPC:new(x, y, width, height, color, moveRange)
    self.x = x
    self.y = y 
    self.width = width
    self.height = height
    self.color = color or {0.5, 0.5, 0.5}

    -- movement 
    self.startX = x
    self.moveRange = moveRange or 0
    self.speed = 30
    self.dir = 1
    self.moveTimer = 0
end

function NPC:update(dt)
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
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

function NPC:isNearBalls(balls, threshold)
    threshold = threshold or 100
    for _, ball in ipairs(balls) do
        local dist = math.sqrt((self.x - ball.x)^2 + (self.y - ball.y)^2)

        if dist < threshold then
            return true, ball
        end
    end

    return false
end