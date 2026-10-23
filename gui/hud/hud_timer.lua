-- gui/hud/hud_timer.lua
-- Turn timer: seconds inside a circle colored by the active team, with a draining ring.

local constants = require("lua_modules.constants")
local game_state = require("lua_modules.game_state")

local M = {}

local WARN_SECONDS = 5
local COLOR_SWAP_TIME = 0.25
local TEAM_COLORS = {
	[constants.TEAM_BLUE] = vmath.vector4(0.16, 0.50, 0.92, 1.0),
	[constants.TEAM_RED] = vmath.vector4(0.90, 0.24, 0.20, 1.0),
}
local RING_COLOR = vmath.vector4(1.0, 1.0, 1.0, 0.9)
local RING_WARN_COLOR = vmath.vector4(1.0, 0.85, 0.25, 1.0)

function M.init(self)
	self.timer = {
		circle = gui.get_node("timer_circle"),
		ring = gui.get_node("timer_ring"),
		text = gui.get_node("timer_text"),
		last_seconds = -1,
		last_team = nil,
	}
end

local function set_team_color(t, team)
	local color = TEAM_COLORS[team] or TEAM_COLORS[constants.TEAM_BLUE]
	gui.cancel_animations(t.circle, "color")
	gui.animate(t.circle, "color", color, gui.EASING_OUTQUAD, COLOR_SWAP_TIME)
	-- Small pop so the turn change is noticeable
	gui.cancel_animations(t.circle, "scale")
	gui.set_scale(t.circle, vmath.vector3(1.2, 1.2, 1))
	gui.animate(t.circle, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3)
end

function M.update(self)
	local t = self.timer
	local seconds_left = math.max(0, math.ceil(game_state.turn_timer))
	local fraction = math.max(0, math.min(1.0, game_state.turn_timer / constants.TURN_DURATION))

	gui.set_fill_angle(t.ring, 360 * fraction)

	if game_state.active_team ~= t.last_team then
		t.last_team = game_state.active_team
		set_team_color(t, t.last_team)
	end

	if seconds_left ~= t.last_seconds then
		t.last_seconds = seconds_left
		gui.set_text(t.text, tostring(seconds_left))
		local is_warn = (seconds_left <= WARN_SECONDS)
		gui.set_color(t.ring, is_warn and RING_WARN_COLOR or RING_COLOR)
		if is_warn and seconds_left > 0 then
			-- Tick pulse in the final seconds
			gui.cancel_animations(t.text, "scale")
			gui.set_scale(t.text, vmath.vector3(1.35, 1.35, 1))
			gui.animate(t.text, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTQUAD, 0.35)
		end
	end
end

-- Force a full refresh on the next update (new match)
function M.reset(self)
	self.timer.last_seconds = -1
	self.timer.last_team = nil
end

return M
