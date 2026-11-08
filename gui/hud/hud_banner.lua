-- gui/hud/hud_banner.lua
-- Short "YOUR TURN / ENEMY TURN / FIGHT!" banner with a soft ray glow.
-- Pure juice: no gameplay logic, no input.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local constants = require("lua_modules.constants")

local M = {}

local BLUE = vmath.vector4(0.35, 0.72, 1.0, 1.0)
local RED = vmath.vector4(1.0, 0.36, 0.30, 1.0)
local GOLD = vmath.vector4(1.0, 0.80, 0.25, 1.0)

function M.build(self)
	local root = kit.group(nil, 480, 270, 960, 540)
	local glow = kit.box(root, "rays", 0, 26, 900, 260, vmath.vector4(1, 0.8, 0.3, 0))
	local title = kit.text(root, "", 0, 26, 38, { font = "title", color = GOLD, max_w = 760 })
	local sub = kit.text(root, "", 0, -14, 14, { font = "label", color = kit.C.white, max_w = 640 })
	self.banner = {
		root = root,
		glow = glow,
		title = title,
		sub = sub,
		timer = nil,
	}
	gui.set_enabled(root, false)
end

function M.hide(self)
	local b = self.banner
	if not b then
		return
	end
	if b.timer then
		timer.cancel(b.timer)
		b.timer = nil
	end
	gui.set_enabled(b.root, false)
end

function M.show(self, title, sub, color)
	local b = self.banner
	if not b then
		return
	end
	M.hide(self)
	gui.set_enabled(b.root, true)
	kit.set_text(b.title, title or "", 760, 38, "title")
	kit.set_text(b.sub, sub or "", 640, 14, "label")
	gui.set_color(b.title, color or GOLD)
	gui.set_color(b.sub, kit.C.white)
	gui.set_color(b.glow, vmath.vector4(color.x, color.y, color.z, 0.16))

	kit.pop_in(b.title)
	gui.cancel_animations(b.glow, "color.w")
	gui.set_color(b.glow, vmath.vector4(color.x, color.y, color.z, 0.18))
	gui.animate(b.glow, "color.w", 0, gui.EASING_OUTQUAD, 0.95)

	b.timer = timer.delay(1.05, false, function()
		b.timer = nil
		if b.root then
			gui.set_enabled(b.root, false)
		end
	end)
end

function M.show_turn(self, team)
	if team == constants.TEAM_BLUE then
		M.show(self, i18n.t("turn_your"), "", BLUE)
	else
		M.show(self, i18n.t("turn_enemy"), "", RED)
	end
end

function M.show_fight(self)
	M.show(self, i18n.t("turn_fight"), i18n.t("turn_fight_sub"), GOLD)
end

return M
