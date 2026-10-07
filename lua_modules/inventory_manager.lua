-- lua_modules/inventory_manager.lua
-- Class-specific Inventory & Loadout Manager for Potato War
-- Manages potato weapon arsenals, arena pickups, ammo counts, active slots, and class skills.

local classes = require("lua_modules.classes")
local weapons = require("lua_modules.weapons")

local M = {}

M.MAX_LOADOUT_SLOTS = 5
M.inventories = {} -- potato_id -> inventory table

-- Create a new inventory record for a given class
function M.create_inventory(class_id, initial_ammo_overrides)
	class_id = class_id or classes.DEFAULT_CLASS_ID
	local c = classes.get(class_id)

	local inv = {
		class_id = c.id,
		weapons = {},
		loadout = { "grenade" },
		active_weapon_id = "grenade",
		skill = {
			id = c.active_skill and c.active_skill.id or "sprint",
			name = c.active_skill and c.active_skill.name or "Навык",
			cooldown = 0,
			max_cooldown = c.active_skill and c.active_skill.cooldown_turns or 2,
			ready = true,
		},
	}

	-- Initialize all weapons in the database
	for _, w in ipairs(weapons.LIST) do
		local count = 0
		if w.id == "grenade" then
			count = -1 -- Unlimited!
		elseif c.base_arsenal and c.base_arsenal[w.id] ~= nil then
			count = c.base_arsenal[w.id]
		end

		if initial_ammo_overrides and initial_ammo_overrides[w.id] ~= nil then
			count = initial_ammo_overrides[w.id]
		end

		inv.weapons[w.id] = {
			ammo = count,
			unlocked = (count > 0 or count == -1),
			is_base = (c.base_arsenal and c.base_arsenal[w.id] ~= nil),
		}

		-- Build initial 5-slot loadout from class arsenal
		if count > 0 and w.id ~= "grenade" and #inv.loadout < M.MAX_LOADOUT_SLOTS then
			table.insert(inv.loadout, w.id)
		end
	end

	return inv
end

-- Register a potato with a class-specific inventory
function M.register_potato(potato_id, class_id, ammo_overrides)
	local inv = M.create_inventory(class_id, ammo_overrides)
	M.inventories[potato_id] = inv
	return inv
end

-- Get inventory by potato_id
function M.get(potato_id)
	if not potato_id then
		return nil
	end
	if not M.inventories[potato_id] then
		M.inventories[potato_id] = M.create_inventory(classes.DEFAULT_CLASS_ID)
	end
	return M.inventories[potato_id]
end

-- Get ammo count for potato weapon
function M.get_ammo(potato_id, weapon_id)
	if weapon_id == "grenade" then
		return -1
	end
	local inv = M.get(potato_id)
	if not inv or not inv.weapons[weapon_id] then
		local w = weapons.get(weapon_id)
		return (w and w.default_ammo) or 0
	end
	return inv.weapons[weapon_id].ammo or 0
end

-- Check if potato has weapon available (ammo > 0 or unlimited)
function M.has_weapon(potato_id, weapon_id)
	if weapon_id == "grenade" then
		return true
	end
	return M.get_ammo(potato_id, weapon_id) > 0
end

-- Add ammo (from arena pickup, airdrop crate, or card reward)
function M.add_ammo(potato_id, weapon_id, count, is_pickup)
	local inv = M.get(potato_id)
	if not inv then return false end

	if not inv.weapons[weapon_id] then
		inv.weapons[weapon_id] = { ammo = 0, unlocked = false, is_base = false }
	end

	local cur = inv.weapons[weapon_id].ammo
	if cur == -1 then
		return true -- Already unlimited
	end

	inv.weapons[weapon_id].ammo = math.max(0, cur + count)
	inv.weapons[weapon_id].unlocked = (inv.weapons[weapon_id].ammo > 0)
	if is_pickup then
		inv.weapons[weapon_id].is_pickup = true
	end

	-- Add to active 5-slot loadout if not present
	local in_loadout = false
	for _, id in ipairs(inv.loadout) do
		if id == weapon_id then
			in_loadout = true
			break
		end
	end

	if not in_loadout then
		if #inv.loadout < M.MAX_LOADOUT_SLOTS then
			table.insert(inv.loadout, weapon_id)
		else
			-- Replace slot 2 (keeping grenade in slot 1)
			table.remove(inv.loadout, 2)
			table.insert(inv.loadout, weapon_id)
		end
	end

	return true
end

-- Consume ammo on weapon fired
function M.consume_ammo(potato_id, weapon_id)
	if weapon_id == "grenade" then
		return true
	end

	local inv = M.get(potato_id)
	if not inv or not inv.weapons[weapon_id] then
		return false
	end

	local cur = inv.weapons[weapon_id].ammo or 0
	if cur > 0 then
		inv.weapons[weapon_id].ammo = cur - 1
		if inv.weapons[weapon_id].ammo <= 0 then
			inv.weapons[weapon_id].unlocked = false
			-- Remove depleted weapon from active loadout
			for idx, id in ipairs(inv.loadout) do
				if id == weapon_id and id ~= "grenade" then
					table.remove(inv.loadout, idx)
					break
				end
			end
			if inv.active_weapon_id == weapon_id then
				inv.active_weapon_id = "grenade"
			end
		end
		return true
	else
		if inv.active_weapon_id == weapon_id then
			inv.active_weapon_id = "grenade"
		end
		return false
	end
end

-- Select active weapon
function M.select_weapon(potato_id, weapon_id)
	local inv = M.get(potato_id)
	if not inv then return false end

	if weapon_id ~= "grenade" and M.get_ammo(potato_id, weapon_id) <= 0 then
		return false
	end

	inv.active_weapon_id = weapon_id

	-- Ensure it's in loadout
	local in_loadout = false
	for _, id in ipairs(inv.loadout) do
		if id == weapon_id then
			in_loadout = true
			break
		end
	end
	if not in_loadout then
		if #inv.loadout < M.MAX_LOADOUT_SLOTS then
			table.insert(inv.loadout, weapon_id)
		else
			table.remove(inv.loadout, 2)
			table.insert(inv.loadout, weapon_id)
		end
	end

	return true
end

-- Select loadout slot
function M.select_slot(potato_id, slot_idx)
	local inv = M.get(potato_id)
	if not inv then return false end
	local w_id = inv.loadout[slot_idx]
	if w_id and M.has_weapon(potato_id, w_id) then
		return M.select_weapon(potato_id, w_id)
	end
	return false
end

-- Get current loadout list
function M.get_loadout(potato_id)
	local inv = M.get(potato_id)
	return (inv and inv.loadout) or { "grenade" }
end

-- Check skill readiness
function M.can_use_skill(potato_id)
	local inv = M.get(potato_id)
	if not inv or not inv.skill then return false end
	return (inv.skill.cooldown or 0) <= 0
end

-- Use active skill
function M.use_skill(potato_id)
	local inv = M.get(potato_id)
	if not inv or not inv.skill or not M.can_use_skill(potato_id) then
		return false, "on_cooldown"
	end

	inv.skill.cooldown = inv.skill.max_cooldown or 2
	inv.skill.ready = false
	return true, inv.skill.id
end

-- Update cooldowns at turn boundary
function M.update_turn(potato_id)
	local inv = M.get(potato_id)
	if not inv or not inv.skill then return end

	if inv.skill.cooldown > 0 then
		inv.skill.cooldown = inv.skill.cooldown - 1
		inv.skill.ready = (inv.skill.cooldown <= 0)
	end
end

-- Reset all inventories (for new match)
function M.reset()
	M.inventories = {}
end

return M
