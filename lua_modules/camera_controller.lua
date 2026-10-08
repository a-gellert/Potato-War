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
	M.zoom = 1.0
	M.target_zoom = 1.0
	M.follow(x, y, true)
end

function M.get_view_matrix()
	return M.view_matrix or vmath.matrix4()
end

-- Focus camera on a target coordinate
function M.follow(x, y, immediate)
	local effective_zoom = math.max(0.65, M.target_zoom or M.zoom or 1.0)
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

-- Add screen shake effect on explosions
function M.shake(amount, duration)
	M.shake_amount = math.max(M.shake_amount, amount or 10.0)
	M.shake_timer = math.max(M.shake_timer, duration or 0.3)
end

-- Set target zoom level (1.0 = normal, >1.0 = zoomed in on projectile)
function M.set_zoom(z)
	M.target_zoom = math.max(0.75, math.min(1.45, z or 1.0))
end

-- Convert world coordinates to screen (GUI) coordinates
function M.world_to_screen(wx, wy)
	local sw = constants.SCREEN_WIDTH
	local sh = constants.SCREEN_HEIGHT
	local sx = (wx - M.pos.x) * M.zoom + sw * 0.5
	local sy = (wy - M.pos.y) * M.zoom + sh * 0.5
	return sx, sy
end

-- Convert screen (GUI) coordinates to world coordinates
function M.screen_to_world(sx, sy)
	local sw = constants.SCREEN_WIDTH
	local sh = constants.SCREEN_HEIGHT
	local wx = (sx - sw * 0.5) / M.zoom + M.pos.x
	local wy = (sy - sh * 0.5) / M.zoom + M.pos.y
	return wx, wy
end

-- Update camera position, zoom, screenshake, and apply view matrix to render pipeline
function M.update(dt)
	-- Smooth position interpolation (8.5x for quick & responsive tracking)
	local lerp_speed = 8.5
	M.pos.x = M.pos.x + (M.target_pos.x - M.pos.x) * math.min(1.0, lerp_speed * dt)
	M.pos.y = M.pos.y + (M.target_pos.y - M.pos.y) * math.min(1.0, lerp_speed * dt)

	-- Smooth zoom interpolation (3.5x for gradual cinematic zoom-in/out)
	M.zoom = M.zoom + (M.target_zoom - M.zoom) * math.min(1.0, 3.5 * dt)

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

	-- Apply view matrix to Defold render pipeline
	local sw = constants.SCREEN_WIDTH
	local sh = constants.SCREEN_HEIGHT
	local z = M.zoom

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
