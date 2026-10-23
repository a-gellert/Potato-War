-- gui/game_over/go_frontline.lua
-- Campaign frontline minimap on the debrief screen, plus the panel layout that depends on it.

local territory_map = require("lua_modules.territory_map")
local i18n = require("lua_modules.i18n")

local M = {}

local BLUE = vmath.vector4(0.20, 0.62, 0.98, 1.0)
local RED = vmath.vector4(0.92, 0.26, 0.24, 1.0)

-- Animates the contested sector dot: flips owner on assault win / defense loss, otherwise a small pop.
local function animate_contested_dot(m_dot, outcome)
	local function flip_to(color)
		gui.animate(m_dot, "scale", vmath.vector3(1.8, 1.8, 1), gui.EASING_OUTBACK, 0.55, 0.2, function()
			gui.set_color(m_dot, color)
			gui.animate(m_dot, "scale", vmath.vector3(1.0, 1.0, 1), gui.EASING_INOUTQUAD, 0.25)
		end)
	end

	if outcome.is_victory and outcome.battle_type == "assault" then
		gui.set_color(m_dot, RED) -- red, then flips to blue
		flip_to(BLUE)
	elseif (not outcome.is_victory) and outcome.battle_type == "defense" then
		gui.set_color(m_dot, BLUE) -- blue, then flips to red
		flip_to(RED)
	else
		gui.animate(m_dot, "scale", vmath.vector3(1.4, 1.4, 1), gui.EASING_OUTQUAD, 0.35, 0, function()
			gui.animate(m_dot, "scale", vmath.vector3(1.0, 1.0, 1), gui.EASING_INQUAD, 0.2)
		end)
	end
end

local function update_minimap(outcome)
	for sid = 1, 18 do
		local sec = territory_map.get_sector(sid)
		local is_blue = (sec and sec.owner == "blue")
		gui.set_color(gui.get_node("m_sec_" .. sid), is_blue and BLUE or RED)
	end

	-- Highlight contested sector
	local active_sid = outcome and outcome.sector_id
	local pulse_node = gui.get_node("m_sec_pulse")
	if active_sid and active_sid >= 1 and active_sid <= 18 then
		local m_dot = gui.get_node("m_sec_" .. active_sid)
		gui.set_position(pulse_node, gui.get_position(m_dot))
		gui.set_enabled(pulse_node, true)
		gui.set_scale(pulse_node, vmath.vector3(0.7, 0.7, 1))
		gui.animate(pulse_node, "scale", vmath.vector3(2.2, 2.2, 1), gui.EASING_OUTQUAD, 0.85, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		animate_contested_dot(m_dot, outcome)
	else
		gui.set_enabled(pulse_node, false)
	end

	-- Territory control counters
	local blue_cnt = #territory_map.get_sectors_by_owner("blue")
	local red_cnt = 18 - blue_cnt
	local pct = math.floor((blue_cnt / 18) * 100)
	gui.set_text(gui.get_node("minimap_legend"), i18n.t("go_legend_fmt", blue_cnt, red_cnt))
	gui.set_size(gui.get_node("minimap_bar_fill"), vmath.vector3(math.floor(250 * (blue_cnt / 18)), 8, 0))
	gui.set_text(gui.get_node("minimap_status_lbl"), string.format(i18n.t("frontline_control_fmt"), blue_cnt, pct))
end

-- Positions the report panels (shifted left when the minimap is shown) and updates the minimap.
function M.layout(is_campaign, outcome)
	local reward_bg = gui.get_node("reward_bg")
	local stats_bg = gui.get_node("debrief_stats_bg")
	local skin_bg = gui.get_node("skin_progress_bg")
	local minimap_bg = gui.get_node("minimap_bg")

	local x = is_campaign and 295 or 480
	gui.set_enabled(minimap_bg, is_campaign)
	gui.set_position(reward_bg, vmath.vector3(x, 338, 0))
	gui.set_position(stats_bg, vmath.vector3(x, 238, 0))
	gui.set_position(skin_bg, vmath.vector3(x, 166, 0))

	if is_campaign then
		update_minimap(outcome)
	end
end

return M
