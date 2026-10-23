-- gui/campaign_map/camp_data.lua
-- Display-name helpers for the campaign map.

local i18n = require("lua_modules.i18n")

local M = {}

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
