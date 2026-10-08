-- lua_modules/level_config.lua
-- Central configuration module for Potato War levels:
-- Level number, enemy HP, enemy count, terrain type, enemy skill level, and biome themes.

local i18n = require("lua_modules.i18n")

local M = {}

-- Supported terrain types and default biomes
M.TERRAIN_TYPES = {
	HILLS = "hills",
	FLOATING_ISLANDS = "floating_islands",
	CANYON_BRIDGE = "canyon_bridge",
	CAVERN = "cavern",
	SWISS_CHEESE = "swiss_cheese",
	BUNKERS = "bunkers",
	ISLANDS = "islands",
	FLAT = "flat",
}

-- Supported enemy skill levels
M.SKILL_LEVELS = {
	EASY = "easy",
	NORMAL = "normal",
	HARD = "hard",
}

-- Deduce biome theme based on terrain type if not explicitly set
function M.deduce_biome(terrain_type)
	if terrain_type == "canyon" or terrain_type == "canyon_bridge" or terrain_type == "bunkers" then
		return "desert"
	elseif terrain_type == "floating_islands" then
		return "arctic"
	elseif terrain_type == "cavern" then
		return "volcano"
	elseif terrain_type == "swiss_cheese" then
		return "alien"
	else
		return "grass"
	end
end

-- Normalize skill level from various formats (number 1-3, strings, Russian terms)
function M.normalize_skill(skill)
	if type(skill) == "number" then
		if skill <= 1 then
			return "easy"
		elseif skill == 2 then
			return "normal"
		else
			return "hard"
		end
	end

	if type(skill) == "string" then
		local s = string.lower(skill)
		if s == "easy" or s == "легкий" or s == "лёгкий" or s == "1" then
			return "easy"
		elseif s == "hard" or s == "сложный" or s == "тяжелый" or s == "тяжёлый" or s == "expert" or s == "3" then
			return "hard"
		else
			return "normal"
		end
	end

	return "normal"
end

-- Normalize a single level configuration entry with all aliases and fallback defaults
function M.normalize_level(entry, level_index)
	local lvl = entry.level or entry.id or level_index or 1
	local terrain = entry.terrain_type or entry.terrain_preset or "hills"
	local biome = entry.biome or M.deduce_biome(terrain)
	local skill = M.normalize_skill(entry.enemy_skill or entry.bot_difficulty or entry.skill_level or "normal")

	local enemy_cnt = entry.enemy_count or entry.red_count or 1
	local player_cnt = entry.player_count or entry.blue_count or 1

	-- Normalize enemy HP (can be number or table per enemy)
	local enemy_hp = entry.enemy_hp
	if enemy_hp == nil then
		enemy_hp = (lvl == 1) and 85 or 100
	end

	-- Normalize enemy classes and unit levels (ranks)
	local enemy_classes = entry.enemy_classes
	if not enemy_classes or #enemy_classes == 0 then
		enemy_classes = {}
		for i = 1, enemy_cnt do
			table.insert(enemy_classes, "recruit")
		end
	end

	local enemy_levels = entry.enemy_levels
	if not enemy_levels or #enemy_levels == 0 then
		enemy_levels = {}
		for i = 1, enemy_cnt do
			table.insert(enemy_levels, 1)
		end
	end

	local is_ru = (i18n.current_lang == "ru")
	local lvl_name = (is_ru and entry.name) or entry.name_en or entry.name or ((is_ru and "Сектор " or "Sector ") .. tostring(lvl))
	local lvl_desc = (is_ru and entry.desc) or entry.desc_en or entry.desc or ""

	return {
		level = lvl,
		id = lvl,
		name = lvl_name,
		desc = lvl_desc,
		name_ru = entry.name_ru or entry.name,
		name_en = entry.name_en or entry.name,
		desc_ru = entry.desc_ru or entry.desc,
		desc_en = entry.desc_en or entry.desc,
		enemy_hp = enemy_hp,
		enemy_count = enemy_cnt,
		red_count = enemy_cnt, -- Backwards compatibility alias
		player_count = player_cnt,
		blue_count = player_cnt, -- Backwards compatibility alias
		terrain_type = terrain,
		terrain_preset = terrain, -- Backwards compatibility alias
		biome = biome,
		enemy_skill = skill,
		bot_difficulty = skill, -- Backwards compatibility alias
		skill_level = skill, -- Backwards compatibility alias
		enemy_classes = enemy_classes,
		enemy_levels = enemy_levels,
	}
end

