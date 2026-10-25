-- gui/hud/hud_tutorial.lua
-- Hint panel, animated drag hand with tension & trajectory visualization,
-- WASD keyboard widget, and mobile arrow indicators:
-- Level 1: teaches shooting with an intuitive hold-and-drag gesture & trajectory arc.
-- Level 2: teaches movement and jumping with WASD/touch indicators.

local constants = require("lua_modules.constants")
local game_state = require("lua_modules.game_state")
local i18n = require("lua_modules.i18n")
local camera_controller = require("lua_modules.camera_controller")
local tutorial = require("lua_modules.tutorial")

local M = {}

local HAND_CYCLE = 2.40
local COLOR_TAP = vmath.vector4(1.0, 0.4, 0.2, 1.0)
local COLOR_DEFAULT = vmath.vector4(1.0, 0.90, 0.25, 1.0)

local COLOR_KEY_ACTIVE = vmath.vector4(1.0, 1.0, 1.0, 1.0)
local COLOR_TEXT_ACTIVE = vmath.vector4(0.18, 0.18, 0.16, 1.0)
local COLOR_KEY_DIMMED = vmath.vector4(0.35, 0.38, 0.42, 0.50)
local COLOR_TEXT_DIMMED = vmath.vector4(0.55, 0.58, 0.62, 0.45)

function M.init(self)
	self.tutorial_hand_done = false
	self.tutorial_hand_timer = 0
	self.tap_hint_timer = 0
	self.tut_anim_timer = 0
	M.hide_all()
end

function M.reset(self)
	self.tutorial_hand_done = false
	self.tutorial_hand_timer = 0
	self.tap_hint_timer = 0
	self.tut_anim_timer = 0
	M.hide_all()
end

function M.hide_all()
	pcall(function()
		gui.set_enabled(gui.get_node("tutorial_hint_panel"), false)
		gui.set_enabled(gui.get_node("tutorial_wasd"), false)
		gui.set_enabled(gui.get_node("tutorial_hand"), false)
		gui.set_enabled(gui.get_node("tutorial_ripple"), false)
		gui.set_enabled(gui.get_node("tut_drag_anchor"), false)
		gui.set_enabled(gui.get_node("tut_drag_dot1"), false)
		gui.set_enabled(gui.get_node("tut_drag_dot2"), false)
		gui.set_enabled(gui.get_node("tut_drag_dot3"), false)
		gui.set_enabled(gui.get_node("tut_arrow_left"), false)
		gui.set_enabled(gui.get_node("tut_arrow_jump"), false)
		gui.set_enabled(gui.get_node("tut_arrow_right"), false)
	end)
	pcall(function()
		msg.post("/aim_guide#aim_guide", "hide_tutorial_aim")
	end)
end

function M.on_hide(self)
	self.tutorial_hand_done = true
	if not tutorial.is_active() then
		M.hide_all()
	end
end

function M.on_tap_hint(self)
	self.tap_hint_timer = 2.5
end

local function tap_text(is_slingshot)
	return i18n.t(is_slingshot and "tut_tap_sling" or "tut_tap_direct")
end

local function arena_text(is_slingshot)
	if is_slingshot then
		return i18n.t("tut_arena_sling")
	end
	return i18n.t("tutorial_hint")
end

local function apply_key_style(key_id, is_highlighted, pulse)
	local box = gui.get_node("tut_key_" .. key_id)
	local txt = gui.get_node("tut_key_" .. key_id .. "_text")
	if is_highlighted then
		gui.set_color(box, COLOR_KEY_ACTIVE)
		gui.set_color(txt, COLOR_TEXT_ACTIVE)
		gui.set_scale(box, vmath.vector3(pulse or 1.0, pulse or 1.0, 1.0))
	else
		gui.set_color(box, COLOR_KEY_DIMMED)
		gui.set_color(txt, COLOR_TEXT_DIMMED)
		gui.set_scale(box, vmath.vector3(1.0, 1.0, 1.0))
	end
end

