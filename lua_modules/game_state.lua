-- lua_modules/game_state.lua
-- Central match state, 15-second turn manager, card choices, and campaign progression for Potato War

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")
local cards = require("lua_modules.cards")
local player_profile = require("lua_modules.player_profile")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

-- Campaign level definitions: 1 Player vs Bots!
M.CAMPAIGN_LEVELS = {
	{
		id = 1,
		name = "Арена 1: Быстрая Дуэль",
		desc = "Быстрая дуэль 1 на 1. Выберите карточку и разгромите соперника!",
		terrain_preset = "flat",
		blue_count = 1,
		red_count = 1,
		bot_difficulty = "easy",
	},
	{
		id = 2,
		name = "Арена 2: Парящие Острова",
		desc = "Быстрый бой 1 на 1 над водой.",
		terrain_preset = "islands",
		blue_count = 1,
		red_count = 1,
		bot_difficulty = "normal",
	},
	{
		id = 3,
		name = "Арена 3: Каньон Огня",
		desc = "Дуэль 1 на 1 на высокой местности.",
		terrain_preset = "canyon",
		blue_count = 1,
		red_count = 1,
		bot_difficulty = "normal",
	},
	{
		id = 4,
		name = "Арена 4: Бункерный Рубеж",
		desc = "1 против 2 ботов в укрытиях.",
		terrain_preset = "bunkers",
		blue_count = 1,
		red_count = 2,
		bot_difficulty = "hard",
	},
	{
		id = 5,
		name = "Арена 5: Цитадель",
		desc = "Финальный штурм: 1 против 2 метких ботов!",
		terrain_preset = "hills",
		blue_count = 1,
		red_count = 2,
		bot_difficulty = "hard",
	},
}

-- Poki SDK Safety Wrappers
function M.poki_gameplay_start()
	constants.log(">>> POKI SDK: gameplayStart")
	pcall(function()
		if poki_sdk then poki_sdk.gameplay_start() end
	end)
end

function M.poki_gameplay_stop()
	constants.log(">>> POKI SDK: gameplayStop")
	pcall(function()
		if poki_sdk then poki_sdk.gameplay_stop() end
	end)
end

function M.poki_commercial_break(callback)
	constants.log(">>> POKI SDK: commercialBreak")
	local called = false
	local function done()
		if not called then
			called = true
			if callback then callback() end
		end
	end
	if poki_sdk and poki_sdk.commercial_break then
		pcall(function()
			poki_sdk.commercial_break(done)
		end)
	else
		done()
	end
end

function M.poki_rewarded_break(callback)
	constants.log(">>> POKI SDK: rewardedBreak")
	if poki_sdk and poki_sdk.rewarded_break then
		pcall(function()
			poki_sdk.rewarded_break(function(self, success)
				if callback then callback(success) end
			end)
		end)
	else
		if callback then callback(true) end
	end
end

-- Runtime state
M.mode = constants.MODE_CAMPAIGN
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

M.current_cards = nil -- { card1, card2 } during card select phase
M.player_weapons = { "grenade" } -- Unlocked weapons inventory
M.player_ammo = {
	grenade = -1, -- Unlimited!
	rifle = 0,
	knife = 0,
	molotov = 0,
	burst = 0,
	bazooka = 0,
	shotgun = 0,
	holy_grenade = 0,
}
M.player_perks = {
	fire_bullets = false,
	triple_jump = false,
}

function M.get_ammo(weapon_id)
	if weapon_id == "grenade" then
		return -1 -- Unlimited
	end
	if M.mode ~= constants.MODE_CAMPAIGN then
		return weapons.get(weapon_id).default_ammo or 2
	end
	if not M.player_ammo then
		M.player_ammo = { grenade = -1 }
	end
	return M.player_ammo[weapon_id] or 0
end

function M.add_ammo(weapon_id, count)
	if not M.player_ammo then
		M.player_ammo = { grenade = -1 }
	end
	M.player_ammo[weapon_id] = (M.player_ammo[weapon_id] or 0) + count
	M.unlock_weapon(weapon_id)
	if M.on_ammo_changed then
		M.on_ammo_changed()
	end
end

