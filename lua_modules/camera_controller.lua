-- lua_modules/camera_controller.lua
-- Smooth camera tracking, projectile chase zoom, screenshake, and viewport adaptation for Potato War

local constants = require("lua_modules.constants")

local M = {}

M.pos = vmath.vector3(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5, 0)
M.target_pos = vmath.vector3(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5, 0)
M.shake_amount = 0
M.shake_timer = 0
M.zoom = 1.0
M.target_zoom = 1.0
M.camera_id = nil
M.view_matrix = vmath.matrix4()

function M.init(camera_url)
	M.camera_id = camera_url or msg.url("camera")
	M.reset(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5)
end

-- Reset camera to standard default zoom and position
function M.reset(x, y)
	x = x or (constants.SCREEN_WIDTH * 0.5)
	y = y or (constants.SCREEN_HEIGHT * 0.5)
	M.pos.x = x
	M.pos.y = y
	M.target_pos.x = x
	M.target_pos.y = y
	M.shake_amount = 0
	M.shake_timer = 0
	M.punch = 0
	M.zoom = 1.0
	M.target_zoom = 1.0
	M.follow(x, y, true)
end

function M.get_view_matrix()
	return M.view_matrix or vmath.matrix4()
end

-- Focus camera on a target coordinate
function M.follow(x, y, immediate)
	local effective_zoom = math.max(0.55, M.target_zoom or M.zoom or 1.0)
	local half_w = (constants.SCREEN_WIDTH * 0.5) / effective_zoom
	local half_h = (constants.SCREEN_HEIGHT * 0.5) / effective_zoom

	local cur_w = constants.WORLD_WIDTH -- 1920
	local max_h = constants.WORLD_HEIGHT + 350 -- High sky altitude for flying projectiles and sky islands

	local min_x = half_w - 60
	local max_x = cur_w - half_w + 60
	local min_y = half_h - 40
	local max_y = max_h - half_h + 80

	x = math.max(min_x, math.min(max_x, x))
	y = math.max(min_y, math.min(max_y, y))

	M.target_pos.x = x
	M.target_pos.y = y

	if immediate then
		M.pos.x = x
		M.pos.y = y
	end
end

M.shake_duration = 0.3
M.shake_phase = 0
M.punch = 0 -- extra zoom kick from big blasts, decays back to 0

-- Add screen shake effect on explosions
function M.shake(amount, duration)
	amount = amount or 10.0
	duration = duration or 0.3
	-- A new shake only overrides the rest of the current one when it is stronger
	local remaining = (M.shake_timer > 0) and M.shake_amount * (M.shake_timer / M.shake_duration) or 0
	if amount >= remaining then
		M.shake_amount = amount
		M.shake_timer = duration
		M.shake_duration = duration
	end
	-- Big blasts also kick the zoom in for a moment
	if amount >= 10 then
		M.punch = math.max(M.punch, math.min(0.08, amount * 0.0025))
	end
end

-- Set target zoom level (1.0 = normal, >1.0 = zoomed in on projectile)
function M.set_zoom(z)
	M.target_zoom = math.max(0.55, math.min(2.0, z or 1.0))
end

-- Convert world coordinates to screen (GUI) coordinates
function M.world_to_screen(wx, wy)
	local sw = constants.SCREEN_WIDTH
	local sh = constants.SCREEN_HEIGHT
	local sx = (wx - M.pos.x) * M.zoom * (1 + M.punch) + sw * 0.5
	local sy = (wy - M.pos.y) * M.zoom * (1 + M.punch) + sh * 0.5
	return sx, sy
end

-- Convert screen (GUI) coordinates to world coordinates
function M.screen_to_world(sx, sy)
	local sw = constants.SCREEN_WIDTH
	local sh = constants.SCREEN_HEIGHT
	local wx = (sx - sw * 0.5) / (M.zoom * (1 + M.punch)) + M.pos.x
	local wy = (sy - sh * 0.5) / (M.zoom * (1 + M.punch)) + M.pos.y
	return wx, wy
end

-- Update camera position, zoom, screenshake, and apply view matrix to render pipeline
function M.update(dt)
	-- Smooth position interpolation (8.5x for quick & responsive tracking)
	local lerp_speed = 8.5
	M.pos.x = M.pos.x + (M.target_pos.x - M.pos.x) * math.min(1.0, lerp_speed * dt)
	M.pos.y = M.pos.y + (M.target_pos.y - M.pos.y) * math.min(1.0, lerp_speed * dt)

	-- Smooth zoom interpolation (3.8x for gradual cinematic zoom-in/out)
	M.zoom = M.zoom + (M.target_zoom - M.zoom) * math.min(1.0, 3.8 * dt)

	-- Shake: smooth sum-of-sines wobble, eased out over the shake's own duration
	local shake_x = 0
	local shake_y = 0
	if M.shake_timer > 0 then
		M.shake_timer = math.max(0, M.shake_timer - dt)
		M.shake_phase = M.shake_phase + dt
		local k = M.shake_timer / math.max(0.01, M.shake_duration)
		local amp = M.shake_amount * k * k
		local t = M.shake_phase
		shake_x = amp * (0.6 * math.sin(t * 47.0) + 0.4 * math.sin(t * 83.0 + 1.3))
		shake_y = amp * (0.6 * math.sin(t * 53.0 + 2.1) + 0.4 * math.sin(t * 71.0 + 0.4))
		if M.shake_timer <= 0 then
			M.shake_amount = 0
		end
	end
	M.punch = M.punch * math.exp(-9.0 * dt)

	local render_x = M.pos.x + shake_x
	local render_y = M.pos.y + shake_y

	-- Update camera game object position if exists
	if M.camera_id then
		pcall(function()
			go.set_position(vmath.vector3(render_x, render_y, 0), M.camera_id)
		end)
	end

	-- Apply view matrix to Defold render pipeline
	local sw = constants.SCREEN_WIDTH
	local sh = constants.SCREEN_HEIGHT
	local z = M.zoom * (1 + M.punch)

	local view = vmath.matrix4_translation(vmath.vector3(sw * 0.5, sh * 0.5, 0))
		* vmath.matrix4_scale(vmath.vector3(z, z, 1))
		* vmath.matrix4_translation(vmath.vector3(-render_x, -render_y, 0))

	M.view_matrix = view

	pcall(function()
		msg.post("@render:", "set_view_projection", {
			view = view
		})
	end)

	return render_x, render_y, M.zoom
end

return M
