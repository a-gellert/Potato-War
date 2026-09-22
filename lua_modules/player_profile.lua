-- lua_modules/player_profile.lua
-- Persistent storage for player points, unlocked skins, equipped skin, and campaign HP

local M = {}

M.SKINS = {
	{
		id = "classic",
		name = "Обычный Боец",
		desc = "Классический синий картофельный боец",
		price = 0,
		tint = { 1.0, 1.0, 1.0, 1.0 },
	},
	{
		id = "gold",
		name = "Золотой Самородок",
		desc = "Покрыт чистым золотом высшей пробы",
		price = 150,
		tint = { 1.0, 0.85, 0.2, 1.0 },
	},
	{
		id = "ninja",
		name = "Картошка-Ниндзя",
		desc = "Темный скрытный мастер боевых искусств",
		price = 250,
		tint = { 0.35, 0.35, 0.45, 1.0 },
	},
	{
		id = "cyber",
		name = "Киборг MK-II",
		desc = "Неоновый кибернетический корпус",
		price = 400,
		tint = { 0.2, 0.9, 1.0, 1.0 },
	},
	{
		id = "king",
		name = "Король Пюре",
		desc = "Королевское величие и пурпурная мантия",
		price = 600,
		tint = { 0.85, 0.25, 0.85, 1.0 },
	},
	{
		id = "magma",
		name = "Магмовый Титан",
		desc = "Раскаленная лава и несокрушимая броня",
		price = 900,
		tint = { 1.0, 0.4, 0.1, 1.0 },
	},
	{
		id = "emerald",
		name = "Изумрудный Страж",
		desc = "Древний кристальный защитник урожая",
		price = 1200,
		tint = { 0.2, 1.0, 0.4, 1.0 },
	},
}

M.SKINS_BY_ID = {}
for _, s in ipairs(M.SKINS) do
	M.SKINS_BY_ID[s.id] = s
end

-- Profile state
M.data = {
	points = 0,
	unlocked_skins = { ["classic"] = true },
	equipped_skin = "classic",
	campaign_hp = 100,
	campaign_max_hp = 100,
}

local function get_save_path()
	return sys.get_save_file("potato_war", "profile_save")
end

function M.load()
	local path = get_save_path()
	local loaded = sys.load(path)
	if loaded and type(loaded) == "table" and loaded.unlocked_skins then
		M.data.points = loaded.points or 0
		M.data.unlocked_skins = loaded.unlocked_skins or { ["classic"] = true }
		M.data.equipped_skin = loaded.equipped_skin or "classic"
		M.data.campaign_hp = loaded.campaign_hp or 100
		M.data.campaign_max_hp = loaded.campaign_max_hp or 100
	else
		M.data.points = 0
		M.data.unlocked_skins = { ["classic"] = true }
		M.data.equipped_skin = "classic"
		M.data.campaign_hp = 100
		M.data.campaign_max_hp = 100
	end
	return M.data
end

function M.save()
	local path = get_save_path()
	sys.save(path, M.data)
end

function M.get_points()
	return M.data.points or 0
end

function M.add_points(amount)
	M.data.points = (M.data.points or 0) + (amount or 0)
	M.save()
	return M.data.points
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
	M.data.campaign_hp = math.max(1, math.min(100, hp or 100))
	M.save()
end

function M.reset_campaign_hp()
	M.data.campaign_hp = 100
	M.save()
end

-- Initialize by loading on startup
M.load()

return M
