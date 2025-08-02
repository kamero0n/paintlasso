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