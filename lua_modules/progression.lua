-- lua_modules/progression.lua
-- Long-term progression: weapon levels (coins + blueprints), squad ranks (XP per potato),
-- commander level (total XP) and supply crates with random loot after battles.
-- Every number of the economy lives here; state is stored in player_profile.data.

local player_profile = require("lua_modules.player_profile")
local weapons = require("lua_modules.weapons")
local classes = require("lua_modules.classes")

local M = {}

-- ---------- rarity ----------

-- weight: blueprint drop weight; cost: coin cost multiplier for upgrades; bp: blueprint stack size
M.RARITY = {
	common = { weight = 50, cost = 1.0, bp = { 4, 7 }, color = vmath.vector4(0.62, 0.68, 0.74, 1) },
	rare = { weight = 30, cost = 1.3, bp = { 3, 5 }, color = vmath.vector4(0.25, 0.62, 1.0, 1) },
	epic = { weight = 15, cost = 1.7, bp = { 2, 3 }, color = vmath.vector4(0.72, 0.38, 1.0, 1) },
	legendary = { weight = 5, cost = 2.2, bp = { 1, 2 }, color = vmath.vector4(1.0, 0.72, 0.16, 1) },
}
M.RARITY_ORDER = { "common", "rare", "epic", "legendary" }

-- ---------- weapon levels ----------

M.MAX_WEAPON_LEVEL = 5
-- Cost of reaching level n (index = target level)
local UPGRADE_BLUEPRINTS = { [2] = 4, [3] = 8, [4] = 14, [5] = 24 }
local UPGRADE_COINS = { [2] = 80, [3] = 200, [4] = 450, [5] = 900 }
local DAMAGE_PER_LEVEL = 0.08
local RADIUS_PER_LEVEL = 0.04
local EXTRA_AMMO_LEVELS = { 3, 5 } -- limited weapons carry one more shot at these levels
local BLUEPRINT_COINS = 5 -- blueprints of a maxed weapon turn into coins

local function data()
	local d = player_profile.data
	d.weapon_levels = d.weapon_levels or {}
	d.blueprints = d.blueprints or {}
	d.commander_xp = d.commander_xp or 0
	d.stats = d.stats or { battles = 0, wins = 0, kills = 0, crates = 0 }
	return d
end

function M.weapon_level(id)
	return data().weapon_levels[id] or 1
end

function M.blueprints(id)
	return data().blueprints[id] or 0
end

-- { blueprints = n, coins = c } for the next level, nil at max level
function M.upgrade_cost(id)
	local next_level = M.weapon_level(id) + 1
	if next_level > M.MAX_WEAPON_LEVEL then
		return nil
	end
	local r = M.RARITY[weapons.get(id).rarity or "common"] or M.RARITY.common
	return {
		blueprints = UPGRADE_BLUEPRINTS[next_level],
		coins = math.floor(UPGRADE_COINS[next_level] * r.cost / 10 + 0.5) * 10,
	}
end

-- true, or false + "max" | "blueprints" | "coins"
function M.can_upgrade(id)
	local cost = M.upgrade_cost(id)
	if not cost then
		return false, "max"
	end
	if M.blueprints(id) < cost.blueprints then
		return false, "blueprints"
	end
	if player_profile.get_points() < cost.coins then
		return false, "coins"
	end
	return true
end

function M.upgrade_weapon(id)
	local ok, why = M.can_upgrade(id)
	if not ok then
		return false, why
	end
	local cost = M.upgrade_cost(id)
	local d = data()
	d.blueprints[id] = M.blueprints(id) - cost.blueprints
	d.weapon_levels[id] = M.weapon_level(id) + 1
	player_profile.add_points(-cost.coins) -- saves
	return true, d.weapon_levels[id]
end

-- Stat multipliers of a weapon at a level
function M.level_bonus(level)
	level = math.max(1, level or 1)
	local extra_ammo = 0
	for _, l in ipairs(EXTRA_AMMO_LEVELS) do
		if level >= l then
			extra_ammo = extra_ammo + 1
		end
	end
	return {
		damage = 1 + DAMAGE_PER_LEVEL * (level - 1),
		radius = 1 + RADIUS_PER_LEVEL * (level - 1),
		extra_ammo = extra_ammo,
	}
end

