---@class Paddle
---@field x number
---@field y number
---@field dy number
---@field width number
---@field height number
---@field speed number
Paddle = {
	width = 5,
	height = 20,
	speed = 200,
}

function Paddle:new(x, y, params)
	local p = {}
	params = params or {}
	setmetatable(p, self)
	self.__index = self

	p.x = x
	p.y = y
	p.dy = 0
	p.width = params.width
	p.height = params.height

	return p
end

function Paddle:render()
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

function Paddle:update(dt)
	if self.dy > 0 then
		self.y = math.min(GAME_HEIGHT - self.height, self.y + self.speed * dt)
	elseif self.dy < 0 then
		self.y = math.max(0, self.y - self.speed * dt)
	end
end

return Paddle
