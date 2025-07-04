local love = require("love")

local SCORE_Y_POS_PCT = 15

local M = {}

M.display_score = function(p1, p2)
	local old_font = love.graphics.getFont()
	local old_color = { love.graphics.getColor() }

	love.graphics.setFont(Font_big)
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

M.display_fps = function()
	local old_font = love.graphics.getFont()
	local old_color = { love.graphics.getColor() }

	love.graphics.setFont(Font_small)
	love.graphics.setColor(0, 1, 0, 1)
	love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 2, 2)

	love.graphics.setColor(old_color)
	love.graphics.setFont(old_font)
end

M.display_ball_speed = function(game_state, ball)
	local old_font = love.graphics.getFont()
	local old_color = { love.graphics.getColor() }

	love.graphics.setFont(Font_small)

	love.graphics.setColor(1, 1, 1, 1)
	local label = "Ball speed: "
	love.graphics.print(label, GAME_WIDTH - 75, 2)

	-- The faster the ball gets, the more "red" the speed will be shown
	local speed = game_state == "play" and ball:speed() or 0
	local speed_n = ball:speed_normalized()
	love.graphics.setColor(1, 1 - math.min(1, speed_n), 1 - math.min(1, speed_n), 1)
	love.graphics.print(speed, GAME_WIDTH - 75 + love.graphics.getFont():getWidth(label), 2)

	love.graphics.setColor(old_color)
	love.graphics.setFont(old_font)
end

---@param type 'alert'|'info'
M.display_message = function(type, msg)
	local old_font = love.graphics.getFont()
	local old_color = { love.graphics.getColor() }

	-- hack to count the number of lines in msg
	local _, n_newlines = string.gsub(msg, "\n", "")
	local n_lines = n_newlines + 1

	-- Big message at the center of the screen
	if type == "alert" then
		-- Blur background, use BG_COLOR with high opacity
		local bg = { unpack(BG_COLOR) }
		table.insert(bg, 240)
		love.graphics.setColor(bg)
		love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

		love.graphics.setFont(Font_big)
		love.graphics.setColor(1, 1, 1, 1)
		local msg_height = love.graphics.getFont():getHeight() * n_lines
		love.graphics.printf(msg, 0, math.floor(GAME_HEIGHT / 2 - msg_height / 2), GAME_WIDTH, "center")
	-- Small message vertically centered between score and top
	elseif type == "info" then
		love.graphics.setFont(Font_small)
		local msg_height = love.graphics.getFont():getHeight() * n_lines
		love.graphics.printf(
			msg,
			0,
			math.floor((GAME_HEIGHT * SCORE_Y_POS_PCT / 100 / 2) - msg_height / 2),
			GAME_WIDTH,
			"center"
		)
	end

	love.graphics.setColor(old_color)
	love.graphics.setFont(old_font)
end

return M
