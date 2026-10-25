-- gui/campaign_map/camp_inspector.lua
-- War map side panel: the selected sector's owner, enemies, difficulty, defence, income and the
-- attack / defend / fortify actions.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local territory_map = require("lua_modules.territory_map")
local strategic_campaign = require("lua_modules.strategic_campaign")
local level_config = require("lua_modules.level_config")
local classes = require("lua_modules.classes")
local player_profile = require("lua_modules.player_profile")
local camp_data = require("gui.campaign_map.camp_data")

local M = {}

local X, Y, W, H = 818, 240, 272, 476
local MAX_ENEMIES = 4
local DIFFICULTY_COLORS = { easy = kit.C.green, normal = kit.C.gold, hard = kit.C.red }

local function row(parent, y, icon, label_key)
	local r = {}
	kit.icon(parent, icon, -112, y, 26)
	r.label = kit.text(parent, "", -94, y, 14, { font = "label", align = "left", color = kit.C.muted, max_w = 110 })
	r.value = kit.text(parent, "", 118, y, 15, { font = "label", align = "right", max_w = 120 })
	r.key = label_key
	return r
end

function M.build(self, handlers)
	local p = kit.panel(nil, X, Y, W, H)
	self.insp = { panel = p }
	local ins = self.insp
	local header = kit.box(p, "header", 0, H / 2 - 22, W - 8, 44)
	ins.title = kit.text(header, "", 0, 2, 18, { font = "title", color = kit.C.gold, max_w = W - 30 })
	ins.region = kit.text(p, "", 0, 178, 13, { font = "label", color = kit.C.muted, max_w = W - 30 })
	ins.status_bg = kit.box(p, "pill", 0, 150, W - 40, 32)
	ins.status = kit.text(ins.status_bg, "", 0, 0, 16, { font = "label", max_w = W - 60 })

	ins.enemies_label = kit.text(p, "", -112, 118, 14, { font = "label", align = "left", color = kit.C.muted })
	ins.enemies = {}
	ins.enemy_emotions = {}
	for k = 1, MAX_ENEMIES do
		local ex = -84 + (k - 1) * 56
		ins.enemies[k] = kit.icon(p, "recruit", ex, 82, 46, { texture = "game" })
		ins.enemy_emotions[k] = kit.icon(p, "s_angry", ex, 85, 18, { texture = "game" })
	end
	ins.rows = {
		difficulty = row(p, 36, "ic_skull", "ui_difficulty_normal"),
		weapons = row(p, 8, "ic_arsenal", "ui_weapons"),
		defense = row(p, -20, "ic_star", "ui_defense"),
		income = row(p, -48, "ic_coin", "ui_income"),
	}
	ins.terrain = kit.text(p, "", 0, -78, 13, { font = "label", color = kit.C.muted, max_w = W - 30 })

	ins.fortify = kit.button(self.ui, p, "insp_fortify", 0, -122, W - 40, 50, { style = "steel", icon = "ic_coin", icon_size = 26, label = "", px = 17, on_click = handlers.fortify })
	ins.note = kit.text(p, "", 0, -122, 13, { font = "label", color = kit.C.muted, width = W - 40 })
	ins.action = kit.button(self.ui, p, "insp_action", 0, -186, W - 30, 64, { style = "gold", icon = "ic_battle", icon_size = 36, label = "", px = 24, on_click = handlers.action })
	gui.animate(ins.action.node, "scale", vmath.vector3(1.04, 1.04, 1), gui.EASING_INOUTSINE, 0.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	self.insp.root = p
end

function M.refresh(self)
	local ins = self.insp
	local s = territory_map.get_sector(self.selected_sector_id)
	if not s then
		gui.set_enabled(ins.root, false)
		return
	end
	gui.set_enabled(ins.root, true)
	local ours = s.owner == "blue"
	local can_attack = territory_map.can_attack(s.id)
	local cfg = level_config.get(s.id)

	kit.set_text(ins.title, string.format("%02d  ", s.id) .. i18n.field(s, "name"), W - 30, 18, "title")
	local region = territory_map.REGIONS[s.region]
	kit.set_text(ins.region, region and i18n.field(region, "name") or "", W - 30, 13, "label")

	local status, color
	if s.under_attack then
		status, color = i18n.t("ui_under_attack"), kit.C.red
	elseif ours then
		status, color = i18n.t("ui_ours"), kit.C.blue
	else
		status, color = i18n.t("ui_enemy_sector"), kit.C.red
	end
	kit.set_text(ins.status, status, W - 60, 16, "label")
	gui.set_color(ins.status, color)

	-- Enemies: the sector garrison, or the counter-attack force when defending
	local enemy_classes = (not ours and cfg.enemy_classes) or nil
	local show_enemies = (not ours) or s.under_attack
	gui.set_enabled(ins.enemies_label, show_enemies)
	kit.set_text(ins.enemies_label, i18n.t("ui_enemies"), 200, 14, "label")
	for k, node in ipairs(ins.enemies) do
		local cid = enemy_classes and enemy_classes[k]
		local visible = show_enemies and ((enemy_classes and cid ~= nil) or (not enemy_classes and k <= 2))
		gui.set_enabled(node, visible)
		if ins.enemy_emotions and ins.enemy_emotions[k] then
			gui.set_enabled(ins.enemy_emotions[k], visible)
		end
		if visible then
			kit.set_icon(node, classes.sprite_of(cid or "recruit"), 44, 46, "game")
		end
	end

	local skill = level_config.normalize_skill(cfg.enemy_skill)
	local r = ins.rows
	kit.set_text(r.difficulty.label, i18n.t("ui_difficulty"), 110, 14, "label")
	kit.set_text(r.difficulty.value, i18n.t("ui_difficulty_" .. skill), 120, 15, "label")
	gui.set_color(r.difficulty.value, DIFFICULTY_COLORS[skill] or kit.C.white)
	kit.set_text(r.weapons.label, i18n.t("ui_enemy_weapons"), 110, 14, "label")
	kit.set_text(r.weapons.value, string.format(i18n.t("ui_level_fmt"), 1 + math.floor((s.id - 1) / 6)), 120, 15, "label")
	kit.set_text(r.defense.label, i18n.t("ui_defense"), 110, 14, "label")
	kit.set_text(r.defense.value, camp_data.get_defense_name(s.defense_level or 1), 120, 15, "label")
	kit.set_text(r.income.label, i18n.t("ui_income"), 110, 14, "label")
	kit.set_text(r.income.value, string.format(i18n.t("ui_income_fmt"), s.income or 25), 120, 15, "label")
	gui.set_color(r.income.value, kit.C.gold)
	kit.set_text(ins.terrain, camp_data.get_terrain_display_name(s.terrain_preset), W - 30, 13, "label")

	-- Fortify own sectors with coins
	local fort_cost = territory_map.get_fortify_cost(s.id)
	local can_fortify = ours and territory_map.can_fortify(s.id)
	gui.set_enabled(ins.fortify.node, can_fortify)
	if can_fortify then
		ins.fortify.set_label(i18n.t("ui_fortify") .. "  " .. fort_cost)
		ins.fortify.set_enabled(player_profile.get_points() >= fort_cost)
	end

	-- Main action: attack a reachable enemy sector or defend one under attack
	local action
	if s.under_attack and ours then
		action = "defend"
		ins.action.set_style("red")
		ins.action.set_label(i18n.t("ui_defend"))
	elseif can_attack then
		action = "attack"
		ins.action.set_style("gold")
		ins.action.set_label(i18n.t("ui_attack"))
	end
	gui.set_enabled(ins.action.node, action ~= nil)
	gui.set_enabled(ins.note, not ours and not can_attack)
	gui.set_text(ins.note, i18n.t("ui_not_reachable"))
end

return M
