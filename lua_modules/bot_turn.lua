-- lua_modules/bot_turn.lua
-- Worms-style bot turn state machine driven from main.script update.
-- States:
-- "survey": looks around, pauses, picks a standing spot (bot_ai.plan_move)
-- "move": walks there, hopping over bumps, never off a ledge into the water
-- "settle": waits until the bot stands still again
-- "think": works out the shot from where it actually stands (bot_ai.solve_attack, spread over frames)
-- "aim": equips weapon, stepped aiming (overshoots and corrects back) with reticle preview
-- "retreat": after firing, cautious bots scurry away while the shell is in the air

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")
local terrain_grid = require("lua_modules.terrain_grid")
local physics_sim = require("lua_modules.physics_sim")
local bot_ai = require("lua_modules.bot_ai")
local game_state = require("lua_modules.game_state")
local i18n = require("lua_modules.i18n")

local M = {}

local THINK_BUDGET = 0.006   -- seconds of solver work per frame
local MOVE_TIMEOUT = 3.5     -- longest walk
local SETTLE_TIMEOUT = 1.5   -- longest wait for the bot to stop moving before thinking
local HURRY_TIME = 6.0       -- with less turn time left the bot skips walking
local CHAT_CHANCE = 0.55

local function set_facing(bot, facing)
	if facing == 0 or facing == bot.facing then
		return
	end
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

local function say(bot, key, force)
	local lines = key and bot_ai.CHAT[key]
	if not (lines and bot.url) or (not force and math.random() > CHAT_CHANCE) then
		return
	end
	msg.post("/gui_hud#gui", "show_damage", {
		x = bot.pos.x,
		y = bot.pos.y + 30,
		amount = 0,
		status = "chat",
		label = i18n.pick(lines),
	})
end

local function skill_info()
	local config = game_state.get_current_config()
	local bot_skill = config.enemy_skill or config.bot_difficulty or "normal"
	local is_pvp = game_state.mode == constants.MODE_PVP_BOTS or game_state.mode == constants.MODE_QUICK_PVP
	return bot_skill, is_pvp
end

function M.reset(self)
	self.bot_thinking = false
	self.bot_plan = nil
	self.bot_move = nil
	self.bot_state = nil
	self.bot_solver = nil
end

-- Ground ahead is water or a fall the bot should not take
local function hazard_ahead(bot, dir)
	local ahead_x = bot.pos.x + dir * 14
	local gy = terrain_grid.get_smooth_ground_y(ahead_x, 4.0, bot.pos.y + 8)
	local here = terrain_grid.get_smooth_ground_y(bot.pos.x, 4.0, bot.pos.y + 8)
	return gy < constants.WATER_LEVEL + 14 or (here - gy) > 90
end

local function start_turn(self, bot)
	local bot_skill, is_pvp = skill_info()
	self.bot_skill = bot_skill
	self.bot_is_pvp = is_pvp
	self.bot_move = bot_ai.plan_move(bot, game_state.potatoes, terrain_grid, bot_skill, is_pvp)

	-- Start in SURVEY state (Worms style: looking left and right, checking position)
	self.bot_state = "survey"
	self.bot_timer = (is_pvp and 0.9 or 0.55) + math.random() * 0.35
	self.bot_survey_flips = 0
	self.bot_survey_flip_timer = 0.22
end

local function begin_settle(self)
	self.bot_state = "settle"
	self.bot_timer = SETTLE_TIMEOUT
end

local function update_survey(self, bot, dt)
	-- Bot turns left/right inquisitively before committing to action
	self.bot_timer = self.bot_timer - dt
	self.bot_survey_flip_timer = self.bot_survey_flip_timer - dt

	if self.bot_survey_flip_timer <= 0 and self.bot_survey_flips < 2 then
		self.bot_survey_flip_timer = 0.25
		self.bot_survey_flips = self.bot_survey_flips + 1
		set_facing(bot, -(bot.facing or 1))
	end

	if self.bot_timer <= 0 then
		local move = self.bot_move
		if move and move.intent ~= "hold" and game_state.turn_timer > HURRY_TIME then
			self.bot_state = "move"
			self.bot_timer = MOVE_TIMEOUT
			self.bot_stuck_timer = 0
			self.bot_last_x = bot.pos.x
			say(bot, move.chat)
		else
			begin_settle(self)
		end
	end
