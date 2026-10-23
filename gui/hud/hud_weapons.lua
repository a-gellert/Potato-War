-- gui/hud/hud_weapons.lua
-- Weapon quick bar (5 slots) and the full inventory overlay (12 weapons).

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

function M.update_selection(self, selected_weapon_id)
	local def_color = vmath.vector4(0.20, 0.26, 0.34, 1.0) -- Normal available
	local lock_color = vmath.vector4(0.10, 0.12, 0.15, 0.40) -- Empty / locked

	for i = 1, M.SLOT_COUNT do
		pcall(function()
			local btn_node = gui.get_node("btn_wpn_" .. i)
			local ammo_node = gui.get_node("ammo_wpn_" .. i)
			local icon_node = gui.get_node("icon_wpn_" .. i)

			local w = game_state.get_slot_weapon(i)
			if not w then
				-- Empty slot in loadout
				gui.set_color(btn_node, lock_color)
				gui.set_color(icon_node, vmath.vector4(0, 0, 0, 0))
				gui.set_text(ammo_node, "")
				return
			end

			local ammo = game_state.get_ammo(w.id)
			ui_manager.fit_icon(icon_node, hash(w.icon or w.projectile_sprite or "circle"))

			if w.id == "grenade" then
				gui.set_text(ammo_node, "INF")
				gui.set_color(ammo_node, GOLD)
			else
				gui.set_text(ammo_node, (ammo > 0) and ("x" .. ammo) or "0")
				gui.set_color(ammo_node, (ammo > 0) and WHITE or vmath.vector4(0.5, 0.5, 0.5, 0.5))
			end

			if game_state.is_weapon_unlocked(w.id) then
				gui.set_color(btn_node, w.id == selected_weapon_id and GOLD or def_color)
				gui.set_color(icon_node, WHITE)
			else
				gui.set_color(btn_node, lock_color)
				gui.set_color(icon_node, vmath.vector4(0.4, 0.4, 0.4, 0.35))
			end
		end)
	end
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
					gui.set_text(count_node, "INF")
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
	if game_state.mode == constants.MODE_CAMPAIGN and force_state ~= false then
		force_state = false
	end
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

-- Weapon bar / touch controls / inventory button are shown only on the player's turn
function M.update_panels(self)
	pcall(function()
		local is_player_turn = not game_state.is_bot_turn() and game_state.state == constants.STATE_TURN_ACTIVE
		local is_pvp = (game_state.mode == constants.MODE_PVP_BOTS or game_state.mode == constants.MODE_QUICK_PVP)
		local is_campaign = (game_state.mode == constants.MODE_CAMPAIGN)

		gui.set_enabled(gui.get_node("weapon_panel"), is_player_turn and not is_pvp)
		gui.set_enabled(gui.get_node("touch_controls"), is_player_turn and self.is_touch_screen)
		gui.set_enabled(gui.get_node("btn_inventory"), is_player_turn and not is_campaign)
	end)

	if game_state.selected_weapon_id ~= self.last_weapon then
		self.last_weapon = game_state.selected_weapon_id
		M.update_selection(self, game_state.selected_weapon_id)
	end
end

return M