function M.consume_ammo(weapon_id)
	if weapon_id == "grenade" then
		return true
	end
	if M.mode == constants.MODE_CAMPAIGN then
		if not M.player_ammo then M.player_ammo = { grenade = -1 } end
		local cur = M.player_ammo[weapon_id] or 0
		if cur > 0 then
			M.player_ammo[weapon_id] = cur - 1
			if M.player_ammo[weapon_id] <= 0 then
				M.select_weapon("grenade")
			end
			if M.on_ammo_changed then
				M.on_ammo_changed()
			end
			return true
		else
			M.select_weapon("grenade")
			if M.on_ammo_changed then
				M.on_ammo_changed()
			end
			return false
		end
	end
	return true
end

function M.has_perk(perk_id)
	if not M.player_perks then return false end
	return M.player_perks[perk_id] == true
end

function M.is_weapon_unlocked(weapon_id)
	if weapon_id == "grenade" then
		return true
	end
	if M.mode ~= constants.MODE_CAMPAIGN then
		return true
	end
	return M.get_ammo(weapon_id) > 0
end

function M.unlock_weapon(weapon_id)
	if not M.player_weapons then
		M.player_weapons = { "grenade" }
	end
	for _, w_id in ipairs(M.player_weapons) do
		if w_id == weapon_id then return end
	end
	table.insert(M.player_weapons, weapon_id)
end

-- Callback hooks for UI / Main
M.on_state_changed = nil
M.on_turn_changed = nil
M.on_timer_updated = nil
M.on_weapon_changed = nil
M.on_ammo_changed = nil
M.on_cards_offered = nil
M.on_game_over = nil

function M.set_state(new_state)
	M.state = new_state
	if M.on_state_changed then
		M.on_state_changed(new_state)
	end
end

function M.select_weapon(weapon_id)
	if weapon_id ~= "grenade" and M.get_ammo(weapon_id) <= 0 then
		return
	end
	M.selected_weapon_id = weapon_id
	if M.on_weapon_changed then
		M.on_weapon_changed(weapon_id)
	end
end

-- Start a new match
function M.start_match(mode, campaign_lvl)
	M.mode = mode or constants.MODE_CAMPAIGN
	M.campaign_level = campaign_lvl or 1
	M.potatoes = {}
	M.active_team = constants.TEAM_BLUE
	M.team_turn_index[constants.TEAM_BLUE] = 1
	M.team_turn_index[constants.TEAM_RED] = 1
	M.turn_timer = constants.TURN_DURATION
	M.selected_weapon_id = weapons.TYPES.GRENADE
	M.winner_team = nil
	M.settle_timer = 0
	M.current_cards = nil

	-- Reset inventory on new campaign run (level 1)
	if M.mode == constants.MODE_CAMPAIGN and M.campaign_level == 1 then
		player_profile.reset_campaign_hp()
		M.player_weapons = { "grenade" }
		M.player_ammo = {
			grenade = -1,
			rifle = 0,
			knife = 0,
			molotov = 0,
			burst = 0,
			bazooka = 0,
			shotgun = 0,
			holy_grenade = 0,
		}
		M.player_perks = {
			fire_bullets = false,
			triple_jump = false,
		}
	end

	M.poki_gameplay_start()

	-- Offer bonus card selection at the beginning of each level in campaign mode!
	if M.mode == constants.MODE_CAMPAIGN then
		local p_hp = player_profile.get_campaign_hp() or 100
		local c1, c2 = cards.draw_2_cards(p_hp, 100, M.campaign_level, M.player_perks)
		M.current_cards = { c1, c2 }
		M.set_state(constants.STATE_CARD_SELECT)
		if M.on_cards_offered then
			M.on_cards_offered(c1, c2)
		end
	else
		M.set_state(constants.STATE_INTRO)
	end
end

