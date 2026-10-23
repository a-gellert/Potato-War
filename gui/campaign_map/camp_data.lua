-- gui/campaign_map/camp_data.lua
-- Static lookup tables and display-name helpers for the campaign map.

local i18n = require("lua_modules.i18n")

local M = {}

M.DEF_STARS = {
	[1] = "[1/3]",
	[2] = "[2/3]",
	[3] = "[3/3]",
}

M.CLASS_AVATARS = {
	recruit     = "recruit",
	assault     = "assault",
	assault_2   = "assault",
	sniper      = "sniper",
	sapper      = "sapper",
	sapper_2    = "sapper",
	commando    = "sapper",
	artillery   = "tank",
	artillery_2 = "tank",
	rocketeer   = "tank",
	medic       = "medic",
	surgeon     = "medic",
	engineer    = "sapper",
	tank        = "tank",
}

function M.get_defense_name(lvl)
	if lvl == 1 then
		return i18n.t("camp_def_1")
	elseif lvl == 2 then
		return i18n.t("camp_def_2")
	else
		return i18n.t("camp_def_3")
	end
end

function M.get_terrain_display_name(preset)
	local known = { hills = true, flat = true, canyon_bridge = true, swiss_cheese = true, floating_islands = true, cavern = true, bunkers = true, islands = true }
	return i18n.t("ter_" .. (known[preset] and preset or "hills"))
end

return M
