GAME_WIDTH = 432
GAME_HEIGHT = 243

BG_COLOR = { 40 / 255, 45 / 255, 52 / 255 }

local WINDOW_WIDTH = 1280
local WINDOW_HEIGHT = 720

local WIN_SCORE = 10

local BALL_RADIUS = 2
-- Above that, collision detection doesn't work
local MAX_BALL_X_SPEED = 700

---@type love.Font
Font_small = nil
---@type love.Font
Font_big = nil

local love = require("love")
local push = require("push")
local Ball = require("ball")
local Paddle = require("paddle")
local Player = require("player")
local hud = require("hud")

local paddle_sound = love.audio.newSource("sounds/paddle_hit.wav", "static")
local scored_sound = love.audio.newSource("sounds/scored.wav", "static")
local start_sound = love.audio.newSource("sounds/start.wav", "static")
local win_sound = love.audio.newSource("sounds/win.wav", "static")

---@type Player, Player, Player
local p1, p2, winner, serving_player
---@type Ball
local ball

local game_state = nil

local function running_from_web()
	return love.system.getOS() == "Web"
end

local function opponent(p)
	if p == p1 then
		return p2
	else
		return p1
	end
end

local function reset_game()
	ball:reset()
	p1:reset()
	p2:reset()
end

local function quit_game_if_possible()
	if running_from_web() then
		return
	end
	love.event.quit()
end

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")

	Font_big = love.graphics.newFont("font.ttf", 32)
	Font_small = love.graphics.newFont("font.ttf", 8)

	ball = Ball:new(BALL_RADIUS)
	p1 = Player:new("Player 1", 10, 10, function()
		return ball.x + ball.width > GAME_WIDTH
	end)
	p2 = Player:new("Player 2", GAME_WIDTH - 10, GAME_HEIGHT - Paddle.height - 10, function()
		return ball.x < 0
	end)

	love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
		resizable = true,
		vsync = true,
		fullscreen = false,
	})
	push.setupScreen(GAME_WIDTH, GAME_HEIGHT, { upscale = "normal" })

	math.randomseed(os.time())

	love.window.setTitle("Pong")

	reset_game()
	game_state = "start"
	start_sound:play()
end

function love.keypressed(key)
	if game_state == "start" then
		if key == "space" then
			game_state = "play"
		elseif key == "q" then
			quit_game_if_possible()
		end
	elseif game_state == "play" then
		if key == "space" then
			game_state = "paused"
		end
	elseif game_state == "serve" then
		if key == "space" then
			game_state = "play"
		elseif key == "q" then
			quit_game_if_possible()
		end
	elseif game_state == "paused" then
		if key == "space" then
			game_state = "play"
		elseif key == "q" then
			quit_game_if_possible()
		end
	elseif game_state == "end" then
		if key == "space" then
			reset_game()
			game_state = "start"
			start_sound:play()
		elseif key == "q" then
			quit_game_if_possible()
		end
	end
end

function love.resize(w, h)
	push.resize(w, h)
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

			-- Play sound
			paddle_sound:play()
			paddle_sound:setPitch(1 + ball:speed_normalized() / 2)
		end

		-- Scoring
		if player:scored() then
			player.score = player.score + 1
			if player.score >= WIN_SCORE then
				winner = player
				ball:reset()
				win_sound:play()
				game_state = "end"
			else
				p1:reset_paddle()
				p2:reset_paddle()

				-- Give service to the player who just lost the point
				serving_player = opponent(player)
				ball:reset(serving_player)

				scored_sound:play()

				game_state = "serve"
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

local function show_state_info()
	local alert = nil
	local info = nil
	if game_state == "paused" then
		alert = "PAUSED"
		info = "Press space to resume"
	elseif game_state == "end" then
		alert = winner.name .. " WINS !"
		info = "Press space to play again"
	elseif game_state == "start" then
		info = "Welcome to Pong\nPress space to start"
	elseif game_state == "play" then
		info = "Press space to pause"
	elseif game_state == "serve" then
		info = "Service to " .. serving_player.name .. "\nPress space to play"
	end

	if alert ~= nil then
		hud.display_message("alert", alert)
	end
	if info ~= nil then
		if game_state ~= "play" and not running_from_web() then
			info = info .. "\nPress q to quit"
		end
		hud.display_message("info", info)
	end
end

function love.draw()
	push.start()

	love.graphics.setColor(love.math.colorFromBytes(255, 255, 255, 255))
	love.graphics.clear(BG_COLOR)

	hud.display_fps()
	hud.display_ball_speed(game_state, ball)
	hud.display_score(p1, p2)

	p1.paddle:render()
	p2.paddle:render()
	ball:render()

	show_state_info()

	push.finish()
end