-- Level a weapon fires at in the current battle: the player's own levels for the blue team,
-- the battle's enemy_weapon_level for bots, level 1 in local two-player games
function M.battle_weapon_level(weapon_id, team, battle)
	if not battle or battle.pvp then
		return 1
	end
	if team == battle.player_team then
		return M.weapon_level(weapon_id)
	end
	return battle.enemy_weapon_level or 1
end

-- ---------- squad ranks ----------

M.MAX_RANK = 10
local RANK_XP = { 0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200 }
local HP_PER_RANK = 0.06

M.RANK_NAMES = {
	{ ru = "Рядовой", en = "Private", pt = "Soldado", fr = "Soldat", es = "Soldado", tr = "Er" },
	{ ru = "Ефрейтор", en = "Lance Corporal", pt = "Cabo", fr = "Caporal", es = "Cabo", tr = "Onbaşı" },
	{ ru = "Капрал", en = "Corporal", pt = "Cabo-chefe", fr = "Caporal-chef", es = "Cabo Primero", tr = "Kıdemli Onbaşı" },
	{ ru = "Сержант", en = "Sergeant", pt = "Sargento", fr = "Sergent", es = "Sargento", tr = "Çavuş" },
	{ ru = "Старший сержант", en = "Staff Sergeant", pt = "Primeiro-sargento", fr = "Sergent-chef", es = "Sargento Primero", tr = "Üstçavuş" },
	{ ru = "Старшина", en = "Master Sergeant", pt = "Subtenente", fr = "Adjudant", es = "Brigada", tr = "Başçavuş" },
	{ ru = "Лейтенант", en = "Lieutenant", pt = "Tenente", fr = "Lieutenant", es = "Teniente", tr = "Teğmen" },
	{ ru = "Капитан", en = "Captain", pt = "Capitão", fr = "Capitaine", es = "Capitán", tr = "Yüzbaşı" },
	{ ru = "Майор", en = "Major", pt = "Major", fr = "Commandant", es = "Comandante", tr = "Binbaşı" },
	{ ru = "Полковник", en = "Colonel", pt = "Coronel", fr = "Colonel", es = "Coronel", tr = "Albay" },
}

-- rank, xp into this rank, xp needed for the next one (nil at max)
function M.rank_of(xp)
	xp = xp or 0
	local rank = 1
	for r = M.MAX_RANK, 1, -1 do
		if xp >= RANK_XP[r] then
			rank = r
			break
		end
	end
	if rank >= M.MAX_RANK then
		return rank, xp - RANK_XP[rank], nil
	end
	return rank, xp - RANK_XP[rank], RANK_XP[rank + 1] - RANK_XP[rank]
end

function M.rank_hp_mult(rank)
	return 1 + HP_PER_RANK * ((rank or 1) - 1)
end

function M.member_rank(member)
	return (M.rank_of(member and member.xp or 0))
end

-- Class promotions also need experience: tier 1 classes from rank 2, tier 2 from rank 4
local PROMOTION_RANK = { [1] = 2, [2] = 4 }
function M.promotion_rank(tier)
	return PROMOTION_RANK[tier] or 1
end

-- ---------- notification badges ----------

-- Some weapon can be upgraded right now
function M.any_weapon_upgrade()
	for _, w in ipairs(weapons.PLAYER_LIST) do
		if M.can_upgrade(w.id) then
			return true
		end
	end
	return false
end

-- A fighter can be hired or promoted right now
function M.squad_can_improve()
	local stars = player_profile.get_stars()
	local cost = player_profile.get_next_potato_unlock_cost()
	if cost and stars >= cost then
		return true
	end
	for _, member in ipairs(player_profile.get_squad()) do
		local rank = M.member_rank(member)
		for _, c in ipairs(classes.get_promotions(member.class_id)) do
			if stars >= (c.star_cost or 0) and rank >= M.promotion_rank(c.tier) then
				return true
			end
		end
	end
	return false
end

-- ---------- commander level ----------

-- XP from level L to L+1
local function level_step(level)
	return 120 + 60 * (level - 1)
end

-- level, xp into the level, xp needed for the next level
function M.commander_level(xp)
	xp = xp or data().commander_xp
	local level = 1
	while xp >= level_step(level) do
		xp = xp - level_step(level)
		level = level + 1
	end
	return level, xp, level_step(level)
