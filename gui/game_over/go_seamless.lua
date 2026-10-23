-- gui/game_over/go_seamless.lua
-- Onboarding splash after the training ground: the reward hat and coins, then straight on to the
-- second battle (automatically, or at once on a tap).

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

local AUTO_CONTINUE = 2.6

function M.build(self)
	local root = kit.group(nil, 480, 270, 960, 540)
	self.splash = { root = root }
	local sp = self.splash
	kit.dim(root, 0.8)
	sp.panel = kit.panel(root, 0, -4, 460, 330)
	sp.title = kit.text(sp.panel, "", 0, 132, 30, { font = "title", color = kit.C.gold, max_w = 420 })
	sp.rays = kit.box(sp.panel, "rays", 0, 26, 300, 300, vmath.vector4(1, 0.9, 0.5, 0.45))
	sp.hat = kit.icon(sp.panel, "hat_cap", 0, 30, 130, { texture = "game" })
	sp.badge = kit.text(sp.panel, "", 0, -60, 20, { font = "label", color = kit.C.green })
	sp.name = kit.text(sp.panel, "", 0, -86, 18, { font = "label", max_w = 420 })
	kit.icon(sp.panel, "ic_coin", -36, -124, 34)
	sp.coins = kit.text(sp.panel, "", -14, -124, 24, { font = "label", align = "left", color = kit.C.gold })
	sp.go = kit.button(self.ui, root, "splash_go", 0, -222, 280, 60, { style = "gold", label = "", px = 22, on_click = function()
		M.finish(self)
	end })
	gui.set_enabled(root, false)
end

function M.show(self, data)
	local sp = self.splash
	self.splash_done = false
	gui.set_enabled(sp.root, true)
	kit.set_text(sp.title, i18n.t("ui_tutorial_done"), 420, 30, "title")
	kit.set_icon(sp.hat, data.unlocked_hat_sprite or "hat_cap", 170, 130, "game")
	gui.set_text(sp.badge, i18n.t("ui_new_hat"))
	kit.set_text(sp.name, data.unlocked_hat_name or "", 420, 18, "label")
	gui.set_text(sp.coins, "+" .. (data.coins_awarded or 0))
	sp.go.set_label(i18n.t("ui_continue"))

	kit.pop_in(sp.panel)
	gui.cancel_animations(sp.rays, "rotation.z")
	gui.animate(sp.rays, "rotation.z", 360, gui.EASING_LINEAR, 8, 0, nil, gui.PLAYBACK_LOOP_FORWARD)
	gui.animate(sp.hat, "position.y", 42, gui.EASING_INOUTSINE, 0.7, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	sound_manager.play("win")
	sound_manager.play("unlock")
	timer.delay(AUTO_CONTINUE, false, function()
		M.finish(self)
	end)
end

function M.finish(self)
	if self.splash_done then
		return
	end
	self.splash_done = true
	gui.set_enabled(self.splash.root, false)
	msg.post(".", "disable")
	msg.post("/main#main", "start_seamless_battle_2")
end

function M.hide(self)
	gui.set_enabled(self.splash.root, false)
end

return M
