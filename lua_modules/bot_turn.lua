-- lua_modules/bot_turn.lua
-- Worms-style bot turn state machine driven from main.script update.
-- States:
-- "survey": looks around, pauses, assesses surrounding threats & footing
-- "move": walks towards target/cover, dynamically climbing or jumping over obstacles
-- "assess": deliberate pause after moving to evaluate the chosen vantage point
-- "aim": equips weapon, stepped aiming (overshoots and corrects back) with reticle preview
-- "shoot": fires weapon with recoil
-- "retreat": tactical retreat into bunker/depression away from explosion/water

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")
local terrain_grid = require("lua_modules.terrain_grid")
local physics_sim = require("lua_modules.physics_sim")
local bot_ai = require("lua_modules.bot_ai")
local game_state = require("lua_modules.game_state")

local M = {}

local STEP_TIME = 0.08

local function set_facing(bot, facing)
	bot.facing = facing
	if bot.url then
		msg.post(bot.url, "set_facing", { facing = facing })
	end
end

local function walk(bot, dir, dt)
	physics_sim.walk_potato(bot, dir, dt, terrain_grid)
	set_facing(bot, dir)
	if bot.url and bot.walk_step_time then
		msg.post(bot.url, "on_step", { hop = math.abs(math.sin(bot.walk_step_time)) })
	end
end

local function jump(bot)
	if physics_sim.jump_potato(bot) and bot.url then
		msg.post(bot.url, "on_jump")
	end
end

function M.reset(self)
	self.bot_thinking = false
	self.bot_plan = nil
	self.bot_state = nil
end

local function plan_turn(self, bot)
	local config = game_state.get_current_config()
	local bot_skill = config.enemy_skill or config.bot_difficulty or "normal"
	if game_state.mode == constants.MODE_PVP_BOTS or game_state.mode == constants.MODE_QUICK_PVP or bot_skill == "hard" then
		self.bot_plan = bot_ai.plan_pvp_turn(bot, game_state.potatoes, terrain_grid, bot_skill, game_state.wind_vector)
	else
		self.bot_plan = bot_ai.plan_turn(bot, game_state.potatoes, terrain_grid, bot_skill, game_state.wind_vector)
	end

	-- Start in SURVEY state (Worms style: looking left and right, checking position)
	self.bot_state = "survey"
	self.bot_survey_timer = 0.55 + math.random() * 0.35
	self.bot_survey_flips = 0
	self.bot_survey_flip_timer = 0.22
	self.bot_move_steps_done = 0
	self.bot_move_timer = 0
	self.bot_move_jumped = false
	self.bot_aim_timer = 0
	self.bot_aim_total = 0
	self.bot_overshoot_angle = (math.random() > 0.5 and 0.08 or -0.08)
	self.bot_retreat_steps = 0
	self.bot_retreat_done = 0

	if self.bot_plan and bot.url then
		msg.post(bot.url, "set_facing", { facing = bot.facing or -1 })
	end
end

local function begin_aim(self, bot, aim_total)
	self.bot_state = "aim"
	self.bot_aim_total = aim_total
	self.bot_aim_timer = aim_total
	self.bot_overshoot_angle = (math.random() > 0.5 and 0.09 or -0.09)
	game_state.select_weapon(self.bot_plan.weapon_id)
	set_facing(bot, (self.bot_plan.aim_dx >= 0) and 1 or -1)
	if bot.url then
		msg.post(bot.url, "set_weapon", { weapon_id = self.bot_plan.weapon_id })
	end
end

local function update_survey(self, bot, dt)
	-- Bot turns left/right inquisitively before committing to action
	self.bot_survey_timer = self.bot_survey_timer - dt
	self.bot_survey_flip_timer = self.bot_survey_flip_timer - dt

	if self.bot_survey_flip_timer <= 0 and self.bot_survey_flips < 2 then
		self.bot_survey_flip_timer = 0.25
		self.bot_survey_flips = self.bot_survey_flips + 1
		set_facing(bot, -bot.facing)
	end

	if self.bot_survey_timer <= 0 then
		local move = self.bot_plan.movement
		if move and move.steps and move.steps > 0 then
			self.bot_state = "move"
			self.bot_move_steps_done = 0
			self.bot_move_timer = 0
			set_facing(bot, move.dir)
		else
			local plan = self.bot_plan
			begin_aim(self, bot, plan.is_pvp_bot and (plan.aim_delay or 0.85) or (plan.think_delay or 0.70))
		end
	end
end

local function update_move(self, bot, dt)
	-- Walk towards desired spot, climb slopes and jump rims
	local move = self.bot_plan.movement
	if move and move.steps > 0 and self.bot_move_steps_done < move.steps then
		self.bot_move_timer = self.bot_move_timer + dt

		if move.dir ~= 0 then
			walk(bot, move.dir, dt)

			-- Dynamic step climbing / obstacle clearing
			local ground_ahead_y = terrain_grid.get_smooth_ground_y(bot.pos.x + move.dir * 12.0, 4.0)
			local step_diff = ground_ahead_y - bot.pos.y
			if step_diff > 7.0 and step_diff <= 36.0 and bot.is_grounded then
				jump(bot)
				self.bot_move_jumped = true
			end
		end

		if self.bot_move_timer >= STEP_TIME then
			self.bot_move_timer = self.bot_move_timer - STEP_TIME
			self.bot_move_steps_done = self.bot_move_steps_done + 1
		end

		-- Mid-movement jump if obstacle or planned
		if move.should_jump and not self.bot_move_jumped and bot.is_grounded and self.bot_move_steps_done >= math.floor(move.steps * 0.3) then
			jump(bot)
			self.bot_move_jumped = true
		end

		if bot.url then
			go.set_position(bot.pos, bot.url)
		end
	else
		-- Movement completed: brief tactical assessment pause before pulling out weapon
		self.bot_state = "assess"
		self.bot_timer = self.bot_plan.is_pvp_bot and (self.bot_plan.assess_delay or 0.75) or 0.40
		set_facing(bot, (self.bot_plan.aim_dx >= 0) and 1 or -1)
	end
