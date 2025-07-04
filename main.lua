GAME_WIDTH = 432
GAME_HEIGHT = 243

SCORE_Y_POS_PCT = 15

local WINDOW_WIDTH = 1280
local WINDOW_HEIGHT = 720

local WIN_SCORE = 10

local BALL_RADIUS = 2
-- Above that, collision detection doesn't work
local MAX_BALL_X_SPEED = 700

local font_big
local font_small

local love = require("love")
local push = require("push")
local Ball = require("ball")
local Paddle = require("paddle")
local Player = require("player")

---@type Player, Player, Player
local p1, p2, winner, serving_player
---@type Ball
local ball

local game_state = nil

local function display_fps()
	local old_font = love.graphics.getFont()
	local old_color = { love.graphics.getColor() }

	love.graphics.setFont(font_small)
	love.graphics.setColor(0, 1, 0, 1)
	love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 2, 2)

	love.graphics.setColor(old_color)
	love.graphics.setFont(old_font)
end

local function display_ball_speed()
	local old_font = love.graphics.getFont()
	local old_color = { love.graphics.getColor() }

	love.graphics.setFont(font_small)

	love.graphics.setColor(1, 1, 1, 1)
	local label = "Ball speed: "
	love.graphics.print(label, GAME_WIDTH - 75, 2)

	-- The faster the ball gets, the more "red" the speed will be shown
	local speed = game_state == "play" and ball:speed() or 0
	local speed_normalized = speed / 500
	love.graphics.setColor(1, 1 - math.min(1, speed_normalized), 1 - math.min(1, speed_normalized), 1)
	love.graphics.print(speed, GAME_WIDTH - 75 + love.graphics.getFont():getWidth(label), 2)

	love.graphics.setColor(old_color)
	love.graphics.setFont(old_font)
end

local function opponent(p)
	if p == p1 then
		return p2
	else
		return p1
	end
end

local function display_score()
	local old_font = love.graphics.getFont()
	local old_color = { love.graphics.getColor() }

	love.graphics.setFont(font_big)
	love.graphics.printf(
		p1.score .. "\t" .. p2.score,
		0,
		math.floor(GAME_HEIGHT * SCORE_Y_POS_PCT / 100),
		GAME_WIDTH,
		"center"
	)

	love.graphics.setColor(old_color)
	love.graphics.setFont(old_font)
end

local function reset_game()
	ball:reset()
	p1:reset()
	p2:reset()
end

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")

	font_big = love.graphics.newFont("font.ttf", 32)
	font_small = love.graphics.newFont("font.ttf", 8)

	ball = Ball:new(BALL_RADIUS)
	p1 = Player:new("Player 1", 10, 10, function()
		return ball.x + ball.width > GAME_WIDTH
	end)
	p2 = Player:new("Player 2", GAME_WIDTH - 10, GAME_HEIGHT - Paddle.height - 10, function()
		return ball.x < 0
	end)

	love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
		resizable = false,
		vsync = true,
		fullscreen = false,
	})
	push.setupScreen(GAME_WIDTH, GAME_HEIGHT, { upscale = "normal" })

	math.randomseed(os.time())

	love.window.setTitle("Pong")

	reset_game()
	game_state = "start"
end

function love.keypressed(key)
	if key == "q" then
		love.event.quit()
	end

	if game_state == "start" then
		if key == "space" then
			game_state = "play"
		end
	elseif game_state == "play" then
		if key == "escape" then
			game_state = "paused"
		end
	elseif game_state == "paused" then
		if key == "escape" then
			game_state = "play"
		end
	elseif game_state == "end" then
		if key == "space" then
			reset_game()
			game_state = "start"
		end
	end
end

function love.update(dt)
	for _, player in pairs({ p1, p2 }) do
		local paddle = player.paddle
		-- Paddle collision
		if ball:collides(paddle) then
			-- Reverse dx
			ball.dx = -ball.dx
			-- Speed up ball a little
			ball.speed_x = math.min(MAX_BALL_X_SPEED, ball.speed_x * 1.15)

			-- snap the ball to the right/left edge of the paddle, to avoid infinite collission
			if ball.dx > 0 then
				ball.x = paddle.x + paddle.width
			else
				ball.x = paddle.x - ball.width
			end

			-- Add some random to speed_y for fun
			ball.speed_y = ball.speed_y * math.random(50, 200) / 100
		end

		-- Scoring
		if player:scored() then
			player.score = player.score + 1
			if player.score >= WIN_SCORE then
				winner = player
				ball:reset()
				game_state = "end"
			else
				p1:reset_paddle()
				p2:reset_paddle()

				-- Give service to the player who just lost the point
				serving_player = opponent(player)
				ball:reset(serving_player)

				game_state = "start"
			end
		end
	end

	-- Up/down collision
	if ball.y < 0 then
		ball.y = 0
		ball.dy = -ball.dy
	elseif ball.y + ball.height > GAME_HEIGHT then
		ball.y = GAME_HEIGHT - ball.height
		ball.dy = -ball.dy
	end

	-- p1
	p1.paddle.dy = 0
	if love.keyboard.isDown("w") then
		p1.paddle.dy = p1.paddle.dy - 1
	end
	if love.keyboard.isDown("s") then
		p1.paddle.dy = p1.paddle.dy + 1
	end

	-- p2
	p2.paddle.dy = 0
	if love.keyboard.isDown("up") then
		p2.paddle.dy = p2.paddle.dy - 1
	end
	if love.keyboard.isDown("down") then
		p2.paddle.dy = p2.paddle.dy + 1
	end

	p1.paddle:update(dt)
	p2.paddle:update(dt)
	if game_state == "play" then
		ball:update(dt)
	end
end

local function bg_color(params)
	params = params or {}
	return love.math.colorFromBytes(40, 45, 52, params.alpha)
end

local function print_center_message(msg)
	local old_font = love.graphics.getFont()
	local old_color = { love.graphics.getColor() }

	love.graphics.setFont(font_big)
	love.graphics.setColor(bg_color({ alpha = 240 }))
	love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)
	love.graphics.printf(msg, 0, (GAME_HEIGHT - love.graphics.getFont():getHeight()) / 2, GAME_WIDTH, "center")

	love.graphics.setColor(old_color)
	love.graphics.setFont(old_font)
end

function love.draw()
	push.start()
	love.graphics.setColor(love.math.colorFromBytes(255, 255, 255, 255))
	love.graphics.clear(bg_color())
	display_fps()
	display_ball_speed()
	display_score()

	p1.paddle:render()
	p2.paddle:render()
	ball:render()

	if game_state == "paused" then
		print_center_message("PAUSED")
	elseif game_state == "end" then
		print_center_message(winner.name .. " WINS !")
	end

	push.finish()
end
