-- gui/hud/hud_tutorial.lua
-- Hint panel and animated hand: step-by-step training on the tutorial level
-- (driven by lua_modules.tutorial) and a single aiming hint on campaign arena 1.

local constants = require("lua_modules.constants")
local game_state = require("lua_modules.game_state")
local i18n = require("lua_modules.i18n")
local camera_controller = require("lua_modules.camera_controller")
local tutorial = require("lua_modules.tutorial")

local M = {}

local HAND_CYCLE = 1.55
local COLOR_TAP = vmath.vector4(1.0, 0.4, 0.2, 1.0)
local COLOR_DEFAULT = vmath.vector4(1.0, 0.90, 0.25, 1.0)

function M.init(self)
	self.tutorial_hand_done = false
	self.tutorial_hand_timer = 0
	self.tap_hint_timer = 0
	M.hide_all()
end

function M.reset(self)
	self.tutorial_hand_done = false
	self.tutorial_hand_timer = 0
	self.tap_hint_timer = 0
end

function M.hide_all()
	pcall(function()
		gui.set_enabled(gui.get_node("tutorial_hint_panel"), false)
		gui.set_enabled(gui.get_node("tutorial_hand"), false)
		gui.set_enabled(gui.get_node("tutorial_ripple"), false)
	end)
end

-- Player started aiming / fired: the one-off arena hint is done
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

local function set_hint(text, color)
	pcall(function()
		local hint_text = gui.get_node("tutorial_hint_text")
		gui.set_enabled(gui.get_node("tutorial_hint_panel"), true)
		gui.set_text(hint_text, text)
		gui.set_color(hint_text, color)
	end)
end

-- Hand presses on the potato and drags towards the enemy (direct) or pulls back (slingshot)
local function update_hand(self, dt)
	self.tutorial_hand_timer = (self.tutorial_hand_timer or 0) + dt
	local p = game_state.active_potato
	if not (p and p.is_alive) then
		pcall(function()
			gui.set_enabled(gui.get_node("tutorial_hand"), false)
			gui.set_enabled(gui.get_node("tutorial_ripple"), false)
		end)
		return
	end

	local cycle = self.tutorial_hand_timer % HAND_CYCLE
	local sx, sy = camera_controller.world_to_screen(p.pos.x, p.pos.y)
	local pull = (game_state.aim_control_mode == "slingshot") and -1 or 1
	local alpha = 0
	local scale = 0.62
	local x_off = 11
	local y_off = -17
	local ripple_alpha = 0
	local ripple_scale = 0.3

	if cycle < 0.25 then
		-- 1. Fade in & press down on potato
		local t = cycle / 0.25
		alpha = 0.75 * t
		scale = 0.76 - 0.14 * t
		ripple_alpha = 0.55 * (1.0 - t)
		ripple_scale = 0.3 + 0.5 * t
	elseif cycle < 1.00 then
		-- 2. Drag
		local t = (cycle - 0.25) / 0.75
		local eased = (t < 0.5) and (2 * t * t) or (-1 + (4 - 2 * t) * t)
		alpha = 0.75
		x_off = 11 + pull * 72 * eased
		y_off = -17 + pull * 24 * math.sin(eased * math.pi * 0.5)
	elseif cycle < 1.30 then
		-- 3. Release & fade out
		local t = (cycle - 1.00) / 0.30
		alpha = 0.75 * (1.0 - t)
		scale = 0.62 + 0.14 * t
		x_off = 11 + pull * 72
		y_off = -17 + pull * 24
	end
	-- 4. Pause before repeating (alpha stays 0)

	pcall(function()
		local h_node = gui.get_node("tutorial_hand")
		local r_node = gui.get_node("tutorial_ripple")

		gui.set_enabled(h_node, alpha > 0.02)
		if alpha > 0.02 then
			gui.set_position(h_node, vmath.vector3(sx + x_off, sy + y_off, 0))
			gui.set_scale(h_node, vmath.vector3(scale, scale, 1))
			gui.set_color(h_node, vmath.vector4(1, 1, 1, alpha))
		end

		gui.set_enabled(r_node, ripple_alpha > 0.02)
		if ripple_alpha > 0.02 then
			gui.set_position(r_node, vmath.vector3(sx, sy, 0))
			gui.set_scale(r_node, vmath.vector3(ripple_scale, ripple_scale, 1))
			gui.set_color(r_node, vmath.vector4(1, 1, 1, ripple_alpha))
		end
	end)
end

local function hide_hand()
	pcall(function()
		gui.set_enabled(gui.get_node("tutorial_hand"), false)
		gui.set_enabled(gui.get_node("tutorial_ripple"), false)
	end)
end

function M.update(self, dt)
	if self.tap_hint_timer > 0 then
		self.tap_hint_timer = self.tap_hint_timer - dt
	end

	local is_player_turn = (game_state.state == constants.STATE_TURN_ACTIVE and game_state.active_team == constants.TEAM_BLUE)
	local is_slingshot = (game_state.aim_control_mode == "slingshot")

	if tutorial.is_active() then
		-- Training level: the hint panel stays for the whole level and teaches step by step
		if not is_player_turn then
			M.hide_all()
			return
		end
		if self.tap_hint_timer > 0 then
			set_hint(tap_text(is_slingshot), COLOR_TAP)
		else
			set_hint(tutorial.get_hint(nil, is_slingshot))
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
			set_hint(tap_text(is_slingshot), COLOR_TAP)
		else
			set_hint(arena_text(is_slingshot), COLOR_DEFAULT)
		end
		update_hand(self, dt)
	else
		M.hide_all()
	end
end

return M