end

local function update_assess(self, bot, dt)
	self.bot_timer = self.bot_timer - dt
	if self.bot_timer <= 0 then
		begin_aim(self, bot, self.bot_plan.is_pvp_bot and (self.bot_plan.aim_delay or 0.85) or 0.70)
	end
end

local function plan_retreat(self, bot)
	local wpn = weapons.get(self.bot_plan.weapon_id)
	local arch = bot.bot_archetype or self.bot_plan.archetype or "coward"
	local retreat_needed = arch == "coward" or arch == "sniper" or (wpn and (wpn.blast_radius or 0) > 20)

	if not (retreat_needed and bot.is_grounded) then
		M.reset(self)
		return
	end

	-- Evaluate left vs right: prefer safe ground away from water
	local left_y = terrain_grid.get_smooth_ground_y(bot.pos.x - 24, 4.0)
	local right_y = terrain_grid.get_smooth_ground_y(bot.pos.x + 24, 4.0)
	local water_y = constants.WATER_LEVEL or 20

	local retreat_dir = (self.bot_plan.aim_dx >= 0) and -1 or 1
	if retreat_dir == -1 and left_y <= water_y + 10 then
		retreat_dir = 1
	elseif retreat_dir == 1 and right_y <= water_y + 10 then
		retreat_dir = -1
	end

	self.bot_state = "retreat"
	self.bot_retreat_steps = (arch == "coward") and math.random(5, 9) or math.random(3, 6)
	self.bot_retreat_done = 0
	self.bot_retreat_timer = 0
	self.bot_retreat_dir = retreat_dir
end

local function update_aim(self, bot, dt)
	-- Stepped aiming: overshoots slightly, then corrects back to target angle
	local plan = self.bot_plan
	self.bot_aim_timer = self.bot_aim_timer - dt
	local total_t = math.max(0.1, self.bot_aim_total or 0.70)
	local aim_progress = math.max(0, math.min(1.0, 1.0 - (self.bot_aim_timer / total_t)))

	local base_angle = math.atan2(plan.aim_dy, plan.aim_dx)
	local angle_offset
	if aim_progress < 0.65 then
		-- Sweeping towards target and slightly overshooting
		local sweep = aim_progress / 0.65
		angle_offset = self.bot_overshoot_angle * (1.0 - sweep) + self.bot_overshoot_angle * 0.4 * sweep
	else
		-- Fine-tuning adjustment back to true angle
		local adjust = (aim_progress - 0.65) / 0.35
		angle_offset = (self.bot_overshoot_angle * 0.4) * (1.0 - adjust)
	end

	local cur_angle = base_angle + angle_offset
	local cur_vx = math.cos(cur_angle) * plan.power
	local cur_vy = math.sin(cur_angle) * plan.power
	set_facing(bot, (cur_vx >= 0) and 1 or -1)

	msg.post("/aim_guide#aim_guide", "bot_aim_preview", {
		vx = cur_vx,
		vy = cur_vy,
		weapon_id = plan.weapon_id
	})

	if self.bot_aim_timer <= 0 then
		self.bot_state = "shoot"
		msg.post("/aim_guide#aim_guide", "hide_aim")
		msg.post(".", "fire_weapon", {
			origin_x = bot.pos.x,
			origin_y = bot.pos.y + 8,
			vel_x = plan.aim_dx * plan.power * 1.30,
			vel_y = plan.aim_dy * plan.power * 1.30,
			weapon_id = plan.weapon_id,
			owner_id = bot.id
		})
		plan_retreat(self, bot)
	end
end

local function update_retreat(self, bot, dt)
	-- Bot crawls into cover/away from danger before turn ends
	if self.bot_retreat_done < self.bot_retreat_steps then
		self.bot_retreat_timer = self.bot_retreat_timer + dt
		if self.bot_retreat_dir ~= 0 then
			physics_sim.walk_potato(bot, self.bot_retreat_dir, dt, terrain_grid)
			set_facing(bot, self.bot_retreat_dir)
			if bot.url then
				go.set_position(bot.pos, bot.url)
			end
		end
		if self.bot_retreat_timer >= STEP_TIME then
			self.bot_retreat_timer = self.bot_retreat_timer - STEP_TIME
			self.bot_retreat_done = self.bot_retreat_done + 1
		end
	else
		M.reset(self)
	end
end

local STATE_HANDLERS = {
	survey = update_survey,
	move = update_move,
	assess = update_assess,
	aim = update_aim,
	retreat = update_retreat,
}

function M.update(self, dt)
	if not (game_state.state == constants.STATE_TURN_ACTIVE and game_state.is_bot_turn()) then
		M.reset(self)
		return
	end

	local bot = game_state.active_potato
	if not (bot and bot.is_alive) then
		return
	end

	if not self.bot_thinking then
		self.bot_thinking = true
		plan_turn(self, bot)
	elseif self.bot_plan then
		local handler = STATE_HANDLERS[self.bot_state]
		if handler then
			handler(self, bot, dt)
		end
	else
		-- No valid plan, skip turn
		self.bot_thinking = false
		game_state.on_action_fired()
	end
end

return M
