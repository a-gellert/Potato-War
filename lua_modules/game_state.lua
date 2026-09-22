-- lua_modules/game_state.lua
-- Central match state, 15-second turn manager, and campaign progression for Potato War

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")

local M = {}

-- Campaign level definitions
M.CAMPAIGN_LEVELS = {
	{
		id = 1,
		name = "Миссия 1: Тренировка",
		desc = "Одиночный вражеский бот на открытой местности. Научитесь стрелять!",
		terrain_preset = "flat",
		blue_count = 1,
		red_count = 1,
		bot_difficulty = "easy",
	},
	{
		id = 2,
		name = "Миссия 2: Битва на холмах",
		desc = "Командный бой 2 на 2 на холмистой местности.",
		terrain_preset = "hills",
		blue_count = 2,
		red_count = 2,
		bot_difficulty = "normal",
	},
	{
		id = 3,
		name = "Миссия 3: Островная оборона",
		desc = "Сражение на плато с глубокими провалами и водой!",
		terrain_preset = "canyon",
		blue_count = 2,
		red_count = 2,
		bot_difficulty = "normal",
	},
	{
		id = 4,
		name = "Миссия 4: Бункерный штурм",
		desc = "Тяжелая битва 3 на 3 с тактическими укрытиями и умными ботами.",
		terrain_preset = "bunkers",
		blue_count = 3,
		red_count = 3,
		bot_difficulty = "hard",
	},
	{
		id = 5,
		name = "Миссия 5: Каньон смерти",
		desc = "Стреляйте через глубокий каньон! Один неверный шаг — и в пропасть.",
		terrain_preset = "islands",
		blue_count = 2,
		red_count = 3,
		bot_difficulty = "hard",
	},
}

-- Runtime state
M.mode = constants.MODE_QUICK_BOT
M.state = constants.STATE_MENU
M.campaign_level = 1

M.active_team = constants.TEAM_BLUE
M.turn_timer = constants.TURN_DURATION
M.selected_weapon_id = weapons.TYPES.GRENADE

M.potatoes = {} -- list of all potato records { id, team, pos, vel, hp, max_hp, is_alive, is_grounded, url }
M.team_turn_index = {
	[constants.TEAM_BLUE] = 1,
	[constants.TEAM_RED] = 1,
}

M.active_potato = nil
M.winner_team = nil
M.settle_timer = 0

-- Callback hooks for UI / Main
M.on_state_changed = nil
M.on_turn_changed = nil
M.on_timer_updated = nil
M.on_weapon_changed = nil
M.on_game_over = nil

function M.set_state(new_state)
	M.state = new_state
	if M.on_state_changed then
		M.on_state_changed(new_state)
	end
end

function M.select_weapon(weapon_id)
	M.selected_weapon_id = weapon_id
	if M.on_weapon_changed then
		M.on_weapon_changed(weapon_id)
	end
end

-- Start a new match
function M.start_match(mode, campaign_lvl)
	M.mode = mode or constants.MODE_QUICK_BOT
	M.campaign_level = campaign_lvl or 1
	M.potatoes = {}
	M.active_team = constants.TEAM_BLUE
	M.team_turn_index[constants.TEAM_BLUE] = 1
	M.team_turn_index[constants.TEAM_RED] = 1
	M.turn_timer = constants.TURN_DURATION
	M.selected_weapon_id = weapons.TYPES.GRENADE
	M.winner_team = nil
	M.settle_timer = 0

	M.set_state(constants.STATE_INTRO)
end

-- Get current match configuration
function M.get_current_config()
	if M.mode == constants.MODE_CAMPAIGN then
		return M.CAMPAIGN_LEVELS[M.campaign_level] or M.CAMPAIGN_LEVELS[1]
	elseif M.mode == constants.MODE_QUICK_PVP then
		return {
			name = "Быстрый бой: 2 Игрока",
			terrain_preset = "hills",
			blue_count = 2,
			red_count = 2,
			bot_difficulty = "none",
		}
	else -- constants.MODE_QUICK_BOT
		return {
			name = "Быстрый бой vs Компьютер",
			terrain_preset = ({"hills", "islands", "bunkers", "canyon"})[math.random(1, 4)],
			blue_count = 2,
			red_count = 2,
			bot_difficulty = "normal",
		}
	end
