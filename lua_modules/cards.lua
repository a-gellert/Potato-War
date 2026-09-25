-- lua_modules/cards.lua
-- Card definitions and drawing system for Potato War Campaign Mode

local weapons = require("lua_modules.weapons")
local i18n = require("lua_modules.i18n")

local M = {}

local LOCALIZED_CARD_DATA = {
	bazooka = {
		ru = { title = "ПЮРЕ-БАЗУКА (+2)", badge = "Оружие", desc = "Ракетница-толкушка: всё в пюре!\n2 снаряда | Урон: 65 | Взрыв: 48", btn_label = "ВЗЯТЬ" },
		en = { title = "MASH-ZOOKA (+2)", badge = "Weapon", desc = "Heavy rocket masher!\n2 rockets | Damage: 65 | Blast: 48", btn_label = "TAKE" },
	},
	perk_fire_bullets = {
		ru = { title = "ОГНЕННЫЕ ПУЛИ", badge = "Перк", desc = "Гранаты заливают землю огнем!\nШипящее масло жарит врагов", btn_label = "ВЫБРАТЬ" },
		en = { title = "FIRE BULLETS", badge = "Perk", desc = "Grenades splash boiling oil!\nIgnites ground & fries enemies", btn_label = "CHOOSE" },
	},
	perk_triple_jump = {
		ru = { title = "ТРОЙНОЙ ПРЫЖОК", badge = "Перк", desc = "До 3 прыжков подряд в воздухе!\nЛегко выбирайтесь из любых ям", btn_label = "ВЫБРАТЬ" },
		en = { title = "TRIPLE JUMP", badge = "Perk", desc = "Up to 3 consecutive jumps in air!\nEasily leap out of deep craters", btn_label = "CHOOSE" },
	},
	heal_30 = {
		ru = { title = "+30% ЗДОРОВЬЯ", badge = "Лечение", desc = "Вкусная заправка для картошки!\nВосстанавливает +30 HP", btn_label = "ВЗЯТЬ" },
		en = { title = "+30% HEALTH", badge = "Heal", desc = "Delicious potato butter dressing!\nRestores +30 HP", btn_label = "TAKE" },
	},
	burst = {
		ru = { title = "ФРИ-АВТОМАТ (+3)", badge = "Оружие", desc = "3 очереди картошкой фри подряд!\n3 обоймы | Урон: 3x30 = 90", btn_label = "ВЗЯТЬ" },
		en = { title = "FRY-O-MATIC (+3)", badge = "Weapon", desc = "3 fast crispy french fry bursts!\n3 bursts | Damage: 3x30 = 90", btn_label = "TAKE" },
	},
	holy_grenade = {
		ru = { title = "ЗОЛОТОЙ КЛУБЕНЬ (+1)", badge = "Легендарное", desc = "Священная картофелина!\n1 бросок | Урон: 80 | Радиус: 55", btn_label = "ВЗЯТЬ" },
		en = { title = "HOLY SPUD (+1)", badge = "Legendary", desc = "Divine Golden Potato blast!\n1 spud | Damage: 80 | Radius: 55", btn_label = "TAKE" },
	},
	shotgun = {
		ru = { title = "КУХОННАЯ ТЁРКА (+3)", badge = "Оружие", desc = "Веер острых картофельных чипсов!\n3 выстрела | 5x22 = 110 макс.", btn_label = "ВЗЯТЬ" },
		en = { title = "KITCHEN GRATER (+3)", badge = "Weapon", desc = "Sharp potato chip shard blast!\n3 shots | 5x22 = 110 max", btn_label = "TAKE" },
	},
	rifle = {
		ru = { title = "ШАМПУР-СНАЙПЕР (+3)", badge = "Оружие", desc = "Заостренная шпажка насквозь!\n3 выстрела | Дальний бой: 45", btn_label = "ВЗЯТЬ" },
		en = { title = "SKEWER SNIPER (+3)", badge = "Weapon", desc = "Sharp bamboo skewer sniper!\n3 shots | Long range: 45", btn_label = "TAKE" },
	},
	molotov = {
		ru = { title = "ФРИТЮРНОЕ МАСЛО (+2)", badge = "Оружие", desc = "Бутылки с кипящим маслом!\n2 броска | Урон: 20 + Пепелище", btn_label = "ВЗЯТЬ" },
		en = { title = "FRYING OIL (+2)", badge = "Weapon", desc = "Boiling deep fry oil bottles!\n2 bottles | Damage: 20 + Burn pool", btn_label = "TAKE" },
	},
}

