-- gui/campaign_map/camp_view.lua
-- War map drawing: top bar, the island board, roads between sectors and the sector badges
-- (owner colour, defence pips, enemy avatar, attack / alarm pulses).

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local territory_map = require("lua_modules.territory_map")
local strategic_campaign = require("lua_modules.strategic_campaign")
local level_config = require("lua_modules.level_config")
local classes = require("lua_modules.classes")
local player_profile = require("lua_modules.player_profile")

local M = {}

local BLUE = vmath.vector4(0.45, 0.72, 1.0, 1)
local RED = vmath.vector4(1.0, 0.48, 0.42, 1)
local ROAD_OURS = vmath.vector4(0.25, 0.55, 0.95, 0.65)
local ROAD_ENEMY = vmath.vector4(0.55, 0.2, 0.22, 0.55)
local ROAD_FRONT = vmath.vector4(1.0, 0.76, 0.2, 0.95)
local REGION_COLORS = {
	vmath.vector4(0.55, 0.9, 0.5, 0.7),
	vmath.vector4(1.0, 0.78, 0.45, 0.7),
	vmath.vector4(0.6, 0.85, 1.0, 0.7),
	vmath.vector4(1.0, 0.5, 0.4, 0.7),
}

local function build_top_bar(self, root, handlers)
	kit.box(root, "dim", 480, 514, 980, 54, vmath.vector4(1, 1, 1, 0.65))
	kit.box(root, "white", 480, 486, 980, 2, vmath.vector4(0.95, 0.72, 0.2, 0.55))
	local v = self.view
	v.title = kit.text(root, "", 18, 514, 24, { font = "title", align = "left", color = kit.C.gold, max_w = 230 })
	v.sector_count = kit.counter(root, "ic_flag", 330, 514, 120, "0/18")
	v.turn = kit.text(root, "", 420, 514, 16, { font = "label", align = "left", color = kit.C.muted, max_w = 110 })
	v.coins = kit.counter(root, "ic_coin", 612, 514, 130, "0")
	kit.icon_button(self.ui, root, "map_squad", 740, 514, 46, "ic_squad", handlers.squad)
	kit.icon_button(self.ui, root, "map_arsenal", 794, 514, 46, "ic_arsenal", handlers.arsenal)
	kit.icon_button(self.ui, root, "map_menu", 930, 514, 46, "ic_home", handlers.menu)
	v.squad_badge = kit.badge(root, 758, 532)
	v.arsenal_badge = kit.badge(root, 812, 532)
end

-- One road per sector connection
local function build_roads(self, board)
	self.view.roads = {}
	for _, e in ipairs(territory_map.get_connections()) do
		local a, b = e.sector_a, e.sector_b
		if a and b then
			local dx, dy = b.x - a.x, b.y - a.y
			local len = math.sqrt(dx * dx + dy * dy)
			local road = kit.box(board, "white", (a.x + b.x) * 0.5, (a.y + b.y) * 0.5, len, 3)
			gui.set_rotation(road, vmath.quat_rotation_z(math.atan2(dy, dx)))
			table.insert(self.view.roads, { node = road, from = a.id, to = b.id, len = len })
		end
	end
end

-- Region names sit in the board corners, clear of the sector badges
local REGION_LABELS = { { 112, 30 }, { 360, 30 }, { 300, 470 }, { 570, 470 } }

local function build_region_labels(self, board)
	self.view.regions = {}
	for id, pos in ipairs(REGION_LABELS) do
		self.view.regions[id] = kit.text(board, "", pos[1], pos[2], 15, { font = "title", color = REGION_COLORS[id] or kit.C.muted, max_w = 220 })
	end
end

local function build_sector(self, board, s)
	local n = { id = s.id }
	n.root = kit.group(board, s.x, s.y)
	n.glow = kit.box(n.root, "glow", 0, 0, 96, 96, vmath.vector4(1, 0.8, 0.2, 0))
	n.btn = kit.button(self.ui, n.root, "sec_" .. s.id, 0, 0, 52, 52, { style = "round", slop = 10, on_click = function()
		self.on_select(s.id)
	end })
	n.flag = kit.icon(n.btn.node, "ic_flag", 0, 2, 30)
	n.enemy = kit.icon(n.btn.node, "recruit", 0, 2, 36, { texture = "game" })
	n.number = kit.text(n.root, "", -24, 22, 13, { font = "label" })
	n.pips = {}
	for k = 1, 3 do
		n.pips[k] = kit.icon(n.root, "ic_star", (k - 2) * 13, -30, 14)
	end
	n.alarm = kit.icon(n.root, "ic_damage", 22, 22, 26)
	n.name = kit.text(n.root, "", 0, -44, 12, { font = "label", color = kit.C.white, max_w = 110 })
	return n