-- Update desktop WASD cluster
local function update_wasd_keys(stage, pulse)
	local ok, err = pcall(function()
		local wasd = gui.get_node("tutorial_wasd")

		if stage == "move" then
			gui.set_enabled(wasd, true)
			apply_key_style("a", true, pulse)
			apply_key_style("d", true, pulse)
			apply_key_style("w", false)
			apply_key_style("s", false)
		elseif stage == "jump" then
			gui.set_enabled(wasd, true)
			apply_key_style("w", true, pulse)
			apply_key_style("a", false)
			apply_key_style("s", false)
			apply_key_style("d", false)
		else
			gui.set_enabled(wasd, false)
		end
	end)
	if not ok then
		print("ERROR in update_wasd_keys:", err)
	end
end

-- Update mobile arrows bouncing over touch buttons
local function update_mobile_arrows(stage, bounce)
	pcall(function()
		local arrow_l = gui.get_node("tut_arrow_left")
		local arrow_r = gui.get_node("tut_arrow_right")
		local arrow_j = gui.get_node("tut_arrow_jump")

		if stage == "move" then
			gui.set_enabled(arrow_l, true)
			gui.set_enabled(arrow_r, true)
			gui.set_enabled(arrow_j, false)
			gui.set_position(arrow_l, vmath.vector3(0, 44 + bounce, 0.2))
			gui.set_position(arrow_r, vmath.vector3(0, 44 + bounce, 0.2))
		elseif stage == "jump" then
			gui.set_enabled(arrow_l, false)
			gui.set_enabled(arrow_r, false)
			gui.set_enabled(arrow_j, true)
			gui.set_position(arrow_j, vmath.vector3(0, 44 + bounce, 0.2))
		else
			gui.set_enabled(arrow_l, false)
			gui.set_enabled(arrow_r, false)
			gui.set_enabled(arrow_j, false)
		end
	end)
end

local function set_hint_card(title, text, color, is_touch_screen, stage, anim_timer)
	local ok, err = pcall(function()
		local panel = gui.get_node("tutorial_hint_panel")
		local title_node = gui.get_node("tutorial_hint_title")
		local text_node = gui.get_node("tutorial_hint_text")

		gui.set_enabled(panel, true)
		gui.set_text(title_node, title or "")
		gui.set_color(title_node, color or COLOR_DEFAULT)

		local pulse = 1.0 + 0.06 * math.sin(anim_timer * 6.0)
		local bounce = math.sin(anim_timer * 7.5) * 4.5

		if stage == "aim" then
			-- Level 1: Minimalist compact card for shooting, no WASD / no arrows
			pcall(gui.set_enabled, gui.get_node("tutorial_wasd"), false)
			pcall(function()
				gui.set_enabled(gui.get_node("tut_arrow_left"), false)
				gui.set_enabled(gui.get_node("tut_arrow_jump"), false)
				gui.set_enabled(gui.get_node("tut_arrow_right"), false)
			end)
			gui.set_size(panel, vmath.vector3(260, 50, 0))
			gui.set_position(panel, vmath.vector3(480, 435, 0))
			gui.set_position(title_node, vmath.vector3(0, 10, 0.1))
			gui.set_enabled(text_node, true)
			gui.set_position(text_node, vmath.vector3(0, -10, 0.1))
			gui.set_text(text_node, text or "")
			gui.set_color(text_node, vmath.vector4(0.92, 0.95, 1.0, 1.0))
		elseif is_touch_screen then
			-- Mobile / Touch mode: minimal text, bounce arrows over buttons
			pcall(gui.set_enabled, gui.get_node("tutorial_wasd"), false)
			gui.set_size(panel, vmath.vector3(320, 58, 0))
			gui.set_position(panel, vmath.vector3(480, 430, 0))
			gui.set_position(title_node, vmath.vector3(0, 11, 0.1))
			gui.set_enabled(text_node, true)
			gui.set_position(text_node, vmath.vector3(0, -11, 0.1))
			gui.set_text(text_node, text or "")
			gui.set_color(text_node, vmath.vector4(0.88, 0.92, 0.98, 1.0))
			update_mobile_arrows(stage, bounce)
		else
			-- Desktop mode: visual WASD keys in steps 1 and 2, short punchy text in 3 and 4
			pcall(function()
				gui.set_enabled(gui.get_node("tut_arrow_left"), false)
				gui.set_enabled(gui.get_node("tut_arrow_jump"), false)
				gui.set_enabled(gui.get_node("tut_arrow_right"), false)
			end)

			if stage == "move" or stage == "jump" then
				gui.set_size(panel, vmath.vector3(180, 140, 0))
				gui.set_position(panel, vmath.vector3(480, 390, 0))
				gui.set_position(title_node, vmath.vector3(0, 53, 0.1))
				gui.set_enabled(text_node, false)
				update_wasd_keys(stage, pulse)
			else
				pcall(gui.set_enabled, gui.get_node("tutorial_wasd"), false)
				gui.set_size(panel, vmath.vector3(360, 58, 0))
				gui.set_position(panel, vmath.vector3(480, 430, 0))
				gui.set_position(title_node, vmath.vector3(0, 11, 0.1))
				gui.set_enabled(text_node, true)
				gui.set_position(text_node, vmath.vector3(0, -11, 0.1))
				gui.set_text(text_node, text or "")
				gui.set_color(text_node, vmath.vector4(0.88, 0.92, 0.98, 1.0))
			end
		end
	end)
	if not ok then
		print("ERROR in set_hint_card:", err)
	end
