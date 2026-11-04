-- gui/hud/hud_pause.lua
-- In-battle Pause and Settings menu with exit confirmation dialog.
-- Uses ui_kit for consistent tactical military visual style.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local sound_manager = require("lua_modules.sound_manager")
local game_state = require("lua_modules.game_state")

local M = {}

local STEP = 0.1

local function hide_aim()
	pcall(msg.post, "/aim_guide#aim_guide", "hide_aim")
end

local function volume_row(self, parent, kind, y, icon)
	local row = {}
	kit.icon(parent, icon, -195, y, 40)
	row.label = kit.text(parent, "", -165, y, 20, { font = "label", align = "left", max_w = 140 })
	kit.icon_button(self.ui, parent, "pause_" .. kind .. "_minus", 10, y, 42, "ic_minus", function()
		sound_manager.set_volume(kind, sound_manager.get_volume(kind) - STEP)
		M.refresh(self)
	end, "round")
	row.bar = kit.bar(parent, 108, y, 130, 18, kit.C.gold)
	kit.icon_button(self.ui, parent, "pause_" .. kind .. "_plus", 206, y, 42, "ic_plus", function()
		sound_manager.set_volume(kind, sound_manager.get_volume(kind) + STEP)
		sound_manager.play("click")
		M.refresh(self)
	end, "round")
	return row
end

function M.build(self)
	local root = kit.group(nil, 480, 270, 960, 540)
	self.pause_root = root

	-- Fullscreen dark dimmer covering any mobile aspect ratio (4000x3000)
	local dimmer = kit.box(root, "dim", 0, 0, 4000, 3000, vmath.vector4(1, 1, 1, 0.78))
	gui.set_adjust_mode(dimmer, gui.ADJUST_STRETCH)

	-- 1. Main Pause / Settings panel
	local panel = kit.panel(root, 0, 0, 520, 370)
	self.pause_panel = panel
	local header = kit.box(panel, "header", 0, 160, 512, 44)
	self.pause_title = kit.text(header, "", 0, 2, 26, { font = "title", color = kit.C.gold, max_w = 400 })
	kit.icon_button(self.ui, panel, "pause_close", 236, 160, 48, "ic_close", function()
		M.toggle(self, false)
	end, "round")

	-- SFX & Music rows
	self.pause_sfx = volume_row(self, panel, "sfx", 95, "ic_sound")
	self.pause_music = volume_row(self, panel, "music", 35, "ic_music")

	-- Language switcher row
	kit.icon(panel, "ic_globe", -195, -25, 40)
	self.pause_lang_label = kit.text(panel, "", -165, -25, 20, { font = "label", align = "left", max_w = 140 })
	self.pause_lang_btn = kit.button(self.ui, panel, "pause_lang", 108, -25, 230, 50, {
		style = "steel",
		label = "",
		px = 20,
		on_click = function()
			i18n.toggle_lang()
			M.refresh(self)
			if self.update_localization then
				self:update_localization()
			end
		end
	})

	-- Action buttons: Resume (Gold) and Exit to Menu (Red)
	self.pause_resume_btn = kit.button(self.ui, panel, "pause_resume", -115, -120, 215, 54, {
		style = "gold",
		label = "",
		px = 20,
		on_click = function()
			M.toggle(self, false)
		end
	})

	self.pause_exit_btn = kit.button(self.ui, panel, "pause_exit", 115, -120, 215, 54, {
		style = "red",
		label = "",
		px = 18,
		on_click = function()
			M.show_confirm(self, true)
		end
	})

	-- 2. Exit Confirmation Dialog (modal within pause)
	local confirm_panel = kit.panel(root, 0, 0, 480, 250)
	self.confirm_panel = confirm_panel
	local conf_hdr = kit.box(confirm_panel, "header", 0, 100, 472, 42)
	self.conf_title = kit.text(conf_hdr, "", 0, 2, 22, { font = "title", color = kit.C.red, max_w = 400 })
	self.conf_desc = kit.text(confirm_panel, "", 0, 28, 17, { font = "label", color = kit.C.muted, max_w = 420 })

	self.conf_cancel_btn = kit.button(self.ui, confirm_panel, "pause_conf_cancel", -110, -55, 190, 52, {
		style = "steel",
		label = "",
		px = 20,
		on_click = function()
			M.show_confirm(self, false)
		end
	})

	self.conf_exit_btn = kit.button(self.ui, confirm_panel, "pause_conf_ok", 110, -55, 190, 52, {
		style = "red",
		label = "",
		px = 20,
		on_click = function()
			M.toggle(self, false)
			game_state.on_level_closed(function()
				msg.post("/main#main", "show_menu")
			end, true, false)
		end
	})

	gui.set_enabled(confirm_panel, false)
	gui.set_enabled(root, false)
	self.is_pause_open = false
	self.is_confirm_open = false
end

function M.refresh_confirm(self)
	kit.set_text(self.conf_title, i18n.t("pause_exit_confirm_title"), 400, 22, "title")
	kit.set_text(self.conf_desc, i18n.t("pause_exit_confirm_desc"), 420, 17, "label")
	self.conf_cancel_btn.set_label(i18n.t("pause_btn_cancel"))
	self.conf_exit_btn.set_label(i18n.t("pause_btn_exit"))
end

function M.refresh(self)
	kit.set_text(self.pause_title, i18n.t("pause_title"), 400, 26, "title")
	kit.set_text(self.pause_sfx.label, i18n.t("ui_sounds"), 140, 20, "label")
	kit.set_text(self.pause_music.label, i18n.t("ui_music"), 140, 20, "label")
	self.pause_sfx.bar.set(sound_manager.get_volume("sfx"))
	self.pause_music.bar.set(sound_manager.get_volume("music"))
	kit.set_text(self.pause_lang_label, i18n.t("ui_language"), 140, 20, "label")
	self.pause_lang_btn.set_label(i18n.LANG_NAMES[i18n.current_lang] or i18n.current_lang)
	self.pause_resume_btn.set_label(i18n.t("pause_resume"))
	self.pause_exit_btn.set_label(i18n.t("pause_exit"))
end

function M.show_confirm(self, visible)
	self.is_confirm_open = visible
	gui.set_enabled(self.pause_panel, not visible)
	gui.set_enabled(self.confirm_panel, visible)
	if visible then
		M.refresh_confirm(self)
		kit.pop_in(self.confirm_panel)
		sound_manager.play("click")
	else
		M.refresh(self)
		kit.pop_in(self.pause_panel)
		sound_manager.play("click")
	end
end

function M.is_open(self)
	return self.is_pause_open == true
end

function M.toggle(self, force_state)
	if force_state ~= nil then
		self.is_pause_open = force_state
	else
		self.is_pause_open = not self.is_pause_open
	end

	self.is_confirm_open = false
	gui.set_enabled(self.confirm_panel, false)
	gui.set_enabled(self.pause_panel, self.is_pause_open)
	gui.set_enabled(self.pause_root, self.is_pause_open)

	game_state.is_paused = self.is_pause_open

	if self.is_pause_open then
		hide_aim()
		M.refresh(self)
		kit.pop_in(self.pause_panel)
		sound_manager.play("click")
	else
		sound_manager.play("click")
		if self.update_localization then
			self:update_localization()
		end
	end
end

function M.on_escape(self)
	if self.is_confirm_open then
		M.show_confirm(self, false)
		return true
	elseif self.is_pause_open then
		M.toggle(self, false)
		return true
	end
	return false
end

return M
