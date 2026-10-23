-- gui/game_over/go_report.lua
-- Debrief texts: outcome sounds, title/subtitle, combat report, rewards, hat progress.

local constants = require("lua_modules.constants")
local player_profile = require("lua_modules.player_profile")
local territory_map = require("lua_modules.territory_map")
local sound_manager = require("lua_modules.sound_manager")
local i18n = require("lua_modules.i18n")

local M = {}

local GREEN = vmath.vector4(0.18, 0.82, 0.44, 1.0)
local RED = vmath.vector4(0.92, 0.28, 0.24, 1.0)
local GOLD = vmath.vector4(0.95, 0.77, 0.06, 1.0)

function M.play_sounds(winner, outcome)
	if winner == constants.TEAM_BLUE then
		if outcome and outcome.battle_type == "assault" then
			sound_manager.play_flag_captured()
			timer.delay(0.35, false, function() sound_manager.play_victory_march() end)
		else
			sound_manager.play_victory_march()
		end
	elseif winner == constants.TEAM_RED then
		if outcome and outcome.battle_type == "defense" then
			sound_manager.play_siren()
			timer.delay(0.40, false, function() sound_manager.play_defeat_accent() end)
		else
			sound_manager.play_defeat_accent()
		end
	end
end

local function sector_name(outcome)
	return i18n.field(outcome, "sector_name")
end

function M.set_title(winner, is_campaign, outcome)
	local title_node = gui.get_node("title_text")
	local sub_node = gui.get_node("subtitle_text")
	local function set(title_key, sub_key, name)
		gui.set_text(title_node, name and string.format(i18n.t(title_key), name:upper()) or i18n.t(title_key))
		gui.set_text(sub_node, i18n.t(sub_key))
	end

	if winner == constants.TEAM_BLUE then
		gui.set_color(title_node, GREEN)
		if is_campaign and outcome then
			if outcome.campaign_won then
				set("debrief_campaign_won", "debrief_sub_camp_won")
			elseif outcome.battle_type == "assault" then
				set("debrief_sector_liberated", "debrief_sub_liberated", sector_name(outcome))
			else
				set("debrief_attack_repelled", "debrief_sub_repelled", sector_name(outcome))
			end
		else
			set("victory", "sub_victory")
		end
	elseif winner == constants.TEAM_RED then
		gui.set_color(title_node, RED)
		if is_campaign and outcome then
			if outcome.campaign_lost then
				set("debrief_campaign_lost", "debrief_sub_camp_lost")
			elseif outcome.battle_type == "defense" then
				set("debrief_sector_lost", "debrief_sub_lost", sector_name(outcome))
			else
				set("debrief_assault_failed", "debrief_sub_failed")
			end
		else
			set("defeat", "sub_defeat")
		end
	else
		gui.set_color(title_node, GOLD)
		set("draw", "sub_draw")
	end
end

function M.set_stats(is_campaign, outcome)
	local stats_detail = gui.get_node("txt_stats_detail")
	local stats_front = gui.get_node("txt_stats_front")
	gui.set_text(gui.get_node("txt_stats_title"), i18n.t("debrief_combat_report"))

	if is_campaign and outcome then
		local sec = outcome.sector_id and territory_map.get_sector(outcome.sector_id)
		local stars = string.format("[%d/3]", sec and sec.defense_level or 1)
		local inc = sec and sec.income or 25
		local sname = sector_name(outcome)
		if outcome.is_victory then
			gui.set_text(stats_detail, i18n.t("go_win_detail_fmt", sname))
			gui.set_text(stats_front, i18n.t("go_win_front_fmt", stars, inc))
		else
			gui.set_text(stats_detail, i18n.t("go_lose_detail_fmt", sname))
			gui.set_text(stats_front, i18n.t("go_lose_front_fmt", stars))
		end
	else
		gui.set_text(stats_detail, i18n.t("go_detail_default"))
		gui.set_text(stats_front, i18n.t("go_front_default"))
	end
end

function M.set_rewards(message, winner, outcome)
	local reward_txt = gui.get_node("reward_text")
	local achieve_node = gui.get_node("achieve_text")
	local points = message.points or 0
	local ach_list = message.achievements or {}
	local ach_bonus = message.achieve_bonus or 0

	if winner == constants.TEAM_BLUE then
		local total_str = "+" .. tostring(points) .. i18n.t("go_points_word")
		local stars_earned = message.stars_earned or (outcome and outcome.stars_earned) or 0
		if stars_earned > 0 then
			local star_bonus_lbl = message.flawless_survival and i18n.t("go_no_casualties") or ""
			local star_word = (stars_earned == 1) and i18n.t("star_one") or i18n.t("stars_few")
			total_str = total_str .. "  •  +" .. tostring(stars_earned) .. " " .. star_word .. star_bonus_lbl
		end
		if ach_bonus > 0 then
			total_str = total_str .. i18n.t("go_bonus_fmt", ach_bonus)
		end
		gui.set_text(reward_txt, total_str)

		if #ach_list > 0 then
			local parts = {}
			for _, a in ipairs(ach_list) do
				table.insert(parts, (a.icon or "🏆") .. " " .. (a.title or "") .. " (+" .. tostring(a.points) .. ")")
			end
			gui.set_text(achieve_node, table.concat(parts, " • "))
		else
			gui.set_text(achieve_node, i18n.t("go_tip_keep"))
		end
	else
		gui.set_text(reward_txt, "+0 " .. i18n.t("go_points_word"):sub(2))
		gui.set_text(achieve_node, i18n.t("go_enemy_stronger"))
	end
	gui.set_enabled(gui.get_node("reward_bg"), true)
end

function M.set_hat_progress()
	local skin_bg = gui.get_node("skin_progress_bg")
	local skin_txt = gui.get_node("skin_progress_txt")
	pcall(function()
		local prog = player_profile.get_next_skin_progress()
		if not (prog and prog.skin) then
			gui.set_enabled(skin_bg, false)
			return
		end

		gui.set_enabled(skin_bg, true)
		local skin_name = i18n.field(prog.skin, "name")
		if prog.can_buy then
			gui.set_text(skin_txt, i18n.t("go_hat_avail_fmt", skin_name, prog.target_price))
			gui.set_color(skin_txt, vmath.vector4(0.3, 1.0, 0.5, 1.0))
		else
			gui.set_text(skin_txt, i18n.t("go_hat_progress_fmt", prog.current_points, prog.target_price, skin_name, prog.needed))
			gui.set_color(skin_txt, vmath.vector4(1.0, 0.85, 0.25, 1.0))
		end
	end)
end

return M
