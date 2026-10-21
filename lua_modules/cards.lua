-- lua_modules/cards.lua
-- Card definitions and drawing system for Potato War Campaign Mode

local weapons = require("lua_modules.weapons")
local i18n = require("lua_modules.i18n")

local M = {}

local LOCALIZED_CARD_DATA = {
	bazooka = {
		ru = { title = "БАЗУКА (+2)", badge = "ОРУЖИЕ", dmg_str = "65", btn_label = "ВЗЯТЬ" },
		en = { title = "BAZOOKA (+2)", badge = "WEAPON", dmg_str = "65", btn_label = "TAKE" },
		tr = { title = "BAZUKA (+2)", badge = "SİLAH", dmg_str = "65", btn_label = "AL" },
		es = { title = "BAZUCA (+2)", badge = "ARMA", dmg_str = "65", btn_label = "TOMAR" },
		pt = { title = "BAZUCA (+2)", badge = "ARMA", dmg_str = "65", btn_label = "PEGAR" },
		fr = { title = "BAZOOKA (+2)", badge = "ARME", dmg_str = "65", btn_label = "PRENDRE" },
		icon = "masher_bazooka",
	},
	heal_30 = {
		ru = { title = "+30 ЗДОРОВЬЯ", badge = "ЛЕЧЕНИЕ", dmg_str = "+30 HP", btn_label = "ВЗЯТЬ" },
		en = { title = "+30 HEALTH", badge = "HEAL", dmg_str = "+30 HP", btn_label = "TAKE" },
		tr = { title = "+30 CAN", badge = "İYİLEŞME", dmg_str = "+30 HP", btn_label = "AL" },
		es = { title = "+30 SALUD", badge = "CURACIÓN", dmg_str = "+30 HP", btn_label = "TOMAR" },
		pt = { title = "+30 VIDA", badge = "CURA", dmg_str = "+30 HP", btn_label = "PEGAR" },
		fr = { title = "+30 SANTÉ", badge = "SOIN", dmg_str = "+30 HP", btn_label = "PRENDRE" },
		icon = "holy_spud",
	},
	burst = {
		ru = { title = "АВТОМАТ (+3)", badge = "ОРУЖИЕ", dmg_str = "90 (3x30)", btn_label = "ВЗЯТЬ" },
		en = { title = "ASSAULT RIFLE (+3)", badge = "WEAPON", dmg_str = "90 (3x30)", btn_label = "TAKE" },
		tr = { title = "OTOMATİK TÜFEK (+3)", badge = "SİLAH", dmg_str = "90 (3x30)", btn_label = "AL" },
		es = { title = "FUSIL DE ASALTO (+3)", badge = "ARMA", dmg_str = "90 (3x30)", btn_label = "TOMAR" },
		pt = { title = "FUZIL DE ASSALTO (+3)", badge = "ARMA", dmg_str = "90 (3x30)", btn_label = "PEGAR" },
		fr = { title = "FUSIL D'ASSAUT (+3)", badge = "ARME", dmg_str = "90 (3x30)", btn_label = "PRENDRE" },
		icon = "rifle",
	},
	holy_grenade = {
		ru = { title = "МОЩНАЯ ГРАНАТА (+1)", badge = "ОРУЖИЕ", dmg_str = "80", btn_label = "ВЗЯТЬ" },
		en = { title = "HOLY SPUD (+1)", badge = "WEAPON", dmg_str = "80", btn_label = "TAKE" },
		tr = { title = "KUTSAL PATATES (+1)", badge = "SİLAH", dmg_str = "80", btn_label = "AL" },
		es = { title = "PAPA SAGRADA (+1)", badge = "ARMA", dmg_str = "80", btn_label = "TOMAR" },
		pt = { title = "BATATA SAGRADA (+1)", badge = "ARMA", dmg_str = "80", btn_label = "PEGAR" },
		fr = { title = "PATATE SACRÉE (+1)", badge = "ARME", dmg_str = "80", btn_label = "PRENDRE" },
		icon = "holy_spud",
	},
	shotgun = {
		ru = { title = "ДРОБОВИК (+3)", badge = "ОРУЖИЕ", dmg_str = "110 (5x22)", btn_label = "ВЗЯТЬ" },
		en = { title = "SHOTGUN (+3)", badge = "WEAPON", dmg_str = "110 (5x22)", btn_label = "TAKE" },
		tr = { title = "POMPALI TÜFEK (+3)", badge = "SİLAH", dmg_str = "110 (5x22)", btn_label = "AL" },
		es = { title = "ESCOPETA (+3)", badge = "ARMA", dmg_str = "110 (5x22)", btn_label = "TOMAR" },
		pt = { title = "ESPINGARDA (+3)", badge = "ARMA", dmg_str = "110 (5x22)", btn_label = "PEGAR" },
		fr = { title = "FUSIL À POMPE (+3)", badge = "ARME", dmg_str = "110 (5x22)", btn_label = "PRENDRE" },
		icon = "grater",
	},
	rifle = {
		ru = { title = "ВИНТОВКА (+3)", badge = "ОРУЖИЕ", dmg_str = "45", btn_label = "ВЗЯТЬ" },
		en = { title = "SNIPER RIFLE (+3)", badge = "WEAPON", dmg_str = "45", btn_label = "TAKE" },
		tr = { title = "KESKİN NİŞANCI (+3)", badge = "SİLAH", dmg_str = "45", btn_label = "AL" },
		es = { title = "FRANCOTIRADOR (+3)", badge = "ARMA", dmg_str = "45", btn_label = "TOMAR" },
		pt = { title = "FRANCO-ATIRADOR (+3)", badge = "ARMA", dmg_str = "45", btn_label = "PEGAR" },
		fr = { title = "FUSIL DE PRÉCISION (+3)", badge = "ARME", dmg_str = "45", btn_label = "PRENDRE" },
		icon = "skewer_rifle",
	},
	molotov = {
		ru = { title = "МОЛОТОВ (+2)", badge = "ОРУЖИЕ", dmg_str = "20 + ОГОНЬ", btn_label = "ВЗЯТЬ" },
		en = { title = "MOLOTOV (+2)", badge = "WEAPON", dmg_str = "20 + FIRE", btn_label = "TAKE" },
		tr = { title = "MOLOTOV (+2)", badge = "SİLAH", dmg_str = "20 + ATEŞ", btn_label = "AL" },
		es = { title = "MOLOTOV (+2)", badge = "ARMA", dmg_str = "20 + FUEGO", btn_label = "TOMAR" },
		pt = { title = "MOLOTOV (+2)", badge = "ARMA", dmg_str = "20 + FOGO", btn_label = "PEGAR" },
		fr = { title = "MOLOTOV (+2)", badge = "ARME", dmg_str = "20 + FEU", btn_label = "PRENDRE" },
		icon = "oil_bottle",
	},
	knife = {
		ru = { title = "НОЖ (+3)", badge = "ОРУЖИЕ", dmg_str = "60 + ТОЛЧОК", btn_label = "ВЗЯТЬ" },
		en = { title = "KNIFE (+3)", badge = "WEAPON", dmg_str = "60 + PUSH", btn_label = "TAKE" },
		tr = { title = "BIÇAK (+3)", badge = "SİLAH", dmg_str = "60 + İTME", btn_label = "AL" },
		es = { title = "CUCHILLO (+3)", badge = "ARMA", dmg_str = "60 + EMPUJE", btn_label = "TOMAR" },
		pt = { title = "FACA (+3)", badge = "ARMA", dmg_str = "60 + EMPURRÃO", btn_label = "PEGAR" },
		fr = { title = "COUTEAU (+3)", badge = "ARME", dmg_str = "60 + POUSSÉE", btn_label = "PRENDRE" },
		icon = "peeler",
	},
	beetle = {
		ru = { title = "ЖУКИ (+2)", badge = "ОРУЖИЕ", dmg_str = "72 (3x24)", btn_label = "ВЗЯТЬ" },
		en = { title = "BEETLES (+2)", badge = "WEAPON", dmg_str = "72 (3x24)", btn_label = "TAKE" },
		tr = { title = "BÖCEKLER (+2)", badge = "SİLAH", dmg_str = "72 (3x24)", btn_label = "AL" },
		es = { title = "ESCARABAJOS (+2)", badge = "ARMA", dmg_str = "72 (3x24)", btn_label = "TOMAR" },
		pt = { title = "BESOUROS (+2)", badge = "ARMA", dmg_str = "72 (3x24)", btn_label = "PEGAR" },
		fr = { title = "COLÉOPTÈRES (+2)", badge = "ARME", dmg_str = "72 (3x24)", btn_label = "PRENDRE" },
		icon = "beetle_crate",
	},
	drill = {
		ru = { title = "БУР (+2)", badge = "ОРУЖИЕ", dmg_str = "60 (БУРЕНИЕ)", btn_label = "ВЗЯТЬ" },
		en = { title = "DRILL (+2)", badge = "WEAPON", dmg_str = "60 (PIERCE)", btn_label = "TAKE" },
		tr = { title = "MATKAP (+2)", badge = "SİLAH", dmg_str = "60 (DELME)", btn_label = "AL" },
		es = { title = "TALADRO (+2)", badge = "ARMA", dmg_str = "60 (PERFORAR)", btn_label = "TOMAR" },
		pt = { title = "FURADEIRA (+2)", badge = "ARMA", dmg_str = "60 (PERFURAR)", btn_label = "PEGAR" },
		fr = { title = "PERCEUSE (+2)", badge = "ARME", dmg_str = "60 (PERÇAGE)", btn_label = "PRENDRE" },
		icon = "drill_missile",
	},
	pepper = {
		ru = { title = "ПЕРЕЦ (+2)", badge = "ОРУЖИЕ", dmg_str = "20 + ЯД", btn_label = "ВЗЯТЬ" },
		en = { title = "CHILI PEPPER (+2)", badge = "WEAPON", dmg_str = "20 + POISON", btn_label = "TAKE" },
		tr = { title = "BİBER (+2)", badge = "SİLAH", dmg_str = "20 + ZEHİR", btn_label = "AL" },
		es = { title = "CHILE (+2)", badge = "ARMA", dmg_str = "20 + VENENO", btn_label = "TOMAR" },
		pt = { title = "PIMENTA (+2)", badge = "ARMA", dmg_str = "20 + VENENO", btn_label = "PEGAR" },
		fr = { title = "PIMENT (+2)", badge = "ARME", dmg_str = "20 + POISON", btn_label = "PRENDRE" },
		icon = "pepper_bomb",
	},
	garlic = {
		ru = { title = "ЧЕСНОК (+2)", badge = "ОРУЖИЕ", dmg_str = "25 + ТОЛЧОК", btn_label = "ВЗЯТЬ" },
		en = { title = "GARLIC (+2)", badge = "WEAPON", dmg_str = "25 + PUSH", btn_label = "TAKE" },
		tr = { title = "SARIMSAK (+2)", badge = "SİLAH", dmg_str = "25 + İTME", btn_label = "AL" },
		es = { title = "AJO (+2)", badge = "ARMA", dmg_str = "25 + EMPUJE", btn_label = "TOMAR" },
		pt = { title = "ALHO (+2)", badge = "ARMA", dmg_str = "25 + EMPURRÃO", btn_label = "PEGAR" },
		fr = { title = "AIL (+2)", badge = "ARME", dmg_str = "25 + POUSSÉE", btn_label = "PRENDRE" },
		icon = "garlic_bomb",
	},
}

