-- lua_modules/territory_map.lua
-- Data model and graph algorithms for the Potato War Island Campaign Map

local player_profile = require("lua_modules.player_profile")
local constants = require("lua_modules.constants")

local M = {}

M.OWNER_BLUE = "blue"
M.OWNER_RED = "red"

local function norm_owner(o)
	if not o then return "blue" end
	local s = string.lower(tostring(o))
	if s == "blue" or s == "1" then return "blue" end
	if s == "red" or s == "2" then return "red" end
	return s
end

-- 4 Climatic regions on the Potato Island:
M.REGIONS = {
	[1] = { id = "meadows", name_ru = "Прибрежные Луга", name_en = "Coastal Meadows", biome = "grass" },
	[2] = { id = "canyon", name_ru = "Пустынный Каньон", name_en = "Desert Canyon", biome = "desert" },
	[3] = { id = "ice_pass", name_ru = "Ледяной Перевал", name_en = "Ice Pass", biome = "arctic" },
	[4] = { id = "volcano", name_ru = "Вулканические Бастионы", name_en = "Volcano Bastions", biome = "volcano" },
}

-- Default 18 sectors layout across 960x540 screen
-- Screen coordinates fit comfortably within x: 60..640, y: 70..450, leaving x: 675..940 for the Inspector Panel.
M.DEFAULT_SECTORS = {
	-- REGION 1: Прибрежные Луга (Coastal Meadows) - SW
	[1] = {
		id = 1,
		name_ru = "Бухта Высадки",
		name_en = "Landing Cove",
		region = 1,
		biome = "grass",
		terrain_preset = "hills",
		owner = "blue",
		defense_level = 1,
		income = 20,
		garrison = 2,
		x = 85,
		y = 110,
		neighbors = { 2, 3, 5 },
		under_attack = false,
	},
	[2] = {
		id = 2,
		name_ru = "Зеленые Холмы",
		name_en = "Green Hills",
		region = 1,
		biome = "grass",
		terrain_preset = "hills",
		owner = "blue",
		defense_level = 2,
		income = 25,
		garrison = 3,
		x = 110,
		y = 225,
		neighbors = { 1, 3, 4, 10 },
		under_attack = false,
	},
	[3] = {
		id = 3,
		name_ru = "Изумрудная Долина",
		name_en = "Emerald Valley",
		region = 1,
		biome = "grass",
		terrain_preset = "hills",
		owner = "red",
		defense_level = 1,
		income = 25,
		garrison = 2,
		x = 205,
		y = 165,
		neighbors = { 1, 2, 5, 6, 7 },
		under_attack = false,
	},
	[4] = {
		id = 4,
		name_ru = "Маяк Спокойствия",
		name_en = "Tranquil Lighthouse",
		region = 1,
		biome = "grass",
		terrain_preset = "islands",
		owner = "red",
		defense_level = 1,
		income = 20,
		garrison = 2,
		x = 85,
		y = 335,
		neighbors = { 2, 10 },
		under_attack = false,
	},

	-- REGION 2: Пустынный Каньон (Desert Canyon) - South / Center
	[5] = {
		id = 5,
		name_ru = "Песчаные Дюны",
		name_en = "Sandy Dunes",
		region = 2,
		biome = "desert",
		terrain_preset = "flat",
		owner = "red",
		defense_level = 1,
		income = 30,
		garrison = 2,
		x = 230,
		y = 85,
		neighbors = { 1, 3, 6, 9 },
		under_attack = false,
	},
	[6] = {
		id = 6,
		name_ru = "Каньон Эхо",
		name_en = "Echo Canyon",
		region = 2,
		biome = "desert",
		terrain_preset = "canyon_bridge",
		owner = "red",
		defense_level = 2,
		income = 35,
		garrison = 3,
		x = 325,
		y = 150,
		neighbors = { 3, 5, 7, 8, 9 },
		under_attack = false,
	},
	[7] = {
		id = 7,
		name_ru = "Пыльный Перекресток",
		name_en = "Dusty Crossroads",
		region = 2,
		biome = "desert",
		terrain_preset = "swiss_cheese",
		owner = "red",
		defense_level = 1,
		income = 30,
		garrison = 2,
		x = 310,
		y = 265,
		neighbors = { 3, 6, 8, 10, 13 },
		under_attack = false,
	},
	[8] = {
		id = 8,
		name_ru = "Северный Мост",
		name_en = "North Bridge",
		region = 2,
		biome = "desert",
		terrain_preset = "canyon_bridge",
		owner = "red",
		defense_level = 2,
		income = 40,
		garrison = 3,
		x = 430,
		y = 205,
		neighbors = { 6, 7, 9, 14, 15 },
		under_attack = false,
	},
	[9] = {
		id = 9,
		name_ru = "Золотой Оазис",
		name_en = "Golden Oasis",
		region = 2,
		biome = "desert",
		terrain_preset = "hills",
		owner = "red",
		defense_level = 2,
		income = 45,
		garrison = 3,
		x = 420,
		y = 95,
		neighbors = { 5, 6, 8, 15, 16 },
		under_attack = false,
	},

	-- REGION 3: Ледяной Перевал (Ice Pass) - North / NW
	[10] = {
		id = 10,
		name_ru = "Морозные Высоты",
		name_en = "Frost Heights",
		region = 3,
		biome = "arctic",
		terrain_preset = "floating_islands",
		owner = "red",
		defense_level = 2,
		income = 30,
		garrison = 3,
		x = 195,
		y = 365,
		neighbors = { 2, 4, 7, 11, 13 },
		under_attack = false,
	},
	[11] = {
		id = 11,
		name_ru = "Парящие Льдины",
		name_en = "Floating Floes",
		region = 3,
		biome = "arctic",
		terrain_preset = "floating_islands",
		owner = "red",
		defense_level = 2,
		income = 35,
		garrison = 3,
		x = 295,
		y = 435,
		neighbors = { 10, 12, 13 },
		under_attack = false,
	},
	[12] = {
		id = 12,
		name_ru = "Хребет Метелей",
		name_en = "Blizzard Ridge",
		region = 3,
		biome = "arctic",
		terrain_preset = "cavern",
		owner = "red",
		defense_level = 2,
		income = 35,
		garrison = 3,
		x = 415,
		y = 365,
		neighbors = { 11, 13, 14, 18 },
		under_attack = false,
	},
	[13] = {
		id = 13,
		name_ru = "Ледяной Бастион",
		name_en = "Ice Bastion",
		region = 3,
		biome = "arctic",
		terrain_preset = "bunkers",
		owner = "red",
		defense_level = 3,
		income = 40,
		garrison = 4,
		x = 320,
		y = 350,
		neighbors = { 7, 10, 11, 12, 14 },
		under_attack = false,
	},

	-- REGION 4: Вулканические Бастионы (Volcano Bastions) - East / NE
	[14] = {
		id = 14,
		name_ru = "Обсидиановые Врата",
		name_en = "Obsidian Gates",
		region = 4,
		biome = "volcano",
		terrain_preset = "bunkers",
		owner = "red",
		defense_level = 2,
		income = 45,
		garrison = 3,
		x = 515,
		y = 315,
		neighbors = { 8, 12, 13, 15, 17, 18 },
		under_attack = false,
	},
	[15] = {
		id = 15,
		name_ru = "Лавовое Ущелье",
		name_en = "Lava Gorge",
		region = 4,
		biome = "volcano",
		terrain_preset = "canyon_bridge",
		owner = "red",
		defense_level = 2,
		income = 40,
		garrison = 3,
		x = 525,
		y = 185,
		neighbors = { 8, 9, 14, 16, 17 },
		under_attack = false,
	},
	[16] = {
		id = 16,
		name_ru = "Катакомбы Угля",
		name_en = "Charcoal Catacombs",
		region = 4,
		biome = "volcano",
		terrain_preset = "cavern",
		owner = "red",
		defense_level = 2,
		income = 40,
		garrison = 3,
		x = 610,
		y = 135,
		neighbors = { 9, 15, 17 },
		under_attack = false,
	},
	[17] = {
		id = 17,
		name_ru = "Бункер Генералов",
		name_en = "Generals Bunker",
		region = 4,
		biome = "volcano",
		terrain_preset = "bunkers",
		owner = "red",
		defense_level = 3,
		income = 50,
		garrison = 4,
		x = 620,
		y = 270,
		neighbors = { 14, 15, 16, 18 },
		under_attack = false,
	},
	[18] = {
		id = 18,
		name_ru = "Вулканическая Цитадель",
		name_en = "Volcano Citadel",
		region = 4,
		biome = "volcano",
		terrain_preset = "bunkers",
		owner = "red",
		defense_level = 3,
		income = 60,
		garrison = 4,
		x = 615,
		y = 415,
		neighbors = { 12, 14, 17 },
		under_attack = false,
	},
}

