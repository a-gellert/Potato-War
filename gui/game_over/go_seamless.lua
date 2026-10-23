-- gui/game_over/go_seamless.lua
-- Short "VICTORY / DEFEAT + unlocked hat" splash between chained battles.

local constants = require("lua_modules.constants")
local sound_manager = require("lua_modules.sound_manager")
local i18n = require("lua_modules.i18n")

local M = {}

local HIDDEN_NODES = {
	"debrief_banner", "reward_bg", "debrief_stats_bg",
	"skin_progress_bg", "minimap_bg", "header_badge",
	"btn_rematch", "btn_revive", "btn_next_level", "btn_shop", "btn_menu",
	"txt_rematch", "txt_revive", "txt_next_level", "txt_shop", "txt_menu",
}

-- Loops a node's scale between two values (twinkle / pulse).
local function pulse_scale(node, from, to, duration, delay)
	gui.set_scale(node, vmath.vector3(from, from, 1.0))
	gui.animate(node, "scale", vmath.vector3(to, to, 1.0), gui.EASING_INOUTQUAD, duration, delay or 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
end

local function show_title(winner)
	local title_node = gui.get_node("seamless_title")
	local is_win = (winner == constants.TEAM_BLUE)
	if is_win then
		gui.set_text(title_node, i18n.t("victory"))
		gui.set_color(title_node, vmath.vector4(0.2, 0.95, 0.45, 1.0))
	else
		gui.set_text(title_node, i18n.t("defeat"))
		gui.set_color(title_node, vmath.vector4(0.95, 0.25, 0.25, 1.0))
	end

	-- Punch-in with bouncy overshoot
	gui.set_scale(title_node, vmath.vector3(0.2, 0.2, 1.0))
	gui.animate(title_node, "scale", vmath.vector3(1.5, 1.5, 1.0), gui.EASING_OUTBACK, 0.45)
	return is_win
end

local function show_coins(message)
	local coins_amt = message.coins_awarded or message.points or 100
	gui.set_text(gui.get_node("seamless_coins_text"), string.format("🪙 +%d %s", coins_amt, i18n.t("go_coins_word")))
	local coins_bg = gui.get_node("seamless_coins_bg")
	gui.set_scale(coins_bg, vmath.vector3(0.4, 0.4, 1.0))
	gui.animate(coins_bg, "scale", vmath.vector3(1.0, 1.0, 1.0), gui.EASING_OUTBACK, 0.4, 0.1)
end

local function show_hat(message)
	local hat_card = gui.get_node("seamless_hat_card")
	local hat_sprite = gui.get_node("seamless_hat_sprite")

	gui.set_text(gui.get_node("seamless_hat_badge"), i18n.t("go_new_hat"))
	gui.set_text(gui.get_node("seamless_hat_name"), message.unlocked_hat_name or i18n.t("go_default_hat"))

	if message.unlocked_hat_sprite then
		gui.play_flipbook(hat_sprite, hash(message.unlocked_hat_sprite))
	end

	-- Card pop-in
	gui.set_scale(hat_card, vmath.vector3(0.1, 0.1, 1.0))
	gui.animate(hat_card, "scale", vmath.vector3(1.0, 1.0, 1.0), gui.EASING_OUTBACK, 0.5, 0.15)

	-- Floating hat, pulsating aura, twinkling stars
	gui.set_position(hat_sprite, vmath.vector3(0, 8, 0))
	gui.animate(hat_sprite, "position.y", 22, gui.EASING_INOUTQUAD, 0.65, 0.2, nil, gui.PLAYBACK_LOOP_PINGPONG)
	pulse_scale(gui.get_node("seamless_hat_glow"), 0.85, 1.20, 0.75)
	pulse_scale(gui.get_node("seamless_hat_star_1"), 0.85, 1.25, 0.60)
	pulse_scale(gui.get_node("seamless_hat_star_2"), 0.85, 1.25, 0.60, 0.15)
end

function M.show(self, message, winner)
	local seamless_panel = gui.get_node("seamless_panel")
	local seamless_blackout = gui.get_node("seamless_blackout")

	self.seamless_active = true
	gui.set_enabled(seamless_panel, true)
	gui.set_enabled(seamless_blackout, false)
	gui.set_color(seamless_blackout, vmath.vector4(0, 0, 0, 0))

	-- Hide the standard debrief UI and all action buttons
	for _, nid in ipairs(HIDDEN_NODES) do
		pcall(function() gui.set_enabled(gui.get_node(nid), false) end)
	end

	local is_win = show_title(winner)
	show_coins(message)
	show_hat(message)

	if is_win then
		sound_manager.play_victory_march()
	else
		sound_manager.play_defeat_accent()
	end
	sound_manager.play_heal()

	-- Fade out after 2 seconds, then chain into the next stage / menu
	local stage = message.seamless_stage or 1
	timer.delay(2.0, false, function()
		gui.set_enabled(seamless_blackout, true)
		gui.set_color(seamless_blackout, vmath.vector4(0, 0, 0, 0))
		gui.animate(seamless_blackout, "color.w", 1.0, gui.EASING_INQUAD, 0.35, 0, function()
			self.seamless_active = false
			msg.post(".", "disable")
			if stage == 1 then
				msg.post("/main#main", "start_seamless_battle_2")
			else
				msg.post("/main#main", "show_menu")
			end
		end)
	end)
end

function M.hide()
	gui.set_enabled(gui.get_node("seamless_panel"), false)
	gui.set_enabled(gui.get_node("seamless_blackout"), false)
end

return M
