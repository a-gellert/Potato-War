-- lua_modules/game_state.lua
-- Central match state, 15-second turn manager, card choices, and campaign progression for Potato War

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")
local cards = require("lua_modules.cards")
local player_profile = require("lua_modules.player_profile")
local sound_manager = require("lua_modules.sound_manager")
local level_config = require("lua_modules.level_config")
local meta_progression = require("lua_modules.meta_progression")

local M = {}

-- Campaign level definitions: delegated to level_config module
M.CAMPAIGN_LEVELS = level_config.LEVELS

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
M.MAX_LOADOUT_SLOTS = 5
M.player_loadout = { "grenade" } -- 5-slot active weapon stack
M.player_ammo = {
	grenade = -1, -- Unlimited!
	rifle = 0,
	knife = 0,
	molotov = 0,
	burst = 0,
	bazooka = 0,
	shotgun = 0,
	holy_grenade = 0,
	beetle = 0,
	drill = 0,
	pepper = 0,
	garlic = 0,
}
M.player_perks = {
	fire_bullets = false,
	triple_jump = false,
}

function M.get_slot_weapon(slot_idx)
	if not M.player_loadout then
		M.player_loadout = { "grenade" }
	end
	local w_id = M.player_loadout[slot_idx]
	if w_id then
		return weapons.get(w_id)
	end
	return nil
end

function M.get_ammo(weapon_id)
	if weapon_id == "grenade" then
		return -1 -- Unlimited
	end
	if not M.player_ammo then
		M.player_ammo = { grenade = -1 }
	end
	if M.player_ammo[weapon_id] ~= nil then
		return M.player_ammo[weapon_id]
	end
	local w = weapons.get(weapon_id)
	return (w and w.default_ammo) or 0
end

function M.is_in_loadout(weapon_id)
	if not M.player_loadout then return false end
	for _, w_id in ipairs(M.player_loadout) do
		if w_id == weapon_id then return true end
	end
	return false
end

function M.add_ammo(weapon_id, count)
	if not M.player_ammo then
		M.player_ammo = { grenade = -1 }
	end
	if not M.player_loadout then
		M.player_loadout = { "grenade" }
	end

	M.player_ammo[weapon_id] = (M.player_ammo[weapon_id] or 0) + count

	-- Add to 5-slot weapon stack
	if not M.is_in_loadout(weapon_id) then
		if #M.player_loadout < M.MAX_LOADOUT_SLOTS then
			table.insert(M.player_loadout, weapon_id)
		else
			-- Stack is full (5 weapons): replace slot 2 (keeping Grenade at slot 1)
			table.remove(M.player_loadout, 2)
			table.insert(M.player_loadout, weapon_id)
		end
	end

	if M.on_ammo_changed then
		M.on_ammo_changed()
	end
end

function M.consume_ammo(weapon_id)
	if weapon_id == "grenade" then
		return true
	end

	if not M.player_ammo then M.player_ammo = { grenade = -1 } end
	local cur = M.player_ammo[weapon_id] or 0
	if cur > 0 then
		M.player_ammo[weapon_id] = cur - 1
		if M.player_ammo[weapon_id] <= 0 then
			-- Remove depleted weapon from active 5-slot loadout
			if M.player_loadout then
				for idx, w_id in ipairs(M.player_loadout) do
					if w_id == weapon_id and w_id ~= "grenade" then
						table.remove(M.player_loadout, idx)
						break
					end
				end
			end
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

function M.has_perk(perk_id)
	if not M.player_perks then return false end
	return M.player_perks[perk_id] == true
end

function M.is_weapon_unlocked(weapon_id)
	if weapon_id == "grenade" then
		return true
	end
	return M.get_ammo(weapon_id) > 0
end