end

local function hide_hand()
	pcall(function()
		gui.set_enabled(gui.get_node("tutorial_hand"), false)
		gui.set_enabled(gui.get_node("tutorial_ripple"), false)
		gui.set_enabled(gui.get_node("tut_drag_anchor"), false)
		gui.set_enabled(gui.get_node("tut_drag_dot1"), false)
		gui.set_enabled(gui.get_node("tut_drag_dot2"), false)
		gui.set_enabled(gui.get_node("tut_drag_dot3"), false)
	end)
	pcall(function()
		msg.post("/aim_guide#aim_guide", "hide_tutorial_aim")
	end)
end

-- Clear drag animation: finger presses down firmly on potato, pulls back/up,
-- stretching tension dots and simultaneously visualizing the ballistic trajectory arc!
local function update_hand(self, dt)
	self.tutorial_hand_timer = (self.tutorial_hand_timer or 0) + dt
	local p = game_state.active_potato
	if not (p and p.is_alive) then
		hide_hand()
		return
	end

	-- Find enemy target potato for dynamic aim trajectory preview
	local target = nil
	for _, pot in ipairs(game_state.potatoes or {}) do
		if pot.is_alive and pot.team ~= p.team then
			target = pot
			break
		end
	end

	-- Ideal velocity calculation so the preview trajectory arches right to the enemy
	local dx = target and (target.pos.x - p.pos.x) or 340
	local dy = target and ((target.pos.y + 8) - (p.pos.y + 8)) or 0
	local theta = math.rad(48)
	local cos_t = math.cos(theta)
	local tan_t = math.tan(theta)
	local g = 200 -- constants.GRAVITY * 0.4 (bazooka)
	local denom = 2 * cos_t * cos_t * (dx * tan_t - dy)
	local ideal_v0 = 262
	if denom > 0.001 then
		ideal_v0 = math.sqrt((g * dx * dx) / denom)
	end
	ideal_v0 = math.max(140, math.min(ideal_v0, 420))
	local ideal_vx = ideal_v0 * cos_t
	local ideal_vy = ideal_v0 * math.sin(theta)

	local cycle = self.tutorial_hand_timer % HAND_CYCLE
	local is_slingshot = (game_state.aim_control_mode == "slingshot")
	local sx, sy = camera_controller.world_to_screen(p.pos.x, p.pos.y + 8)

	-- Hand and drag properties
	local hand_alpha = 0
	local hand_scale = 0.65
	local hand_x = sx + 8
	local hand_y = sy - 14

	local anchor_alpha = 0
	local anchor_scale = 0.8
	local ripple_alpha = 0
	local ripple_scale = 0.4
	local dots_alpha = 0

	local max_drag = 82
	local pull_dir_x = is_slingshot and -0.85 or 0.85
	local pull_dir_y = is_slingshot and -0.52 or 0.52

	if cycle < 0.35 then
		-- Phase 1: Hand moves in and presses down (touch contact)
		local t = cycle / 0.35
		hand_alpha = 0.85 * t
		hand_scale = 0.76 - 0.18 * t
		hand_x = sx + 8
		hand_y = sy - 14
		anchor_alpha = 0.65 * t
		anchor_scale = 0.5 + 0.5 * t
		ripple_alpha = 0.5 * (1.0 - t)
		ripple_scale = 0.3 + 0.6 * t
		pcall(function()
			msg.post("/aim_guide#aim_guide", "hide_tutorial_aim")
		end)

	elseif cycle < 1.45 then
		-- Phase 2: Dragging with growing tension and trajectory preview!
		local t = (cycle - 0.35) / 1.10
		local eased = math.sin(t * math.pi * 0.5)
		hand_alpha = 0.88
		hand_scale = 0.58 -- held down firmly
		local cur_drag = max_drag * eased
		hand_x = sx + 8 + cur_drag * pull_dir_x
		hand_y = sy - 14 + cur_drag * pull_dir_y
		anchor_alpha = 0.70 + 0.15 * math.sin(self.tut_anim_timer * 10)
		anchor_scale = 0.85
		dots_alpha = 0.70 * math.min(1.0, cur_drag / 20.0)

		-- Tension velocity: scales trajectory preview arc dynamically!
		local tension = math.max(0.20, eased)
		local preview_vx = ideal_vx * tension
		local preview_vy = ideal_vy * tension
		pcall(function()
			msg.post("/aim_guide#aim_guide", "tutorial_aim_preview", {
				vx = preview_vx,
				vy = preview_vy,
				weapon_id = "bazooka"
			})
		end)

	elseif cycle < 1.80 then
		-- Phase 3: Hold at peak tension — trajectory is at target!
		hand_alpha = 0.88
		hand_scale = 0.58 + 0.02 * math.sin(self.tut_anim_timer * 16)
		hand_x = sx + 8 + max_drag * pull_dir_x
		hand_y = sy - 14 + max_drag * pull_dir_y
		anchor_alpha = 0.70
		anchor_scale = 0.85
		dots_alpha = 0.70
		pcall(function()
			msg.post("/aim_guide#aim_guide", "tutorial_aim_preview", {
				vx = ideal_vx,
				vy = ideal_vy,
				weapon_id = "bazooka"
			})
		end)

	elseif cycle < 2.10 then
		-- Phase 4: Release finger / fire simulation!
		local t = (cycle - 1.80) / 0.30
		hand_alpha = 0.85 * (1.0 - t)
		hand_scale = 0.58 + 0.18 * t
		hand_x = sx + 8 + max_drag * pull_dir_x
		hand_y = sy - 14 + max_drag * pull_dir_y
		anchor_alpha = 0.60 * (1.0 - t)
		anchor_scale = 0.85 + 0.8 * t
		ripple_alpha = 0.65 * (1.0 - t)
		ripple_scale = 0.5 + 1.2 * t
		dots_alpha = 0.70 * (1.0 - t)
		pcall(function()
			msg.post("/aim_guide#aim_guide", "hide_tutorial_aim")
		end)

	else
		-- Phase 5: Brief rest before repeating
		pcall(function()
			msg.post("/aim_guide#aim_guide", "hide_tutorial_aim")
		end)
	end

	-- Apply GUI nodes
	pcall(function()
		local h_node = gui.get_node("tutorial_hand")
		local r_node = gui.get_node("tutorial_ripple")
		local a_node = gui.get_node("tut_drag_anchor")
		local d1 = gui.get_node("tut_drag_dot1")
		local d2 = gui.get_node("tut_drag_dot2")
		local d3 = gui.get_node("tut_drag_dot3")

		gui.set_enabled(h_node, hand_alpha > 0.02)
		if hand_alpha > 0.02 then
			gui.set_position(h_node, vmath.vector3(hand_x, hand_y, 0))
			gui.set_scale(h_node, vmath.vector3(hand_scale, hand_scale, 1))
			gui.set_color(h_node, vmath.vector4(1, 1, 1, hand_alpha))
		end

		gui.set_enabled(a_node, anchor_alpha > 0.02)
		if anchor_alpha > 0.02 then
			gui.set_position(a_node, vmath.vector3(sx + 8, sy - 14, 0))
			gui.set_scale(a_node, vmath.vector3(anchor_scale, anchor_scale, 1))
			gui.set_color(a_node, vmath.vector4(1, 0.85, 0.25, anchor_alpha))
		end

		gui.set_enabled(r_node, ripple_alpha > 0.02)
		if ripple_alpha > 0.02 then
			gui.set_position(r_node, vmath.vector3(sx + 8, sy - 14, 0))
			gui.set_scale(r_node, vmath.vector3(ripple_scale, ripple_scale, 1))
			gui.set_color(r_node, vmath.vector4(1, 1, 1, ripple_alpha))
		end

		gui.set_enabled(d1, dots_alpha > 0.02)
		gui.set_enabled(d2, dots_alpha > 0.02)
		gui.set_enabled(d3, dots_alpha > 0.02)
		if dots_alpha > 0.02 then
			local ax = sx + 8
			local ay = sy - 14
			local c_dot = vmath.vector4(1, 0.90, 0.35, dots_alpha)
			gui.set_position(d1, vmath.vector3(ax + (hand_x - ax) * 0.28, ay + (hand_y - ay) * 0.28, 0))
			gui.set_position(d2, vmath.vector3(ax + (hand_x - ax) * 0.54, ay + (hand_y - ay) * 0.54, 0))
			gui.set_position(d3, vmath.vector3(ax + (hand_x - ax) * 0.78, ay + (hand_y - ay) * 0.78, 0))
			gui.set_color(d1, c_dot)
			gui.set_color(d2, c_dot)
			gui.set_color(d3, c_dot)
		end
	end)