end

local function update_move(self, bot, dt)
	local move = self.bot_move
	self.bot_timer = self.bot_timer - dt
	local dx = move.target_x - bot.pos.x
	local dir = (dx > 0) and 1 or -1

	if math.abs(dx) < 4 or self.bot_timer <= 0 or game_state.turn_timer < HURRY_TIME * 0.5 then
		begin_settle(self)
		return
	end
	if bot.is_grounded and hazard_ahead(bot, dir) then
		begin_settle(self)
		return
	end

	walk(bot, dir, dt)

	-- Hop onto steps and out of pits; give up when a wall does not budge
	if bot.is_grounded then
		local ahead_y = terrain_grid.get_smooth_ground_y(bot.pos.x + dir * 12.0, 4.0, bot.pos.y + 60)
		local rise = ahead_y - (bot.pos.y - constants.POTATO_RADIUS)
		if rise > 20.0 and rise <= 60.0 then
			jump(bot)
		end
	end
	if math.abs(bot.pos.x - self.bot_last_x) < 0.5 then
		self.bot_stuck_timer = self.bot_stuck_timer + dt
		if self.bot_stuck_timer > 0.35 then
			if self.bot_stuck_timer > 1.0 then
				begin_settle(self)
				return
			end
			jump(bot)
		end
	else
		self.bot_stuck_timer = 0
	end
	self.bot_last_x = bot.pos.x

	if bot.url then
		go.set_position(bot.pos, bot.url)
	end
end

local function update_settle(self, bot, dt)
	self.bot_timer = self.bot_timer - dt
	local still = bot.is_grounded and math.abs(bot.vel.x) < 6 and math.abs(bot.vel.y) < 6
	if still or self.bot_timer <= 0 then
		self.bot_state = "think"
		self.bot_timer = self.bot_is_pvp and (0.8 + math.random() * 0.5) or (0.35 + math.random() * 0.3)
		if M.resolve_sniper(bot) then
			self.bot_timer = self.bot_timer + 0.5 -- snipers take their time
		end
		local skill, is_pvp = self.bot_skill, self.bot_is_pvp
		-- Yields back to the frame once this frame's share of solver time is used up
		local tick = function()
			if socket.gettime() > self.bot_deadline then
				coroutine.yield()
			end
		end
		self.bot_solver = coroutine.create(function()
			return bot_ai.solve_attack(bot, game_state.potatoes, terrain_grid, skill, is_pvp, game_state.wind_vector, tick)
		end)
	end
end

function M.resolve_sniper(bot)
	return bot_ai.resolve_archetype(bot) == bot_ai.ARCHETYPES.SNIPER
end

-- Runs the solver for up to THINK_BUDGET seconds; returns the plan once it is done
local function run_solver(self)
	self.bot_deadline = socket.gettime() + THINK_BUDGET
	local ok, plan = coroutine.resume(self.bot_solver)
	if not ok then
		constants.log(">>> BOT SOLVER ERROR:", plan)
		self.bot_solver = nil
		return false, nil
	end
	if coroutine.status(self.bot_solver) == "dead" then
		self.bot_solver = nil
		return true, plan
	end
	return false, nil
end

local function begin_aim(self, bot)
	local plan = self.bot_plan
	self.bot_state = "aim"
	self.bot_aim_total = (self.bot_is_pvp and 1.0 or 0.7) + math.random() * 0.4
	self.bot_aim_timer = self.bot_aim_total
	self.bot_overshoot_angle = (math.random() > 0.5 and 0.09 or -0.09)
	game_state.select_weapon(plan.weapon_id)
	set_facing(bot, (plan.vx >= 0) and 1 or -1)
	if bot.url then
		msg.post(bot.url, "set_weapon", { weapon_id = plan.weapon_id })
	end
	say(bot, plan.chat)
end

