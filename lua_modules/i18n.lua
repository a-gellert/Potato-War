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
		btn_quick_bot = "БЫСТРЫЙ БОЙ VS БОТ",
		btn_quick_pvp = "2 ИГРОКА (ОДИН ЭКРАН)",
		hint_controls = "Управление: A / D — ходьба | W / Пробел — прыжок | 1..8 — выбор оружия\nСтрельба (Angry Birds): зажмите картошку мышкой, потяните назад и отпустите!",
		lang_btn = "ЯЗЫК: RU",

		-- HUD
		turn_blue = "Ход: Картошка (Синие)",
		turn_red_bot = "Ход: Компьютер (Красные)",
		turn_red_pvp = "Ход: Игрок 2 (Красные)",
		weapon_grenade = "1: ГОРЯЧАЯ КАРТОШКА",
		weapon_rifle = "2: ШАМПУР-СНАЙПЕР",
		weapon_knife = "3: КАРТОФЕЛЕЧИСТКА",
		weapon_molotov = "4: ФРИТЮРНОЕ МАСЛО",
		weapon_burst = "5: ФРИ-АВТОМАТ",
		weapon_bazooka = "6: ПЮРЕ-БАЗУКА",
		weapon_shotgun = "7: КУХОННАЯ ТЁРКА",
		weapon_holy_grenade = "8: ЗОЛОТОЙ КЛУБЕНЬ",
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
		btn_rematch = "ПОВТОРИТЬ АРЕНУ",
		btn_next_level = "СЛЕДУЮЩАЯ АРЕНА",
		btn_menu = "ГЛАВНОЕ МЕНЮ",
	},
	en = {
		-- Main Menu
		title = "POTATO WAR",
		subtitle = "Potato Battle — Turn-Based Artillery",
		btn_campaign = "TO BATTLE (CAMPAIGN)",
		btn_quick_bot = "QUICK BATTLE VS BOT",
		btn_quick_pvp = "2 PLAYERS (SAME SCREEN)",
		hint_controls = "Controls: A / D — Walk | W / Space — Jump | 1..8 — Select Weapon\nAiming (Angry Birds): Drag potato back with mouse & release to fire!",
		lang_btn = "LANG: EN",

		-- HUD
		turn_blue = "Turn: Potatoes (Blue)",
		turn_red_bot = "Turn: Computer (Red)",
		turn_red_pvp = "Turn: Player 2 (Red)",
		weapon_grenade = "1: HOT POTATO",
		weapon_rifle = "2: SKEWER SNIPER",
		weapon_knife = "3: POTATO PEELER",
		weapon_molotov = "4: FRYING OIL",
		weapon_burst = "5: FRY-O-MATIC",
		weapon_bazooka = "6: MASH-ZOOKA",
		weapon_shotgun = "7: KITCHEN GRATER",
		weapon_holy_grenade = "8: HOLY SPUD",
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
		btn_rematch = "RETRY ARENA",
		btn_next_level = "NEXT ARENA",
		btn_menu = "MAIN MENU",
	}
}

-- Detect language from system, Poki SDK, or browser environment
function M.detect_language()
	local lang_str = nil

	-- 1. Check HTML5 browser navigator
	if html5 then
		pcall(function()
			local js_lang = html5.eval("navigator.language || navigator.userLanguage")
			if js_lang and type(js_lang) == "string" and js_lang ~= "" then
				lang_str = js_lang
			end
		end)
	end

	-- 2. Check Defold system info if html5 did not provide language
	if not lang_str and sys and sys.get_sys_info then
		pcall(function()
			local info = sys.get_sys_info()
			lang_str = info.language or info.device_language
		end)
	end

	-- Parse detected string
	if lang_str and type(lang_str) == "string" then
		local lower_lang = string.lower(lang_str)
		if string.sub(lower_lang, 1, 2) == "ru" then
			M.current_lang = M.LANG_RU
		else
			M.current_lang = M.LANG_EN
		end
	else
		M.current_lang = M.LANG_EN -- default
	end

	print(">>> I18N DETECTED LANGUAGE:", M.current_lang, "(raw:", tostring(lang_str) .. ")")
	return M.current_lang
end

function M.set_lang(lang_code)
	if lang_code == M.LANG_RU or lang_code == M.LANG_EN then
		M.current_lang = lang_code
	end
end

function M.toggle_lang()
	if M.current_lang == M.LANG_RU then
		M.current_lang = M.LANG_EN
	else
		M.current_lang = M.LANG_RU
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