end

function M.build(self, handlers)
	self.view = {}
	local root = kit.group(nil, 0, 0, 960, 540)
	self.view.root = root
	kit.box(root, "dim", 480, 270, 980, 560, vmath.vector4(0.55, 0.75, 1.0, 1))
	kit.box(root, "vignette", 480, 270, 980, 560)
	local board = kit.inset(root, 345, 240, 676, 476)
	gui.set_color(board, vmath.vector4(0.7, 0.85, 1.0, 0.9))
	self.view.board = kit.group(root, 0, 0)
	build_roads(self, self.view.board)
	build_region_labels(self, self.view.board)
	self.view.sectors = {}
	for id, s in pairs(territory_map.get_sectors()) do
		self.view.sectors[id] = build_sector(self, self.view.board, s)
	end
	build_top_bar(self, root, handlers)
end

-- Sector the enemy fields (first enemy class) for the avatar on the badge
local function enemy_class(s)
	local cfg = level_config.get(s.id)
	return (cfg.enemy_classes and cfg.enemy_classes[1]) or "recruit"
end

function M.refresh(self)
	local v = self.view
	local secs = territory_map.get_sectors()
	local stats = territory_map.get_stats()
	kit.set_text(v.title, i18n.t("ui_campaign"), 230, 24, "title")
	kit.set_text(v.sector_count.text, stats.blue_count .. "/" .. stats.total_count, 76, 19, "label")
	kit.set_text(v.turn, string.format(i18n.t("ui_turn_fmt"), strategic_campaign.get_turn()), 110, 16, "label")
	kit.set_text(v.coins.text, kit.num(player_profile.get_points()), 86, 19, "label")
	for id, label in pairs(v.regions) do
		local r = territory_map.REGIONS[id]
		kit.set_text(label, r and i18n.field(r, "name") or "", 220, 15, "title")
	end

	for _, road in ipairs(v.roads) do
		local a, b = secs[road.from], secs[road.to]
		local front = a.owner ~= b.owner
		local color = front and ROAD_FRONT or ((a.owner == "blue") and ROAD_OURS or ROAD_ENEMY)
		gui.set_color(road.node, color)
		gui.set_size(road.node, vmath.vector3(road.len, front and 5 or 3, 0))
	end

	for id, n in pairs(v.sectors) do
		local s = secs[id]
		local ours = s.owner == "blue"
		local target = territory_map.can_attack(id)
		local selected = (self.selected_sector_id == id)
		gui.set_color(n.btn.node, ours and BLUE or RED)
		gui.set_enabled(n.flag, ours)
		gui.set_enabled(n.enemy, not ours)
		if not ours then
			kit.set_icon(n.enemy, classes.sprite_of(enemy_class(s)), 34, 36, "game")
		end
		gui.set_text(n.number, string.format("%02d", id))
		for k, pip in ipairs(n.pips) do
			gui.set_color(pip, (k <= (s.defense_level or 1)) and vmath.vector4(1, 1, 1, 1) or vmath.vector4(0.2, 0.25, 0.32, 0.9))
		end
		gui.set_enabled(n.alarm, s.under_attack == true)
		kit.set_text(n.name, i18n.field(s, "name"), 110, 12, "label")
		gui.set_color(n.name, selected and kit.C.gold or kit.C.white)

		-- Pulse: gold = can be attacked, red = under attack, white = selected
		gui.cancel_animations(n.glow, "color.w")
		local glow
		if s.under_attack then
			glow = vmath.vector4(1, 0.25, 0.2, 0.9)
		elseif selected then
			glow = vmath.vector4(1, 1, 1, 0.75)
		elseif target then
			glow = vmath.vector4(1, 0.78, 0.2, 0.8)
		end
		if glow then
			gui.set_color(n.glow, glow)
			gui.animate(n.glow, "color.w", glow.w * 0.25, gui.EASING_INOUTSINE, 0.7, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		else
			gui.set_color(n.glow, vmath.vector4(1, 1, 1, 0))
		end
		gui.set_scale(n.root, selected and vmath.vector3(1.15, 1.15, 1) or vmath.vector3(1, 1, 1))
	end
end

function M.set_badges(self, squad, arsenal)
	gui.set_enabled(self.view.squad_badge, squad)
	gui.set_enabled(self.view.arsenal_badge, arsenal)
end

return M
