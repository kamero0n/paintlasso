Object = require ("classic")

SelectableObject = Object:extend(Object)

function SelectableObject:new(x, y, width, height, color)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 50
    self.height = height or 50
    self.color = color or {1, 1, 1}
    self.isSelected = false

    -- for drag

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