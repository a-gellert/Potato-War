-- lua_modules/i18n.lua
-- Internationalization module for Potato War (Russian & English)
-- Auto-detects language from Poki SDK, browser (html5), or system settings.

local M = {}

M.LANG_RU = "ru"
M.LANG_EN = "en"

M.current_lang = M.LANG_EN

local dictionary = {
	ru = {
		-- Main Menu
		title = "POTATO WAR",
		subtitle = "Битва Картошек — Пошаговая артиллерия",
		btn_campaign = "БОЙ",
		btn_battle = "БОЙ",
		btn_upgrades = "ПРОКАЧКА / УЛУЧШЕНИЯ",
		btn_quick_bot = "БЫСТРЫЙ БОЙ VS БОТ",
		upgrades_title = "ГЛОБАЛЬНЫЕ УЛУЧШЕНИЯ",

		-- Campaign Map
		camp_title = "★ КАРТА ВОЙНЫ",
		camp_sectors_fmt = "Секторы: %d/%d (%d%%)",
		camp_supplies_fmt = "Припасы: %d 🥔",
		camp_turn_fmt = "Ход: %d",
		camp_recon_dossier = "ДОСЬЕ РАЗВЕДКИ",
		camp_owner_blue = "Контроль: 🔵 СИНИЕ",
		camp_owner_red = "Контроль: 🔴 КРАСНЫЕ",
		camp_def_fmt = "Оборона: %s (%s)",
		camp_def_1 = "Полевой лагерь",
		camp_def_2 = "Укрепленный форпост",
		camp_def_3 = "Бункерная цитадель",
		camp_garrison_fmt = "Гарнизон: %d картошки",
		camp_income_fmt = "Доход: +%d 🥔 / ход",
		camp_terrain_fmt = "Рельеф: %s",
		camp_status_ready = "⚡ Рубеж готов к штурму",
		camp_status_deep = "🔒 В тылу врага (нет границы)",
		camp_status_under_attack = "⚠️ ВРАГ АТАКУЕТ СЕКТОР!",
		camp_status_defend = "🛡️ Союзный рубеж обороны",
		camp_btn_attack = "⚔️ В АТАКУ!",
		camp_btn_fortify = "🛡️ УКРЕПИТЬ (%d 🥔)",
		camp_btn_max_fort = "🛡️ МАКС. УКРЕПЛЕНИЕ",
		camp_btn_back = "В МЕНЮ",
		camp_hint_bottom = "Кликните на сектор для разведданных. Золотая линия — линия фронта.",
		camp_alert_siren = "⚠️ ТРЕВОГА! ВРАЖЕСКИЙ ШТУРМ СЕКТОРА #%02d!",

		-- Lobby
		lobby_title = "НАСТРОЙКА БОЯ",
		lobby_subtitle = "Настройте параметры командной битвы",
		lbl_potatoes_count = "Картошек в команде:",
		lbl_mode = "Соперник:",
		mode_bot_opt = "🤖 Против Бота",
		mode_human_opt = "⚔️ Против Человека",
		lbl_skin_blue = "Скин Синих:",
		lbl_skin_red = "Скин Красных:",
		lbl_location = "Местность:",
		lbl_relief = "Рельеф:",
		btn_start_battle = "⚔️ В БОЙ!",
		btn_back = "◄ НАЗАД",
		btn_buy = "КУПИТЬ (%d)",
		btn_max = "МАКСИМУМ",
		level_format = "Ур. %d/%d",
		hint_controls = "Управление: A / D — ходьба | W / Пробел — прыжок | Q / клик слева — арсенал\nСтрельба: зажмите мышь/экран, направьте прицел на врага и отпустите!",
		lang_btn = "ЯЗЫК: RU",

		-- HUD
		turn_blue = "Ход: Картошка (Синие)",
		turn_red_bot = "Ход: Компьютер (Красные)",
		turn_red_pvp = "Ход: Игрок 2 (Красные)",
		turn_red_pvp_bot = "Ход: PvP Бот (Красные)",
		weapon_grenade = "ГОРЯЧАЯ КАРТОШКА",
		weapon_rifle = "ШАМПУР-СНАЙПЕР",
		weapon_knife = "КАРТОФЕЛЕЧИСТКА",
		weapon_molotov = "ФРИТЮРНОЕ МАСЛО",
		weapon_burst = "ФРИ-АВТОМАТ",
		weapon_bazooka = "ПЮРЕ-БАЗУКА",
		weapon_shotgun = "КУХОННАЯ ТЁРКА",
		weapon_holy_grenade = "ЗОЛОТОЙ КЛУБЕНЬ",
		weapon_beetle = "КОЛОРАДСКИЙ ДЕСАНТ",
		weapon_drill = "ГРЯДКОВЫЙ БУР",
		weapon_pepper = "ПЕРЦЕМОЛКА «ЧИЛИ»",
		weapon_garlic = "ЧЕСНОЧНЫЙ ДИНАМИТ",
		touch_left = "◄ A",
		touch_jump = "▲ W",
		touch_right = "D ►",
		btn_pause = "МЕНЮ [ESC]",
		btn_inventory = "ОРУЖИЕ [Q]",
		inventory_title = "ИНВЕНТАРЬ ОРУЖИЯ [Q]",
		inventory_sub = "ВЫБЕРИТЕ ОРУЖИЕ ДЛЯ ВЫСТРЕЛА",
		points_lbl = "Очки: ",
		mission_format = "Арена %d",
		mode_bot = "Бой vs Бот",
		mode_pvp = "Игра 1 на 1",
		mode_pvp_bots = "PvP 3x3 vs Боты",
		tutorial_hint = "🎯 Направь прицел на врага и отпусти для выстрела!",
		tutorial_sub = "Зажми мышь/экран и потяни в сторону врага",
		cards_start_title = "ВЫБЕРИТЕ БОНУС АРЕНЫ",
		cards_start_subtitle = "Выберите оружие или усиление на эту арену",

		-- Game Over
		victory = "ПОБЕДА!",
		defeat = "ПОРАЖЕНИЕ!",
		draw = "НИЧЬЯ!",
		sub_victory = "Синяя команда картошек разгромила соперника!",
		sub_defeat = "Красные картошки одержали победу!",
		sub_draw = "Все картошки превратились в пюре!",
		btn_rematch = "НАЧАТЬ ЗАНОВО",
		btn_play_again = "СЫГРАТЬ ЕЩЕ РАЗ",
		btn_next_level = "СЛЕДУЮЩАЯ АРЕНА",
		btn_revive = "ВОСКРЕСИТЬСЯ (+50 HP)",
		btn_shop = "МАГАЗИН СКИНОВ 🛍️",
		btn_menu = "ГЛАВНОЕ МЕНЮ",
		achieve_bonus = "БОНУСЫ ЗА МАСТЕРСТВО:",
		achieve_total = "ИТОГО:",
		air_raid_warn = "⚠️ ВОЗДУШНЫЙ НАЛЕТ!",
		debrief_title = "★ ВОЕННАЯ СВОДКА ГЕНШТАБА ★",
		debrief_sector_liberated = "★ СЕКТОР %s ОСВОБОЖДЕН! ★",
		debrief_sub_liberated = "Флаг Синих поднят! Сектор перешел под контроль штаба.",
		debrief_attack_repelled = "🛡️ АТАКА ОТБИТА: %s! 🛡️",
		debrief_sub_repelled = "Вражеский штурм сокрушен! Оборона рубежа удержана.",
		debrief_sector_lost = "⚠️ СЕКТОР %s ПОТЕРЯН! ⚠️",
		debrief_sub_lost = "Оборона прорвана Красными. Сектор перешел к врагу.",
		debrief_assault_failed = "ШТУРМ ЗАХЛЕБНУЛСЯ",
		debrief_sub_failed = "Штурмовой отряд понес потери и отступил на базу.",
		debrief_campaign_won = "🏆 ОСТРОВ ПОЛНОСТЬЮ ОСВОБОЖДЕН! 🏆",
		debrief_sub_camp_won = "Все 18 секторов под контролем Синих! Кампания выиграна!",
		debrief_campaign_lost = "💀 КАМПАНИЯ ПРОИГРАНА 💀",
		debrief_sub_camp_lost = "Все опорные пункты пали. Штаб эвакуирован.",
		btn_return_hq = "ВЕРНУТЬСЯ В ШТАБ 🎖️",
		frontline_minimap = "КАРТА ЛИНИИ ФРОНТА",
		frontline_control_fmt = "Контроль острова: %d / 18 (%d%%)",
		debrief_combat_report = "★ БОЕВОЕ ДОНЕСЕНИЕ ★",
	},
	en = {
		-- Main Menu
		title = "POTATO WAR",
		subtitle = "Potato Battle — Turn-Based Artillery",
		btn_campaign = "BATTLE",
		btn_battle = "BATTLE",
		btn_upgrades = "UPGRADES & PERKS",
		btn_quick_bot = "QUICK BATTLE VS BOT",
		upgrades_title = "META UPGRADES",

		-- Campaign Map
		camp_title = "★ WAR MAP",
		camp_sectors_fmt = "Sectors: %d/%d (%d%%)",
		camp_supplies_fmt = "Supplies: %d 🥔",
		camp_turn_fmt = "Turn: %d",
		camp_recon_dossier = "RECON DOSSIER",
		camp_owner_blue = "Control: 🔵 BLUE",
		camp_owner_red = "Control: 🔴 RED",
		camp_def_fmt = "Defense: %s (%s)",
		camp_def_1 = "Field Camp",
		camp_def_2 = "Fortified Outpost",
		camp_def_3 = "Bunker Citadel",
		camp_garrison_fmt = "Garrison: %d potatoes",
		camp_income_fmt = "Income: +%d 🥔 / turn",
		camp_terrain_fmt = "Relief: %s",
		camp_status_ready = "⚡ Frontline ready to assault",
		camp_status_deep = "🔒 Deep in enemy territory",
		camp_status_under_attack = "⚠️ ENEMY ATTACKING SECTOR!",
		camp_status_defend = "🛡️ Allied defensive line",
		camp_btn_attack = "⚔️ ATTACK!",
		camp_btn_fortify = "🛡️ FORTIFY (%d 🥔)",
		camp_btn_max_fort = "🛡️ MAX DEFENSE",
		camp_btn_back = "MENU",
		camp_hint_bottom = "Click a sector to view recon intel. Golden line is the active front line.",
		camp_alert_siren = "⚠️ ALERT! ENEMY ASSAULT ON SECTOR #%02d!",

		-- Lobby
		lobby_title = "BATTLE LOBBY",
		lobby_subtitle = "Configure your team battle match",
		lbl_potatoes_count = "Potatoes per team:",
		lbl_mode = "Opponent:",
		mode_bot_opt = "🤖 vs Bot",
		mode_human_opt = "⚔️ vs Human",
		lbl_skin_blue = "Blue Team Skin:",
		lbl_skin_red = "Red Team Skin:",
		lbl_location = "Location:",
		lbl_relief = "Relief:",
		btn_start_battle = "⚔️ TO BATTLE!",
		btn_back = "◄ BACK",
		btn_buy = "BUY (%d)",
		btn_max = "MAX LEVEL",
		level_format = "Lvl %d/%d",
		hint_controls = "Controls: A / D — Walk | W / Space — Jump | Q / left button — Arsenal\nShooting: Hold mouse/touch, drag towards enemy & release to fire!",
		lang_btn = "LANG: EN",

		-- HUD
		turn_blue = "Turn: Potatoes (Blue)",
		turn_red_bot = "Turn: Computer (Red)",
		turn_red_pvp = "Turn: Player 2 (Red)",
		turn_red_pvp_bot = "Turn: PvP Bot (Red)",
		weapon_grenade = "HOT POTATO",
		weapon_rifle = "SKEWER SNIPER",
		weapon_knife = "POTATO PEELER",
		weapon_molotov = "FRYING OIL",
		weapon_burst = "FRY-O-MATIC",
		weapon_bazooka = "MASH-ZOOKA",
		weapon_shotgun = "KITCHEN GRATER",
		weapon_holy_grenade = "HOLY SPUD",
		weapon_beetle = "BEETLE SWARM",
		weapon_drill = "GARDEN DRILL",
		weapon_pepper = "CHILI PEPPER MILL",
		weapon_garlic = "GARLIC DYNAMITE",
		touch_left = "◄ A",
		touch_jump = "▲ W",
		touch_right = "D ►",
		btn_pause = "MENU [ESC]",
		btn_inventory = "WEAPONS [Q]",
		inventory_title = "WEAPON ARSENAL [Q]",
		inventory_sub = "CHOOSE A WEAPON TO FIRE",
		points_lbl = "Points: ",
		mission_format = "Arena %d",
		mode_bot = "Vs Bot Battle",
		mode_pvp = "1 vs 1 Game",
		mode_pvp_bots = "PvP 3v3 vs Bots",
		tutorial_hint = "🎯 Drag towards the enemy to aim, release to shoot!",
		tutorial_sub = "Hold mouse / touch and drag towards the target",
		cards_start_title = "CHOOSE ARENA BONUS",
		cards_start_subtitle = "Select weapon or upgrade for this battle",

		-- Game Over
		victory = "VICTORY!",
		defeat = "DEFEAT!",
		draw = "DRAW!",
		sub_victory = "Blue potato team crushed the enemy!",
		sub_defeat = "Red potatoes won the battle!",
		sub_draw = "All potatoes turned into mashed potatoes!",
		btn_rematch = "RETRY FROM START",
		btn_play_again = "PLAY AGAIN",
		btn_next_level = "NEXT ARENA",
		btn_revive = "REVIVE (+50 HP)",
		btn_shop = "SKIN SHOP 🛍️",
		btn_menu = "MAIN MENU",
		achieve_bonus = "SKILL BONUSES:",
		achieve_total = "TOTAL:",
		air_raid_warn = "⚠️ AIR RAID INCOMING!",
		debrief_title = "★ GENERAL STAFF COMBAT DEBRIEF ★",
		debrief_sector_liberated = "★ SECTOR %s LIBERATED! ★",
		debrief_sub_liberated = "Blue flag raised! Sector is under headquarters control.",
		debrief_attack_repelled = "🛡️ ASSAULT REPELLED: %s! 🛡️",
		debrief_sub_repelled = "Enemy assault crushed! Sector defense held.",
		debrief_sector_lost = "⚠️ SECTOR %s LOST! ⚠️",
		debrief_sub_lost = "Defense line breached by Red forces. Sector seized.",
		debrief_assault_failed = "ASSAULT FAILED",
		debrief_sub_failed = "Assault force took heavy casualties and retreated.",
		debrief_campaign_won = "🏆 ISLAND COMPLETELY LIBERATED! 🏆",
		debrief_sub_camp_won = "All 18 sectors under Blue Army control! Campaign won!",
		debrief_campaign_lost = "💀 CAMPAIGN LOST 💀",
		debrief_sub_camp_lost = "All strongholds fell. Headquarters evacuated.",
		btn_return_hq = "RETURN TO HQ 🎖️",
		frontline_minimap = "FRONTLINE RADAR MAP",
		frontline_control_fmt = "Island Control: %d / 18 (%d%%)",
		debrief_combat_report = "★ COMBAT REPORT ★",
	}
}

