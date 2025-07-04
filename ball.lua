---@class Ball
---@field radius number
---@field x number
---@field y number
---@field dx -1|0|1
---@field dy -1|0|1
---@field width number
---@field height number
---@field private x_init number
---@field private y_init number
Ball = {}

function Ball:new(radius, params)
	local b = {}
	params = params or {}
	setmetatable(b, self)
	self.__index = self

	b.x_init = params.x or GAME_WIDTH / 2 - radius
	b.y_init = params.y or GAME_HEIGHT / 2 - radius
	b.radius = radius
	b.width = radius * 2
	b.height = radius * 2

	b:reset()

	return b
end

---@param serving_player Player | nil
function Ball:reset(serving_player)
	self.x = self.x_init
	self.y = self.y_init
	self.speed_x = 100
	self.speed_y = math.random(50)
	self.dy = math.random(2) == 1 and 1 or -1

	-- Serving player is undefined
	if serving_player == nil then
		self.dx = math.random(2) == 1 and 1 or -1
	-- Serving player is on the right
	elseif self.x + self.width < serving_player.paddle.x then
		self.dx = 1
	-- Serving player is on the left
	else
		self.dx = -1
	end
end

function Ball:render()
	love.graphics.rectangle("fill", self.x, self.y, self.radius * 2, self.radius * 2)
end

---@param dt number
function Ball:update(dt)
	self.x = self.x + self.dx * self.speed_x * dt
	self.y = self.y + self.dy * self.speed_y * dt
end

---@param paddle Paddle
---@return boolean
function Ball:collides(paddle)
	if self.x + self.width <= paddle.x or self.x >= paddle.x + paddle.width then
		return false
	end

	if self.y + self.height <= paddle.y or self.y >= paddle.y + paddle.height then
		return false
	end

	return true
end

return Ball
