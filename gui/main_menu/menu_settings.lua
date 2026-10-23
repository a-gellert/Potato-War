-- gui/main_menu/menu_settings.lua
-- Settings window: sound and music volume, interface language.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

local STEP = 0.1

local function volume_row(self, parent, kind, y, icon)
	local row = {}
	kit.icon(parent, icon, -195, y, 40)
	row.label = kit.text(parent, "", -165, y, 20, { font = "label", align = "left", max_w = 140 })
	kit.icon_button(self.ui, parent, "set_" .. kind .. "_minus", 10, y, 42, "ic_minus", function()
		sound_manager.set_volume(kind, sound_manager.get_volume(kind) - STEP)
		M.refresh(self)
	end, "round")
	row.bar = kit.bar(parent, 108, y, 130, 18, kit.C.gold)
	kit.icon_button(self.ui, parent, "set_" .. kind .. "_plus", 206, y, 42, "ic_plus", function()
		sound_manager.set_volume(kind, sound_manager.get_volume(kind) + STEP)
		sound_manager.play("click")
		M.refresh(self)
	end, "round")
	return row
end

function M.build(self, on_close)
	local win = kit.window(self.ui, nil, "settings", 500, 330, "", on_close)
	self.settings = win
	local p = win.panel
	win.sfx = volume_row(self, p, "sfx", 72, "ic_sound")
	win.music = volume_row(self, p, "music", 4, "ic_music")

	kit.icon(p, "ic_globe", -195, -66, 40)
	win.lang_label = kit.text(p, "", -165, -66, 20, { font = "label", align = "left", max_w = 140 })
	win.lang = kit.button(self.ui, p, "set_lang", 108, -66, 230, 54, { style = "steel", label = "", px = 20, on_click = function()
		i18n.toggle_lang()
		if self.on_language_changed then
			self.on_language_changed()
		end
	end })
	win.ok = kit.button(self.ui, p, "set_ok", 0, -128, 200, 52, { style = "gold", label = "OK", px = 22, on_click = on_close })
	gui.set_enabled(win.root, false)
end

function M.refresh(self)
	local win = self.settings
	kit.set_text(win.title, i18n.t("ui_settings"), 360, 26, "title")
	kit.set_text(win.sfx.label, i18n.t("ui_sounds"), 140, 20, "label")
	kit.set_text(win.music.label, i18n.t("ui_music"), 140, 20, "label")
	win.sfx.bar.set(sound_manager.get_volume("sfx"))
	win.music.bar.set(sound_manager.get_volume("music"))
	kit.set_text(win.lang_label, i18n.t("ui_language"), 140, 20, "label")
	win.lang.set_label(i18n.LANG_NAMES[i18n.current_lang] or i18n.current_lang)
end

function M.show(self, visible)
	gui.set_enabled(self.settings.root, visible)
	if visible then
		M.refresh(self)
		kit.pop_in(self.settings.panel)
	end
end

return M
