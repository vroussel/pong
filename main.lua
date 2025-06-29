GAME_WIDTH = 432
GAME_HEIGHT = 243

local WINDOW_WIDTH = 1280
local WINDOW_HEIGHT = 720

local BALL_RADIUS = 2

local font_big
local font_small

local love = require("love")
local push = require("push")
local Ball = require("ball")
local Paddle = require("paddle")

---@type Paddle, Paddle
local p1, p2
---@type Ball
local ball

local game_state = nil

local function display_fps()
	love.graphics.setFont(font_small)
	love.graphics.setColor(0, 1, 0, 1)
	love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 2, 2)
	love.graphics.setColor(1, 1, 1, 1)
end

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")

	font_big = love.graphics.newFont("font.ttf", 32)
	font_small = love.graphics.newFont("font.ttf", 8)

	ball = Ball:new(BALL_RADIUS)
	p1 = Paddle:new(10, 10, "Player 1")
	p2 = Paddle:new(GAME_WIDTH - 10, GAME_HEIGHT - Paddle.height - 10, "Player 2")

	love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
		resizable = false,
		vsync = true,
		fullscreen = false,
	})
	push.setupScreen(GAME_WIDTH, GAME_HEIGHT, { upscale = "normal" })

	math.randomseed(os.time())

	love.window.setTitle("Pong")

	game_state = "start"
end

function love.keypressed(key)
	if key == "q" then
		love.event.quit()
	elseif key == "space" then
		if game_state == "start" then
			game_state = "play"
		end
	elseif key == "escape" then
		if game_state == "play" then
			game_state = "paused"
		elseif game_state == "paused" then
			game_state = "play"
		end
	end
end

function love.update(dt)
	-- Paddle collision
	for _, p in pairs({ p1, p2 }) do
		if ball:collides(p) then
			-- Reverse dx
			ball.dx = -ball.dx
			-- Speed up ball a little
			ball.speed_x = ball.speed_x * 1.15

			-- snap the ball to the right/left edge of the paddle, to avoid infinite collission
			if ball.dx > 0 then
				ball.x = p.x + p.width
			else
				ball.x = p.x - ball.width
			end

			-- Add some random to speed_y for fun
			ball.speed_y = ball.speed_y * math.random(50, 200) / 100
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
	p1.dy = 0
	if love.keyboard.isDown("w") then
		p1.dy = p1.dy - 1
	end
	if love.keyboard.isDown("s") then
		p1.dy = p1.dy + 1
	end

	-- p2
	p2.dy = 0
	if love.keyboard.isDown("up") then
		p2.dy = p2.dy - 1
	end
	if love.keyboard.isDown("down") then
		p2.dy = p2.dy + 1
	end

	if game_state == "play" then
		p1:update(dt)
		p2:update(dt)
		ball:update(dt)
	end
end

function love.draw()
	push.start()
	love.graphics.setColor(love.math.colorFromBytes(255, 255, 255, 255))
	love.graphics.clear(love.math.colorFromBytes(40, 45, 52))
	display_fps()
	love.graphics.setFont(font_big)
	love.graphics.printf(p1.score .. "\t" .. p2.score, 0, math.floor(GAME_HEIGHT / 6), GAME_WIDTH, "center")

	p1:render()
	p2:render()
	ball:render()

	if game_state == "paused" then
		love.graphics.setColor(love.math.colorFromBytes(40, 45, 52, 240))
		love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("PAUSED", 0, (GAME_HEIGHT - love.graphics.getFont():getHeight()) / 2, GAME_WIDTH, "center")
	end

	push.finish()
end
