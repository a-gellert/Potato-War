-- gui/hud/hud_weapons.lua
-- Inventory overlay and active weapon button.

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")
local game_state = require("lua_modules.game_state")
local i18n = require("lua_modules.i18n")
local ui_manager = require("lua_modules.ui_manager")

local M = {}

M.SLOT_COUNT = 5
M.INVENTORY_COUNT = 12

local WHITE = vmath.vector4(1, 1, 1, 1)
local GOLD = vmath.vector4(0.95, 0.77, 0.06, 1.0)
local DIMMED = vmath.vector4(0.5, 0.5, 0.5, 0.6)

function M.update_selection(self, selected_weapon_id)
	pcall(function()
		local w_id = selected_weapon_id or game_state.selected_weapon_id or "grenade"
		local w = weapons.get(w_id)
		if not w then
			w = weapons.get("grenade")
		end

		local icon_node = gui.get_node("icon_inventory")
		local ammo_node = gui.get_node("ammo_inventory")
		local txt_node = gui.get_node("txt_inventory")

		gui.set_text(txt_node, i18n.t("btn_inventory"))

		if w then
			ui_manager.fit_icon(icon_node, hash(w.icon or w.projectile_sprite or "circle"))
			gui.set_color(icon_node, WHITE)

			local ammo = game_state.get_ammo(w.id)
			if w.id == "grenade" then
				gui.set_text(ammo_node, i18n.t("ammo_inf"))
				gui.set_color(ammo_node, GOLD)
			else
				gui.set_text(ammo_node, (ammo > 0) and ("x" .. ammo) or "0")
				gui.set_color(ammo_node, (ammo > 0) and WHITE or DIMMED)
			end
		end
	end)
end

function M.update_inventory(self)
	local def_color = vmath.vector4(0.18, 0.23, 0.30, 0.95) -- Available
	local dimmed_bg = vmath.vector4(0.06, 0.08, 0.10, 0.40) -- Darkened cell when ammo = 0
	local dimmed_icon = vmath.vector4(0.20, 0.20, 0.20, 0.25)
	local dimmed_txt = vmath.vector4(0.35, 0.35, 0.35, 0.40)

	pcall(function()
		gui.set_text(gui.get_node("inventory_title"), i18n.t("inventory_title"))
		gui.set_text(gui.get_node("inventory_sub"), i18n.t("inventory_sub"))
		gui.set_text(gui.get_node("txt_inventory"), i18n.t("btn_inventory"))
	end)

	for i = 1, M.INVENTORY_COUNT do
		local ok, err = pcall(function()
			local w = weapons.LIST[i]
			if not w then return end

			local slot_node = gui.get_node("inv_slot_" .. i)
			local icon_node = gui.get_node("inv_icon_" .. i)
			local name_node = gui.get_node("inv_name_" .. i)
			local count_node = gui.get_node("inv_ammo_" .. i)

			ui_manager.fit_icon(icon_node, hash(w.icon or w.projectile_sprite or "circle"))

			gui.set_text(name_node, i18n.field(w, "name"))

			local ammo = game_state.get_ammo(w.id)
			local is_selected = (game_state.selected_weapon_id == w.id)

			if w.id == "grenade" or ammo > 0 then
				if w.id == "grenade" then
					gui.set_text(count_node, i18n.t("ammo_inf"))
					gui.set_color(count_node, GOLD)
				else
					gui.set_text(count_node, "x" .. ammo)
					gui.set_color(count_node, WHITE)
				end
				gui.set_color(slot_node, is_selected and GOLD or def_color)
				gui.set_color(icon_node, WHITE)
				gui.set_color(name_node, WHITE)
			else
				-- 0 ammo: Darken the cell, icon, and labels
				gui.set_text(count_node, "0")
				gui.set_color(count_node, dimmed_txt)
				gui.set_color(slot_node, dimmed_bg)
				gui.set_color(icon_node, dimmed_icon)
				gui.set_color(name_node, dimmed_txt)
			end
		end)
		if not ok then
			constants.log(">>> ERROR IN update_inventory slot " .. i .. ":", err)
		end
	end
end

function M.toggle_inventory(self, force_state)
	if force_state ~= nil then
		self.is_inventory_open = force_state
	else
		self.is_inventory_open = not self.is_inventory_open
	end
	pcall(function()
		gui.set_enabled(gui.get_node("inventory_overlay"), self.is_inventory_open)
	end)
	if self.is_inventory_open then
		M.update_inventory(self)
	end
end

function M.select_inventory_weapon(self, weapon_id)
	if weapon_id ~= "grenade" and game_state.get_ammo(weapon_id) <= 0 then
		return -- Cannot select empty dimmed weapon!
	end
	game_state.select_weapon(weapon_id)
	M.update_selection(self, weapon_id)
	M.update_inventory(self)
	M.toggle_inventory(self, false)
end

-- Weapon controls and touch jump are shown during player turn
function M.update_panels(self)
	pcall(function()
		local is_player_turn = not game_state.is_bot_turn() and game_state.state == constants.STATE_TURN_ACTIVE

		gui.set_enabled(gui.get_node("touch_controls"), is_player_turn and self.is_touch_screen)
		gui.set_enabled(gui.get_node("touch_jump"), is_player_turn and self.is_touch_screen)
		gui.set_enabled(gui.get_node("btn_inventory"), is_player_turn)
	end)

	local current_potato_id = game_state.active_potato and game_state.active_potato.id
	if game_state.selected_weapon_id ~= self.last_weapon or current_potato_id ~= self.last_potato_id then
		self.last_weapon = game_state.selected_weapon_id
		self.last_potato_id = current_potato_id
		M.update_selection(self, game_state.selected_weapon_id)
		if self.is_inventory_open then
			M.update_inventory(self)
		end
	end
end

return M
