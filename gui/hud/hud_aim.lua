-- gui/hud/hud_aim.lua
-- Live shot-power / angle meter shown while the player drags a shot.
-- Values arrive from aim_guide.script via the "aim_meter" message.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

local COL_CALM = vmath.vector4(0.28, 0.86, 1.0, 1.0)
local COL_STRONG = vmath.vector4(1.0, 0.78, 0.18, 1.0)
local COL_MAX = vmath.vector4(1.0, 0.34, 0.18, 1.0)
local COL_TARGET = vmath.vector4(0.45, 1.0, 0.40, 1.0)
local COL_DANGER = vmath.vector4(1.0, 0.25, 0.20, 1.0)

local function power_color(power)
	if power >= 0.86 then
		return COL_MAX
	elseif power >= 0.56 then
		return COL_STRONG
	end
	return COL_CALM
end

function M.build(self)
	local root = kit.group(nil, 480, 270, 960, 540)
	local panel = kit.inset(root, 0, -172, 336, 76)
	local title = kit.text(panel, "", 0, 23, 14, { font = "label", color = kit.C.gold, max_w = 200 })
	local angle = kit.text(panel, "", 126, 23, 13, { font = "label", color = kit.C.muted, max_w = 60 })
	local bar = kit.bar(panel, -18, -10, 210, 15, kit.C.gold)
	local value = kit.text(panel, "", 156, -10, 15, { font = "label", color = kit.C.white, max_w = 60, align = "right" })
	local status = kit.text(panel, "", 0, -30, 12, { font = "label", color = kit.C.muted, max_w = 300 })
	self.aim_meter = {
		root = root,
		panel = panel,
		title = title,
		value = value,
		angle = angle,
		bar = bar,
		status = status,
		visible = false,
		pulse = 0,
	}
	gui.set_enabled(root, false)
end

function M.hide(self)
	local m = self.aim_meter
	if m then
		m.visible = false
		m.last_state = nil
		m.shown_pct = nil
		m.shown_angle = nil
		gui.set_enabled(m.root, false)
	end
end

function M.set_aiming(self, is_aiming)
	local m = self.aim_meter
	if not m then
		return
	end
	if not is_aiming then
		M.hide(self)
	end
end

function M.set_values(self, message)
	local m = self.aim_meter
	if not m then
		return
	end
	if message.hidden then
		M.hide(self)
		return
	end

	if not m.visible then
		m.visible = true
		gui.set_enabled(m.root, true)
		kit.pop_in(m.panel)
	end

	local power = math.max(0, math.min(1, message.power or 0))
	local danger = message.danger == true
	local on_target = message.on_target == true
	local color = danger and COL_DANGER or (on_target and COL_TARGET or power_color(power))

	m.bar.set(power)
	m.bar.set_color(color)
	m.base_color = color
	m.danger = danger

	local state = danger and "danger" or (on_target and "target" or "normal")
	if state ~= m.last_state then
		m.last_state = state
		if state == "danger" then
			pcall(sound_manager.play, "alarm")
		elseif state == "target" then
			pcall(sound_manager.play, "tick")
		end
		if danger then
			kit.set_text(m.title, i18n.t("aim_danger"), 200, 14, "label")
			kit.set_text(m.status, i18n.t("aim_danger_hint"), 300, 12, "label")
			gui.set_color(m.title, COL_DANGER)
			gui.set_color(m.status, COL_DANGER)
		elseif on_target then
			kit.set_text(m.title, i18n.t("aim_target"), 200, 14, "label")
			kit.set_text(m.status, i18n.t("aim_target_hint"), 300, 12, "label")
			gui.set_color(m.title, COL_TARGET)
			gui.set_color(m.status, COL_TARGET)
		else
			kit.set_text(m.title, i18n.t("aim_power"), 200, 14, "label")
			kit.set_text(m.status, "", 300, 12, "label")
			gui.set_color(m.title, kit.C.gold)
		end
	end

	local pct = math.floor(power * 100 + 0.5)
	if pct ~= m.shown_pct then
		m.shown_pct = pct
		gui.set_color(m.value, color)
		kit.set_text(m.value, string.format("%d%%", pct), 60, 15, "label")
	end
	local angle = math.floor((message.angle or 0) + 0.5)
	if angle ~= m.shown_angle then
		m.shown_angle = angle
		kit.set_text(m.angle, string.format("%d°", angle), 70, 13, "label")
	end
end

function M.update(self, dt)
	local m = self.aim_meter
	if not m or not m.visible then
		return
	end
	m.pulse = (m.pulse or 0) + dt * 7.0
	if m.danger and m.base_color then
		local c = vmath.vector4(m.base_color)
		c.w = 0.65 + 0.35 * math.sin(m.pulse)
		m.bar.set_color(c)
	end
end

return M