-- Campaign levels table: All 18 campaign sectors
-- Parameters per level:
--   level: номер сектора/уровня (1..18)
--   name / name_en: названия сектора
--   desc / desc_en: тактическое описание
--   enemy_count: количество врагов (1..4)
--   enemy_hp: здоровье врагов (число или таблица { hp1, hp2, ... })
--   enemy_classes: таблица классов вражеских картошек ({ "recruit", "assault", ... })
--   enemy_levels: уровни/ранги врагов ({ 1, 2, ... })
--   terrain_type: тип террейна
--   biome: визуальный биом ("grass", "desert", "arctic", "volcano")
--   enemy_skill: точность/тактика ИИ ("easy", "normal", "hard")
M.LEVELS = {
	-- =========================================================================
	-- РЕГИОН 1: ПРИБРЕЖНЫЕ ЛУГА (Coastal Meadows) - Уровни 1..4 (Grass Biome)
	-- =========================================================================
	{
		level = 1,
		name = "Бухта Высадки",
		name_en = "Landing Cove",
		desc = "Первая высадка десанта. Одинокий часовой-новобранец охраняет берег.",
		desc_en = "Beachhead landing. A lone rookie sentry patrols the sandy shores.",
		enemy_count = 1,
		enemy_hp = { 85 },
		enemy_classes = { "recruit" },
		enemy_levels = { 1 },
		terrain_type = "hills",
		biome = "grass",
		enemy_skill = "easy",
	},
	{
		level = 2,
		name = "Зеленые Холмы",
		name_en = "Green Hills",
		desc = "Холмистый рубеж. Разведчик-штурмовик занял позицию на возвышенности.",
		desc_en = "Rolling hills frontier. An assault scout holds high ground.",
		enemy_count = 1,
		enemy_hp = { 95 },
		enemy_classes = { "assault" },
		enemy_levels = { 1 },
		terrain_type = "hills",
		biome = "grass",
		enemy_skill = "easy",
	},
	{
		level = 3,
		name = "Изумрудная Долина",
		name_en = "Emerald Valley",
		desc = "Передовой парный патруль: штурмовик и сапер минируют подходы.",
		desc_en = "Forward patrol pair: assault spud and sapper laying obstacles.",
		enemy_count = 2,
		enemy_hp = { 90, 90 },
		enemy_classes = { "assault", "sapper" },
		enemy_levels = { 1, 1 },
		terrain_type = "hills",
		biome = "grass",
		enemy_skill = "normal",
	},
	{
		level = 4,
		name = "Маяк Спокойствия",
		name_en = "Tranquil Lighthouse",
		desc = "Островной маяк у берега. Снайпер прикрывает сапера над пропастью.",
		desc_en = "Coastal lighthouse isle. A sniper covers a fortification sapper.",
		enemy_count = 2,
		enemy_hp = { 85, 80 },
		enemy_classes = { "sniper", "sapper" },
		enemy_levels = { 1, 1 },
		terrain_type = "islands",
		biome = "grass",
		enemy_skill = "normal",
	},

	-- =========================================================================
	-- РЕГИОН 2: ПУСТЫННЫЙ КАНЬОН (Desert Canyon) - Уровни 5..9 (Desert Biome)
	-- =========================================================================
	{
		level = 5,
		name = "Песчаные Дюны",
		name_en = "Sandy Dunes",
		desc = "Горячие дюны. Штурмовик при поддержке полевого медика держат оборону.",
		desc_en = "Blistering dunes. An assault backed by a combat medic holds the line.",
		enemy_count = 2,
		enemy_hp = { 90, 85 },
		enemy_classes = { "assault", "medic" },
		enemy_levels = { 1, 1 },
		terrain_type = "flat",
		biome = "desert",
		enemy_skill = "normal",
	},
	{
		level = 6,
		name = "Каньон Эхо",
		name_en = "Echo Canyon",
		desc = "Глубокая пропасть. Трио врагов ведет перекрестный навесной обстрел.",
		desc_en = "Chasm depths. Enemy trio raining mortar fire across the chasm.",
		enemy_count = 3,
		enemy_hp = { 85, 85, 85 },
		enemy_classes = { "artillery", "assault", "sapper" },
		enemy_levels = { 1, 1, 1 },
		terrain_type = "canyon_bridge",
		biome = "desert",
		enemy_skill = "normal",
	},
	{
		level = 7,
		name = "Пыльный Перекресток",
		name_en = "Dusty Crossroads",
		desc = "Изрытая катакомбами земля. Снайпер и тяжелый сапер стерегут развилку.",
		desc_en = "Swiss-cheese earth. A sniper and heavy sapper guard the fork.",
		enemy_count = 2,
		enemy_hp = { 95, 100 },
		enemy_classes = { "sniper", "sapper_2" },
		enemy_levels = { 2, 2 },
		terrain_type = "swiss_cheese",
		biome = "desert",
		enemy_skill = "normal",
	},
	{
		level = 8,
		name = "Северный Мост",
		name_en = "North Bridge",
		desc = "Каменная арка над пропастью. Штурмовой отряд при поддержке артиллерии.",
		desc_en = "Stone bridge arch. Assault vanguard supported by artillery guns.",
		enemy_count = 3,
		enemy_hp = { 95, 95, 105 },
		enemy_classes = { "assault_2", "artillery", "medic" },
		enemy_levels = { 2, 1, 1 },
		terrain_type = "canyon_bridge",
		biome = "desert",
		enemy_skill = "normal",
	},
	{
		level = 9,
		name = "Золотой Оазис",
		name_en = "Golden Oasis",
		desc = "Богатый сектор под охраной бронированного танка и штурмовика.",
		desc_en = "Lush oasis guarded by a heavily plated Tank and assault veteran.",
		enemy_count = 2,
		enemy_hp = { 140, 100 },
		enemy_classes = { "tank", "assault_2" },
		enemy_levels = { 2, 2 },
		terrain_type = "hills",
		biome = "desert",
		enemy_skill = "hard",
	},

	-- =========================================================================
	-- РЕГИОН 3: ЛЕДЯНОЙ ПЕРЕВАЛ (Ice Pass) - Уровни 10..13 (Arctic Biome)
	-- =========================================================================
	{
		level = 10,
		name = "Морозные Высоты",
		name_en = "Frost Heights",
		desc = "Ледяные острова в небе. Мобильный ракетчик и меткий снайпер контролируют воздух.",
		desc_en = "Floating ice peaks. A mobile rocketeer and sharpshooter dominate the sky.",
		enemy_count = 2,
		enemy_hp = { 100, 95 },
		enemy_classes = { "rocketeer", "sniper" },
		enemy_levels = { 2, 2 },
		terrain_type = "floating_islands",
		biome = "arctic",
		enemy_skill = "hard",
	},
	{
		level = 11,
		name = "Парящие Льдины",
		name_en = "Floating Floes",
		desc = "Гряда дрейфующих ледяных глыб. Тройка элитных скалолазов с базуками.",
		desc_en = "Drifting glacial floes. Trio of high-altitude rocketeers and commando.",
		enemy_count = 3,
		enemy_hp = { 100, 100, 105 },
		enemy_classes = { "rocketeer", "commando", "sniper" },
		enemy_levels = { 2, 2, 2 },
		terrain_type = "floating_islands",
		biome = "arctic",
		enemy_skill = "hard",
	},
	{
		level = 12,
		name = "Хребет Метелей",
		name_en = "Blizzard Ridge",
		desc = "Подземная ледяная пещера. Осадный артиллерист и диверсант в засаде.",
		desc_en = "Subterranean ice cavern. Siege artillery and commando in ambush.",
		enemy_count = 2,
		enemy_hp = { 115, 110 },
		enemy_classes = { "artillery_2", "commando" },
		enemy_levels = { 2, 2 },
		terrain_type = "cavern",
		biome = "arctic",
		enemy_skill = "hard",
	},
	{
		level = 13,
		name = "Ледяной Бастион",
		name_en = "Ice Bastion",
		desc = "Неприступная крепость во льдах. Взвод из 3 ветеранов: Танк, Сапер II и Хирург.",
		desc_en = "Impregnable ice fort. 3-spud elite detachment: Tank, Sapper II, Surgeon.",
		enemy_count = 3,
		enemy_hp = { 150, 120, 115 },
		enemy_classes = { "tank", "sapper_2", "surgeon" },
		enemy_levels = { 2, 2, 2 },
		terrain_type = "bunkers",
		biome = "arctic",
		enemy_skill = "hard",
	},

	-- =========================================================================
	-- РЕГИОН 4: ВУЛКАНИЧЕСКИЕ БАСТИОНЫ (Volcano Bastions) - Уровни 14..18 (Volcano Biome)
	-- =========================================================================
	{
		level = 14,
		name = "Обсидиановые Врата",
		name_en = "Obsidian Gates",
		desc = "Вход в вулканический сектор. 3 укрепленных огневых рубежа противника.",
		desc_en = "Gateway to the volcano. Three fortified battle positions.",
		enemy_count = 3,
		enemy_hp = { 120, 115, 125 },
		enemy_classes = { "assault_2", "artillery_2", "surgeon" },
		enemy_levels = { 2, 2, 2 },
		terrain_type = "bunkers",
		biome = "volcano",
		enemy_skill = "hard",
	},
	{
		level = 15,
		name = "Лавовое Ущелье",
		name_en = "Lava Gorge",
		desc = "Мост над кипящей лавой. Опаснейший перекрестный огонь снайпера и ракетчика.",
		desc_en = "Bridge over boiling magma. Lethal crossfire from sniper and rocketeer.",
		enemy_count = 3,
		enemy_hp = { 110, 125, 120 },
		enemy_classes = { "sniper", "rocketeer", "commando" },
		enemy_levels = { 2, 2, 2 },
		terrain_type = "canyon_bridge",
		biome = "volcano",
		enemy_skill = "hard",
	},
	{
		level = 16,
		name = "Катакомбы Угля",
		name_en = "Charcoal Catacombs",
		desc = "Лавовые подземные лабиринты. Осадная батарея и тяжелый сапер ведут бой на выживание.",
		desc_en = "Subterranean magma labyrinth. Heavy sapper and artillery duel to the end.",
		enemy_count = 3,
		enemy_hp = { 130, 135, 120 },
		enemy_classes = { "sapper_2", "artillery_2", "assault_2" },
		enemy_levels = { 2, 2, 2 },
		terrain_type = "cavern",
		biome = "volcano",
		enemy_skill = "hard",
	},
	{
		level = 17,
		name = "Бункер Генералов",
		name_en = "Generals Bunker",
		desc = "Генеральный штаб красных картошек. 4 опытных офицера в глубоком бункере.",
		desc_en = "Red Spud High Command. 4 hardened officers in a fortified bunker.",
		enemy_count = 4,
		enemy_hp = { 150, 130, 125, 130 },
		enemy_classes = { "tank", "artillery_2", "sniper", "surgeon" },
		enemy_levels = { 2, 2, 2, 2 },
		terrain_type = "bunkers",
		biome = "volcano",
		enemy_skill = "hard",
	},
	{
		level = 18,
		name = "Вулканическая Цитадель (ФИНАЛ)",
		name_en = "Volcano Citadel (FINAL BOSS)",
		desc = "Финальная битва на вершине вулкана! Босс Генерал-Клубень с гвардией ветеранов!",
		desc_en = "Final boss confrontation! The Supreme Spud General and elite vanguard!",
		enemy_count = 4,
		enemy_hp = { 200, 140, 140, 135 },
		enemy_classes = { "tank", "artillery_2", "rocketeer", "surgeon" },
		enemy_levels = { 3, 2, 2, 2 },
		terrain_type = "bunkers",
		biome = "volcano",
		enemy_skill = "hard",
	},
}

