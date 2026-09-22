-- lua_modules/i18n.lua
-- Internationalization module for Potato War (Russian & English)
-- Auto-detects language from Poki SDK, browser (html5), or system settings.

local M = {}

M.LANG_RU = "ru"
M.LANG_EN = "en"

M.current_lang = M.LANG_RU

local dictionary = {
	ru = {
		-- Main Menu
		title = "POTATO WAR",
		subtitle = "Битва Картошек — Пошаговая артиллерия",
		btn_campaign = "1. КАМПАНИЯ (МИССИИ)",
		btn_quick_bot = "2. БЫСТРЫЙ БОЙ VS БОТ",
		btn_quick_pvp = "3. 2 ИГРОКА (ОДИН ЭКРАН)",
		hint_controls = "Управление: A / D — ходьба | W / Пробел — прыжок | 1, 2, 3 — выбор оружия\nСтрельба (Angry Birds): зажмите картошку мышкой, потяните назад и отпустите!",
		lang_btn = "ЯЗЫК: RU",

		-- HUD
		turn_blue = "Ход: Картошка (Синие)",
		turn_red_bot = "Ход: Компьютер (Красные)",
		turn_red_pvp = "Ход: Игрок 2 (Красные)",
		weapon_grenade = "1: ГРАНАТА",
		weapon_rifle = "2: ВИНТОВКА",
		weapon_knife = "3: НОЖ",
		touch_left = "◄ A",
		touch_jump = "▲ W",
		touch_right = "D ►",
		btn_pause = "МЕНЮ [ESC]",
		mission_format = "Миссия %d",
		mode_bot = "Бой vs Бот",
		mode_pvp = "Игра 1 на 1",

		-- Game Over
		victory = "ПОБЕДА!",
		defeat = "ПОРАЖЕНИЕ!",
		draw = "НИЧЬЯ!",
		sub_victory = "Синяя команда картошек разгромила соперника!",
		sub_defeat = "Красные картошки одержали победу!",
		sub_draw = "Все картошки превратились в пюре!",
		btn_rematch = "ПОВТОРИТЬ БОЙ",
		btn_next_level = "СЛЕДУЮЩАЯ МИССИЯ",
		btn_menu = "ГЛАВНОЕ МЕНЮ",
	},
	en = {
		-- Main Menu
		title = "POTATO WAR",
		subtitle = "Potato Battle — Turn-Based Artillery",
		btn_campaign = "1. CAMPAIGN (MISSIONS)",
		btn_quick_bot = "2. QUICK BATTLE VS BOT",
		btn_quick_pvp = "3. 2 PLAYERS (SAME SCREEN)",
		hint_controls = "Controls: A / D — Walk | W / Space — Jump | 1, 2, 3 — Select Weapon\nAiming (Angry Birds): Drag potato back with mouse & release to fire!",
		lang_btn = "LANG: EN",

		-- HUD
		turn_blue = "Turn: Potatoes (Blue)",
		turn_red_bot = "Turn: Computer (Red)",
		turn_red_pvp = "Turn: Player 2 (Red)",
		weapon_grenade = "1: GRENADE",
		weapon_rifle = "2: RIFLE",
		weapon_knife = "3: KNIFE",
		touch_left = "◄ A",
		touch_jump = "▲ W",
		touch_right = "D ►",
		btn_pause = "MENU [ESC]",
		mission_format = "Mission %d",
		mode_bot = "Vs Bot Battle",
		mode_pvp = "1 vs 1 Game",

		-- Game Over
		victory = "VICTORY!",
		defeat = "DEFEAT!",
		draw = "DRAW!",
		sub_victory = "Blue potato team crushed the enemy!",
		sub_defeat = "Red potatoes won the battle!",
		sub_draw = "All potatoes turned into mashed potatoes!",
		btn_rematch = "RETRY BATTLE",
		btn_next_level = "NEXT MISSION",
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
		M.current_lang = M.LANG_RU -- default
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
