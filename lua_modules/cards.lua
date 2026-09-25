-- lua_modules/cards.lua
-- Card definitions and drawing system for Potato War Campaign Mode

local weapons = require("lua_modules.weapons")
local i18n = require("lua_modules.i18n")

local M = {}

local LOCALIZED_CARD_DATA = {
	grenade = {
		ru = { title = "ГОРЯЧАЯ КАРТОШКА", badge = "Клубень", desc = "Прыгучий горячий клубень!\nУрон: 50 | Радиус: 36", btn_label = "ВЗЯТЬ" },
		en = { title = "HOT POTATO", badge = "Tuber", desc = "Bouncing hot spud bomb!\nDamage: 50 | Radius: 36", btn_label = "TAKE" },
	},
	rifle = {
		ru = { title = "ШАМПУР-СНАЙПЕР", badge = "Точность", desc = "Заостренная шпажка для канапе\nУрон: 45 | Дальний бой", btn_label = "ВЗЯТЬ" },
		en = { title = "SKEWER SNIPER", badge = "Precision", desc = "Sharp bamboo skewer\nDamage: 45 | Long range", btn_label = "TAKE" },
	},
	knife = {
		ru = { title = "КАРТОФЕЛЕЧИСТКА", badge = "Ближний бой", desc = "Срезает кожуру в упор!\nУрон: 60 + Отталкивание", btn_label = "ВЗЯТЬ" },
		en = { title = "POTATO PEELER", badge = "Melee", desc = "Peels enemy in melee range!\nDamage: 60 + Knockback", btn_label = "TAKE" },
	},
	molotov = {
		ru = { title = "ФРИТЮРНОЕ МАСЛО", badge = "Фритюр", desc = "Бутылка с кипящим маслом\nУрон: 20 + Пепелище", btn_label = "ВЗЯТЬ" },
		en = { title = "FRYING OIL", badge = "Deep Fry", desc = "Boiling oil bottle + fry pool\nDamage: 20 + Burn area", btn_label = "TAKE" },
	},
	burst = {
		ru = { title = "ФРИ-АВТОМАТ", badge = "Очередь", desc = "3 быстрых выстрела фри подряд\nУрон: 3x30 = 90 суммарно", btn_label = "ВЗЯТЬ" },
		en = { title = "FRY-O-MATIC", badge = "Burst", desc = "3 crispy french fry shots\nDamage: 3x30 = 90 total", btn_label = "TAKE" },
	},
	bazooka = {
		ru = { title = "ПЮРЕ-БАЗУКА", badge = "Толкушка", desc = "Мортира-толкушка: всё в пюре!\nУрон: 65 | Взрыв: 48", btn_label = "ВЗЯТЬ" },
		en = { title = "MASH-ZOOKA", badge = "Heavy Masher", desc = "Heavy masher rocket: mashes all!\nDamage: 65 | Blast: 48", btn_label = "TAKE" },
	},
	shotgun = {
		ru = { title = "КУХОННАЯ ТЁРКА", badge = "Чипсы", desc = "Веер острых картофельных чипсов!\nУрон: 5x22 = 110 макс.", btn_label = "ВЗЯТЬ" },
		en = { title = "KITCHEN GRATER", badge = "Chips", desc = "5 sharp potato chip shards\nDamage: 5x22 = 110 max", btn_label = "TAKE" },
	},
	holy_grenade = {
		ru = { title = "ЗОЛОТОЙ КЛУБЕНЬ", badge = "Легендарное", desc = "Священная золотая картофелина!\nУрон: 80 | Радиус: 55", btn_label = "ВЗЯТЬ" },
		en = { title = "HOLY SPUD", badge = "Legendary", desc = "Divine golden spud blast!\nDamage: 80 | Radius: 55", btn_label = "TAKE" },
	},
	heal_small = {
		ru = { title = "СМЕТАНКА", badge = "Закуска", desc = "Ложка вкусной сметанки (+25 HP)\nи дает сделать выстрел!", btn_label = "ВЗЯТЬ" },
		en = { title = "SOUR CREAM", badge = "Snack", desc = "A dollop of sour cream (+25 HP)\nand grants a shot!", btn_label = "TAKE" },
	},
	heal_large = {
		ru = { title = "ПАЧКА МАСЛА+", badge = "Деликатес", desc = "Кусок сливочного масла (+40 HP)\nи дает сделать выстрел!", btn_label = "ВЗЯТЬ" },
		en = { title = "BUTTER BLOCK+", badge = "Delicacy", desc = "Creamy block of butter (+40 HP)\nand grants a shot!", btn_label = "TAKE" },
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

