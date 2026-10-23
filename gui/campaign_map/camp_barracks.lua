-- gui/campaign_map/camp_barracks.lua
-- Barracks overlay: squad slots, promotions, slot unlocks and star purchase.

local player_profile = require("lua_modules.player_profile")
local classes = require("lua_modules.classes")
local sound_manager = require("lua_modules.sound_manager")
local i18n = require("lua_modules.i18n")
local camp_data = require("gui.campaign_map.camp_data")

local M = {}

function M.update(self)
	if not self.is_barracks_open then
		pcall(function()
			gui.set_enabled(gui.get_node("barracks_overlay"), false)
		end)
		return
	end

	pcall(function()
		gui.set_enabled(gui.get_node("barracks_overlay"), true)
		local stars = player_profile.get_stars()
		local pts = player_profile.get_points()

		gui.set_text(gui.get_node("barracks_title"), i18n.t("barracks_title"))
		gui.set_text(gui.get_node("barracks_stars_txt"), i18n.t("barracks_stars") .. tostring(stars))
		gui.set_text(gui.get_node("barracks_points_txt"), i18n.t("points_lbl") .. tostring(pts))
		gui.set_text(gui.get_node("txt_barracks_buy_star"), i18n.t("barracks_buy_star"))

		local buy_btn = gui.get_node("btn_barracks_buy_star")
		if pts >= 1000 then
			gui.set_color(buy_btn, vmath.vector4(0.18, 0.65, 0.35, 1.0))
		else
			gui.set_color(buy_btn, vmath.vector4(0.35, 0.38, 0.42, 0.8))
		end

		local squad = player_profile.get_squad()
		self.barracks_upgrades = {} -- per slot [i][upg_idx] = { class_id, cost }

		for i = 1, 4 do
			self.barracks_upgrades[i] = {}
			local title_node = gui.get_node("b_slot_title_" .. i)
			local avatar = gui.get_node("b_slot_avatar_" .. i)
			local class_node = gui.get_node("b_slot_class_" .. i)
			local stats_node = gui.get_node("b_slot_stats_" .. i)
			local max_node = gui.get_node("b_slot_max_txt_" .. i)
			local unlock_btn = gui.get_node("b_slot_unlock_btn_" .. i)
			local unlock_txt = gui.get_node("b_slot_unlock_txt_" .. i)

			local btn1 = gui.get_node("b_slot_upg1_btn_" .. i)
			local txt1 = gui.get_node("b_slot_upg1_txt_" .. i)
			local btn2 = gui.get_node("b_slot_upg2_btn_" .. i)
			local txt2 = gui.get_node("b_slot_upg2_txt_" .. i)
			local btn3 = gui.get_node("b_slot_upg3_btn_" .. i)
			local txt3 = gui.get_node("b_slot_upg3_txt_" .. i)

			gui.set_text(title_node, i18n.t("barracks_spud") .. tostring(i))

			local member = squad[i]
			if member then
				-- UNLOCKED POTATO MEMBER
				gui.set_enabled(unlock_btn, false)
				gui.set_enabled(avatar, true)
				gui.set_enabled(class_node, true)
				gui.set_enabled(stats_node, true)

				local c_def = classes.get(member.class_id)
				gui.set_text(class_node, i18n.field(c_def, "name"))

				local hp_val = c_def.stats and c_def.stats.base_hp or 100
				local spd_val = math.floor((c_def.stats and c_def.stats.walk_speed_mult or 1.0) * 100)
				gui.set_text(stats_node, i18n.t("barracks_stats_fmt", hp_val, spd_val))

				local tex_name = camp_data.CLASS_AVATARS[member.class_id] or "recruit"
				gui.play_flipbook(avatar, hash(tex_name))

				-- Available promotions along branch
				local promos = classes.get_promotions(member.class_id)
				if #promos == 0 then
					gui.set_enabled(btn1, false)
					gui.set_enabled(btn2, false)
					gui.set_enabled(btn3, false)
					gui.set_enabled(max_node, true)
					gui.set_text(max_node, i18n.t("barracks_max"))
				else
					gui.set_enabled(max_node, false)
					local upg_btns = { { btn = btn1, txt = txt1 }, { btn = btn2, txt = txt2 }, { btn = btn3, txt = txt3 } }

					for u = 1, 3 do
						local p_class = promos[u]
						local b_pair = upg_btns[u]
						if p_class then
							gui.set_enabled(b_pair.btn, true)
							local p_name = i18n.field(p_class, "name")
							local cost = p_class.star_cost or 2
							gui.set_text(b_pair.txt, i18n.t("barracks_promote_fmt", p_name, cost))
							self.barracks_upgrades[i][u] = { class_id = p_class.id, cost = cost }

							if stars >= cost then
								gui.set_color(b_pair.btn, vmath.vector4(0.18, 0.50, 0.85, 1.0))
							else
								gui.set_color(b_pair.btn, vmath.vector4(0.32, 0.35, 0.40, 0.7))
							end
						else
							gui.set_enabled(b_pair.btn, false)
						end
					end
				end
			else
				-- LOCKED POTATO SLOT
				gui.set_enabled(avatar, false)
				gui.set_enabled(class_node, true)
				gui.set_enabled(stats_node, false)
				gui.set_enabled(max_node, false)
				gui.set_enabled(btn1, false)
				gui.set_enabled(btn2, false)
				gui.set_enabled(btn3, false)
				gui.set_enabled(unlock_btn, true)

				gui.set_text(class_node, i18n.t("barracks_slot_locked"))

				-- Unlock cost: 3rd potato = 3 stars, 4th potato = 7 stars
				local unlock_cost = (i == 3) and 3 or 7
				local can_unlock_now = (i == (#squad + 1))

				if can_unlock_now then
					local star_word = i18n.t((unlock_cost == 3) and "stars_few" or "stars_many")
					gui.set_text(unlock_txt, i18n.t("barracks_unlock_fmt", unlock_cost, star_word))
					if stars >= unlock_cost then
						gui.set_color(unlock_btn, vmath.vector4(0.88, 0.62, 0.15, 1.0))
					else
						gui.set_color(unlock_btn, vmath.vector4(0.35, 0.38, 0.42, 0.7))
					end
				else
					-- Prerequisite needed (e.g. slot 4 requires slot 3 first)
					gui.set_text(unlock_txt, i18n.t("barracks_unlock_first"))
					gui.set_color(unlock_btn, vmath.vector4(0.25, 0.28, 0.32, 0.5))
				end
			end
		end
	end)
end

local function play_result(ok)
	if ok then
		sound_manager.play_heal()
	else
		sound_manager.play_click()
	end
end

function M.register(self)
	self.ui:button("btn_top_barracks", function()
		sound_manager.play_click()
		self.is_barracks_open = true
		M.update(self)
	end)

	self.ui:button("btn_barracks_close", function()
		sound_manager.play_click()
		self.is_barracks_open = false
		M.update(self)
	end)

	-- Buy 1 star for 1000 points
	self.ui:button("btn_barracks_buy_star", function()
		local ok = player_profile.buy_star_with_points()
		play_result(ok)
		M.update(self)
	end)

	-- Unlock potato #3 and #4
	for slot_idx = 3, 4 do
		self.ui:button("b_slot_unlock_btn_" .. slot_idx, function()
			local ok = player_profile.unlock_next_potato()
			play_result(ok)
			M.update(self)
		end)
	end

	-- Upgrade buttons for slots 1..4 (up to 3 branch options per slot)
	for slot_idx = 1, 4 do
		for upg_idx = 1, 3 do
			self.ui:button("b_slot_upg" .. upg_idx .. "_btn_" .. slot_idx, function()
				local slot = self.barracks_upgrades and self.barracks_upgrades[slot_idx]
				local upg_data = slot and slot[upg_idx]
				if upg_data then
					local ok = player_profile.promote_potato(slot_idx, upg_data.class_id, upg_data.cost)
					play_result(ok)
					M.update(self)
				end
			end)
		end
	end
end

return M