local function update_think(self, bot, dt)
	self.bot_timer = self.bot_timer - dt
	if self.bot_solver then
		local done, plan = run_solver(self)
		if done then
			self.bot_plan = plan or false
		elseif not self.bot_solver then
			self.bot_plan = false -- solver crashed
		end
	end
	if self.bot_plan ~= nil and self.bot_timer <= 0 then
		if self.bot_plan then
			bot_ai.apply_error(bot, self.bot_plan, self.bot_skill, self.bot_is_pvp)
			begin_aim(self, bot)
		else
			-- No valid plan: skip the turn
			game_state.on_action_fired()
		end
	end
end

local function begin_retreat(self, bot)
	local plan = self.bot_plan
	local w = weapons.get(plan.weapon_id)
	local arch = bot_ai.resolve_archetype(bot)
	local cautious = arch == bot_ai.ARCHETYPES.COWARD or arch == bot_ai.ARCHETYPES.SNIPER
	if not (bot.is_grounded and (cautious or (w.blast_radius or 0) >= 40)) or plan.target_x or plan.melee then
		M.reset(self)
		return
	end
	-- Away from where the shot went
	local dir = (plan.vx >= 0) and -1 or 1
	if hazard_ahead(bot, dir) then
		M.reset(self)
		return
	end
	self.bot_state = "retreat"
	self.bot_timer = (arch == bot_ai.ARCHETYPES.COWARD) and 0.8 or 0.45
	self.bot_retreat_dir = dir
end

local function update_aim(self, bot, dt)
	-- Stepped aiming: overshoots slightly, then corrects back to target angle
	local plan = self.bot_plan
	self.bot_aim_timer = self.bot_aim_timer - dt
	local total_t = math.max(0.1, self.bot_aim_total)
	local aim_progress = math.max(0, math.min(1.0, 1.0 - (self.bot_aim_timer / total_t)))

	local base_angle = math.atan2(plan.vy, plan.vx)
	local speed = math.sqrt(plan.vx * plan.vx + plan.vy * plan.vy)
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
	local cur_vx = math.cos(cur_angle) * speed
	local cur_vy = math.sin(cur_angle) * speed
	set_facing(bot, (cur_vx >= 0) and 1 or -1)

	if not plan.melee then
		msg.post("/aim_guide#aim_guide", "bot_aim_preview", {
			vx = cur_vx,
			vy = cur_vy,
			weapon_id = plan.weapon_id,
			target_x = plan.target_x,
		})
	end

	if self.bot_aim_timer <= 0 then
		msg.post("/aim_guide#aim_guide", "hide_aim")
		set_facing(bot, (plan.vx >= 0) and 1 or -1)
		-- The plan already holds the launch velocity (the solver simulated exactly this shot)
		msg.post(".", "fire_weapon", {
			origin_x = bot.pos.x,
			origin_y = bot.pos.y + 8,
			vel_x = plan.vx,
			vel_y = plan.vy,
			weapon_id = plan.weapon_id,
			owner_id = bot.id,
			target_x = plan.target_x,
		})
		begin_retreat(self, bot)
	end
end

local function update_retreat(self, bot, dt)
	self.bot_timer = self.bot_timer - dt
	if self.bot_timer <= 0 or not bot.is_grounded or hazard_ahead(bot, self.bot_retreat_dir) then
		M.reset(self)
		return
	end
	walk(bot, self.bot_retreat_dir, dt)
	if bot.url then
		go.set_position(bot.pos, bot.url)
	end
end

local STATE_HANDLERS = {
	survey = update_survey,
	move = update_move,
	settle = update_settle,
	think = update_think,
	aim = update_aim,
	retreat = update_retreat,
}

function M.update(self, dt)
	local bot = game_state.active_potato
	-- The retreat runs on while the shell is in the air
	local retreating = self.bot_state == "retreat" and game_state.state == constants.STATE_ACTION
	if not retreating and not (game_state.state == constants.STATE_TURN_ACTIVE and game_state.is_bot_turn()) then
		if self.bot_thinking then
			M.reset(self)
		end
		return
	end

	if not (bot and bot.is_alive) then
		return
	end

	if not self.bot_thinking then
		self.bot_thinking = true
		start_turn(self, bot)
		if not self.bot_move then
			-- Nobody left to fight
			M.reset(self)
			self.bot_thinking = true
			game_state.on_action_fired()
			return
		end
	end

	local handler = STATE_HANDLERS[self.bot_state]
	if handler then
		handler(self, bot, dt)
	end
end

return M
