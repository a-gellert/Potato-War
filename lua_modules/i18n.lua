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
		btn_campaign = "В БОЙ (КАМПАНИЯ)",
		btn_upgrades = "ПРОКАЧКА / УЛУЧШЕНИЯ",
		btn_quick_bot = "БЫСТРЫЙ БОЙ VS БОТ",
		btn_quick_pvp = "2 ИГРОКА (ОДИН ЭКРАН)",
		upgrades_title = "ГЛОБАЛЬНЫЕ УЛУЧШЕНИЯ",
		btn_buy = "КУПИТЬ (%d)",
		btn_max = "МАКСИМУМ",
		level_format = "Ур. %d/%d",
		hint_controls = "Управление: A / D — ходьба | W / Пробел — прыжок | 1..5 — выбор слота\nСтрельба (Angry Birds): зажмите картошку мышкой, потяните назад и отпустите!",
		lang_btn = "ЯЗЫК: RU",

		-- HUD
		turn_blue = "Ход: Картошка (Синие)",
		turn_red_bot = "Ход: Компьютер (Красные)",
		turn_red_pvp = "Ход: Игрок 2 (Красные)",
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
		mission_format = "Арена %d",
		mode_bot = "Бой vs Бот",
		mode_pvp = "Игра 1 на 1",
		tutorial_hint = "Потяни назад, чтобы выстрелить вперед!",
		tutorial_sub = "Зажми мышь и потяни в сторону от врага",
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
		btn_next_level = "СЛЕДУЮЩАЯ АРЕНА",
		btn_revive = "ВОСКРЕСИТЬСЯ (+50 HP)",
		btn_shop = "МАГАЗИН СКИНОВ 🛍️",
		btn_menu = "ГЛАВНОЕ МЕНЮ",
		achieve_bonus = "БОНУСЫ ЗА МАСТЕРСТВО:",
		achieve_total = "ИТОГО:",
		air_raid_warn = "⚠️ ВОЗДУШНЫЙ НАЛЕТ!",
	},
	en = {
		-- Main Menu
		title = "POTATO WAR",
		subtitle = "Potato Battle — Turn-Based Artillery",
		btn_campaign = "TO BATTLE (CAMPAIGN)",
		btn_upgrades = "UPGRADES & PERKS",
		btn_quick_bot = "QUICK BATTLE VS BOT",
		btn_quick_pvp = "2 PLAYERS (SAME SCREEN)",
		upgrades_title = "META UPGRADES",
		btn_buy = "BUY (%d)",
		btn_max = "MAX LEVEL",
		level_format = "Lvl %d/%d",
		hint_controls = "Controls: A / D — Walk | W / Space — Jump | 1..5 — Select Weapon Slot\nAiming (Angry Birds): Drag potato back with mouse & release to fire!",
		lang_btn = "LANG: EN",

		-- HUD
		turn_blue = "Turn: Potatoes (Blue)",
		turn_red_bot = "Turn: Computer (Red)",
		turn_red_pvp = "Turn: Player 2 (Red)",
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
		mission_format = "Arena %d",
		mode_bot = "Vs Bot Battle",
		mode_pvp = "1 vs 1 Game",
		tutorial_hint = "Pull back to shoot forward!",
		tutorial_sub = "Click & drag potato away from the target",
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
		btn_next_level = "NEXT ARENA",
		btn_revive = "REVIVE (+50 HP)",
		btn_shop = "SKIN SHOP 🛍️",
		btn_menu = "MAIN MENU",
		achieve_bonus = "SKILL BONUSES:",
		achieve_total = "TOTAL:",
		air_raid_warn = "⚠️ AIR RAID INCOMING!",
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