-- Current active sectors table
M.sectors = {}

local function deep_copy_sectors(source)
	local res = {}
	for id, s in pairs(source) do
		local n_copy = {}
		for _, nid in ipairs(s.neighbors or {}) do
			table.insert(n_copy, nid)
		end
		res[id] = {
			id = s.id,
			name_ru = s.name_ru,
			name_en = s.name_en,
			region = s.region,
			biome = s.biome,
			terrain_preset = s.terrain_preset,
			owner = s.owner,
			defense_level = s.defense_level,
			income = s.income,
			garrison = s.garrison,
			x = s.x,
			y = s.y,
			neighbors = n_copy,
			under_attack = s.under_attack == true,
		}
	end
	return res
end

function M.reset_map()
	M.sectors = deep_copy_sectors(M.DEFAULT_SECTORS)
	M.save_to_profile()
	return M.sectors
end

function M.get_sectors()
	if not M.sectors or next(M.sectors) == nil then
		M.load_from_profile()
	end
	return M.sectors
end

function M.get_sector(id)
	local secs = M.get_sectors()
	return secs[id]
end

-- Unique list of edges (pairs of connected sector ids)
function M.get_connections()
	local secs = M.get_sectors()
	local edges = {}
	local seen = {}
	for id, s in pairs(secs) do
		for _, nid in ipairs(s.neighbors) do
			local key = (id < nid) and (id .. "_" .. nid) or (nid .. "_" .. id)
			if not seen[key] then
				seen[key] = true
				local neighbor = secs[nid]
				local is_frontline = (neighbor ~= nil) and (s.owner ~= neighbor.owner)
				table.insert(edges, {
					from = id,
					to = nid,
					sector_a = s,
					sector_b = neighbor,
					is_frontline = is_frontline,
				})
			end
		end
	end
	return edges
