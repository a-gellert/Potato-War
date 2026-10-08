-- lua_modules/player_profile.lua
-- Persistent storage for player points, unlocked skins, equipped skin, and campaign HP

local M = {}

M.SKINS = {
	{
		id = "classic",
		name = "Обычный Боец",
		name_ru = "Обычный Боец",
		name_en = "Classic Spud",
		desc = "Классический синий картофельный боец",
		desc_ru = "Классический синий картофельный боец",
		desc_en = "Classic blue potato warrior",
		price = 0,
		tint = { 1.0, 1.0, 1.0, 1.0 },
	},
	{
		id = "gold",
		name = "Золотой Самородок",
		name_ru = "Золотой Самородок",
		name_en = "Golden Nugget",
		desc = "Покрыт чистым золотом высшей пробы",
		desc_ru = "Покрыт чистым золотом высшей пробы",
		desc_en = "Coated in pure 24-karat gold",
		price = 150,
		tint = { 1.0, 0.85, 0.2, 1.0 },
	},
	{
		id = "ninja",
		name = "Картошка-Ниндзя",
		name_ru = "Картошка-Ниндзя",
		name_en = "Ninja Spud",
		desc = "Темный скрытный мастер боевых искусств",
		desc_ru = "Темный скрытный мастер боевых искусств",
		desc_en = "Stealthy martial arts master",
		price = 250,
		tint = { 0.35, 0.35, 0.45, 1.0 },
	},
	{
		id = "cyber",
		name = "Киборг MK-II",
		name_ru = "Киборг MK-II",
		name_en = "Cyborg MK-II",
		desc = "Неоновый кибернетический корпус",
		desc_ru = "Неоновый кибернетический корпус",
		desc_en = "Neon cybernetic battle chassis",
		price = 400,
		tint = { 0.2, 0.9, 1.0, 1.0 },
	},
	{
		id = "king",
		name = "Король Пюре",
		name_ru = "Король Пюре",
		name_en = "King Mash",
		desc = "Королевское величие и пурпурная мантия",
		desc_ru = "Королевское величие и пурпурная мантия",
		desc_en = "Royal majesty in a purple robe",
		price = 600,
		tint = { 0.85, 0.25, 0.85, 1.0 },
	},
	{
		id = "magma",
		name = "Магмовый Титан",
		name_ru = "Магмовый Титан",
		name_en = "Magma Titan",
		desc = "Раскаленная лава и несокрушимая броня",
		desc_ru = "Раскаленная лава и несокрушимая броня",
		desc_en = "Molten lava and indestructible armor",
		price = 900,
		tint = { 1.0, 0.4, 0.1, 1.0 },
	},
	{
		id = "emerald",
		name = "Изумрудный Страж",
		name_ru = "Изумрудный Страж",
		name_en = "Emerald Sentinel",
		desc = "Древний кристальный защитник урожая",
		desc_ru = "Древний кристальный защитник урожая",
		desc_en = "Ancient crystal crop guardian",
		price = 1200,
		tint = { 0.2, 1.0, 0.4, 1.0 },
	},
}

M.SKINS_BY_ID = {}
for _, s in ipairs(M.SKINS) do
	M.SKINS_BY_ID[s.id] = s
end

function M.get_skin_name(skin, lang)
	if not skin then return "" end
	lang = lang or "en"
	if lang == "ru" then
		return skin.name_ru or skin.name or ""
	else
		return skin.name_en or skin.name or ""
	end
end

function M.get_skin_desc(skin, lang)
	if not skin then return "" end
	lang = lang or "en"
	if lang == "ru" then
		return skin.desc_ru or skin.desc or ""
	else
		return skin.desc_en or skin.desc or ""
	end
end

-- Profile state
M.data = {
	language = nil,
	points = 0,
	stars = 0,
	squad = {
		{ id = 1, class_id = "recruit" },
		{ id = 2, class_id = "recruit" },
	},
	unlocked_skins = { ["classic"] = true },
	equipped_skin = "classic",
	campaign_hp = 100,
	campaign_max_hp = 100,
	meta_upgrades = {
		max_hp = 0,
		starting_weapon = 0,
		hp_regen = 0,
	},
	campaign_map = nil,
	campaign_turn = 1,
	campaign_stats = {
		battles_won = 0,
		battles_lost = 0,
		sectors_conquered = 0,
		sectors_lost = 0,
		counterattacks_repelled = 0,
	},
}