M.ALL_CARDS = {
	{ id = "bazooka", type = "weapon", weapon_id = "bazooka", ammo = 2, bg_color = { 0.45, 0.18, 0.18, 1.0 }, accent_color = { 1.0, 0.3, 0.2, 1.0 } },
	{ id = "heal_30", type = "heal", heal_amount = 30, bg_color = { 0.15, 0.45, 0.25, 1.0 }, accent_color = { 0.3, 1.0, 0.5, 1.0 } },
	{ id = "burst", type = "weapon", weapon_id = "burst", ammo = 3, bg_color = { 0.28, 0.22, 0.45, 1.0 }, accent_color = { 0.7, 0.5, 1.0, 1.0 } },
	{ id = "holy_grenade", type = "weapon", weapon_id = "holy_grenade", ammo = 1, bg_color = { 0.55, 0.45, 0.15, 1.0 }, accent_color = { 1.0, 0.9, 0.3, 1.0 } },
	{ id = "shotgun", type = "weapon", weapon_id = "shotgun", ammo = 3, bg_color = { 0.30, 0.35, 0.25, 1.0 }, accent_color = { 0.6, 0.9, 0.4, 1.0 } },
	{ id = "rifle", type = "weapon", weapon_id = "rifle", ammo = 3, bg_color = { 0.35, 0.32, 0.22, 1.0 }, accent_color = { 1.0, 0.85, 0.3, 1.0 } },
	{ id = "molotov", type = "weapon", weapon_id = "molotov", ammo = 2, bg_color = { 0.45, 0.25, 0.12, 1.0 }, accent_color = { 1.0, 0.5, 0.15, 1.0 } },
	{ id = "knife", type = "weapon", weapon_id = "knife", ammo = 3, bg_color = { 0.25, 0.35, 0.40, 1.0 }, accent_color = { 0.4, 0.8, 0.9, 1.0 } },
	{ id = "beetle", type = "weapon", weapon_id = "beetle", ammo = 2, bg_color = { 0.48, 0.38, 0.12, 1.0 }, accent_color = { 1.0, 0.85, 0.2, 1.0 } },
	{ id = "drill", type = "weapon", weapon_id = "drill", ammo = 2, bg_color = { 0.28, 0.32, 0.48, 1.0 }, accent_color = { 0.5, 0.75, 1.0, 1.0 } },
	{ id = "pepper", type = "weapon", weapon_id = "pepper", ammo = 2, bg_color = { 0.52, 0.15, 0.15, 1.0 }, accent_color = { 1.0, 0.35, 0.2, 1.0 } },
	{ id = "garlic", type = "weapon", weapon_id = "garlic", ammo = 2, bg_color = { 0.42, 0.45, 0.32, 1.0 }, accent_color = { 0.9, 0.95, 0.6, 1.0 } },
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
		copy.dmg_str = lang_data.dmg_str
		copy.btn_label = lang_data.btn_label
		copy.icon = loc_entry.icon or card.icon or "circle"
	end
	return copy
end

-- Draw 2 distinct cards for arena start (curated for Level 1 or random for higher levels)
function M.draw_2_cards(player_hp, player_max_hp, level)
	level = level or 1

	if level == 1 then
		-- Curated first level choices: Bazooka (+2) or Shotgun (+3)
		local c1 = M.ALL_CARDS[1] -- bazooka
		local c2 = M.ALL_CARDS[5] -- shotgun
		return localize_card(c1), localize_card(c2)
	end

	-- Filter available cards
	local candidates = {}
	for _, c in ipairs(M.ALL_CARDS) do
		local ok = true
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