function M.unlock_weapon(weapon_id)
	M.add_ammo(weapon_id, 0)
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
	if not M.is_in_loadout(weapon_id) then
		if not M.player_loadout then M.player_loadout = { "grenade" } end
		if #M.player_loadout < M.MAX_LOADOUT_SLOTS then
			table.insert(M.player_loadout, weapon_id)
		else
			table.remove(M.player_loadout, 2)
			table.insert(M.player_loadout, weapon_id)
		end
	end
	if M.on_weapon_changed then
		M.on_weapon_changed(weapon_id)
	end
	if M.on_ammo_changed then
		M.on_ammo_changed()
	end
end

function M.select_slot(slot_idx)
	local w = M.get_slot_weapon(slot_idx)
	if w and M.is_weapon_unlocked(w.id) then
		M.select_weapon(w.id)
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
	M.active_potato = nil
	M.winner_team = nil
	M.settle_timer = 0
	M.current_cards = nil

	-- Setup inventory loadout (up to 5 weapons)
	if M.mode == constants.MODE_CAMPAIGN then
		if M.campaign_level == 1 then
			player_profile.reset_campaign_hp()
			M.player_loadout = { "grenade", "bazooka", "molotov" }
			M.player_ammo = {
				grenade = -1,
				rifle = 0,
				knife = 0,
				molotov = 2,
				burst = 0,
				bazooka = 2,
				shotgun = 0,
				holy_grenade = 0,
				beetle = 0,
				drill = 0,
				pepper = 0,
				garlic = 0,
			}
			M.player_perks = {
				fire_bullets = false,
				triple_jump = false,
			}
			meta_progression.apply_starting_loadout(M)
		end
	else
		-- Quick Battle vs Bot, PvP 3v3, or Quick PvP: provide complete arsenal
		M.player_loadout = { "grenade", "bazooka", "shotgun", "rifle", "drill" }
		M.player_ammo = {
			grenade = -1, -- Unlimited!
			rifle = 3,
			knife = 4,
			molotov = 3,
			burst = 3,
			bazooka = 3,
			shotgun = 4,
			holy_grenade = 1,
			beetle = 2,
			drill = 3,
			pepper = 3,
			garlic = 2,
		}
	end

	M.poki_gameplay_start()

	-- Offer bonus card selection at the beginning of each level in campaign mode!
	if M.mode == constants.MODE_CAMPAIGN then
		local max_p_hp = meta_progression.get_player_max_hp()
		local p_hp = player_profile.get_campaign_hp() or max_p_hp
		local c1, c2 = cards.draw_2_cards(p_hp, max_p_hp, M.campaign_level, M.player_perks)
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
		return level_config.get(M.campaign_level)
	else
		return level_config.get_quick_match(M.mode)
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
		local max_p_hp = meta_progression.get_player_max_hp()
		local heal_amt = chosen_card.heal_amount or 30
		local cur = player_profile.get_campaign_hp() or max_p_hp
		local next_hp = math.min(max_p_hp, cur + heal_amt)
		player_profile.set_campaign_hp(next_hp)
		for _, p in ipairs(M.potatoes) do
			if p.team == constants.TEAM_BLUE and p.is_alive then
				p.hp = math.min(p.max_hp, p.hp + heal_amt)
				if p.url then
					msg.post(p.url, "apply_heal", { amount = heal_amt })
				end
				msg.post("/gui_hud#gui", "show_damage", {
					x = p.pos.x,
					y = p.pos.y,
					amount = heal_amt,
					is_heal = true
				})
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
				-- +70% max HP bonus on winning arena (at least +65 HP)
				hp_healed = math.max(65, math.floor(blue_potato.max_hp * 0.70))
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
			-- Round HP Regeneration (meta-upgrade): restores % of max HP after each round of combat
			for _, p in ipairs(M.potatoes) do
				if p.team == constants.TEAM_BLUE and p.is_alive then
					meta_progression.apply_round_regen(p, M)
				end
			end
			M.next_turn()
		end
	end
end

-- Called when an attack is launched
function M.on_action_fired()
	M.set_state(constants.STATE_ACTION)
end

return M
