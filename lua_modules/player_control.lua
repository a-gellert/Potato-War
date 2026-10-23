-- lua_modules/player_control.lua
-- Human player controls for main.script: smooth walking (keyboard & touch), jumping, weapon hotkeys.

local constants = require("lua_modules.constants")
local terrain_grid = require("lua_modules.terrain_grid")
local physics_sim = require("lua_modules.physics_sim")
local game_state = require("lua_modules.game_state")
local tutorial = require("lua_modules.tutorial")

local M = {}

local TOUCH_HOLD_TIME = 0.25

local function is_player_turn()
	return game_state.state == constants.STATE_TURN_ACTIVE and not game_state.is_bot_turn()
end

function M.is_player_turn()
	return is_player_turn()
end

function M.reset(self)
	self.touch_move_dir = 0
	self.touch_move_timer = 0
	self.key_left_held = false
	self.key_right_held = false
end

function M.set_touch_dir(self, dir)
	if is_player_turn() then
		game_state.poki_gameplay_start()
	end
	self.touch_move_dir = dir or 0
	self.touch_move_timer = (self.touch_move_dir ~= 0) and TOUCH_HOLD_TIME or 0
end

function M.jump()
	if not is_player_turn() then
		return
	end
	local potato = game_state.active_potato
	if potato and potato.is_alive and physics_sim.jump_potato(potato, 1) then
		if potato.url then
			msg.post(potato.url, "on_jump")
		end
		tutorial.on_jump()
	end
end

-- Per-frame walking for touch & keyboard
function M.update(self, dt)
	if not is_player_turn() then
		M.reset(self)
		return
	end

	if self.touch_move_timer > 0 then
		self.touch_move_timer = self.touch_move_timer - dt
		if self.touch_move_timer <= 0 then
			self.touch_move_dir = 0
		end
	end

	local move_dir = self.touch_move_dir
	if move_dir == 0 then
		if self.key_left_held and not self.key_right_held then
			move_dir = -1
		elseif self.key_right_held and not self.key_left_held then
			move_dir = 1
		end
	end

	local p = game_state.active_potato
	if move_dir ~= 0 and p and p.is_alive then
		physics_sim.walk_potato(p, move_dir, dt, terrain_grid)
		p.facing = move_dir
		if p.url then
			msg.post(p.url, "set_facing", { facing = move_dir })
			if p.walk_step_time then
				msg.post(p.url, "on_step", { hop = math.abs(math.sin(p.walk_step_time)) })
			end
		end
	end
end

-- Keyboard movement, jump and weapon slot keys. Returns true if the input was consumed.
function M.on_input(self, action_id, action)
	if action_id == hash("left") then
		self.key_left_held = not action.released
	elseif action_id == hash("right") then
		self.key_right_held = not action.released
	end

	if not is_player_turn() then
		return false
	end
	local potato = game_state.active_potato
	if not (potato and potato.is_alive) then
		return false
	end

	if action_id == hash("left") or action_id == hash("right") then
		return true
	elseif action_id == hash("jump") and action.pressed then
		M.jump()
		return true
	end

	-- Weapon selection via slot keys 1..5 (in PvP weapons are selected exclusively via inventory)
	local is_pvp = (game_state.mode == constants.MODE_PVP_BOTS or game_state.mode == constants.MODE_QUICK_PVP)
	if not is_pvp and action.pressed then
		for i = 1, 5 do
			if action_id == hash("weapon_" .. i) then
				game_state.select_slot(i)
				return true
			end
		end
	end
	return false
end

return M
