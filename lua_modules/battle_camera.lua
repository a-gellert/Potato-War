-- lua_modules/battle_camera.lua
-- Battle camera director for main.script: intro flyover, Worms-style damage focus,
-- projectile tracking, aiming lead and the victory celebration.

local constants = require("lua_modules.constants")
local terrain_grid = require("lua_modules.terrain_grid")
local game_state = require("lua_modules.game_state")
local camera_controller = require("lua_modules.camera_controller")
local tutorial = require("lua_modules.tutorial")

local M = {}

local FLYOVER_ZOOM = 0.82
local VICTORY_ZOOM = 1.42
local DAMAGE_ZOOM = 1.38
local AIM_ZOOM = 0.67 -- Zoomed out further while aiming to see wider trajectory
local PROJECTILE_ZOOM = 1.55 -- 50% closer dramatic close-up tracking
local TUTORIAL_AIM_ZOOM = 0.95
local TUTORIAL_PROJECTILE_ZOOM = 1.60
local VICTORY_JUMP_INTERVAL = 0.55

function M.init(self)
	self.victory_celebration = false
	self.victory_timer = 0
	self.victory_jump_timer = 0
	self.victory_potato = nil
	self.pending_game_over_data = nil
	self.damage_focus = nil
	self.intro_flyover = false
	self.intro_flyover_timer = 0
	self.intro_flyover_duration = 2.0
end

local function snap_to_active()
	local p = game_state.active_potato
	if p and p.is_alive then
		camera_controller.follow(p.pos.x, p.pos.y, true)
	end
	camera_controller.set_zoom(1.0)
end

-- 2-second pan from the right edge to the first active potato to showcase the battlefield
function M.start_flyover(self)
	local active = game_state.active_potato
	local start_x = math.min(constants.WORLD_WIDTH - 240, 1620)
	local start_y = math.max(270, math.min(constants.WORLD_HEIGHT - 200, terrain_grid.get_smooth_ground_y(start_x, 4.0) + 90))

	self.intro_flyover = true
	self.intro_flyover_timer = 2.0
	self.intro_flyover_duration = 2.0
	self.intro_cam_start_x = start_x
	self.intro_cam_start_y = start_y
	self.intro_cam_dest_x = active and active.pos.x or 350
	self.intro_cam_dest_y = active and active.pos.y or 270

	camera_controller.reset(start_x, start_y)
	camera_controller.set_zoom(FLYOVER_ZOOM)
end

-- Returns true if a running flyover was skipped
function M.skip_flyover(self)
	if not self.intro_flyover then
		return false
	end
	self.intro_flyover = false
	snap_to_active()
	return true
end

function M.focus_damage(self, x, y, potato_id)
	self.damage_focus = { x = x, y = y, timer = 1.5, potato_id = potato_id }
end

function M.is_settled(self)
	return self.damage_focus == nil
end

-- Zoom on the victorious potato with jumps; the result screen opens afterwards
function M.start_victory(self, game_over_data)
	local winner = nil
	for _, p in ipairs(game_state.potatoes) do
		if p.team == constants.TEAM_BLUE and p.is_alive then
			winner = p
			break
		end
	end

	self.victory_celebration = true
	self.victory_timer = game_over_data.seamless and 0.8 or 2.4
	self.victory_jump_timer = VICTORY_JUMP_INTERVAL
	self.victory_potato = winner
	self.pending_game_over_data = game_over_data

	if winner then
		camera_controller.follow(winner.pos.x, winner.pos.y)
		camera_controller.set_zoom(VICTORY_ZOOM)
		if winner.url then
			msg.post(winner.url, "on_jump")
		end
	end
end

function M.cancel_victory(self)
	self.victory_celebration = false
	self.pending_game_over_data = nil
end

local function update_victory(self, dt)
	self.victory_timer = self.victory_timer - dt
	self.victory_jump_timer = (self.victory_jump_timer or VICTORY_JUMP_INTERVAL) - dt
	if self.victory_jump_timer <= 0 then
		self.victory_jump_timer = VICTORY_JUMP_INTERVAL
		if self.victory_potato and self.victory_potato.url then
			msg.post(self.victory_potato.url, "on_jump")
		end
	end

	if self.victory_potato and self.victory_potato.is_alive then
		camera_controller.follow(self.victory_potato.pos.x, self.victory_potato.pos.y)
		camera_controller.set_zoom(VICTORY_ZOOM)
	end

	if self.victory_timer <= 0 then
		self.victory_celebration = false
		msg.post("/gui_game_over", "enable")
		if self.pending_game_over_data then
			msg.post("/gui_game_over#gui", "show_result") -- payload in match_results.last
			self.pending_game_over_data = nil
		end
	end
