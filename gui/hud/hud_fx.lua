-- gui/hud/hud_fx.lua
-- Full-screen impact flash and small colour helpers for hit feedback.

local kit = require("lua_modules.ui_kit")
local constants = require("lua_modules.constants")
local game_state = require("lua_modules.game_state")

local M = {}

local COL_HURT = vmath.vector4(1.0, 0.18, 0.14, 1.0)
local COL_HIT = vmath.vector4(1.0, 0.78, 0.30, 1.0)
local COL_HEAL = vmath.vector4(0.35, 1.0, 0.45, 1.0)
local COL_STATUS = {
	burning = vmath.vector4(1.0, 0.48, 0.12, 1.0),
	poisoned = vmath.vector4(0.35, 1.0, 0.35, 1.0),
	glued = vmath.vector4(1.0, 0.78, 0.20, 1.0),
	concussed = vmath.vector4(0.45, 0.78, 1.0, 1.0),
	combo = vmath.vector4(1.0, 0.35, 1.0, 1.0),
}

function M.build(self)
	local flash = kit.box(nil, "white", 480, 270, 4000, 3000, vmath.vector4(1, 1, 1, 0))
	gui.set_adjust_mode(flash, gui.ADJUST_STRETCH)
	self.fx = { flash = flash }
end

function M.flash(self, color, alpha)
	local fx = self.fx
	if not fx then
		return
	end
	alpha = alpha or 0.12
	gui.cancel_animations(fx.flash, "color")
	gui.set_color(fx.flash, vmath.vector4(color.x, color.y, color.z, alpha))
	gui.animate(fx.flash, "color.w", 0, gui.EASING_OUTQUAD, 0.30)
end

-- Pick a flash colour from a show_damage message. Player hits flash red, enemy
-- hits gold and heals green; status/combo popups get their own colour.
function M.on_damage(self, message)
	if not message then
		return
	end
	if message.is_heal then
		M.flash(self, COL_HEAL, 0.10)
		return
	end
	if message.status and COL_STATUS[message.status] then
		M.flash(self, COL_STATUS[message.status], 0.08)
		return
	end
	if (message.amount or 0) <= 0 then
		return
	end
	local player_hit = false
	for _, p in ipairs(game_state.potatoes or {}) do
		if p.team == constants.TEAM_BLUE and p.pos then
			if math.abs(p.pos.x - (message.x or 0)) < 70 and math.abs(p.pos.y - (message.y or 0)) < 100 then
				player_hit = true
				break
			end
		end
	end
	M.flash(self, player_hit and COL_HURT or COL_HIT, player_hit and 0.16 or 0.10)
end

return M
