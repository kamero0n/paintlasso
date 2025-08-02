require "assets/tools/lassoObjects"

BouncyBall = SelectableObject:extend()

function BouncyBall:new(x, y, radius, color, world)
    BouncyBall.super.new(self, x, y, radius * 2, radius * 2, color, world)

    self.radius = radius
    self.ogRadius = radius
    self.bounceDamping = 0.7 -- how much it loses on bounce
    self.minBounceVel = 50 -- min velocity to bounce
    self.world = world

    -- bouncing state
    self.isBouncing = false
    
    -- override to be circle
    if self.body then
        self.body:destroy()
        self.body = world:newCircleCollider(self.x + radius, self.y + radius, radius)
        self.body:setType("dynamic")
        self.body:setRestitution(self.bounceDamping)

        self.body:setCategory(2)
    end
end

function BouncyBall:update(dt, isBeingDragged, allObjects)
    if isBeingDragged then
        -- let physics handle bouncing when not being dragged
        if self.body then
            self.body:setType("kinematic")
            self.body:setPosition(self.x + self.radius, self.y + self.radius)
            self.body:setLinearVelocity(0, 0)
        end

        self.isBouncing = false
        self.bounceTimeout = 0
    else
        -- when not being dragged, move physics body to match
        if self.body then
            self.body:setType("dynamic")

            local bodyX, bodyY = self.body:getPosition()
            self.x = bodyX - self.radius
            self.y = bodyY - self.radius

            -- check if ball is bouncing based on velocity
            local velX, velY = self.body:getLinearVelocity()
            local totalVelocity = math.sqrt(velX^2 + velY^2)

            if totalVelocity > 30 then
                self.isBouncing = true
            else 
                self.isBouncing = false
            end

        end
    end
end

function BouncyBall:setSize(width, height)
    -- calculate new radius based on width
    local newRadius = width / 2
    self.radius = newRadius
    self.ogRadius = newRadius

    self.width = width
    self.height = height

    if self.body and self.world then
        local bodyX, bodyY = self.body:getPosition()
        local velX, velY = self.body:getLinearVelocity()
        local angularVel = self.body:getAngularVelocity()

        -- destroy old body
        self.body:destroy()

        -- new bod
        self.body = self.world:newCircleCollider(bodyX, bodyY, newRadius)
        self.body:setType("dynamic")
        self.body:setRestitution(self.bounceDamping)
        self.body:setCategory(2)

        -- restore velocity
        self.body:setLinearVelocity(velX, velY)
        self.body:setAngularVelocity(angularVel)
    end

end

function BouncyBall:draw()
    if self.isSelected then
        -- draw selection outline
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.circle("line", self.x + self.radius, self.y + self.radius, self.radius)
    end

    -- draw ball
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
    love.graphics.circle("fill", self.x + self.radius, self.y + self.radius, self.radius)
end