-- Procedural generator for endless/high levels beyond the preconfigured 18 levels
function M.generate_endless_level(level_num)
	local presets = { "hills", "floating_islands", "canyon_bridge", "cavern", "swiss_cheese", "islands", "bunkers" }
	local biomes = { "grass", "arctic", "desert", "volcano", "alien", "grass", "desert" }
	local idx = ((level_num - 1) % #presets) + 1

	local enemy_cnt = math.min(4, 2 + math.floor((level_num - 18) / 3))
	local scaled_hp = math.min(220, 120 + (level_num - 18) * 8)

	local class_pool = { "tank", "artillery_2", "rocketeer", "assault_2", "sniper", "sapper_2", "surgeon", "commando" }
	local enemy_classes = {}
	local enemy_levels = {}
	local enemy_hps = {}
	for i = 1, enemy_cnt do
		local pick = class_pool[((level_num + i) % #class_pool) + 1]
		table.insert(enemy_classes, pick)
		table.insert(enemy_levels, 2 + math.floor((level_num - 18) / 5))
		table.insert(enemy_hps, scaled_hp)
	end

	return M.normalize_level({
		level = level_num,
		name = "Арена " .. tostring(level_num) .. ": Экстрим",
		name_en = "Arena " .. tostring(level_num) .. ": Extreme",
		desc = "1 против волны элитных ботов-ветеранов!",
		desc_en = "Battle against elite spud veterans wave!",
		enemy_hp = enemy_hps,
		enemy_count = enemy_cnt,
		enemy_classes = enemy_classes,
		enemy_levels = enemy_levels,
		terrain_type = presets[idx],
		biome = biomes[idx],
		enemy_skill = "hard",
	}, level_num)
end

-- Get level configuration by level number
function M.get(level_num)
	level_num = level_num or 1
	if level_num >= 1 and level_num <= #M.LEVELS then
		return M.normalize_level(M.LEVELS[level_num], level_num)
	else
		return M.generate_endless_level(level_num)
	end
end

-- Get specific HP for enemy at index (1-based) on given level
function M.get_enemy_hp(level_num, enemy_index)
	local cfg = M.get(level_num)
	enemy_index = enemy_index or 1

	if type(cfg.enemy_hp) == "table" then
		if cfg.enemy_hp[enemy_index] then
			return cfg.enemy_hp[enemy_index]
		elseif #cfg.enemy_hp > 0 then
			return cfg.enemy_hp[#cfg.enemy_hp]
		else
			return 100
		end
	elseif type(cfg.enemy_hp) == "number" then
		return cfg.enemy_hp
	else
		return 100
	end
end

-- Get enemy count for given level
function M.get_enemy_count(level_num)
	local cfg = M.get(level_num)
	return cfg.enemy_count or 1
end

-- Get enemy class ID for enemy at index (1-based) on given level
function M.get_enemy_class(level_num, enemy_index)
	local cfg = M.get(level_num)
	enemy_index = enemy_index or 1
	if cfg.enemy_classes and #cfg.enemy_classes > 0 then
		return cfg.enemy_classes[enemy_index] or cfg.enemy_classes[#cfg.enemy_classes] or "recruit"
	end
	return "recruit"
end

-- Get enemy unit level / rank for enemy at index (1-based) on given level
function M.get_enemy_level(level_num, enemy_index)
	local cfg = M.get(level_num)
	enemy_index = enemy_index or 1
	if cfg.enemy_levels and #cfg.enemy_levels > 0 then
		return cfg.enemy_levels[enemy_index] or cfg.enemy_levels[#cfg.enemy_levels] or 1
	end
	return 1
end

-- Get terrain type for given level
function M.get_terrain_type(level_num)
	local cfg = M.get(level_num)
	return cfg.terrain_type or "hills"
end

-- Get biome for given level
function M.get_biome(level_num)
	local cfg = M.get(level_num)
	return cfg.biome or M.deduce_biome(cfg.terrain_type)
end

-- Get bot skill / difficulty for given level
function M.get_skill_level(level_num)
	local cfg = M.get(level_num)
	return cfg.enemy_skill or "normal"
end
M.get_bot_difficulty = M.get_skill_level

-- Get total number of predefined levels
function M.count()
	return #M.LEVELS
end

-- Register or override a level configuration dynamically
function M.set_level(level_num, config)
	if not config then return end
	config.level = level_num
	M.LEVELS[level_num] = M.normalize_level(config, level_num)
end

-- Quick match configurations (Quick Bot & Quick PvP)
function M.get_quick_match(mode)
	local pool_presets = {
		"hills", "floating_islands", "canyon_bridge", "cavern", "swiss_cheese",
		"bunkers", "islands", "pyramid_temple", "twin_peaks", "valley_caves"
	}
	local pool_biomes = { "grass", "arctic", "desert", "volcano", "alien" }
	local pick_preset = pool_presets[math.random(1, #pool_presets)]
	local pick_biome = pool_biomes[math.random(1, #pool_biomes)]

	if mode == "pvp_bots" or mode == "quick_pvp_bots" then
		return {
			name = "PvP vs Боты (3 на 3)",
			name_en = "PvP vs Bots (3v3)",
			enemy_hp = 100,
			enemy_count = 3,
			red_count = 3,
			player_count = 3,
			blue_count = 3,
			terrain_type = pick_preset,
			terrain_preset = pick_preset,
			biome = pick_biome,
			enemy_skill = "hard",
			bot_difficulty = "hard",
		}
	elseif mode == "quick_pvp" then
		return {
			name = "Быстрый бой: 2 Игрока",
			enemy_hp = 100,
			enemy_count = 2,
			red_count = 2,
			player_count = 2,
			blue_count = 2,
			terrain_type = pick_preset,
			terrain_preset = pick_preset,
			biome = pick_biome,
			enemy_skill = "none",
			bot_difficulty = "none",
		}
	else
		return {
			name = "Быстрый бой vs Компьютер",
			enemy_hp = 100,
			enemy_count = 2,
			red_count = 2,
			player_count = 2,
			blue_count = 2,
			terrain_type = pick_preset,
			terrain_preset = pick_preset,
			biome = pick_biome,
			enemy_skill = "normal",
			bot_difficulty = "normal",
		}
	end
end

return M
