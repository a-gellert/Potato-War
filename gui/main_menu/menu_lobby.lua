-- gui/main_menu/menu_lobby.lua
-- Quick-battle lobby: fighters per team, opponent, team hats, location and terrain, start.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local player_profile = require("lua_modules.player_profile")
local menu_data = require("gui.main_menu.menu_data")

local BIOMES = menu_data.BIOMES
local RELIEFS = menu_data.RELIEFS

local M = {}

local ROW_Y = { 132, 82, 32, -18, -68, -118 }
local LABEL_X = -280
local VALUE_X = 110

-- Wraps a 1-based index forward/backward over a list of `total` items.
local function cycle(idx, total, step)
	return ((idx - 1 + step) % total) + 1
end

local function row_label(parent, y)
	return kit.text(parent, "", LABEL_X, y, 19, { font = "label", align = "left", max_w = 200, color = kit.C.muted })
end

-- [<] value [>] selector cycling self.lobby[field] over `total` options
local function selector(self, parent, id, y, field, total)
	local box = kit.inset(parent, VALUE_X, y, 250, 42)
	local value = kit.text(box, "", 0, 0, 17, { font = "label", max_w = 170 })
	kit.icon_button(self.ui, parent, id .. "_prev", VALUE_X - 150, y, 42, "ic_left", function()
		self.lobby[field] = cycle(self.lobby[field], total(), -1)
		M.refresh(self)
	end, "round")
	kit.icon_button(self.ui, parent, id .. "_next", VALUE_X + 150, y, 42, "ic_right", function()
		self.lobby[field] = cycle(self.lobby[field], total(), 1)
		M.refresh(self)
	end, "round")
	return value
end

function M.build(self, on_close, on_start)
	self.lobby = { count = 2, opponent = "bot", blue_hat = 1, red_hat = 1, biome = 1, relief = 1 }
	local win = kit.window(self.ui, nil, "lobby", 660, 470, "", on_close)
	self.lobby_ui = win
	local p = win.panel
	win.labels = {}
	for i = 1, 6 do
		win.labels[i] = row_label(p, ROW_Y[i])
	end

	win.count_btns = {}
	for i = 1, 4 do
		win.count_btns[i] = kit.button(self.ui, p, "lobby_cnt_" .. i, VALUE_X - 108 + (i - 1) * 72, ROW_Y[1], 62, 44, { style = "dark", label = tostring(i), px = 22, on_click = function()
			self.lobby.count = i
			M.refresh(self)
		end })
	end
	win.opp_bot = kit.button(self.ui, p, "lobby_bot", VALUE_X - 64, ROW_Y[2], 122, 44, { style = "dark", label = "", px = 18, on_click = function()
		self.lobby.opponent = "bot"
		M.refresh(self)
	end })
	win.opp_human = kit.button(self.ui, p, "lobby_human", VALUE_X + 64, ROW_Y[2], 122, 44, { style = "dark", label = "", px = 18, on_click = function()
		self.lobby.opponent = "human"
		M.refresh(self)
	end })
	local hats = function() return #player_profile.SKINS end
	win.blue_hat = selector(self, p, "lobby_blue_hat", ROW_Y[3], "blue_hat", hats)
	win.red_hat = selector(self, p, "lobby_red_hat", ROW_Y[4], "red_hat", hats)
	win.biome = selector(self, p, "lobby_biome", ROW_Y[5], "biome", function() return #BIOMES end)
	win.relief = selector(self, p, "lobby_relief", ROW_Y[6], "relief", function() return #RELIEFS end)

	win.hint = kit.text(p, "", 0, -162, 14, { font = "label", color = kit.C.gold, width = 580 })
	win.start = kit.button(self.ui, p, "lobby_start", 0, -205, 260, 62, { style = "gold", icon = "ic_battle", icon_size = 36, label = "", px = 24, on_click = function()
		local l = self.lobby
		local blue = player_profile.SKINS[l.blue_hat] or player_profile.SKINS[1]
		local red = player_profile.SKINS[l.red_hat] or player_profile.SKINS[1]
		on_start({
			potato_count = l.count,
			opponent_type = l.opponent,
			skin_blue = blue.id,
			skin_red = red.id,
			biome = BIOMES[l.biome].id,
			terrain_type = RELIEFS[l.relief].id,
		})
	end })
	gui.set_enabled(win.root, false)
end

function M.refresh(self)
	local win, l = self.lobby_ui, self.lobby
	kit.set_text(win.title, i18n.t("ui_lobby_title"), 460, 26, "title")
	local keys = { "ui_lobby_count", "ui_lobby_opponent", "ui_lobby_blue_hat", "ui_lobby_red_hat", "ui_lobby_biome", "ui_lobby_relief" }
	for i, key in ipairs(keys) do
		kit.set_text(win.labels[i], i18n.t(key), 200, 19, "label")
	end
	for i, b in ipairs(win.count_btns) do
		b.set_style(l.count == i and "blue" or "dark")
	end
	win.opp_bot.set_style(l.opponent == "bot" and "blue" or "dark")
	win.opp_human.set_style(l.opponent == "human" and "blue" or "dark")
	win.opp_bot.set_label(i18n.t("ui_lobby_bot"))
	win.opp_human.set_label(i18n.t("ui_lobby_friend"))

	local skins = player_profile.SKINS
	kit.set_text(win.blue_hat, player_profile.get_skin_name(skins[l.blue_hat] or skins[1], i18n.current_lang), 170, 17, "label")
	kit.set_text(win.red_hat, player_profile.get_skin_name(skins[l.red_hat] or skins[1], i18n.current_lang), 170, 17, "label")
	kit.set_text(win.biome, i18n.pick(BIOMES[l.biome]), 170, 17, "label")
	kit.set_text(win.relief, i18n.pick(RELIEFS[l.relief]), 170, 17, "label")
	gui.set_text(win.hint, l.opponent == "bot" and i18n.t("ui_lobby_hint") or "")
	win.start.set_label(i18n.t("ui_lobby_start"))
end

function M.show(self, visible)
	gui.set_enabled(self.lobby_ui.root, visible)
	if visible then
		-- Start with the player's own hat on the blue team
		local equipped = player_profile.get_equipped_skin()
		for i, s in ipairs(player_profile.SKINS) do
			if s.id == equipped.id then
				self.lobby.blue_hat = i
			end
		end
		M.refresh(self)
		kit.pop_in(self.lobby_ui.panel)
	end
end

return M
