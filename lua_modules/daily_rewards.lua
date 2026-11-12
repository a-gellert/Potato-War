-- lua_modules/daily_rewards.lua
-- Daily supply drop: one claim per calendar day on a 7-day cycle. Claiming on consecutive days
-- moves along the cycle; missing a day starts it again at day 1. Rewards reuse the crate loot
-- format of progression.lua ({ type = "coins"|"blueprints"|"hat"|"stars", amount, ... }).
-- State lives in player_profile.data.daily = { last_day = <day number>, streak = <days in a row> }.

local player_profile = require("lua_modules.player_profile")
local progression = require("lua_modules.progression")

local M = {}

M.CYCLE = 7

-- What each day of the cycle gives; crates are rolled on claim
M.DAYS = {
	{ coins = 60 },
	{ crate = "wood" },
	{ coins = 120 },
	{ crate = "steel" },
	{ stars = 1 },
	{ coins = 200 },
	{ crate = "gold" },
}

-- Local calendar day number (noon avoids DST edge cases)
local function today()
	local t = os.date("*t")
	return math.floor(os.time({ year = t.year, month = t.month, day = t.day, hour = 12 }) / 86400)
end

local function state()
	local d = player_profile.data
	if type(d.daily) ~= "table" then
		d.daily = { last_day = 0, streak = 0 }
	end
	return d.daily
end

-- Day of the cycle (1..7) that the next claim gives
function M.next_cycle_day()
	local s = state()
	local streak = s.streak or 0
	if (s.last_day or 0) < today() - 1 then
		streak = 0 -- a day was missed: the cycle restarts
	end
	return (streak % M.CYCLE) + 1
end

function M.can_claim()
	return (state().last_day or 0) < today()
end

-- Claims today's reward: applies it and returns the loot list for the screen, or nil if already claimed
function M.claim()
	if not M.can_claim() then
		return nil
	end
	local s = state()
	local day = M.next_cycle_day()
	local def = M.DAYS[day]
	local loot
	if def.crate then
		loot = progression.roll_crate(def.crate)
	elseif def.stars then
		loot = { { type = "stars", amount = def.stars } }
	else
		loot = { { type = "coins", amount = def.coins } }
	end
	if (s.last_day or 0) == today() - 1 then
		s.streak = (s.streak or 0) + 1
	else
		s.streak = 1
	end
	s.last_day = today()
	M.apply(loot) -- saves
	return loot, day
end

-- Crate loot goes through progression (blueprints, hats, crate stats); plain coins and stars are
-- granted directly so a coin day does not count as an opened crate
function M.apply(loot)
	local crate_items = {}
	local is_crate = false
	for _, item in ipairs(loot) do
		if item.type == "blueprints" or item.type == "hat" then
			is_crate = true
		end
	end
	for _, item in ipairs(loot) do
		if item.type == "stars" then
			player_profile.add_stars(item.amount)
		elseif item.type == "coins" and not is_crate then
			player_profile.add_points(item.amount)
		else
			table.insert(crate_items, item)
		end
	end
	if #crate_items > 0 then
		progression.apply_loot(crate_items)
	end
	player_profile.save()
end

-- Second copy of the same reward for the rewarded ad (double_loot keeps coins, blueprints and
-- stars, and drops hats)
function M.double(loot)
	local extra = progression.double_loot(loot)
	M.apply(extra)
	return extra
end

return M
