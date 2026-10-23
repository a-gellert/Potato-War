-- gui/hud/hud_indicators.lua
-- Wind widget and the floating badge above the active fighter.

local constants = require("lua_modules.constants")
local game_state = require("lua_modules.game_state")
local i18n = require("lua_modules.i18n")
local camera_controller = require("lua_modules.camera_controller")

local M = {}

local function wind_color(spd)
	if spd > 20 then
		return vmath.vector4(0.95, 0.45, 0.20, 1.0) -- Intense orange/red
	elseif spd > 10 then
		return vmath.vector4(0.95, 0.77, 0.06, 1.0) -- Moderate gold
	end
	return vmath.vector4(0.20, 0.85, 0.95, 1.0) -- Calm cyan
end

function M.update_wind(self)
	local wind_x = game_state.wind_vector and math.floor(game_state.wind_vector.x) or 0
	pcall(function()
		local arrow_node = gui.get_node("wind_arrow")
		local spd = math.abs(wind_x)
		gui.set_text(gui.get_node("wind_title"), i18n.t("wind_title"))
		gui.set_text(gui.get_node("wind_val"), tostring(spd) .. i18n.t("wind_unit"))

		if spd <= 2 then
			-- Calm / No wind (0-2 m/s)
			gui.set_enabled(arrow_node, false)
			return
		end
		gui.set_enabled(arrow_node, true)
		gui.set_rotation(arrow_node, vmath.vector3(0, 0, (wind_x > 0) and 0 or 180))
		local scale_factor = 0.5 + 0.4 * (spd / 30.0)
		gui.set_scale(arrow_node, vmath.vector3(scale_factor, scale_factor, 1.0))
		gui.set_color(arrow_node, wind_color(spd))
	end)
end

local function hide_badges()
	gui.set_enabled(gui.get_node("marker_player_bg"), false)
	gui.set_enabled(gui.get_node("marker_enemy_bg"), false)
end

function M.hide_badges(self)
	pcall(hide_badges)
end

-- Plate with name, micro HP bar and pulsing arrow above the active fighter
function M.update_badges(self, dt)
	self.badge_timer = (self.badge_timer or 0) + dt

	local p = game_state.active_potato
	local is_active_game = (game_state.state == constants.STATE_TURN_ACTIVE or game_state.state == constants.STATE_ACTION)
	if not is_active_game or not p or not p.is_alive then
		hide_badges()
		return
	end

	local sx, sy = camera_controller.world_to_screen(p.pos.x, p.pos.y)
	if sx < 20 or sx > 940 or sy < 20 or sy > 520 then
		hide_badges()
		return
	end

	local is_blue = (p.team == constants.TEAM_BLUE)
	local prefix = is_blue and "marker_player" or "marker_enemy"
	local bg = gui.get_node(prefix .. "_bg")

	gui.set_enabled(gui.get_node("marker_player_bg"), is_blue)
	gui.set_enabled(gui.get_node("marker_enemy_bg"), not is_blue)

	local bounce_y = math.sin(self.badge_timer * 4.5) * 3.0
	local arrow_pulse = 14 + math.sin(self.badge_timer * 6.0) * 2.5
	local hp_pct = math.max(0.01, math.min(1.0, (p.hp or 100) / (p.max_hp or 100)))
	local default_name = i18n.t(is_blue and "name_you" or "name_enemy")

	gui.set_position(bg, vmath.vector3(sx, sy + 34 + bounce_y, 0))
	gui.set_text(gui.get_node(prefix .. "_text"), p.name or default_name)
	gui.set_scale(gui.get_node(prefix .. "_hp_fill"), vmath.vector3(hp_pct, 1.0, 1.0))
	gui.set_position(gui.get_node(prefix .. "_arrow"), vmath.vector3(0, arrow_pulse, 0.1))
end

return M