end

-- List of contested frontline edges (Blue-to-Red connections)
function M.get_frontline()
	local all = M.get_connections()
	local frontline = {}
	for _, e in ipairs(all) do
		if e.is_frontline then
			table.insert(frontline, e)
		end
	end
	return frontline
end

-- Available targets for attacker team (default: Blue player attacking Red sectors)
function M.get_available_targets(attacker_owner)
	attacker_owner = norm_owner(attacker_owner or "blue")
	local enemy_owner = (attacker_owner == "blue") and "red" or "blue"
	local secs = M.get_sectors()
	local targets = {}
	local target_map = {}
	for id, s in pairs(secs) do
		if s.owner == enemy_owner then
			for _, nid in ipairs(s.neighbors) do
				local n = secs[nid]
				if n and n.owner == attacker_owner and not target_map[id] then
					target_map[id] = true
					table.insert(targets, s)
					break
				end
			end
		end
	end
	table.sort(targets, function(a, b) return a.id < b.id end)
	return targets
end

function M.can_attack(id)
	local s = M.get_sector(id)
	if not s or s.owner ~= "red" then return false end
	local secs = M.get_sectors()
	for _, nid in ipairs(s.neighbors) do
		local n = secs[nid]
		if n and n.owner == "blue" then
			return true
		end
	end
	return false