-- Detect language from saved preference, Poki SDK, or default to English
function M.detect_language()
	-- 1. Check if user previously saved a manual language preference
	local saved_lang = nil
	pcall(function()
		local player_profile = require("lua_modules.player_profile")
		if player_profile and player_profile.get_language then
			saved_lang = player_profile.get_language()
		end
	end)
	if saved_lang == M.LANG_RU or saved_lang == M.LANG_EN then
		M.current_lang = saved_lang
		print(">>> I18N: Using saved language preference:", M.current_lang)
		return M.current_lang
	end

	local detected_lang = nil

	-- 2. Query Poki SDK in HTML5 / Web environment
	-- Official Poki SDK exposes PokiSDK.getLanguage() returning ISO 639-1 code (e.g. 'en', 'ru')
	if html5 then
		pcall(function()
			local js_lang = html5.eval([[(function() {
				try {
					if (typeof PokiSDK !== 'undefined') {
						if (typeof PokiSDK.getLanguage === 'function') {
							var pl = PokiSDK.getLanguage();
							if (pl && typeof pl === 'string' && pl.length >= 2) return pl;
						}
						if (typeof PokiSDK.getURLParam === 'function') {
							var up = PokiSDK.getURLParam('lang') || PokiSDK.getURLParam('locale') || PokiSDK.getURLParam('language');
							if (up && typeof up === 'string' && up.length >= 2) return up;
						}
					}
					if (window.location && window.location.search) {
						var sp = new URLSearchParams(window.location.search);
						var ql = sp.get('lang') || sp.get('locale') || sp.get('language') || sp.get('poki_lang');
						if (ql && typeof ql === 'string' && ql.length >= 2) return ql;
					}
				} catch(e) {}
				return '';
			})()]])
			if js_lang and type(js_lang) == "string" and js_lang ~= "" then
				detected_lang = js_lang
				print(">>> I18N: Detected from Poki SDK (HTML5):", detected_lang)
			end
		end)
	end

	-- 3. Query Defold poki_sdk native extension
	if not detected_lang and poki_sdk then
		pcall(function()
			if poki_sdk.get_language then
				local pl = poki_sdk.get_language()
				if pl and type(pl) == "string" and pl ~= "" then
					detected_lang = pl
					print(">>> I18N: Detected from poki_sdk.get_language:", detected_lang)
				end
			end
			if not detected_lang and poki_sdk.get_url_param then
				local up = poki_sdk.get_url_param("lang") or poki_sdk.get_url_param("locale") or poki_sdk.get_url_param("language")
				if up and type(up) == "string" and up ~= "" then
					detected_lang = up
					print(">>> I18N: Detected from poki_sdk.get_url_param:", detected_lang)
				end
			end
		end)
	end

	-- 4. Evaluate Poki SDK language
	if detected_lang and type(detected_lang) == "string" then
		local lower = string.lower(detected_lang)
		if string.sub(lower, 1, 2) == "ru" then
			M.current_lang = M.LANG_RU
		else
			-- On Poki, all non-Russian locales map to standard English
			M.current_lang = M.LANG_EN
		end
		print(">>> I18N: Active language via Poki SDK:", M.current_lang, "(raw:", detected_lang .. ")")
		return M.current_lang
	end

	-- 5. Standard Global Default: English (Never force Russian from local OS/browser locale)
	M.current_lang = M.LANG_EN
	print(">>> I18N: Defaulting to standard English:", M.current_lang)
	return M.current_lang
end

function M.set_lang(lang_code)
	if lang_code == M.LANG_RU or lang_code == M.LANG_EN then
		M.current_lang = lang_code
		pcall(function()
			local player_profile = require("lua_modules.player_profile")
			if player_profile and player_profile.set_language then
				player_profile.set_language(lang_code)
			end
		end)
	end
end

function M.toggle_lang()
	if M.current_lang == M.LANG_RU then
		M.set_lang(M.LANG_EN)
	else
		M.set_lang(M.LANG_RU)
	end
	return M.current_lang
end

function M.t(key, ...)
	local dict = dictionary[M.current_lang] or dictionary.en
	local text = dict[key] or dictionary.en[key] or key
	if select("#", ...) > 0 then
		local ok, formatted = pcall(string.format, text, ...)
		if ok then
			return formatted
		end
	end
	return text
end

-- Initialize language detection automatically on module load
M.detect_language()

return M
