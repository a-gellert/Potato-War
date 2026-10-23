-- gui/game_over/go_actions.lua
-- Action buttons of the debrief screen: wiring and per-outcome visibility.

local constants = require("lua_modules.constants")
local game_state = require("lua_modules.game_state")
local i18n = require("lua_modules.i18n")

local M = {}

function M.register(self)
	self.ui:button("btn_rematch", function()
		msg.post(".", "disable")
		msg.post("/main#main", "start_match", {
			mode = game_state.mode,
			level = game_state.campaign_level or 1,
		})
	end)

	self.ui:button("btn_revive", function()
		msg.post(".", "disable")
		msg.post("/main#main", "revive_player")
	end)

	self.ui:button("btn_next_level", function()
		msg.post(".", "disable")
		msg.post("/main#main", "show_campaign_map")
	end)

	self.ui:button("btn_shop", function()
		msg.post(".", "disable")
		msg.post("/gui_menu#gui", "open_shop", { mode = "skins" })
	end)

	self.ui:button("btn_menu", function()
		msg.post(".", "disable")
		msg.post("/main#main", "show_menu")
	end)
end

-- Shows/hides a button together with its label, optionally setting the label text.
local function set_button(id, enabled, text)
	local btn = gui.get_node("btn_" .. id)
	local txt = gui.get_node("txt_" .. id)
	if text then gui.set_text(txt, text) end
	gui.set_enabled(btn, enabled)
	gui.set_enabled(txt, enabled)
	return btn
end

local function place_primary(btn)
	gui.set_position(btn, vmath.vector3(480, 95, 0))
end

-- Chooses which of next / revive / rematch to show for this outcome; shop and menu are always shown.
function M.show(message, winner, is_campaign)
	if message.is_tutorial or game_state.mode == constants.MODE_TUTORIAL then
		gui.set_color(gui.get_node("title_text"), vmath.vector4(0.2, 0.95, 0.45, 1.0))
		gui.set_text(gui.get_node("title_text"), i18n.t("go_ready_title"))
		gui.set_text(gui.get_node("subtitle_text"), i18n.t("go_ready_sub"))
		place_primary(set_button("next_level", true, i18n.t("go_start_campaign")))
		set_button("revive", false)
		set_button("rematch", false)
		gui.set_enabled(gui.get_node("minimap_bg"), false)
	elseif is_campaign then
		place_primary(set_button("next_level", true, i18n.t("btn_return_hq")))
		set_button("revive", false)
		set_button("rematch", true, i18n.t("go_retry"))
	elseif winner == constants.TEAM_BLUE then
		place_primary(set_button("next_level", true, i18n.t("btn_next_level")))
		set_button("revive", false)
		set_button("rematch", false)
	elseif winner == constants.TEAM_RED then
		set_button("next_level", false)
		place_primary(set_button("revive", true, i18n.t("btn_revive")))
		set_button("rematch", true, i18n.t("btn_rematch"))
	else
		set_button("next_level", false)
		set_button("revive", false)
		set_button("rematch", true, i18n.t("btn_play_again"))
	end

	set_button("shop", true, i18n.t("btn_shop"))
	set_button("menu", true, i18n.t("btn_menu"))
end

return M