M.ALL_CARDS = {
	{ id = "bazooka", type = "weapon", weapon_id = "bazooka", ammo = 2, bg_color = { 0.45, 0.18, 0.18, 1.0 }, accent_color = { 1.0, 0.3, 0.2, 1.0 } },
	{ id = "perk_fire_bullets", type = "perk", perk_id = "fire_bullets", bg_color = { 0.50, 0.28, 0.12, 1.0 }, accent_color = { 1.0, 0.55, 0.1, 1.0 } },
	{ id = "perk_triple_jump", type = "perk", perk_id = "triple_jump", bg_color = { 0.20, 0.35, 0.50, 1.0 }, accent_color = { 0.3, 0.8, 1.0, 1.0 } },
	{ id = "heal_30", type = "heal", heal_amount = 30, bg_color = { 0.15, 0.45, 0.25, 1.0 }, accent_color = { 0.3, 1.0, 0.5, 1.0 } },
	{ id = "burst", type = "weapon", weapon_id = "burst", ammo = 3, bg_color = { 0.28, 0.22, 0.45, 1.0 }, accent_color = { 0.7, 0.5, 1.0, 1.0 } },
	{ id = "holy_grenade", type = "weapon", weapon_id = "holy_grenade", ammo = 1, bg_color = { 0.55, 0.45, 0.15, 1.0 }, accent_color = { 1.0, 0.9, 0.3, 1.0 } },
	{ id = "shotgun", type = "weapon", weapon_id = "shotgun", ammo = 3, bg_color = { 0.30, 0.35, 0.25, 1.0 }, accent_color = { 0.6, 0.9, 0.4, 1.0 } },
	{ id = "rifle", type = "weapon", weapon_id = "rifle", ammo = 3, bg_color = { 0.35, 0.32, 0.22, 1.0 }, accent_color = { 1.0, 0.85, 0.3, 1.0 } },
	{ id = "molotov", type = "weapon", weapon_id = "molotov", ammo = 2, bg_color = { 0.45, 0.25, 0.12, 1.0 }, accent_color = { 1.0, 0.5, 0.15, 1.0 } },
}

local function localize_card(card)
	if not card then return nil end
	local copy = {}
	for k, v in pairs(card) do copy[k] = v end
	local loc_entry = LOCALIZED_CARD_DATA[card.id]
	if loc_entry then
		local lang_data = loc_entry[i18n.current_lang] or loc_entry.en
		copy.title = lang_data.title
		copy.badge = lang_data.badge
		copy.desc = lang_data.desc
		copy.btn_label = lang_data.btn_label
	end
	return copy
end

-- Draw 2 distinct cards for arena start (curated for Level 1 or random for higher levels)
function M.draw_2_cards(player_hp, player_max_hp, level, active_perks)
	level = level or 1
	active_perks = active_perks or {}

	if level == 1 then
		-- Curated first level choices: Bazooka (+2) or Perk Fire Bullets!
		local c1 = M.ALL_CARDS[1] -- bazooka
		local c2 = M.ALL_CARDS[2] -- perk_fire_bullets
		return localize_card(c1), localize_card(c2)
	end

	-- Filter available cards (don't offer perks the player already has)
	local candidates = {}
	for _, c in ipairs(M.ALL_CARDS) do
		local ok = true
		if c.type == "perk" and active_perks[c.perk_id] then
			ok = false
		end
		if c.type == "heal" and (player_hp or 100) >= (player_max_hp or 100) then
			-- Don't prioritize heal if already full HP
			ok = (math.random() > 0.6)
		end
		if ok then
			table.insert(candidates, c)
		end
	end

	if #candidates < 2 then
		candidates = M.ALL_CARDS
	end

	local idx1 = math.random(1, #candidates)
	local idx2 = math.random(1, #candidates - 1)
	if idx2 >= idx1 then
		idx2 = idx2 + 1
	end

	return localize_card(candidates[idx1]), localize_card(candidates[idx2])
end

return M
