-- gui/game_over/go_actions.lua
-- Results, bottom buttons: menu, retry and the main action of this outcome
-- (back to the war map, next quick battle, or on to the menu after the onboarding).

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local constants = require("lua_modules.constants")
local game_state = require("lua_modules.game_state")
local strategic_campaign = require("lua_modules.strategic_campaign")
local territory_map = require("lua_modules.territory_map")

local M = {}

local function leave(path, message_id, message)
	msg.post(".", "disable")
	msg.post(path, message_id, message or {})
end

-- Same battle once more: the sector for war map battles, the lobby setup for quick battles
local function retry(self)
	local outcome = self.result and self.result.campaign_outcome
	if outcome and outcome.sector_id then
		local cfg = strategic_campaign.prepare_battle(outcome.sector_id)
		if cfg then
			leave("/main#main", "start_battle", cfg)
		end
	elseif game_state.match_config then
		leave("/main#main", "start_battle", game_state.match_config)
	end
end

function M.build(self, root)
	self.actions = {}
	local a = self.actions
	a.menu = kit.button(self.ui, root, "go_menu", -326, -222, 160, 56, { style = "steel", icon = "ic_home", icon_size = 28, label = "", px = 18, on_click = function()
		leave("/main#main", "show_menu")
	end })
	a.retry = kit.button(self.ui, root, "go_retry", -122, -222, 220, 56, { style = "steel", icon = "ic_retry", icon_size = 28, label = "", px = 18, on_click = function()
		retry(self)
	end })
	a.main = kit.button(self.ui, root, "go_main", 238, -222, 320, 64, { style = "gold", label = "", px = 23, on_click = function()
		if self.on_main then
			self.on_main()
		end
	end })
end

function M.show(self, data)
	local a = self.actions
	local outcome = data.campaign_outcome
	local won = data.winner == constants.TEAM_BLUE
	a.menu.set_label(i18n.t("ui_menu"))
	a.retry.set_label(i18n.t("ui_retry"))

	-- Retry only makes sense when there is something left to win
	local can_retry
	if outcome and outcome.sector_id then
		local s = territory_map.get_sector(outcome.sector_id)
		can_retry = not won and s ~= nil and s.owner == "red"
	else
		can_retry = game_state.match_config ~= nil and not data.seamless
	end
	gui.set_enabled(a.retry.node, can_retry)

	if data.seamless then
		a.main.set_label(i18n.t("ui_continue"))
		self.on_main = function() leave("/main#main", "show_menu") end
	elseif outcome then
		a.main.set_label(i18n.t("ui_to_map"))
		self.on_main = function() leave("/main#main", "show_campaign_map") end
	elseif game_state.match_config then
		a.main.set_label(i18n.t("ui_next_battle"))
		self.on_main = function() leave("/main#main", "start_battle", game_state.match_config) end
	else
		a.main.set_label(i18n.t("ui_continue"))
		self.on_main = function() leave("/main#main", "show_menu") end
	end
end

return M