end

-- Sectors owned by Blue that can be fortified (defense_level < 3)
function M.get_fortifiable_sectors()
	local secs = M.get_sectors()
	local list = {}
	for id, s in pairs(secs) do
		if s.owner == "blue" and (s.defense_level or 1) < 3 then
			table.insert(list, s)
		end
	end
	table.sort(list, function(a, b) return a.id < b.id end)
	return list
end

function M.can_fortify(id)
	local s = M.get_sector(id)
	if not s or s.owner ~= "blue" then return false end
	return (s.defense_level or 1) < 3
end

function M.get_fortify_cost(id)
	local s = M.get_sector(id)
	if not s then return 50 end
	local lvl = s.defense_level or 1
	if lvl == 1 then return 40 end
	if lvl == 2 then return 80 end
	return 999
end

function M.fortify_sector(id)
	local s = M.get_sector(id)
	if not s or s.owner ~= "blue" then return false, "Нельзя укрепить" end
	if (s.defense_level or 1) >= 3 then
		return false, "Максимальный уровень"
	end
	s.defense_level = (s.defense_level or 1) + 1
	if s.defense_level == 2 then
		s.garrison = math.max(s.garrison or 2, 3)
	elseif s.defense_level == 3 then
		s.garrison = math.max(s.garrison or 2, 4)
	end
	M.save_to_profile()
	return true, s.defense_level
end

function M.capture_sector(id, new_owner)
	local s = M.get_sector(id)
	if not s then return false end
	s.owner = norm_owner(new_owner or "blue")
	s.defense_level = 1
	s.under_attack = false
	if s.owner == "blue" then
		s.garrison = 2
	end
	M.save_to_profile()
	return true, s
end

function M.set_under_attack(id, state)
	local s = M.get_sector(id)
	if s then
		s.under_attack = (state == true)
		M.save_to_profile()
	end
end

-- Blue sectors bordering Red sectors (vulnerable to enemy counter-attack)
function M.get_vulnerable_blue_sectors()
	return M.get_vulnerable_border_sectors("blue")
end

-- Get all sectors as a sorted list
function M.get_all_sectors()
	local secs = M.get_sectors()
	local list = {}
	for _, s in pairs(secs) do
		table.insert(list, s)
	end
	table.sort(list, function(a, b) return a.id < b.id end)
	return list
end

-- Get sectors owned by specific faction
function M.get_sectors_by_owner(owner)
	owner = norm_owner(owner or "blue")
	local secs = M.get_sectors()
	local list = {}
	for _, s in pairs(secs) do
		if s.owner == owner then
			table.insert(list, s)
		end
	end
	table.sort(list, function(a, b) return a.id < b.id end)
	return list
end

-- Border sectors owned by faction that neighbor an enemy faction
function M.get_border_sectors(owner)
	owner = norm_owner(owner or "blue")
	local enemy_owner = (owner == "blue") and "red" or "blue"
	local secs = M.get_sectors()
	local border = {}
	for _, s in pairs(secs) do
		if s.owner == owner then
			for _, nid in ipairs(s.neighbors or {}) do
				local n = secs[nid]
				if n and n.owner == enemy_owner then
					table.insert(border, s)
					break
				end
			end
		end
	end
	table.sort(border, function(a, b) return a.id < b.id end)
	return border
end

-- Vulnerable border sectors sorted by vulnerability score (lowest defense first, highest pressure)
function M.get_vulnerable_border_sectors(owner)
	owner = norm_owner(owner or "blue")
	local border = M.get_border_sectors(owner)
	local enemy_owner = (owner == "blue") and "red" or "blue"
	local secs = M.get_sectors()

	local list = {}
	for _, s in ipairs(border) do
		local red_pressure = 0
		for _, nid in ipairs(s.neighbors or {}) do
			local n = secs[nid]
			if n and n.owner == enemy_owner then
				red_pressure = red_pressure + 1
			end
		end
		table.insert(list, {
			sector = s,
			defense_level = s.defense_level or 1,
			red_pressure = red_pressure,
			income = s.income or 0,
		})
	end

	table.sort(list, function(a, b)
		if a.defense_level ~= b.defense_level then
			return a.defense_level < b.defense_level
		elseif a.red_pressure ~= b.red_pressure then
			return a.red_pressure > b.red_pressure
		else
			return a.income < b.income
		end
	end)

	local res = {}
	for _, item in ipairs(list) do
		table.insert(res, item.sector)
	end
	return res
