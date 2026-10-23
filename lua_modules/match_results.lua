-- lua_modules/match_results.lua
-- Match end bookkeeping: achievements, campaign stars, onboarding rewards and
-- the payload for the game over screen.

local constants = require("lua_modules.constants")
local game_state = require("lua_modules.game_state")
local player_profile = require("lua_modules.player_profile")
local achievements = require("lua_modules.achievements")
local strategic_campaign = require("lua_modules.strategic_campaign")
local i18n = require("lua_modules.i18n")

local M = {}

-- Onboarding rewards for the first (training) and second battles
local SEAMLESS_REWARDS = {
	[1] = { hat_id = "cap", sprite = "hat_cap", name_ru = "КЕПКА БОЙЦА", name_en = "FIGHTER CAP", name_pt = "BONÉ DE COMBATE", name_fr = "CASQUETTE DE COMBATTANT", name_es = "GORRA DE COMBATE", name_tr = "SAVAŞÇI ŞAPKASI", coins = 100 },
	[2] = { hat_id = "bandana", sprite = "hat_bandana", name_ru = "БАНДАНА НИНДЗЯ", name_en = "NINJA BANDANA", name_pt = "BANDANA NINJA", name_fr = "BANDEAU NINJA", name_es = "BANDANA NINJA", name_tr = "NİNJA BANDANASI", coins = 150 },
}

-- 1 star for victory + 1 star for keeping all units alive
local function award_stars()
	local blue_total, blue_alive = 0, 0
	for _, p in ipairs(game_state.potatoes or {}) do
		if p.team == constants.TEAM_BLUE then
			blue_total = blue_total + 1
			if p.is_alive and p.hp > 0 then
				blue_alive = blue_alive + 1
			end
		end
	end
	local flawless = (blue_total > 0 and blue_alive == blue_total)
	local stars = 1 + (flawless and 1 or 0)
	player_profile.add_stars(stars)
	return stars, flawless
end

local function apply_seamless_reward(data, stage)
	local reward = SEAMLESS_REWARDS[stage]
	player_profile.unlock_hat(reward.hat_id)
	if stage == 1 then
		player_profile.equip_hat(reward.hat_id)
	else
		player_profile.set_tutorial_completed(true)
	end
	player_profile.add_points(reward.coins)
	player_profile.set_onboarding_stage(stage)

	data.seamless = true
	data.seamless_stage = stage
	data.unlocked_hat_id = reward.hat_id
	data.unlocked_hat_name = reward["name_" .. i18n.current_lang] or reward.name_en
	data.unlocked_hat_sprite = reward.sprite
	data.coins_awarded = reward.coins
	data.total_coins = player_profile.get_points()
end

-- Builds the game over payload; seamless_stage is main.script's onboarding stage (0/1/2)
function M.build(seamless_stage, winner_team, points_earned, hp_healed, current_hp, next_hp)
	local player_hp = current_hp or (game_state.potatoes[1] and game_state.potatoes[1].hp) or 100
	local ach_list, ach_bonus = achievements.evaluate_match_end(winner_team, player_hp)
	if ach_bonus > 0 then
		player_profile.add_points(ach_bonus)
	end

	local stars_earned = 0
	local flawless_survival = false
	local in_sector_battle = strategic_campaign and strategic_campaign.active_battle_sector_id ~= nil
	local is_campaign = (game_state.mode == constants.MODE_CAMPAIGN) or in_sector_battle
	if winner_team == constants.TEAM_BLUE and is_campaign then
		stars_earned, flawless_survival = award_stars()
	end

	local campaign_outcome = nil
	if in_sector_battle then
		campaign_outcome = strategic_campaign.resolve_battle(winner_team, points_earned + ach_bonus)
		if campaign_outcome then
			campaign_outcome.stars_earned = stars_earned
			campaign_outcome.flawless_survival = flawless_survival
		end
	end

	local is_tutorial = (game_state.mode == constants.MODE_TUTORIAL) or (seamless_stage == 1)
	local data = {
		winner = winner_team,
		points = points_earned + ach_bonus,
		base_points = points_earned,
		achieve_bonus = ach_bonus,
		achievements = ach_list,
		hp_healed = hp_healed,
		current_hp = current_hp,
		next_hp = next_hp,
		campaign_outcome = campaign_outcome,
		stars_earned = stars_earned,
		flawless_survival = flawless_survival,
		is_tutorial = is_tutorial,
	}

	if is_tutorial or player_profile.get_onboarding_stage() == 0 then
		apply_seamless_reward(data, 1)
	elseif seamless_stage == 2 or (game_state.match_config and game_state.match_config.is_seamless_battle) then
		apply_seamless_reward(data, 2)
	end

	return data
end

return M