end

function M.update(self, dt)
	self.tut_anim_timer = (self.tut_anim_timer or 0) + dt
	if self.tap_hint_timer > 0 then
		self.tap_hint_timer = self.tap_hint_timer - dt
	end

	local is_player_turn = (game_state.state == constants.STATE_TURN_ACTIVE and game_state.active_team == constants.TEAM_BLUE)
	local is_slingshot = (game_state.aim_control_mode == "slingshot")

	if tutorial.is_active() then
		if not is_player_turn then
			M.hide_all()
			return
		end
		if self.tap_hint_timer > 0 then
			set_hint_card(i18n.t("aim_title") or "ATTACK", tap_text(is_slingshot), COLOR_TAP, self.is_touch_screen, nil, self.tut_anim_timer)
		else
			local info = tutorial.get_step_info(is_slingshot)
			set_hint_card(info.title, info.text, info.color, self.is_touch_screen, info.stage, self.tut_anim_timer)
		end
		if tutorial.wants_hand() and not game_state.is_aiming then
			update_hand(self, dt)
		else
			hide_hand()
		end
		return
	end

	-- Campaign arena 1: one aiming hint until the first aim or the enemy's turn
	if game_state.active_team == constants.TEAM_RED then
		self.tutorial_hand_done = true
	end
	local is_arena_1 = (game_state.mode == constants.MODE_CAMPAIGN and (game_state.campaign_level or 1) == 1)
	if not self.tutorial_hand_done and is_arena_1 and is_player_turn and not game_state.is_aiming then
		if self.tap_hint_timer > 0 then
			set_hint_card(i18n.t("aim_title") or "ATTACK", tap_text(is_slingshot), COLOR_TAP, self.is_touch_screen, nil, self.tut_anim_timer)
		else
			set_hint_card(i18n.t("aim_title") or "ATTACK", arena_text(is_slingshot), COLOR_DEFAULT, self.is_touch_screen, nil, self.tut_anim_timer)
		end
		update_hand(self, dt)
	else
		M.hide_all()
	end
end

return M
