-- gui/campaign_map/camp_buttons.lua
-- Button wiring for the map screen: sectors, top bar, inspector, barracks.

local territory_map = require("lua_modules.territory_map")
local strategic_campaign = require("lua_modules.strategic_campaign")
local sound_manager = require("lua_modules.sound_manager")
local camp_view = require("gui.campaign_map.camp_view")
local camp_barracks = require("gui.campaign_map.camp_barracks")

local M = {}

local function on_attack(self)
	local sid = self.selected_sector_id
	local s = sid and territory_map.get_sector(sid)
	if not s then return end

	local can_atk = territory_map.can_attack(sid)
	local is_under_atk = s.under_attack and (s.owner == "blue")

	if can_atk or is_under_atk then
		sound_manager.play_click()
		local battle_cfg = strategic_campaign.prepare_battle(sid)
		if battle_cfg then
			msg.post(".", "disable")
			msg.post("/main#main", "start_battle", battle_cfg)
		end
	end
end

local function on_fortify(self)
	local sid = self.selected_sector_id
	if not sid then return end

	if strategic_campaign.fortify(sid) then
		sound_manager.play_heal()
		camp_view.bounce_sector(sid, 1.2, 0.3)
		camp_view.update_visuals(self)
	else
		-- Squash-and-bounce the fortify button on failure
		pcall(function()
			local btn = gui.get_node("btn_insp_fortify")
			gui.cancel_animations(btn, "scale")
			gui.set_scale(btn, vmath.vector3(1.10, 0.85, 1.0))
			gui.animate(btn, "scale", vmath.vector3(1.0, 1.0, 1.0), gui.EASING_OUTBOUNCE, 0.25)
		end)
	end
end

function M.register(self)
	for i = 1, 18 do
		local sid = i
		self.ui:button("sec_btn_" .. sid, function()
			camp_view.select_sector(self, sid)
		end, { slop = 10 })
	end

	self.ui:button("btn_top_menu", function()
		sound_manager.play_click()
		msg.post(".", "disable")
		msg.post("/main#main", "show_menu")
	end)

	self.ui:button("btn_insp_attack", function() on_attack(self) end)
	self.ui:button("btn_insp_fortify", function() on_fortify(self) end)

	self.ui:button("btn_insp_close", function()
		sound_manager.play_click()
		self.selected_sector_id = nil
		pcall(function()
			gui.set_enabled(gui.get_node("panel_inspector"), false)
		end)
		camp_view.update_visuals(self)
	end)

	camp_barracks.register(self)
end

return M
