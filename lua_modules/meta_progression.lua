-- lua_modules/meta_progression.lua
-- Global meta-progression upgrades for Potato War:
-- 1. Max Health (Максимальное здоровье)
-- 2. Starting Weapon (Стартовое оружие)
-- 3. Round HP Regeneration (Восстановление HP за раунд в %)

local constants = require("lua_modules.constants")
local player_profile = require("lua_modules.player_profile")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

M.UPGRADE_MAX_HP = "max_hp"
M.UPGRADE_STARTING_WEAPON = "starting_weapon"
M.UPGRADE_HP_REGEN = "hp_regen"

-- Definitions for meta-upgrades
M.UPGRADES = {
	[M.UPGRADE_MAX_HP] = {
		id = M.UPGRADE_MAX_HP,
		max_level = 5,
		name_ru = "МАКС. ЗДОРОВЬЕ",
		name_en = "MAX HEALTH",
		desc_ru = "+15..+25 HP к максимальному здоровью картошки",
		desc_en = "+15..+25 HP to maximum potato health",
		name_pt = "SAÚDE MÁX.",
		name_fr = "SANTÉ MAX.",
		name_es = "SALUD MÁX.",
		name_tr = "MAKS. SAĞLIK",
		desc_pt = "+15..+25 HP na saúde máxima da batata",
		desc_fr = "+15..+25 PV à la santé maximale de la patate",
		desc_es = "+15..+25 HP a la salud máxima de la patata",
		desc_tr = "Patatanın maksimum sağlığına +15..+25 HP",
		icon = "❤️",
		costs = { 250, 1000, 2100, 5000, 9700 },
		bonuses = { 15, 30, 50, 75, 100 }, -- Cumulative bonus HP added to base 100 HP
	},
	[M.UPGRADE_STARTING_WEAPON] = {
		id = M.UPGRADE_STARTING_WEAPON,
		max_level = 5,
		name_ru = "СТАРТОВЫЙ АРСЕНАЛ",
		name_en = "STARTING WEAPONS",
		desc_ru = "Бонусное оружие и патроны в начале каждой битвы",
		desc_en = "Bonus weapons & ammo at start of every battle",
		name_pt = "ARSENAL INICIAL",
		name_fr = "ARSENAL DE DÉPART",
		name_es = "ARSENAL INICIAL",
		name_tr = "BAŞLANGIÇ CEPHANELİĞİ",
		desc_pt = "Armas e munição extras no início de cada batalha",
		desc_fr = "Armes et munitions bonus au début de chaque bataille",
		desc_es = "Armas y munición extra al inicio de cada batalla",
		desc_tr = "Her savaşın başında bonus silah ve mühimmat",
		icon = "💣",
		costs = { 1000, 2200, 3400, 7000, 12000 },
		descriptions = {
			ru = {
				[0] = "Только Граната (Базовый)",
				[1] = "+ Шотган / Тёрка (2 патрона)",
				[2] = "+ Шотган (2) и Снайперка (2)",
				[3] = "+ Шотган (2), Снайперка (2), Базука (2)",
				[4] = "+ Шотган, Снайперка, Базука, Фри-Автомат (3)",
				[5] = "+ Весь арсенал + Золотой Клубень (1)!",
			},
			en = {
				[0] = "Only Grenade (Default)",
				[1] = "+ Shotgun / Grater (2 shots)",
				[2] = "+ Shotgun (2) and Sniper (2)",
				[3] = "+ Shotgun (2), Sniper (2), Bazooka (2)",
				[4] = "+ Shotgun, Sniper, Bazooka, Burst (3)",
				[5] = "+ Full Arsenal + Holy Spud (1)!",
			},
			pt = {
				[0] = "Só Batata Quente (Básico)",
				[1] = "+ Ralador de Cozinha (2 tiros)",
				[2] = "+ Ralador (2) e Espeto Atirador (2)",
				[3] = "+ Ralador (2), Espeto (2), Purê-Bazuca (2)",
				[4] = "+ Ralador, Espeto, Bazuca, Frita-Mática (3)",
				[5] = "+ Arsenal completo + Tubérculo Dourado (1)!",
			},
			fr = {
				[0] = "Seulement Patate Chaude (de base)",
				[1] = "+ Râpe de cuisine (2 tirs)",
				[2] = "+ Râpe (2) et Brochette Sniper (2)",
				[3] = "+ Râpe (2), Brochette (2), Purée-Zooka (2)",
				[4] = "+ Râpe, Brochette, Zooka, Frito-Matic (3)",
				[5] = "+ Arsenal complet + Tubercule Doré (1) !",
			},
			es = {
				[0] = "Solo Patata Caliente (básico)",
				[1] = "+ Rallador de cocina (2 disparos)",
				[2] = "+ Rallador (2) y Brocheta Francotiradora (2)",
				[3] = "+ Rallador (2), Brocheta (2), Puré-Bazuca (2)",
				[4] = "+ Rallador, Brocheta, Bazuca, Fri-Automática (3)",
				[5] = "+ Arsenal completo + Tubérculo Dorado (1)!",
			},
			tr = {
				[0] = "Sadece Sıcak Patates (Temel)",
				[1] = "+ Mutfak Rendesi (2 atış)",
				[2] = "+ Mutfak Rendesi (2) ve Şiş Keskin Nişancı (2)",
				[3] = "+ Mutfak Rendesi (2), Şiş (2), Püre-Bazuka (2)",
				[4] = "+ Mutfak Rendesi, Şiş, Bazuka, Kızartmatik (3)",
				[5] = "+ Tüm cephanelik + Altın Yumru (1)!",
			}
		}
	},
	[M.UPGRADE_HP_REGEN] = {
		id = M.UPGRADE_HP_REGEN,
		max_level = 5,
		name_ru = "РЕГЕНЕРАЦИЯ ЗА ХОД",
		name_en = "ROUND HP REGEN",
		desc_ru = "Восстановление % HP после каждого раунда/выстрела",
		desc_en = "Restores % HP after each shot/round",
		name_pt = "REGENERAÇÃO POR RODADA",
		name_fr = "RÉGÉNÉRATION PAR TOUR",
		name_es = "REGENERACIÓN POR RONDA",
		name_tr = "TUR BAŞI YENİLENME",
		desc_pt = "Restaura % de HP após cada rodada/tiro",
		desc_fr = "Restaure un % de PV après chaque tour/tir",
		desc_es = "Restaura % de HP tras cada ronda/disparo",
		desc_tr = "Her tur/atıştan sonra HP'nin bir yüzdesini yeniler",
		icon = "🌿",
		costs = { 500, 1000, 2000, 5500, 13000 },
		regen_percents = { 5, 10, 15, 20, 25 }, -- % of max HP regenerated per round
	}
}

