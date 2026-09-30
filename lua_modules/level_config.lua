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
		enemy_hp = (lvl == 1) and 60 or 100
	end

	local is_ru = (i18n.current_lang == "ru")
	local lvl_name = (is_ru and entry.name) or entry.name_en or entry.name or ((is_ru and "Арена " or "Arena ") .. tostring(lvl))
	local lvl_desc = (is_ru and entry.desc) or entry.desc_en or entry.desc or ""

	return {
		level = lvl,
		id = lvl,
		name = lvl_name,
		desc = lvl_desc,
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
	}
end

-- Campaign levels table:
-- Parameters per level:
--   level: номер уровня
--   enemy_hp: здоровье врагов (число или таблица { hp1, hp2, ... })
--   enemy_count: количество врагов
--   terrain_type: тип террейна ("hills", "floating_islands", "canyon_bridge", "cavern", "swiss_cheese", "bunkers", "islands")
--   enemy_skill: уровень скила противника ("easy", "normal", "hard" или 1, 2, 3)
--   biome: визуальная тема биома (опционально: "grass", "arctic", "desert", "volcano", "alien")
M.LEVELS = {
	{
		level = 1,
		name = "Арена 1: Зеленые Холмы",
		name_en = "Arena 1: Green Hills",
		desc = "Быстрая дуэль 1 на 1 среди цветущих лугов!",
		desc_en = "Fast 1v1 duel across rolling meadow hills!",
		enemy_hp = 80,
		enemy_count = 1,
		terrain_type = "hills",
		biome = "grass",
		enemy_skill = "easy",
	},
	{
		level = 2,
		name = "Арена 2: Ледяной Архипелаг",
		name_en = "Arena 2: Arctic Archipelago",
		desc = "Дуэль на парящих в воздухе ледяных островах!",
		desc_en = "Aerial battle on floating icebergs and glaciers!",
		enemy_hp = 110,
		enemy_count = 1,
		terrain_type = "bunkers",
		biome = "arctic",
		enemy_skill = "easy",
	},
	{
		level = 3,
		name = "Арена 3: Каньон и Каменный Мост",
		name_en = "Arena 3: Canyon & Stone Bridge",
		desc = "Сражение на гигантской каменной арке над пустынным ущельем.",
		desc_en = "Epic clash on a sandstone arch across a desert chasm.",
		enemy_hp = 70,
		enemy_count = 2,
		terrain_type = "canyon_bridge",
		biome = "desert",
		enemy_skill = "normal",
	},
	{
		level = 4,
		name = "Арена 4: Лавовые Катакомбы",
		name_en = "Arena 4: Lava Catacombs",
		desc = "1 против 2 ботов в вулканическом кратере с лавой!",
		desc_en = "1 vs 2 bots in an active volcanic crater!",
		enemy_hp = 85,
		enemy_count = 2,
		terrain_type = "cavern",
		biome = "volcano",
		enemy_skill = "normal",
	},
	{
		level = 5,
		name = "Арена 5: Инопланетная Цитадель",
		name_en = "Arena 5: Alien Citadel",
		desc = "Финальный штурм: 1 против 2 ботов в изрезанной кавернами цитадели!",
		desc_en = "Assault against 2 bots in a bio-cavern fortress!",
		enemy_hp = 95,
		enemy_count = 2,
		terrain_type = "swiss_cheese",
		biome = "alien",
		enemy_skill = "normal",
	},
	{
		level = 6,
		name = "Арена 6: Пустынные Бункеры",
		name_en = "Arena 6: Desert Bunkers",
		desc = "Окопная война среди песчаных дюн и укрепленных бункеров!",
		desc_en = "Trench warfare among fortified concrete pillboxes!",
		enemy_hp = 140,
		enemy_count = 1,
		terrain_type = "bunkers",
		biome = "desert",
		enemy_skill = "hard",
	},
	{
		level = 7,
		name = "Арена 7: Островной Архипелаг",
		name_en = "Arena 7: Island Archipelago",
		desc = "Ожесточенное сражение на трех островах против троих врагов!",
		desc_en = "Fierce crossfire across three coastal sea islands!",
		enemy_hp = 100,
		enemy_count = 3,
		terrain_type = "islands",
		biome = "grass",
		enemy_skill = "hard",
	},
	{
		level = 8,
		name = "Арена 8: Огненная Преисподняя",
		name_en = "Arena 8: Molten Inferno",
		desc = "Финальная битва: 1 против 3 элитных ботов-ветеранов!",
		desc_en = "Final boss showdown: 1 vs 3 veteran elite spuds!",
		enemy_hp = 125,
		enemy_count = 3,
		terrain_type = "cavern",
		biome = "volcano",
		enemy_skill = "hard",
	},
}

-- Procedural generator for endless/high levels beyond the preconfigured list
function M.generate_endless_level(level_num)
	local presets = { "hills", "floating_islands", "canyon_bridge", "cavern", "swiss_cheese", "islands", "bunkers" }
	local biomes = { "grass", "arctic", "desert", "volcano", "alien", "grass", "desert" }
	local idx = ((level_num - 1) % #presets) + 1

	local enemy_cnt = math.min(3, 1 + math.floor(level_num / 2))
	local scaled_hp = math.min(200, 100 + (level_num - #M.LEVELS) * 10)

	return M.normalize_level({
		level = level_num,
		name = "Арена " .. tostring(level_num) .. ": Экстрим",
		desc = "1 против волны элитных ботов!",
		enemy_hp = scaled_hp,
		enemy_count = enemy_cnt,
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