local function get_save_path()
	if sys and sys.get_save_file then
		return sys.get_save_file("potato_war", "profile_save")
	end
	return nil
end

function M.load()
	local path = get_save_path()
	local loaded = (path and sys and sys.load) and sys.load(path) or nil
	if loaded and type(loaded) == "table" and loaded.unlocked_skins then
		M.data.language = loaded.language
		M.data.points = loaded.points or 0
		M.data.stars = loaded.stars or 0
		M.data.squad = loaded.squad or {
			{ id = 1, class_id = "recruit" },
			{ id = 2, class_id = "recruit" },
		}
		-- Ensure squad has at least 2 members
		if #M.data.squad < 2 then
			M.data.squad = {
				{ id = 1, class_id = "recruit" },
				{ id = 2, class_id = "recruit" },
			}
		end
		M.data.unlocked_skins = loaded.unlocked_skins or { ["classic"] = true }
		M.data.equipped_skin = loaded.equipped_skin or "classic"
		M.data.campaign_hp = loaded.campaign_hp or 100
		M.data.campaign_max_hp = loaded.campaign_max_hp or 100
		M.data.meta_upgrades = loaded.meta_upgrades or { max_hp = 0, starting_weapon = 0, hp_regen = 0 }
		M.data.campaign_map = loaded.campaign_map
		M.data.campaign_turn = loaded.campaign_turn or 1
		M.data.campaign_stats = loaded.campaign_stats or {
			battles_won = 0,
			battles_lost = 0,
			sectors_conquered = 0,
			sectors_lost = 0,
			counterattacks_repelled = 0,
		}
	else
		M.data.language = nil
		M.data.points = 0
		M.data.stars = 0
		M.data.squad = {
			{ id = 1, class_id = "recruit" },
			{ id = 2, class_id = "recruit" },
		}
		M.data.unlocked_skins = { ["classic"] = true }
		M.data.equipped_skin = "classic"
		M.data.campaign_hp = 100
		M.data.campaign_max_hp = 100
		M.data.meta_upgrades = { max_hp = 0, starting_weapon = 0, hp_regen = 0 }
		M.data.campaign_map = nil
		M.data.campaign_turn = 1
		M.data.campaign_stats = {
			battles_won = 0,
			battles_lost = 0,
			sectors_conquered = 0,
			sectors_lost = 0,
			counterattacks_repelled = 0,
		}
	end
	return M.data
end

function M.save()
	local path = get_save_path()
	if path and sys and sys.save then
		sys.save(path, M.data)
	end
end

function M.get_language()
	return M.data.language
end

function M.set_language(lang)
	if lang == "ru" or lang == "en" then
		M.data.language = lang
		M.save()
	end
end

function M.get_points()
	return M.data.points or 0
end

function M.add_points(amount)
	M.data.points = (M.data.points or 0) + (amount or 0)
	M.save()
	return M.data.points
end

function M.get_stars()
	return M.data.stars or 0
end

function M.add_stars(amount)
	M.data.stars = math.max(0, (M.data.stars or 0) + (amount or 0))
	M.save()
	return M.data.stars
end

function M.spend_stars(amount)
	local cur = M.get_stars()
	if cur >= amount then
		M.data.stars = cur - amount
		M.save()
		return true
	end
	return false
end

-- 1 star = 1000 points
function M.buy_star_with_points()
	if M.get_points() >= 1000 then
		M.data.points = M.data.points - 1000
		M.data.stars = (M.data.stars or 0) + 1
		M.save()
		return true, M.data.stars
	end
	return false, "Недостаточно очков (требуется 1000 очков)"
end

function M.get_squad()
	if not M.data.squad or #M.data.squad < 2 then
		M.data.squad = {
			{ id = 1, class_id = "recruit" },
			{ id = 2, class_id = "recruit" },
		}
	end
	return M.data.squad
end

-- Squad expansion: 3rd potato costs 3 stars, 4th potato costs 7 stars (max 4)
function M.get_next_potato_unlock_cost()
	local cur_count = #(M.get_squad())
	if cur_count == 2 then
		return 3
	elseif cur_count == 3 then
		return 7
	end
	return nil -- Squad is full (4/4)
