-- lua_modules/world_events.lua
-- Timed battlefield events for main.script: airship flyby bombing and parachute airdrop crates.

local constants = require("lua_modules.constants")
local weapons = require("lua_modules.weapons")
local game_state = require("lua_modules.game_state")
local i18n = require("lua_modules.i18n")

local M = {}

local AIRSHIP_INTERVAL = 30.0
local CRATE_INTERVAL = 60.0

local function toast(icon, title)
	msg.post("/gui_hud#gui", "show_achievement_toast", { icon = icon, title = title, points = 0 })
end

local function update_airship(self, dt)
	if self.airship_url then
		return
	end
	self.airship_timer = self.airship_timer - dt
	if self.airship_timer <= 0 then
		self.airship_timer = AIRSHIP_INTERVAL
		constants.log(">>> SPAWNING AIRSHIP FLYBY!")
		toast("ic_skull", i18n.t("air_raid_warn"))
		local airship_pos = vmath.vector3(-140, constants.WORLD_HEIGHT * 0.88, 0.35)
		self.airship_url = factory.create("#airship_factory", airship_pos)
	end
end

local function update_airdrop(self, dt)
	self.crate_timer = (self.crate_timer or CRATE_INTERVAL) - dt
	if self.crate_timer > 0 then
		return
	end
	self.crate_timer = CRATE_INTERVAL

	local drop_x = math.random(200, constants.WORLD_WIDTH - 200)
	local is_medkit = (math.random() < 0.5)
	local pickup = weapons.get_random_arena_pickup()
	local w_id = (pickup and pickup.id ~= "grenade") and pickup.id or "dynamite"
	local amt = is_medkit and math.random(20, 50) or math.random(1, 3)

	local c_pos = vmath.vector3(drop_x, constants.WORLD_HEIGHT - 25, 0.2)
	local crate_url = factory.create("#crate_factory", c_pos, nil, {
		crate_type = is_medkit and hash("medkit") or hash("weapon"),
		amount = amt,
		weapon_id = hash(w_id)
	})
	table.insert(self.spawned_crates, { url = crate_url })

	if is_medkit then
		local hp = " (+" .. amt .. " HP)!"
		toast("❤️", i18n.pick({
			ru = "С неба падает аптечка" .. hp,
			en = "Airdrop: Medkit inbound" .. hp,
			pt = "Lançamento aéreo: kit médico a caminho" .. hp,
			fr = "Parachutage : trousse de soins en approche" .. hp,
			es = "Lanzamiento aéreo: botiquín en camino" .. hp,
			tr = "Hava ikmali: ilk yardım çantası geliyor" .. hp,
		}))
	else
		toast("📦", i18n.pick({
			ru = "С неба падает ящик с оружием!",
			en = "Airdrop: Weapon crate inbound!",
			pt = "Lançamento aéreo: caixa de armas a caminho!",
			fr = "Parachutage : caisse d'armes en approche !",
			es = "Lanzamiento aéreo: ¡caja de armas en camino!",
			tr = "Hava ikmali: silah sandığı geliyor!",
		}))
	end
end

function M.update(self, dt)
	local is_battle_running = (game_state.state == constants.STATE_TURN_ACTIVE
		or game_state.state == constants.STATE_ACTION
		or game_state.state == constants.STATE_SETTLING)
	-- Outdoor battles only; the training ground stays calm
	if not is_battle_running or self.current_terrain_preset == "cavern" or game_state.mode == constants.MODE_TUTORIAL then
		return
	end
	update_airship(self, dt)
	update_airdrop(self, dt)
end

function M.on_airship_finished(self)
	self.airship_url = nil
	self.airship_timer = AIRSHIP_INTERVAL
end

return M
