require "assets/tools/lassoObjects"

BouncyBall = SelectableObject:extend()

function BouncyBall:new(x, y, radius, color, world)
    BouncyBall.super.new(self, x, y, radius * 2, radius * 2, color, world)

    self.radius = radius
    self.bounceDamping = 0.7 -- how much it loses on bounce
    self.minBounceVel = 50 -- min velocity to bounce

    -- override to be circle
    if self.body then
        self.body:destroy()
        self.body = world:newCircleCollider(self.x + radius, self.y + radius, radius)
        self.body:setType("dynamic")
        self.body:setRestitution(self.bounceDamping)
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
    else
        -- when not being dragged, move physics body to match
        if self.body then
            self.body:setType("dynamic")

            local bodyX, bodyY = self.body:getPosition()
            self.x = bodyX - self.radius
            self.y = bodyY - self.radius
        end
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