-- Get current match configuration
function M.get_current_config()
	if M.mode == constants.MODE_CAMPAIGN then
		if M.campaign_level <= #M.CAMPAIGN_LEVELS then
			return M.CAMPAIGN_LEVELS[M.campaign_level]
		else
			-- Infinite / high arenas
			local presets = { "hills", "islands", "bunkers", "canyon" }
			return {
				id = M.campaign_level,
				name = "Арена " .. tostring(M.campaign_level) .. ": Экстрим",
				desc = "1 против волны элитных ботов!",
				terrain_preset = presets[((M.campaign_level - 1) % #presets) + 1],
				blue_count = 1,
				red_count = math.min(3, 1 + math.floor(M.campaign_level / 2)),
				bot_difficulty = "hard",
			}
		end
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

-- Begin turn for current active team (no turn interruptions during match!)
local function begin_current_turn()
	M.pick_active_potato()
	M.turn_timer = constants.TURN_DURATION

	if M.on_turn_changed then
		M.on_turn_changed(M.active_team, M.active_potato)
	end

	-- Ensure selected weapon is valid and has ammo
	if M.active_team == constants.TEAM_BLUE then
		if M.selected_weapon_id ~= weapons.TYPES.GRENADE and M.get_ammo(M.selected_weapon_id) <= 0 then
			M.select_weapon(weapons.TYPES.GRENADE)
		end
	else
		M.selected_weapon_id = weapons.TYPES.GRENADE
	end

	M.set_state(constants.STATE_TURN_ACTIVE)
end

-- Called when player selects one of the bonus cards at level start
function M.select_card(card_index)
	if M.state ~= constants.STATE_CARD_SELECT or not M.current_cards then
		return
	end

	local chosen_card = M.current_cards[card_index]
	if not chosen_card then
		return
	end

	if chosen_card.type == "heal" then
		sound_manager.play_heal()
		local heal_amt = chosen_card.heal_amount or 30
		local cur = player_profile.get_campaign_hp() or 100
		local next_hp = math.min(100, cur + heal_amt)
		player_profile.set_campaign_hp(next_hp)
		for _, p in ipairs(M.potatoes) do
			if p.team == constants.TEAM_BLUE and p.is_alive then
				p.hp = math.min(p.max_hp, p.hp + heal_amt)
				if p.url then
					msg.post(p.url, "apply_heal", { amount = heal_amt })
				end
			end
		end
	elseif chosen_card.type == "weapon" then
		M.add_ammo(chosen_card.weapon_id, chosen_card.ammo or 2)
		M.select_weapon(chosen_card.weapon_id)
	elseif chosen_card.type == "perk" then
		if not M.player_perks then M.player_perks = {} end
		M.player_perks[chosen_card.perk_id] = true
	end

	M.current_cards = nil
	M.set_state(constants.STATE_INTRO)
	M.settle_timer = 0
end

-- Advance to next turn
function M.next_turn()
	-- Check match end
	local blue_alive = 0
	local red_alive = 0
	local blue_potato = nil

	for _, p in ipairs(M.potatoes) do
		if p.is_alive then
			if p.team == constants.TEAM_BLUE then
				blue_alive = blue_alive + 1
				blue_potato = p
			else
				red_alive = red_alive + 1
			end
		end
	end

	if blue_alive == 0 or red_alive == 0 then
		M.set_state(constants.STATE_GAME_OVER)
		local points_earned = 0
		local hp_healed = 0
		local current_hp = 0
		local next_hp = 0

		if blue_alive > 0 then
			M.winner_team = constants.TEAM_BLUE
			if M.mode == constants.MODE_CAMPAIGN and blue_potato then
				current_hp = blue_potato.hp
				-- +10% max HP bonus on winning arena
				hp_healed = math.floor(blue_potato.max_hp * 0.10)
				next_hp = math.min(blue_potato.max_hp, current_hp + hp_healed)
				player_profile.set_campaign_hp(next_hp)

				-- Points reward: 100 base + 50 * level + HP bonus
				points_earned = 100 + (M.campaign_level * 50) + math.floor(current_hp * 0.5)
				player_profile.add_points(points_earned)
			else
				points_earned = 50
				player_profile.add_points(points_earned)
			end
		elseif red_alive > 0 then
			M.winner_team = constants.TEAM_RED
			if M.mode == constants.MODE_CAMPAIGN then
				player_profile.reset_campaign_hp()
			end
		else
			M.winner_team = 0 -- Draw
		end

		M.poki_gameplay_stop()
		if M.on_game_over then
			M.on_game_over(M.winner_team, points_earned, hp_healed, current_hp, next_hp)
		end
		return
	end

	-- Switch active team
	M.active_team = (M.active_team == constants.TEAM_BLUE) and constants.TEAM_RED or constants.TEAM_BLUE
	begin_current_turn()
end

-- Update game state timers
function M.update(dt, active_projectiles_count)
	active_projectiles_count = active_projectiles_count or 0

	if M.state == constants.STATE_INTRO then
		M.settle_timer = M.settle_timer + dt
		if M.settle_timer >= 1.5 then
			M.settle_timer = 0
			begin_current_turn()
		end

	elseif M.state == constants.STATE_CARD_SELECT then
		-- Card selection active: timer pauses or gives player time to choose
		-- No timeout pressure during card selection

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
