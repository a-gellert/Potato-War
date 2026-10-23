-- gui/main_menu/menu_lobby.lua
-- Quick-battle lobby overlay: potato count, opponent, hats, biome, relief, start.

local player_profile = require("lua_modules.player_profile")
local i18n = require("lua_modules.i18n")
local menu_data = require("gui.main_menu.menu_data")

local BIOMES = menu_data.BIOMES
local RELIEFS = menu_data.RELIEFS

local M = {}

function M.init_state(self)
	self.lobby_count = 3
	self.lobby_opponent = "bot"
	self.lobby_skin_blue_idx = 1
	self.lobby_skin_red_idx = 1
	self.lobby_biome_idx = 1
	self.lobby_relief_idx = 1
end

function M.update(self)
	pcall(function()
		gui.set_text(gui.get_node("lobby_title"), i18n.t("lobby_title"))
		gui.set_text(gui.get_node("lobby_subtitle"), i18n.t("lobby_subtitle"))
		gui.set_text(gui.get_node("lbl_count"), i18n.t("lbl_potatoes_count"))
		gui.set_text(gui.get_node("lbl_opponent"), i18n.t("lbl_mode"))
		gui.set_text(gui.get_node("lbl_skin_blue"), i18n.t("lbl_skin_blue"))
		gui.set_text(gui.get_node("lbl_skin_red"), i18n.t("lbl_skin_red"))
		gui.set_text(gui.get_node("lbl_biome"), i18n.t("lbl_location"))
		gui.set_text(gui.get_node("lbl_relief"), i18n.t("lbl_relief"))
		gui.set_text(gui.get_node("txt_lobby_start"), i18n.t("btn_start_battle"))
		gui.set_text(gui.get_node("txt_lobby_back"), i18n.t("btn_back"))

		gui.set_text(gui.get_node("txt_opp_bot"), i18n.t("mode_bot_opt"))
		gui.set_text(gui.get_node("txt_opp_human"), i18n.t("mode_human_opt"))

		-- Count buttons 1..4 and opponent buttons: highlight the selected one
		local active_col = vmath.vector4(0.18, 0.5, 0.82, 1.0)
		local inactive_col = vmath.vector4(0.2, 0.25, 0.32, 1.0)
		for i = 1, 4 do
			gui.set_color(gui.get_node("btn_cnt_" .. i), (self.lobby_count == i) and active_col or inactive_col)
		end
		gui.set_color(gui.get_node("btn_opp_bot"), (self.lobby_opponent == "bot") and active_col or inactive_col)
		gui.set_color(gui.get_node("btn_opp_human"), (self.lobby_opponent == "human") and active_col or inactive_col)

		-- Selected hats
		local skins = player_profile.SKINS
		local s_blue = skins[self.lobby_skin_blue_idx] or skins[1]
		local s_red = skins[self.lobby_skin_red_idx] or skins[1]
		gui.set_text(gui.get_node("txt_skin_blue_val"), player_profile.get_skin_name(s_blue, i18n.current_lang))
		gui.set_text(gui.get_node("txt_skin_red_val"), player_profile.get_skin_name(s_red, i18n.current_lang))

		-- Biome & relief
		local biome = BIOMES[self.lobby_biome_idx] or BIOMES[1]
		gui.set_text(gui.get_node("txt_biome_val"), i18n.pick(biome))
		local relief = RELIEFS[self.lobby_relief_idx] or RELIEFS[1]
		gui.set_text(gui.get_node("txt_relief_val"), i18n.pick(relief))
	end)
end

-- Wraps a 1-based index forward/backward over a list of `total` items.
local function cycle(idx, total, step)
	return ((idx - 1 + step) % total) + 1
end

-- Registers a prev/next button pair that cycles self[field] over `total` items.
local function register_selector(self, prefix, field, total)
	self.ui:button(prefix .. "_prev", function()
		self[field] = cycle(self[field], total, -1)
		M.update(self)
	end)
	self.ui:button(prefix .. "_next", function()
		self[field] = cycle(self[field], total, 1)
		M.update(self)
	end)
end

-- on_back is supplied by the screen controller (it owns the background menu).
function M.register(self, on_back)
	for i = 1, 4 do
		self.ui:button("btn_cnt_" .. i, function()
			self.lobby_count = i
			M.update(self)
		end)
	end

	self.ui:button("btn_opp_bot", function()
		self.lobby_opponent = "bot"
		M.update(self)
	end)
	self.ui:button("btn_opp_human", function()
		self.lobby_opponent = "human"
		M.update(self)
	end)

	local total_skins = #player_profile.SKINS
	register_selector(self, "btn_skin_blue", "lobby_skin_blue_idx", total_skins)
	register_selector(self, "btn_skin_red", "lobby_skin_red_idx", total_skins)
	register_selector(self, "btn_biome", "lobby_biome_idx", #BIOMES)
	register_selector(self, "btn_relief", "lobby_relief_idx", #RELIEFS)

	self.ui:button("btn_lobby_start", function()
		msg.post(".", "disable")
		local s_blue = player_profile.SKINS[self.lobby_skin_blue_idx] or player_profile.SKINS[1]
		local s_red = player_profile.SKINS[self.lobby_skin_red_idx] or player_profile.SKINS[1]
		msg.post("/main#main", "start_battle", {
			potato_count = self.lobby_count,
			opponent_type = self.lobby_opponent,
			skin_blue = s_blue.id,
			skin_red = s_red.id,
			biome = BIOMES[self.lobby_biome_idx].id,
			terrain_type = RELIEFS[self.lobby_relief_idx].id,
		})
	end)

	self.ui:button("btn_lobby_back", on_back)
end

return M