end

-- Check if current turn belongs to a bot
function M.is_bot_turn()
	if M.mode == constants.MODE_QUICK_PVP then
		return false
	end
	return M.active_team == constants.TEAM_RED
end

-- Select next living potato for current active team
function M.pick_active_potato()
	local team_potatoes = {}
	for _, p in ipairs(M.potatoes) do
		if p.team == M.active_team and p.is_alive then
			table.insert(team_potatoes, p)
		end
	end

	if #team_potatoes == 0 then
		M.active_potato = nil
		return nil
	end

	local idx = M.team_turn_index[M.active_team]
	if idx > #team_potatoes then
		idx = 1
	end
	M.active_potato = team_potatoes[idx]
	M.team_turn_index[M.active_team] = (idx % #team_potatoes) + 1

	return M.active_potato
end

-- Advance to next turn
function M.next_turn()
	-- Check match end
	local blue_alive = 0
	local red_alive = 0
	for _, p in ipairs(M.potatoes) do
		if p.is_alive then
			if p.team == constants.TEAM_BLUE then
				blue_alive = blue_alive + 1
			else
				red_alive = red_alive + 1
			end
		end
	end

	if blue_alive == 0 or red_alive == 0 then
		M.set_state(constants.STATE_GAME_OVER)
		if blue_alive > 0 then
			M.winner_team = constants.TEAM_BLUE
		elseif red_alive > 0 then
			M.winner_team = constants.TEAM_RED
		else
			M.winner_team = 0 -- Draw
		end
		if M.on_game_over then
			M.on_game_over(M.winner_team)
		end
		return
	end

	-- Switch active team
	M.active_team = (M.active_team == constants.TEAM_BLUE) and constants.TEAM_RED or constants.TEAM_BLUE
	M.pick_active_potato()
	M.turn_timer = constants.TURN_DURATION
	M.selected_weapon_id = weapons.TYPES.GRENADE

	M.set_state(constants.STATE_TURN_ACTIVE)
	if M.on_turn_changed then
		M.on_turn_changed(M.active_team, M.active_potato)
	end
end

-- Update game state timers
function M.update(dt, active_projectiles_count)
	active_projectiles_count = active_projectiles_count or 0

	if M.state == constants.STATE_INTRO then
		M.settle_timer = M.settle_timer + dt
		if M.settle_timer >= 1.5 then
			M.settle_timer = 0
			M.pick_active_potato()
			M.set_state(constants.STATE_TURN_ACTIVE)
			if M.on_turn_changed then
				M.on_turn_changed(M.active_team, M.active_potato)
			end
		end

	elseif M.state == constants.STATE_TURN_ACTIVE then
		M.turn_timer = M.turn_timer - dt
		if M.on_timer_updated then
			M.on_timer_updated(math.max(0, math.ceil(M.turn_timer)), M.turn_timer / constants.TURN_DURATION)
		end

		-- Turn timeout (15 seconds exceeded!)
		if M.turn_timer <= 0 then
			M.on_action_fired() -- Switch to settling
		end

	elseif M.state == constants.STATE_ACTION then
		-- In action phase: projectile is flying
		if active_projectiles_count == 0 then
			M.set_state(constants.STATE_SETTLING)
			M.settle_timer = 0
		end

	elseif M.state == constants.STATE_SETTLING then
		M.settle_timer = M.settle_timer + dt

		-- Check if all potatoes have stopped moving
		local all_settled = true
		for _, p in ipairs(M.potatoes) do
			if p.is_alive then
				local speed = math.sqrt(p.vel.x * p.vel.x + p.vel.y * p.vel.y)
				if speed > 6.0 or not p.is_grounded then
					all_settled = false
					break
				end
			end
		end

		if (all_settled and M.settle_timer > 0.8) or M.settle_timer > constants.SETTLE_TIMEOUT then
			M.next_turn()
		end
	end
end

-- Called when an attack is launched
function M.on_action_fired()
	M.set_state(constants.STATE_ACTION)
end

return M