-- Get current upgrade level
function M.get_level(upgrade_id)
	if not player_profile.data or not player_profile.data.meta_upgrades then
		return 0
	end
	return player_profile.data.meta_upgrades[upgrade_id] or 0
end

-- Get bonus max HP from upgrades
function M.get_max_hp_bonus()
	local lvl = M.get_level(M.UPGRADE_MAX_HP)
	if lvl <= 0 then return 0 end
	local bonuses = M.UPGRADES[M.UPGRADE_MAX_HP].bonuses
	return bonuses[math.min(lvl, #bonuses)] or 0
end

-- Get effective player max HP (Base 100 + Meta Upgrade Bonus)
function M.get_player_max_hp()
	return 100 + M.get_max_hp_bonus()
end

-- Get round HP regen percent (e.g. 0, 5, 10, 15, 20, 25)
function M.get_regen_percent()
	local lvl = M.get_level(M.UPGRADE_HP_REGEN)
	if lvl <= 0 then return 0 end
	local pcts = M.UPGRADES[M.UPGRADE_HP_REGEN].regen_percents
	return pcts[math.min(lvl, #pcts)] or 0
end

-- Get starting weapons table { [weapon_id] = count } based on upgrade level
function M.get_starting_weapons()
	local lvl = M.get_level(M.UPGRADE_STARTING_WEAPON)
	local loadout = {}

	if lvl >= 1 then
		loadout.shotgun = 2
	end
	if lvl >= 2 then
		loadout.rifle = 2
	end
	if lvl >= 3 then
		loadout.bazooka = 2
	end
	if lvl >= 4 then
		loadout.burst = 3
	end
	if lvl >= 5 then
		loadout.holy_grenade = 1
		loadout.molotov = 2
	end

	return loadout
end

-- Apply starting weapons to game_state at campaign/match start
function M.apply_starting_loadout(game_state)
	if not game_state then return end
	local loadout = M.get_starting_weapons()
	for weapon_id, count in pairs(loadout) do
		game_state.add_ammo(weapon_id, count)
	end
end

-- Apply HP regeneration after a round (after shot/turn settles)
-- Returns the actual amount healed
function M.apply_round_regen(potato, game_state)
	if not potato or not potato.is_alive then
		return 0
	end

	local pct = M.get_regen_percent()
	if pct <= 0 then
		return 0
	end

	if potato.hp >= potato.max_hp then
		return 0
	end

	local heal_amount = math.max(1, math.floor(potato.max_hp * (pct / 100)))
	local old_hp = potato.hp
	potato.hp = math.min(potato.max_hp, potato.hp + heal_amount)
	local actual_healed = potato.hp - old_hp

	if actual_healed > 0 then
		sound_manager.play_heal()
		if potato.url then
			msg.post(potato.url, "apply_heal", { amount = actual_healed })
		end
		msg.post("/gui_hud#gui", "show_damage", {
			x = potato.pos.x,
			y = potato.pos.y,
			amount = actual_healed,
			is_heal = true
		})
		if game_state and game_state.mode == constants.MODE_CAMPAIGN then
			player_profile.set_campaign_hp(potato.hp)
		end
		constants.log(">>> META REGEN: Restored", actual_healed, "HP (", pct, "%) for Potato", potato.id)
	end

	return actual_healed
end

-- Get cost for next level of upgrade
function M.get_upgrade_cost(upgrade_id)
	local upg = M.UPGRADES[upgrade_id]
	if not upg then return 0 end
	local cur_lvl = M.get_level(upgrade_id)
	if cur_lvl >= upg.max_level then
		return -1 -- Max level reached
	end
	return upg.costs[cur_lvl + 1] or 999999
end

-- Check if player can afford next level
function M.can_afford(upgrade_id)
	local cost = M.get_upgrade_cost(upgrade_id)
	if cost <= 0 then return false end
	return player_profile.get_points() >= cost
end

-- Buy upgrade
function M.buy_upgrade(upgrade_id)
	local upg = M.UPGRADES[upgrade_id]
	if not upg then return false, "Upgrade not found" end

	local cur_lvl = M.get_level(upgrade_id)
	if cur_lvl >= upg.max_level then
		return false, "Max level already reached"
	end

	local cost = upg.costs[cur_lvl + 1]
	if player_profile.get_points() < cost then
		return false, "Not enough points"
	end

	player_profile.add_points(-cost)
	if not player_profile.data.meta_upgrades then
		player_profile.data.meta_upgrades = {}
	end
	player_profile.data.meta_upgrades[upgrade_id] = cur_lvl + 1

	-- If Max HP was upgraded, update campaign max HP
	if upgrade_id == M.UPGRADE_MAX_HP then
		local new_max = M.get_player_max_hp()
		player_profile.data.campaign_max_hp = new_max
	end

	player_profile.save()
	sound_manager.play_click()
	constants.log(">>> META UPGRADE BOUGHT:", upgrade_id, "New Level:", cur_lvl + 1)
	return true, "Success"
end

return M
