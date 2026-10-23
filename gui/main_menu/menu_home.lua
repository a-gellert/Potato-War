-- gui/main_menu/menu_home.lua
-- Home screen: layout, localization, overlay switching (lobby / shop), top-level buttons.

local sound_manager = require("lua_modules.sound_manager")
local i18n = require("lua_modules.i18n")
local menu_lobby = require("gui.main_menu.menu_lobby")
local menu_shop = require("gui.main_menu.menu_shop")

local M = {}

local function set_enabled(node_id, enabled)
	gui.set_enabled(gui.get_node(node_id), enabled)
end

function M.set_background_enabled(enabled)
	pcall(function()
		set_enabled("btn_campaign", enabled)
		set_enabled("btn_quick_pvp", enabled)
		set_enabled("btn_shop", enabled)
		set_enabled("btn_lang", enabled)
	end)
end

function M.hide_overlays()
	pcall(function()
		set_enabled("shop_overlay", false)
		set_enabled("lobby_overlay", false)
	end)
end

-- Places and colors the main menu buttons.
function M.layout()
	pcall(function()
		local function place(id, y, color)
			local btn = gui.get_node(id)
			gui.set_enabled(btn, true)
			gui.set_position(btn, vmath.vector3(480, y, 0))
			gui.set_size(btn, vmath.vector3(320, 48, 0))
			gui.set_color(btn, color)
		end
		place("btn_campaign", 290, vmath.vector4(0.18, 0.76, 0.38, 1.0)) -- Hero Green
		place("btn_quick_pvp", 225, vmath.vector4(0.70, 0.38, 0.28, 1.0))
		place("btn_shop", 165, vmath.vector4(0.18, 0.50, 0.82, 1.0))

		-- Unused upgrades button
		local upg_btn = gui.get_node("btn_quick_bot")
		gui.set_enabled(upg_btn, false)
		gui.set_position(upg_btn, vmath.vector3(-9999, -9999, 0))

		gui.set_position(gui.get_node("hint_text"), vmath.vector3(480, 95, 0))
	end)
end

function M.update_localized(self)
	pcall(function()
		gui.set_text(gui.get_node("title_text"), i18n.t("title"))
		gui.set_text(gui.get_node("subtitle_text"), i18n.t("subtitle"))
		gui.set_text(gui.get_node("txt_campaign"), i18n.t("menu_campaign"))
		gui.set_text(gui.get_node("txt_quick_pvp"), i18n.t("menu_quick"))
		gui.set_text(gui.get_node("hint_text"), i18n.t("hint_controls"))
		gui.set_text(gui.get_node("txt_lang"), i18n.t("lang_btn"))
		gui.set_text(gui.get_node("txt_shop"), i18n.t("menu_shop"))
		gui.set_text(gui.get_node("txt_shop_back"), i18n.t("menu_back"))
	end)
	menu_shop.update_points(self)
	menu_lobby.update(self)
end

function M.register(self)
	self.ui:button("btn_campaign", function()
		sound_manager.play_click()
		msg.post(".", "disable")
		msg.post("/gui_campaign_map", "enable")
		msg.post("/gui_campaign_map#gui", "show")
	end)

	self.ui:button("btn_quick_pvp", function()
		M.set_background_enabled(false)
		pcall(set_enabled, "lobby_overlay", true)
		menu_lobby.update(self)
	end)

	self.ui:button("btn_shop", function()
		self.overlay_mode = "skins"
		M.set_background_enabled(false)
		pcall(set_enabled, "shop_overlay", true)
		menu_shop.update(self)
	end)

	self.ui:button("btn_lang", function()
		i18n.toggle_lang()
		M.update_localized(self)
		menu_shop.update(self)
	end)

	self.ui:button("btn_shop_back", function()
		pcall(set_enabled, "shop_overlay", false)
		M.set_background_enabled(true)
		menu_shop.update_points(self)
	end)

	menu_lobby.register(self, function()
		pcall(set_enabled, "lobby_overlay", false)
		M.set_background_enabled(true)
		M.update_localized(self)
	end)
	menu_shop.register(self)
end

return M