end

function M.unlock_next_potato()
	local cost = M.get_next_potato_unlock_cost()
	if not cost then
		return false, "Максимальный размер банды (4 картошки)"
	end
	if not M.spend_stars(cost) then
		return false, "Недостаточно звезд"
	end
	local new_id = #(M.data.squad) + 1
	table.insert(M.data.squad, { id = new_id, class_id = "recruit" })
	M.save()
	return true, new_id
end

function M.promote_potato(slot_index, new_class_id, star_cost)
	local sq = M.get_squad()
	local member = sq[slot_index]
	if not member then
		return false, "Боец не найден"
	end
	star_cost = star_cost or 0
	if star_cost > 0 then
		if not M.spend_stars(star_cost) then
			return false, "Недостаточно звезд"
		end
	end
	member.class_id = new_class_id
	M.save()
	return true, member
end

function M.is_skin_unlocked(skin_id)
	return M.data.unlocked_skins[skin_id] == true
end

function M.buy_skin(skin_id)
	local skin = M.SKINS_BY_ID[skin_id]
	if not skin then
		return false, "Скин не найден"
	end
	if M.is_skin_unlocked(skin_id) then
		return true, "Уже куплен"
	end
	if M.get_points() < skin.price then
		return false, "Недостаточно очков"
	end
	M.data.points = M.data.points - skin.price
	M.data.unlocked_skins[skin_id] = true
	M.data.equipped_skin = skin_id
	M.save()
	return true, "Куплено"
end

function M.equip_skin(skin_id)
	if M.is_skin_unlocked(skin_id) then
		M.data.equipped_skin = skin_id
		M.save()
		return true
	end
	return false
end

function M.get_equipped_skin()
	local id = M.data.equipped_skin or "classic"
	return M.SKINS_BY_ID[id] or M.SKINS[1]
end

function M.get_campaign_hp()
	return M.data.campaign_hp or 100
end

function M.set_campaign_hp(hp)
	local max_hp = M.data.campaign_max_hp or 100
	M.data.campaign_hp = math.max(1, math.min(max_hp, hp or max_hp))
	M.save()
end

function M.reset_campaign_hp()
	local max_hp = M.data.campaign_max_hp or 100
	M.data.campaign_hp = max_hp
	M.save()
end

function M.get_upgrade_level(upgrade_id)
	if not M.data.meta_upgrades then
		M.data.meta_upgrades = {}
	end
	return M.data.meta_upgrades[upgrade_id] or 0
end

function M.set_upgrade_level(upgrade_id, level)
	if not M.data.meta_upgrades then
		M.data.meta_upgrades = {}
	end
	M.data.meta_upgrades[upgrade_id] = level or 0
	M.save()
end

function M.get_next_skin_progress()
	local pts = M.get_points()
	for _, skin in ipairs(M.SKINS) do
		if skin.price > 0 and not M.is_skin_unlocked(skin.id) then
			local pct = math.min(1.0, math.max(0.0, pts / skin.price))
			local needed = math.max(0, skin.price - pts)
			return {
				skin = skin,
				current_points = pts,
				target_price = skin.price,
				needed = needed,
				percent = pct,
				can_buy = (pts >= skin.price)
			}
		end
	end
	return nil
end

function M.get_campaign_map()
	return M.data.campaign_map
end

function M.set_campaign_map(map_data)
	M.data.campaign_map = map_data
	M.save()
end

function M.get_campaign_turn()
	return M.data.campaign_turn or 1
end

function M.set_campaign_turn(turn)
	M.data.campaign_turn = turn or 1
	M.save()
end

function M.get_campaign_stats()
	return M.data.campaign_stats or {
		battles_won = 0,
		battles_lost = 0,
		sectors_conquered = 0,
		sectors_lost = 0,
		counterattacks_repelled = 0,
	}
end

function M.set_campaign_stats(stats)
	M.data.campaign_stats = stats
	M.save()
end

function M.reset_campaign_progress()
	M.data.campaign_map = nil
	M.data.campaign_turn = 1
	M.data.campaign_stats = {
		battles_won = 0,
		battles_lost = 0,
		sectors_conquered = 0,
		sectors_lost = 0,
		counterattacks_repelled = 0,
	}
	M.save()
end

-- Initialize by loading on startup
M.load()

return M