end

-- ---------- crates ----------

M.CRATES = {
	wood = { coins = { 40, 70 }, stacks = 2, hat_chance = 0.03, boost = 0 },
	steel = { coins = { 90, 150 }, stacks = 3, hat_chance = 0.08, boost = 1 },
	gold = { coins = { 200, 320 }, stacks = 4, hat_chance = 0.20, boost = 2 },
}

local function roll_weapon(boost)
	local total = 0
	local pool = {}
	for _, w in ipairs(weapons.PLAYER_LIST) do
		local r = M.RARITY[w.rarity or "common"]
		local weight = r.weight
		if w.rarity == "epic" or w.rarity == "legendary" then
			weight = weight + boost * 5
		end
		total = total + weight
		table.insert(pool, { w = w, weight = weight })
	end
	local pick = math.random() * total
	for _, e in ipairs(pool) do
		pick = pick - e.weight
		if pick <= 0 then
			return e.w
		end
	end
	return pool[#pool].w
end

local function random_missing_hat()
	local missing = {}
	for _, h in ipairs(player_profile.SKINS) do
		if h.price > 0 and not player_profile.is_skin_unlocked(h.id) then
			table.insert(missing, h)
		end
	end
	if #missing == 0 then
		return nil
	end
	return missing[math.random(1, #missing)]
end

-- Loot of one crate: list of { type = "coins"|"blueprints"|"hat", amount, weapon_id, hat_id }
function M.roll_crate(tier)
	local c = M.CRATES[tier] or M.CRATES.wood
	local loot = { { type = "coins", amount = math.random(c.coins[1], c.coins[2]) } }
	local by_weapon = {}
	for _ = 1, c.stacks do
		local w = roll_weapon(c.boost)
		local bp = M.RARITY[w.rarity or "common"].bp
		local amount = math.floor(math.random(bp[1], bp[2]) * (1 + 0.5 * c.boost) + 0.5)
		if by_weapon[w.id] then
			by_weapon[w.id].amount = by_weapon[w.id].amount + amount
		else
			by_weapon[w.id] = { type = "blueprints", weapon_id = w.id, amount = amount }
			table.insert(loot, by_weapon[w.id])
		end
	end
	if math.random() < c.hat_chance then
		local h = random_missing_hat()
		if h then
			table.insert(loot, { type = "hat", hat_id = h.id })
		end
	end
	return loot
end

-- Adds the loot to the profile. Blueprints of maxed weapons and hats already owned become coins.
function M.apply_loot(loot)
	local d = data()
	local coins = 0
	for _, item in ipairs(loot) do
		if item.type == "coins" then
			coins = coins + item.amount
		elseif item.type == "blueprints" then
			if M.weapon_level(item.weapon_id) >= M.MAX_WEAPON_LEVEL then
				coins = coins + item.amount * BLUEPRINT_COINS
			else
				d.blueprints[item.weapon_id] = M.blueprints(item.weapon_id) + item.amount
			end
		elseif item.type == "hat" then
			if player_profile.is_skin_unlocked(item.hat_id) then
				local h = player_profile.SKINS_BY_ID[item.hat_id]
				coins = coins + math.floor((h and h.price or 200) / 4)
			else
				player_profile.unlock_hat(item.hat_id)
			end
		end
	end
	d.stats.crates = (d.stats.crates or 0) + 1
	player_profile.add_points(coins) -- saves
end

-- Loot of a second identical crate for the rewarded ad: hats are not repeated
function M.double_loot(loot)
	local copy = {}
	for _, item in ipairs(loot) do
		if item.type ~= "hat" then
			table.insert(copy, { type = item.type, amount = item.amount, weapon_id = item.weapon_id })
		end
	end
	return copy
end

-- ---------- battle results ----------

local XP_PARTICIPATION = 15
local XP_PER_DAMAGE = 0.5
local XP_DAMAGE_CAP = 60
local XP_PER_KILL = 25
local XP_WIN = 20
local XP_FLAWLESS = 10
local DEFEAT_XP_SHARE = 0.4
local TRAINING_XP_SHARE = 0.5 -- quick battles train the whole squad at half rate
local COINS_DEFEAT = 15
local COINS_QUICK_WIN = 40
local COINS_SECTOR_WIN = 60
local COINS_PER_SECTOR_LEVEL = 10

local function potato_xp(p, won, flawless)
	local stats = p.stats or {}
	local xp = XP_PARTICIPATION
		+ math.min(XP_DAMAGE_CAP, (stats.damage or 0) * XP_PER_DAMAGE)
		+ (stats.kills or 0) * XP_PER_KILL
	if won then
		xp = xp + XP_WIN + (flawless and XP_FLAWLESS or 0)
	end
	return math.floor(xp)
end

-- Adds xp to squad member `slot`; returns { slot, class_id, xp, gained, rank_before, rank_after }
local function grant_member_xp(squad, slot, gained)
	local m = squad[slot]
	if not m then
		return nil
	end
	local before = M.rank_of(m.xp or 0)
	m.xp = (m.xp or 0) + gained
	local after = M.rank_of(m.xp)
	return { slot = slot, class_id = m.class_id, xp = m.xp, gained = gained, rank_before = before, rank_after = after }
end

-- Works out and stores everything a finished battle gives.
-- battle: { player_team, potatoes, won, flawless, uses_squad, sector_level, is_tutorial, pvp }
-- Returns the report shown on the results screen.
function M.finish_battle(battle)
	local d = data()
	local report = { won = battle.won, members = {}, coins = 0, uses_squad = battle.uses_squad }
	if battle.is_tutorial or battle.pvp then
		return report
	end

	-- 1. Experience for the squad
	local squad = player_profile.get_squad()
	local total_xp = 0
	local share = battle.won and 1 or DEFEAT_XP_SHARE
	if battle.uses_squad then
		for _, p in ipairs(battle.potatoes) do
			if p.team == battle.player_team and p.squad_slot then
				local gained = math.floor(potato_xp(p, battle.won, battle.flawless) * share)
				local r = grant_member_xp(squad, p.squad_slot, gained)
				if r then
					table.insert(report.members, r)
					total_xp = total_xp + gained
				end
			end
		end
	else
		local team_xp = 0
		local count = 0
		for _, p in ipairs(battle.potatoes) do
			if p.team == battle.player_team then
				team_xp = team_xp + potato_xp(p, battle.won, battle.flawless)
				count = count + 1
			end
		end
		local each = math.floor(team_xp / math.max(1, count) * share * TRAINING_XP_SHARE)
		for slot = 1, #squad do
			local r = grant_member_xp(squad, slot, each)
			if r then
				table.insert(report.members, r)
				total_xp = total_xp + each
			end
		end
	end

	-- 2. Commander level
	local level_before = M.commander_level(d.commander_xp)
	d.commander_xp = d.commander_xp + total_xp
	local level_after, into, need = M.commander_level(d.commander_xp)
	report.commander = { gained = total_xp, level_before = level_before, level = level_after, into = into, need = need }

	-- 3. Coins and the supply crate
	if battle.won then
		if battle.sector_level then
			report.coins = COINS_SECTOR_WIN + COINS_PER_SECTOR_LEVEL * battle.sector_level
			report.crate_tier = battle.flawless and "gold" or "steel"
		else
			report.coins = COINS_QUICK_WIN
			report.crate_tier = "wood"
		end
		-- A commander level-up adds its own reward crate
		if level_after > level_before then
			report.levelup_crate = (level_after % 5 == 0) and "gold" or "steel"
		end
	else
		report.coins = COINS_DEFEAT
	end

	-- 4. Lifetime stats
	d.stats.battles = (d.stats.battles or 0) + 1
	if battle.won then
		d.stats.wins = (d.stats.wins or 0) + 1
	end
	for _, p in ipairs(battle.potatoes) do
		if p.team == battle.player_team and p.stats then
			d.stats.kills = (d.stats.kills or 0) + (p.stats.kills or 0)
		end
	end

	player_profile.add_points(report.coins) -- saves the whole profile

	-- 5. Crate loot is rolled and stored right away; the results screen only shows it opening
	if report.crate_tier then
		report.loot = M.roll_crate(report.crate_tier)
		if report.levelup_crate then
			for _, item in ipairs(M.roll_crate(report.levelup_crate)) do
				table.insert(report.loot, item)
			end
		end
		M.apply_loot(report.loot)
	end
	return report
end

return M
