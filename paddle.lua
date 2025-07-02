---@class Paddle
---@field x number
---@field y number
---@field dy -1|0|1
---@field width number
---@field height number
---@field speed number
---@field private x_init number
---@field private y_init number
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

	p.x_init = x
	p.y_init = y
	p.width = params.width
	p.height = params.height

	p:reset()

	return p
end

function Paddle:reset()
	self:reset_position()
	self.score = 0
end

function Paddle:reset_position()
	self.x = self.x_init
	self.y = self.y_init
	self.dy = 0
end

function Paddle:render()
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

function Paddle:update(dt)
	if self.dy == 1 then
		self.y = math.min(GAME_HEIGHT - self.height, self.y + self.speed * dt)
	elseif self.dy == -1 then
		self.y = math.max(0, self.y - self.speed * dt)
	end
end

return Paddle
