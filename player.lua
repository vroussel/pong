local Paddle = require("paddle")

---@class Player
---@field name string
---@field score number
---@field paddle Paddle
---@field private scored_pred function
Player = {}

function Player:new(name, paddle_x, paddle_y, scored_pred, params)
	local p = {}
	params = params or {}
	setmetatable(p, self)
	self.__index = self

	p.name = name
	p.score = 0
	p.scored_pred = scored_pred
	p.paddle = Paddle:new(paddle_x, paddle_y, params.paddle)

	return p
end

function Player:reset_score()
	self.score = 0
end

function Player:reset_paddle()
	self.paddle:reset()
end

function Player:reset()
	self:reset_paddle()
	self:reset_score()
end

function Player:scored()
	return self.scored_pred()
end

return Player
