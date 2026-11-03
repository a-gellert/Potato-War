-- gui/hud/hud_popups.lua
-- Floating damage/heal numbers and the achievement toast.

local i18n = require("lua_modules.i18n")
local camera_controller = require("lua_modules.camera_controller")

local M = {}

-- Toast sits below the timer circle and the tutorial hint
local TOAST_Y = 350
local TOAST_HIDDEN_Y = 322

local function damage_color(label, is_heal, is_crit, status)
	if status == "chat" then
		return vmath.vector4(0.92, 0.96, 1.0, 1.0) -- Bot shout: plain white-blue
	elseif is_heal or status == "water" then
		return vmath.vector4(0.18, 1.0, 0.45, 1.0) -- Vibrant emerald green
	elseif status == "poisoned" then
		return vmath.vector4(0.35, 1.0, 0.30, 1.0) -- Poison green
	elseif status == "burning" or status == "fire" or status == "combo" then
		return vmath.vector4(1.0, 0.45, 0.15, 1.0) -- Fire orange
	elseif status == "glued" or status == "concussed" then
		return vmath.vector4(1.0, 0.90, 0.25, 1.0) -- Honey yellow
	elseif is_crit then
		return vmath.vector4(1.0, 0.18, 0.12, 1.0) -- Crit red
	end
	return vmath.vector4(1.0, 0.88, 0.2, 1.0) -- Gold/yellow
end

function M.show_damage(message)
	local sx, sy = camera_controller.world_to_screen(message.x or 480, message.y or 270)
	local x = sx
	local y = sy + 18
	local amt = message.amount or 0
	local is_heal = (message.is_heal == true)
	local is_crit = (not is_heal) and (amt >= 45)
	local label = message.label

	local text_str
	if label then
		text_str = (amt > 0) and (label .. " -" .. tostring(amt)) or label
	else
		text_str = (is_heal and "+" or "-") .. tostring(amt)
	end

	local txt_node = gui.new_text_node(vmath.vector3(x, y, 0), text_str)
	gui.set_font(txt_node, "system_font")
	local base_scale = is_heal and 0.85 or (is_crit and 1.15 or (label and 0.80 or 0.75))
	gui.set_scale(txt_node, vmath.vector3(base_scale * 1.5, base_scale * 1.5, 1.0))
	gui.set_color(txt_node, damage_color(label, is_heal, is_crit, message.status))

	-- Punchy scale-down pop and drifting upward with horizontal scatter
	local scatter_x = (math.random() - 0.5) * 24
	gui.animate(txt_node, "scale", vmath.vector3(base_scale, base_scale, 1.0), gui.EASING_OUTBACK, 0.22)
	gui.animate(txt_node, "position.x", x + scatter_x, gui.EASING_OUTQUAD, 0.75)
	gui.animate(txt_node, "position.y", y + (is_crit and 58 or 44), gui.EASING_OUTQUAD, 0.75)
	gui.animate(txt_node, "color.w", 0.0, gui.EASING_INQUAD, 0.75, 0.25, function()
		pcall(gui.delete_node, txt_node)
	end)
end

local TOAST_ICONS = {
	["🎯"] = "ic_radius",
	["🌊"] = "ic_damage",
	["🏹"] = "ic_battle",
	["🛡️"] = "ic_check",
	["🛡"] = "ic_check",
	["❤️"] = "ic_heart",
	["💥"] = "ic_damage",
	["📦"] = "ic_ammo",
	["⚠️"] = "ic_skull",
	["🏆"] = "ic_trophy",
}

function M.show_toast(message)
	local panel = gui.get_node("toast_panel")
	local txt = gui.get_node("toast_text")
	local pts = message.points or 0
	local pts_str = ""
	if pts > 0 then
		pts_str = i18n.t("toast_pts_fmt", pts)
	end

	gui.set_text(txt, (message.title or "") .. pts_str)
	gui.set_enabled(panel, true)

	gui.cancel_animations(panel, gui.PROP_POSITION)
	gui.cancel_animations(panel, gui.PROP_SCALE)
	gui.set_position(panel, vmath.vector3(480, TOAST_HIDDEN_Y, 0))
	gui.set_scale(panel, vmath.vector3(0.85, 0.85, 1.0))

	gui.animate(panel, gui.PROP_POSITION, vmath.vector3(480, TOAST_Y, 0), gui.EASING_OUTBACK, 0.35)
	gui.animate(panel, gui.PROP_SCALE, vmath.vector3(1.0, 1.0, 1.0), gui.EASING_OUTBACK, 0.35, 0, function()
		gui.animate(panel, gui.PROP_POSITION, vmath.vector3(480, TOAST_HIDDEN_Y, 0), gui.EASING_INQUAD, 0.35, 1.8, function()
			gui.set_enabled(panel, false)
		end)
	end)
end

local FTUE_Y = 440
local FTUE_HIDDEN_Y = 530

local FTUE_COLORS = {
	concussed = vmath.vector4(1.0, 0.85, 0.20, 1.0),
	burning   = vmath.vector4(1.0, 0.48, 0.16, 1.0),
	poisoned  = vmath.vector4(0.35, 1.0, 0.32, 1.0),
	glued     = vmath.vector4(1.0, 0.82, 0.25, 1.0),
}

function M.dismiss_ftue()
	pcall(function()
		local panel = gui.get_node("ftue_card")
		if gui.is_enabled(panel) then
			gui.cancel_animations(panel, gui.PROP_POSITION)
			gui.animate(panel, gui.PROP_POSITION, vmath.vector3(480, FTUE_HIDDEN_Y, 0), gui.EASING_INQUAD, 0.25, 0, function()
				gui.set_enabled(panel, false)
			end)
		end
	end)
end

function M.show_ftue(status_key)
	pcall(function()
		local panel = gui.get_node("ftue_card")
		local title_node = gui.get_node("ftue_title")
		local desc_node = gui.get_node("ftue_desc")

		local title = i18n.t("ftue_status_" .. tostring(status_key) .. "_title")
		local desc = i18n.t("ftue_status_" .. tostring(status_key) .. "_desc")
		if not title or title == "" then
			return
		end

		gui.set_text(title_node, title)
		gui.set_color(title_node, FTUE_COLORS[status_key] or vmath.vector4(1.0, 0.88, 0.2, 1.0))
		gui.set_text(desc_node, desc or "")

		gui.set_enabled(panel, true)
		gui.cancel_animations(panel, gui.PROP_POSITION)
		gui.cancel_animations(panel, gui.PROP_SCALE)
		gui.set_position(panel, vmath.vector3(480, FTUE_HIDDEN_Y, 0))
		gui.set_scale(panel, vmath.vector3(0.9, 0.9, 1.0))

		local sound_manager = require("lua_modules.sound_manager")
		pcall(sound_manager.play, "crate")

		gui.animate(panel, gui.PROP_POSITION, vmath.vector3(480, FTUE_Y, 0), gui.EASING_OUTBACK, 0.38)
		gui.animate(panel, gui.PROP_SCALE, vmath.vector3(1.0, 1.0, 1.0), gui.EASING_OUTBACK, 0.38, 0, function()
			gui.animate(panel, gui.PROP_POSITION, vmath.vector3(480, FTUE_HIDDEN_Y, 0), gui.EASING_INQUAD, 0.3, 3.8, function()
				gui.set_enabled(panel, false)
			end)
		end)
	end)
end

return M
