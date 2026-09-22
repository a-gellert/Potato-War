-- lua_modules/camera_controller.lua
-- Smooth camera tracking, screenshake, and viewport adaptation for Potato War

local constants = require("lua_modules.constants")

local M = {}

M.pos = vmath.vector3(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5, 0)
M.target_pos = vmath.vector3(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5, 0)
M.shake_amount = 0
M.shake_timer = 0
M.zoom = 1.0
M.target_zoom = 1.0
M.camera_id = nil

function M.init(camera_url)
	M.camera_id = camera_url or msg.url("camera")
	M.pos = vmath.vector3(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5, 0)
	M.target_pos = vmath.vector3(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5, 0)
	M.shake_amount = 0
	M.shake_timer = 0
	M.zoom = 1.0
	M.target_zoom = 1.0
end

-- Focus camera on a target coordinate
function M.follow(x, y, immediate)
	x = math.max(constants.SCREEN_WIDTH * 0.4, math.min(constants.WORLD_WIDTH - constants.SCREEN_WIDTH * 0.4, x))
	y = math.max(constants.SCREEN_HEIGHT * 0.4, math.min(constants.WORLD_HEIGHT - constants.SCREEN_HEIGHT * 0.4, y))

	M.target_pos.x = x
	M.target_pos.y = y

	if immediate then
		M.pos.x = x
		M.pos.y = y
	end
end

-- Add screen shake effect on explosions
function M.shake(amount, duration)
	M.shake_amount = math.max(M.shake_amount, amount or 10.0)
	M.shake_timer = math.max(M.shake_timer, duration or 0.3)
end

-- Set target zoom level
function M.set_zoom(z)
	M.target_zoom = math.max(0.75, math.min(1.5, z or 1.0))
end

-- Update camera position and shake
function M.update(dt)
	-- Smooth position interpolation
	local lerp_speed = 6.0
	M.pos.x = M.pos.x + (M.target_pos.x - M.pos.x) * math.min(1.0, lerp_speed * dt)
	M.pos.y = M.pos.y + (M.target_pos.y - M.pos.y) * math.min(1.0, lerp_speed * dt)

	-- Smooth zoom interpolation
	M.zoom = M.zoom + (M.target_zoom - M.zoom) * math.min(1.0, 4.0 * dt)

	-- Calculate shake offset
	local shake_x = 0
	local shake_y = 0
	if M.shake_timer > 0 then
		M.shake_timer = M.shake_timer - dt
		local decay = M.shake_timer / 0.3
		shake_x = (math.random() - 0.5) * 2.0 * M.shake_amount * decay
		shake_y = (math.random() - 0.5) * 2.0 * M.shake_amount * decay
		if M.shake_timer <= 0 then
			M.shake_amount = 0
		end
	end

	local render_x = M.pos.x + shake_x
	local render_y = M.pos.y + shake_y

	-- Update camera game object position if exists
	if M.camera_id then
		pcall(function()
			go.set_position(vmath.vector3(render_x, render_y, 0), M.camera_id)
		end)
	end

	return render_x, render_y, M.zoom
end

return M
