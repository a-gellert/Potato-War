-- lua_modules/cards.lua
-- Card definitions and drawing system for Potato War Campaign Mode

local weapons = require("lua_modules.weapons")
local i18n = require("lua_modules.i18n")

local M = {}

local LOCALIZED_CARD_DATA = {
	grenade = {
		ru = { title = "ГРАНАТА", badge = "Оружие", desc = "+1 Граната в арсенал\nОтскоки и взрыв", btn_label = "ВЗЯТЬ" },
		en = { title = "GRENADE", badge = "Weapon", desc = "+1 Grenade to arsenal\nBouncing blast", btn_label = "TAKE" },
	},
	rifle = {
		ru = { title = "ВИНТОВКА", badge = "Точность", desc = "+1 Снайперка в арсенал\nМгновенный выстрел", btn_label = "ВЗЯТЬ" },
		en = { title = "SNIPER RIFLE", badge = "Precision", desc = "+1 Sniper in arsenal\nInstant hit", btn_label = "TAKE" },
	},
	knife = {
		ru = { title = "БОЕВОЙ НОЖ", badge = "Ближний бой", desc = "+1 Нож в арсенал\nУдар в упор + отброс", btn_label = "ВЗЯТЬ" },
		en = { title = "COMBAT KNIFE", badge = "Melee", desc = "+1 Knife in arsenal\nClose strike + knockback", btn_label = "TAKE" },
	},
	molotov = {
		ru = { title = "МОЛОТОВ", badge = "Огонь", desc = "+1 Молотов в арсенал\nПоджигает область", btn_label = "ВЗЯТЬ" },
		en = { title = "MOLOTOV", badge = "Fire", desc = "+1 Molotov in arsenal\nBurns target area", btn_label = "TAKE" },
	},
	burst = {
		ru = { title = "АВТОМАТ", badge = "Очередь", desc = "+1 Автомат в арсенал\n3 выстрела подряд", btn_label = "ВЗЯТЬ" },
		en = { title = "ASSAULT RIFLE", badge = "Burst", desc = "+1 Rifle in arsenal\n3 burst shots", btn_label = "TAKE" },
	},
	bazooka = {
		ru = { title = "БАЗУКА", badge = "Тяжелое", desc = "+1 Базука в арсенал\nОгромный взрыв!", btn_label = "ВЗЯТЬ" },
		en = { title = "BAZOOKA", badge = "Heavy", desc = "+1 Bazooka in arsenal\nHuge explosive crater!", btn_label = "TAKE" },
	},
	shotgun = {
		ru = { title = "ДРОБОВИК", badge = "Веер", desc = "+1 Дробовик в арсенал\n5 дробинок веером", btn_label = "ВЗЯТЬ" },
		en = { title = "SHOTGUN", badge = "Spread", desc = "+1 Shotgun in arsenal\n5 pellets spread", btn_label = "TAKE" },
	},
	holy_grenade = {
		ru = { title = "СВ. ГРАНАТА", badge = "Легендарное", desc = "+1 Св. Граната\nМаксимальный урон!", btn_label = "ВЗЯТЬ" },
		en = { title = "HOLY GRENADE", badge = "Legendary", desc = "+1 Holy Grenade\nMax damage explosion!", btn_label = "TAKE" },
	},
	heal_small = {
		ru = { title = "АПТЕЧКА", badge = "Здоровье", desc = "+25 Здоровья картошке\nМгновенно!", btn_label = "ЛЕЧИТЬ" },
		en = { title = "FIRST AID", badge = "Health", desc = "+25 HP to your potato\nInstantly!", btn_label = "HEAL" },
	},
	heal_large = {
		ru = { title = "МЕДПАКЕТ+", badge = "Супер Здоровье", desc = "+40 Здоровья картошке\nМаксимальная помощь!", btn_label = "ЛЕЧИТЬ" },
		en = { title = "MEDKIT+", badge = "Super Health", desc = "+40 HP to your potato\nMax healing boost!", btn_label = "HEAL" },
	},
}

M.ALL_CARDS = {
	{ id = "grenade", type = "weapon", weapon_id = "grenade", bg_color = { 0.22, 0.35, 0.55, 1.0 }, accent_color = { 0.4, 0.7, 1.0, 1.0 } },
	{ id = "rifle", type = "weapon", weapon_id = "rifle", bg_color = { 0.35, 0.32, 0.22, 1.0 }, accent_color = { 1.0, 0.85, 0.3, 1.0 } },
	{ id = "knife", type = "weapon", weapon_id = "knife", bg_color = { 0.45, 0.22, 0.22, 1.0 }, accent_color = { 1.0, 0.4, 0.4, 1.0 } },
	{ id = "molotov", type = "weapon", weapon_id = "molotov", bg_color = { 0.50, 0.28, 0.12, 1.0 }, accent_color = { 1.0, 0.55, 0.1, 1.0 } },
	{ id = "burst", type = "weapon", weapon_id = "burst", bg_color = { 0.28, 0.22, 0.45, 1.0 }, accent_color = { 0.7, 0.5, 1.0, 1.0 } },
	{ id = "bazooka", type = "weapon", weapon_id = "bazooka", bg_color = { 0.45, 0.18, 0.18, 1.0 }, accent_color = { 1.0, 0.3, 0.2, 1.0 } },
	{ id = "shotgun", type = "weapon", weapon_id = "shotgun", bg_color = { 0.30, 0.35, 0.25, 1.0 }, accent_color = { 0.6, 0.9, 0.4, 1.0 } },
	{ id = "holy_grenade", type = "weapon", weapon_id = "holy_grenade", bg_color = { 0.55, 0.45, 0.15, 1.0 }, accent_color = { 1.0, 0.9, 0.3, 1.0 } },
	{ id = "heal_small", type = "heal", heal_amount = 25, bg_color = { 0.15, 0.45, 0.25, 1.0 }, accent_color = { 0.3, 1.0, 0.5, 1.0 } },
	{ id = "heal_large", type = "heal", heal_amount = 40, bg_color = { 0.12, 0.52, 0.32, 1.0 }, accent_color = { 0.4, 1.0, 0.6, 1.0 } },
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

-- Draw 2 distinct cards
function M.draw_2_cards(player_hp, player_max_hp)
	player_hp = player_hp or 100
	player_max_hp = player_max_hp or 100

	local weapon_cards = {}
	local heal_cards = {}
	for _, c in ipairs(M.ALL_CARDS) do
		if c.type == "heal" then
			table.insert(heal_cards, c)
		else
			table.insert(weapon_cards, c)
		end
	end

	local heal_chance = (player_hp < player_max_hp * 0.7) and 0.42 or 0.25
	local include_heal = (math.random() < heal_chance) and (#heal_cards > 0)

	local card1, card2

	if include_heal then
		card1 = heal_cards[math.random(1, #heal_cards)]
		card2 = weapon_cards[math.random(1, #weapon_cards)]
		if math.random() > 0.5 then
			card1, card2 = card2, card1
		end
	else
		local idx1 = math.random(1, #weapon_cards)
		local idx2 = math.random(1, #weapon_cards - 1)
		if idx2 >= idx1 then
			idx2 = idx2 + 1
		end
		card1 = weapon_cards[idx1]
		card2 = weapon_cards[idx2]
	end

	return localize_card(card1), localize_card(card2)
end

return M