end

local function update_flyover(self, dt)
	self.intro_flyover_timer = self.intro_flyover_timer - dt
	local t = 1.0 - math.max(0, self.intro_flyover_timer / (self.intro_flyover_duration or 2.0))
	local ease = t * t * (3.0 - 2.0 * t) -- Smoothstep easing
	local cur_x = self.intro_cam_start_x + (self.intro_cam_dest_x - self.intro_cam_start_x) * ease
	local cur_y = self.intro_cam_start_y + (self.intro_cam_dest_y - self.intro_cam_start_y) * ease

	camera_controller.follow(cur_x, cur_y, true)
	camera_controller.set_zoom(FLYOVER_ZOOM + (1.0 - FLYOVER_ZOOM) * ease)

	if self.intro_flyover_timer <= 0 then
		self.intro_flyover = false
		snap_to_active()
	end
end

local function update_damage_focus(self, dt)
	-- Linger at the damage location with zoom-in, tracking the potato if the blast moves it
	local focus = self.damage_focus
	focus.timer = focus.timer - dt

	local focus_x, focus_y = focus.x, focus.y
	if focus.potato_id then
		for _, p in ipairs(game_state.potatoes) do
			if p.id == focus.potato_id then
				focus_x, focus_y = p.pos.x, p.pos.y
				break
			end
		end
	end

	camera_controller.follow(focus_x, focus_y)
	camera_controller.set_zoom(DAMAGE_ZOOM)

	if focus.timer <= 0 then
		self.damage_focus = nil
	end
end

local function update_turn(self)
	local p = game_state.active_potato
	if tutorial.is_active() and tutorial.tutorial_level == 1 and tutorial.stage ~= "move" and tutorial.stage ~= "jump" then
		-- In level 1 tutorial (aim & shoot): zoom in close-up and center on player & enemy
		local target = nil
		for _, other in ipairs(game_state.potatoes or {}) do
			if other.team == constants.TEAM_RED and other.is_alive then
				target = other
				break
			end
		end
		local cx = p.pos.x
		local cy = p.pos.y
		if target then
			cx = p.pos.x * 0.55 + target.pos.x * 0.45
			cy = (p.pos.y + target.pos.y) * 0.5 + 24
		end
		camera_controller.follow(cx, cy)
		camera_controller.set_zoom(game_state.is_aiming and TUTORIAL_AIM_ZOOM or 1.22)
		return
	end

	if game_state.is_aiming and not game_state.is_bot_turn() then
		-- Zoom out while aiming and lead the camera towards the crosshair (60% potato + 40% aim point)
		local target_x, target_y = p.pos.x, p.pos.y
		if game_state.aim_target_x and game_state.aim_target_y then
			target_x = p.pos.x * 0.60 + game_state.aim_target_x * 0.40
			target_y = (p.pos.y + 12) * 0.60 + game_state.aim_target_y * 0.40
		end
		camera_controller.follow(target_x, target_y)
		camera_controller.set_zoom(AIM_ZOOM)
	else
		camera_controller.follow(p.pos.x, p.pos.y)
		camera_controller.set_zoom(1.0)
	end
end

function M.update(self, dt)
	if self.victory_celebration then
		update_victory(self, dt)
		return
	end

	local in_action = (game_state.state == constants.STATE_ACTION or game_state.state == constants.STATE_SETTLING)

	if self.intro_flyover then
		update_flyover(self, dt)
	elseif self.damage_focus and self.damage_focus.timer > 0 then
		update_damage_focus(self, dt)
	elseif in_action and #self.active_projectiles > 0 then
		-- Flying projectile tracking: smooth 50% closer zoom
		local ok, ppos = pcall(go.get_position, self.active_projectiles[#self.active_projectiles])
		if ok and ppos then
			camera_controller.follow(ppos.x, ppos.y)
			camera_controller.set_zoom(tutorial.is_active() and TUTORIAL_PROJECTILE_ZOOM or PROJECTILE_ZOOM)
		end
	elseif in_action then
		-- Projectiles exploded and settling: hold the camera, do NOT snap back to the shooter
	elseif game_state.state == constants.STATE_TURN_ACTIVE and game_state.active_potato and game_state.active_potato.is_alive then
		update_turn(self)
	else
		camera_controller.set_zoom(1.0)
	end
end

return M
