-- gui/campaign_map/camp_inspector.lua
-- Sector inspector panel: dossier text, owner/status cards, attack & fortify buttons.

local territory_map = require("lua_modules.territory_map")
local strategic_campaign = require("lua_modules.strategic_campaign")
local classes = require("lua_modules.classes")
local i18n = require("lua_modules.i18n")
local level_config = require("lua_modules.level_config")
local camp_data = require("gui.campaign_map.camp_data")

local M = {}

function M.update(self)
	local s = territory_map.get_sector(self.selected_sector_id)
	if not s then
		pcall(function()
			gui.set_enabled(gui.get_node("panel_inspector"), false)
		end)
		return
	end

	pcall(function()
		gui.set_enabled(gui.get_node("panel_inspector"), true)

		-- Badge & Title
		gui.set_text(gui.get_node("insp_badge_txt"), i18n.t("camp_recon_dossier"))
		local s_name = i18n.field(s, "name")
		local id_prefix = string.format("[#%02d] ", s.id)
		gui.set_text(gui.get_node("insp_title"), id_prefix .. s_name)

		-- Region
		local reg_info = territory_map.REGIONS[s.region]
		local reg_name = reg_info and i18n.field(reg_info, "name") or ""
		local reg_icon = (s.region == 1 and "🌿 ") or (s.region == 2 and "🏜️ ") or (s.region == 3 and "❄️ ") or "🌋 "
		gui.set_text(gui.get_node("insp_region"), reg_icon .. reg_name)

		-- Owner
		local is_blue = (s.owner == "blue")
		local owner_text = is_blue and i18n.t("camp_owner_blue") or i18n.t("camp_owner_red")
		gui.set_text(gui.get_node("insp_owner_txt"), owner_text)
		local owner_card = gui.get_node("insp_owner_card")
		if is_blue then
			gui.set_color(owner_card, vmath.vector4(0.12, 0.32, 0.65, 1.0))
		else
			gui.set_color(owner_card, vmath.vector4(0.65, 0.16, 0.18, 1.0))
		end

		-- Defense & Garrison
		local def_lvl = s.defense_level or 1
		local stars = camp_data.DEF_STARS[def_lvl] or "★☆☆"
		local def_name = camp_data.get_defense_name(def_lvl)
		local def_str = string.format("%s (%s)", stars, def_name)
		gui.set_text(gui.get_node("insp_def_txt"), i18n.t("insp_defense") .. def_str)

		local lvl_cfg = level_config.get(s.id)
		local gar_count = (not is_blue and lvl_cfg.enemy_count) or s.garrison or 2
		local gar_str = string.format(i18n.t("camp_garrison_fmt"), gar_count)
		if not is_blue and lvl_cfg.enemy_classes and #lvl_cfg.enemy_classes > 0 then
			local cls_names = {}
			for idx, cid in ipairs(lvl_cfg.enemy_classes) do
				local cdef = classes.get(cid)
				local cname = cdef and i18n.field(cdef, "name") or cid
				local clvl = (lvl_cfg.enemy_levels and lvl_cfg.enemy_levels[idx]) or 1
				if clvl > 1 then
					cname = cname .. "★"
				end
				table.insert(cls_names, cname)
			end
			gar_str = gar_str .. " (" .. table.concat(cls_names, ", ") .. ")"
		end
		gui.set_text(gui.get_node("insp_gar_txt"), gar_str)

		-- Income
		gui.set_text(gui.get_node("insp_inc_txt"), string.format(i18n.t("camp_income_fmt"), s.income or 25))

		-- Terrain
		local ter_name = camp_data.get_terrain_display_name(s.terrain_preset)
		gui.set_text(gui.get_node("insp_ter_txt"), string.format(i18n.t("camp_terrain_fmt"), ter_name))

		-- Tactical status & Buttons
		local can_atk = territory_map.can_attack(s.id)
		local supplies = strategic_campaign.get_supplies()
		local fort_cost = territory_map.get_fortify_cost(s.id)

		local status_txt_node = gui.get_node("insp_stat_txt")
		local status_card_node = gui.get_node("insp_stat_card")

		if s.under_attack then
			gui.set_text(status_txt_node, i18n.t("camp_status_under_attack"))
			gui.set_color(status_txt_node, vmath.vector4(1.0, 0.25, 0.25, 1.0))
			gui.set_color(status_card_node, vmath.vector4(0.40, 0.10, 0.10, 1.0))
		elseif is_blue then
			gui.set_text(status_txt_node, i18n.t("camp_status_defend"))
			gui.set_color(status_txt_node, vmath.vector4(0.35, 0.85, 0.95, 1.0))
			gui.set_color(status_card_node, vmath.vector4(0.10, 0.22, 0.35, 1.0))
		elseif can_atk then
			gui.set_text(status_txt_node, i18n.t("camp_status_ready"))
			gui.set_color(status_txt_node, vmath.vector4(0.95, 0.85, 0.20, 1.0))
			gui.set_color(status_card_node, vmath.vector4(0.35, 0.28, 0.10, 1.0))
		else
			gui.set_text(status_txt_node, i18n.t("camp_status_deep"))
			gui.set_color(status_txt_node, vmath.vector4(0.65, 0.68, 0.75, 1.0))
			gui.set_color(status_card_node, vmath.vector4(0.15, 0.18, 0.22, 1.0))
		end

		-- ATTACK Button
		local btn_atk = gui.get_node("btn_insp_attack")
		local txt_atk = gui.get_node("txt_insp_attack")
		if can_atk then
			gui.set_enabled(btn_atk, true)
			gui.set_color(btn_atk, vmath.vector4(0.18, 0.74, 0.35, 1.0)) -- Vibrant Combat Green
			gui.set_text(txt_atk, i18n.t("camp_btn_attack"))
		elseif s.under_attack and is_blue then
			gui.set_enabled(btn_atk, true)
			gui.set_color(btn_atk, vmath.vector4(0.85, 0.25, 0.20, 1.0)) -- Defense Red
			gui.set_text(txt_atk, i18n.t("insp_repel"))
		else
			gui.set_enabled(btn_atk, false)
			gui.set_color(btn_atk, vmath.vector4(0.25, 0.28, 0.32, 1.0))
			gui.set_text(txt_atk, i18n.t("camp_btn_attack"))
		end

		-- FORTIFY Button
		local btn_fort = gui.get_node("btn_insp_fortify")
		local txt_fort = gui.get_node("txt_insp_fortify")
		if is_blue then
			gui.set_enabled(btn_fort, true)
			if def_lvl >= 3 then
				gui.set_color(btn_fort, vmath.vector4(0.25, 0.35, 0.45, 1.0))
				gui.set_text(txt_fort, i18n.t("camp_btn_max_fort"))
			else
				local has_enough = (supplies >= fort_cost)
				if has_enough then
					gui.set_color(btn_fort, vmath.vector4(0.88, 0.62, 0.15, 1.0))
				else
					gui.set_color(btn_fort, vmath.vector4(0.35, 0.38, 0.42, 1.0))
				end
				gui.set_text(txt_fort, string.format(i18n.t("camp_btn_fortify"), fort_cost))
			end
		else
			gui.set_enabled(btn_fort, false)
			gui.set_color(btn_fort, vmath.vector4(0.22, 0.25, 0.28, 1.0))
			gui.set_text(txt_fort, i18n.t("insp_enemy_base"))
		end
	end)
end

return M