end

-- Total turn income for specified faction
function M.get_income(team)
	team = norm_owner(team or "blue")
	local secs = M.get_sectors()
	local total = 0
	for _, s in pairs(secs) do
		if s.owner == team then
			total = total + (s.income or 0)
		end
	end
	return total
end

-- Campaign statistics overview
function M.get_stats()
	local secs = M.get_sectors()
	local blue_count = 0
	local red_count = 0
	local total_count = 0
	local blue_income = 0
	for _, s in pairs(secs) do
		total_count = total_count + 1
		if s.owner == "blue" then
			blue_count = blue_count + 1
			blue_income = blue_income + (s.income or 0)
		else
			red_count = red_count + 1
		end
	end
	local pct = math.floor((blue_count / math.max(1, total_count)) * 100)
	return {
		blue_count = blue_count,
		red_count = red_count,
		total_count = total_count,
		blue_income = blue_income,
		progress_pct = pct,
	}
end

-- Export serializable map state
function M.get_state()
	local secs = M.get_sectors()
	local serialized = {}
	for id, s in pairs(secs) do
		serialized[id] = {
			owner = s.owner,
			defense_level = s.defense_level,
			under_attack = s.under_attack == true,
		}
	end
	return serialized
end

-- Restore map state from serialized table
function M.set_state(saved_state)
	if not saved_state or type(saved_state) ~= "table" then
		M.reset_map()
		return
	end
	M.reset_map()
	for id, data in pairs(saved_state) do
		local s = M.sectors[tonumber(id)]
		if s and type(data) == "table" then
			if data.owner then s.owner = norm_owner(data.owner) end
			if data.defense_level then
				s.defense_level = math.max(1, math.min(3, tonumber(data.defense_level) or 1))
			end
			if data.under_attack ~= nil then s.under_attack = data.under_attack end
		end
	end
	M.save_to_profile()
end

-- Check victory condition (owner controls all sectors)
function M.is_victory(owner)
	owner = norm_owner(owner or "blue")
	local secs = M.get_sectors()
	for _, s in pairs(secs) do
		if s.owner ~= owner then return false end
	end
	return true
end

-- Check defeat condition (owner has lost all sectors)
function M.is_defeat(owner)
	owner = norm_owner(owner or "blue")
	local secs = M.get_sectors()
	for _, s in pairs(secs) do
		if s.owner == owner then return false end
	end
	return true
end

-- Get localized sector name
function M.get_name(sector, lang)
	if not sector then return "" end
	lang = lang or "en"
	if lang == "ru" then
		return sector.name_ru or sector.name_en or ""
	else
		return sector.name_en or sector.name_ru or ""
	end
end

-- Reset alias
M.reset = M.reset_map

-- Save / Load integration with player_profile
function M.save_to_profile()
	if not M.sectors or next(M.sectors) == nil then return end
	local serialized = M.get_state()
	player_profile.set_campaign_map(serialized)
end

function M.load_from_profile()
	M.sectors = deep_copy_sectors(M.DEFAULT_SECTORS)
	local saved = player_profile.data and player_profile.data.campaign_map
	if saved and type(saved) == "table" then
		for id, data in pairs(saved) do
			local s = M.sectors[tonumber(id)]
			if s and type(data) == "table" then
				if data.owner then s.owner = norm_owner(data.owner) end
				if data.defense_level then s.defense_level = data.defense_level end
				if data.under_attack ~= nil then s.under_attack = data.under_attack end
			end
		end
	end
	return M.sectors
end

-- Auto initialize
M.load_from_profile()

return M
