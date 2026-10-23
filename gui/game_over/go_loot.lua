-- gui/game_over/go_loot.lua
-- Results, right panel: coins and stars of the battle, the supply crate that pops open on tap,
-- its loot (coins, weapon blueprints, a hat), and the rewarded-ad button that doubles it.
-- The loot itself is already stored by progression.finish_battle; this only presents it.

local kit = require("lua_modules.ui_kit")
local constants = require("lua_modules.constants")
local i18n = require("lua_modules.i18n")
local weapons = require("lua_modules.weapons")
local player_profile = require("lua_modules.player_profile")
local progression = require("lua_modules.progression")
local game_state = require("lua_modules.game_state")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

local SLOTS = 8
local SLOT_W, SLOT_H = 72, 84
local SLOT_X = { -117, -39, 39, 117 }
local SLOT_Y = { 40, -48 }
local CRATE_SCALE = 1.15

-- Card look of one loot item: frame, image, texture
local function item_look(item)
	if item.type == "coins" then
		return "card_legendary", "ic_coin", "ui"
	elseif item.type == "hat" then
		local h = player_profile.SKINS_BY_ID[item.hat_id]
		return "card_" .. (h and h.rarity or "epic"), h and h.hat or "hat_cap", "game"
	end
	local w = weapons.get(item.weapon_id)
	return "card_" .. (w.rarity or "common"), w.icon, "game"
end

-- Coins merged into one card, blueprints of the same weapon stacked
local function merge(loot)
	local out, coins, by_weapon = {}, nil, {}
	for _, item in ipairs(loot or {}) do
		if item.type == "coins" then
			coins = coins or { type = "coins", amount = 0 }
			coins.amount = coins.amount + item.amount
		elseif item.type == "blueprints" then
			if by_weapon[item.weapon_id] then
				by_weapon[item.weapon_id].amount = by_weapon[item.weapon_id].amount + item.amount
			else
				by_weapon[item.weapon_id] = { type = "blueprints", weapon_id = item.weapon_id, amount = item.amount }
				table.insert(out, by_weapon[item.weapon_id])
			end
		else
			table.insert(out, { type = item.type, hat_id = item.hat_id })
		end
	end
	if coins then
		table.insert(out, 1, coins)
	end
	return out
end

local function build_slot(parent, i)
	local col = (i - 1) % 4 + 1
	local row = math.floor((i - 1) / 4) + 1
	local s = { node = kit.card(parent, SLOT_X[col], SLOT_Y[row], SLOT_W, SLOT_H, "common") }
	s.icon = kit.icon(s.node, "ic_coin", 0, 10, 48)
	s.bp = kit.icon(s.node, "ic_blueprint", 22, 26, 24)
	s.amount = kit.text(s.node, "", 0, -30, 15, { font = "label" })
	gui.set_enabled(s.node, false)
	return s
end

function M.build(self, root)
	local panel = kit.panel(root, 232, 20, 440, 300)
	local header = kit.box(panel, "header", 0, 128, 432, 40)
	self.loot = { panel = panel }
	local lp = self.loot
	lp.title = kit.text(header, "", 0, 2, 18, { font = "title", color = kit.C.gold, max_w = 400 })

	kit.icon(panel, "ic_coin", -150, 92, 34)
	lp.coins = kit.text(panel, "", -126, 92, 22, { font = "label", align = "left", color = kit.C.gold })
	lp.star_icon = kit.icon(panel, "ic_star", 40, 92, 34)
	lp.stars = kit.text(panel, "", 64, 92, 22, { font = "label", align = "left", color = kit.C.gold })

	-- Crate: rays behind, body and lid as one big tap target
	lp.crate = kit.group(panel, 0, -8)
	lp.rays = kit.box(lp.crate, "rays", 0, 0, 260, 260, vmath.vector4(1, 0.9, 0.5, 0.55))
	lp.body = kit.box(lp.crate, "crate_steel", 0, 0, 128 * CRATE_SCALE, 96 * CRATE_SCALE)
	lp.lid = kit.box(lp.crate, "crate_steel_lid", 0, 50, 136 * CRATE_SCALE, 32 * CRATE_SCALE)
	lp.open_btn = kit.button(self.ui, lp.crate, "loot_open", 0, 4, 170, 150, { style = "dark", on_click = function()
		M.open(self)
	end })
	gui.set_visible(lp.open_btn.node, false)
	lp.crate_name = kit.text(panel, "", 0, -84, 16, { font = "label", max_w = 400 })
	lp.hint = kit.text(panel, "", 0, -106, 13, { font = "label", color = kit.C.muted, max_w = 400 })

	lp.slots = {}
	for i = 1, SLOTS do
		lp.slots[i] = build_slot(panel, i)
	end
	lp.double = kit.button(self.ui, panel, "loot_double", 0, -108, 250, 50, { style = "gold", icon = "ic_ad", icon_size = 30, label = "", px = 19, on_click = function()
		M.double(self)
	end })
	lp.revive = kit.button(self.ui, panel, "loot_revive", 0, -50, 270, 60, { style = "green", icon = "ic_ad", icon_size = 34, label = "", px = 21, on_click = function()
		msg.post(".", "disable")
		msg.post("/main#main", "revive_player")
	end })
	lp.note = kit.text(panel, "", 0, 30, 15, { font = "label", color = kit.C.muted, width = 380 })
end

local function show_items(self, items, delay)
	local lp = self.loot
	for i, s in ipairs(lp.slots) do
		local item = items[i]
		gui.set_enabled(s.node, item ~= nil)
		if item then
			local frame, image, texture = item_look(item)
			kit.set_image(s.node, frame)
			kit.set_icon(s.icon, image, 52, 46, texture)
			gui.set_enabled(s.bp, item.type == "blueprints")
			gui.set_text(s.amount, item.amount and ("+" .. kit.num(item.amount)) or i18n.t("ui_new_hat"))
			kit.fit_text(s.amount, SLOT_W - 8, 15, "label")
			gui.set_scale(s.node, vmath.vector3(0.01, 0.01, 1))
			local d = (delay or 0) + i * 0.12
			gui.animate(s.node, "scale", vmath.vector3(1, 1, 1), gui.EASING_OUTBACK, 0.3, d)
			timer.delay(d, false, function()
				sound_manager.play(item.type == "coins" and "coin" or "pop", { vary = 0.1 })
			end)
		end
	end
end

function M.show(self, data)
	local lp = self.loot
	local progress = data.progress or {}
	self.loot_data = progress
	self.loot_items = merge(progress.loot)
	self.loot_doubled = false
	self.crate_open = false
	kit.set_text(lp.title, i18n.t("ui_reward"), 400, 18, "title")

	local stars = data.stars_earned or 0
	gui.set_text(lp.coins, "+" .. kit.num(progress.coins or 0))
	gui.set_enabled(lp.star_icon, stars > 0)
	gui.set_enabled(lp.stars, stars > 0)
	gui.set_text(lp.stars, "+" .. stars)

	for _, s in ipairs(lp.slots) do
		gui.set_enabled(s.node, false)
	end
	gui.set_enabled(lp.double.node, false)
	lp.double.set_label(i18n.t("ui_double"))

	local tier = progress.crate_tier
	gui.set_enabled(lp.crate, tier ~= nil)
	gui.set_text(lp.crate_name, "")
	gui.set_text(lp.hint, "")
	gui.set_color(lp.hint, kit.C.muted)
	gui.set_text(lp.note, "")
	gui.set_enabled(lp.revive.node, false)
	if tier then
		kit.set_image(lp.body, "crate_" .. tier)
		kit.set_image(lp.lid, "crate_" .. tier .. "_lid")
		gui.set_position(lp.lid, vmath.vector3(0, 50, 0))
		gui.set_rotation(lp.lid, vmath.quat())
		gui.set_color(lp.lid, vmath.vector4(1, 1, 1, 1))
		gui.set_color(lp.body, vmath.vector4(1, 1, 1, 1))
		gui.set_scale(lp.rays, vmath.vector3(0.7, 0.7, 1))
		gui.cancel_animations(lp.rays, "rotation.z")
		gui.set_rotation(lp.rays, vmath.quat())
		gui.animate(lp.rays, "rotation.z", 360, gui.EASING_LINEAR, 9, 0, nil, gui.PLAYBACK_LOOP_FORWARD)
		-- Idle wobble invites the tap
		gui.cancel_animations(lp.body, "position.y")
		gui.set_position(lp.body, vmath.vector3(0, 0, 0))
		gui.animate(lp.body, "position.y", 6, gui.EASING_INOUTSINE, 0.5, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		kit.set_text(lp.crate_name, i18n.t("ui_crate_" .. tier), 400, 16, "label")
		kit.set_text(lp.hint, i18n.t("ui_tap_to_open"), 400, 13, "label")
		kit.pop_in(lp.crate, 0.3)
	else
		gui.set_text(lp.note, i18n.t("ui_no_crate"))
		-- Defeat outside the tutorial: the rewarded revive is offered here
		local can_revive = data.winner == constants.TEAM_RED and not data.seamless and not data.is_tutorial
		gui.set_enabled(lp.revive.node, can_revive)
		lp.revive.set_label(i18n.t("ui_revive"))
	end
end

function M.open(self)
	local lp = self.loot
	if self.crate_open then
		return
	end
	self.crate_open = true
	sound_manager.play("crate")
	gui.cancel_animations(lp.body, "position.y")
	-- shake, lid flies off, crate fades, loot pops in
	gui.animate(lp.body, "position.x", 6, gui.EASING_INOUTSINE, 0.06, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	gui.animate(lp.rays, "scale", vmath.vector3(1.4, 1.4, 1), gui.EASING_OUTBACK, 0.4)
	timer.delay(0.35, false, function()
		gui.cancel_animations(lp.body, "position.x")
		sound_manager.play("unlock")
		gui.animate(lp.lid, "position", vmath.vector3(60, 170, 0), gui.EASING_OUTQUAD, 0.45)
		gui.animate(lp.lid, "rotation.z", -40, gui.EASING_OUTQUAD, 0.45)
		gui.animate(lp.lid, "color.w", 0, gui.EASING_INQUAD, 0.45)
		gui.animate(lp.body, "color.w", 0, gui.EASING_INQUAD, 0.35, 0.15)
		timer.delay(0.4, false, function()
			gui.set_enabled(lp.crate, false)
			gui.set_text(lp.hint, "")
			gui.set_text(lp.crate_name, "")
			show_items(self, self.loot_items, 0)
			timer.delay(0.3 + #self.loot_items * 0.12, false, function()
				gui.set_enabled(lp.double.node, not self.loot_doubled)
				if not self.loot_doubled then
					kit.pop_in(lp.double.node)
				end
			end)
		end)
	end)
end

-- Rewarded ad: the same loot once more (hats excluded)
function M.double(self)
	local lp = self.loot
	if self.loot_doubled then
		return
	end
	game_state.poki_rewarded_break(function(success)
		if not success then
			return
		end
		self.loot_doubled = true
		local extra = progression.double_loot(self.loot_data.loot or {})
		progression.apply_loot(extra)
		for _, item in ipairs(self.loot_items) do
			if item.amount then
				item.amount = item.amount * 2
			end
		end
		gui.set_enabled(lp.double.node, false)
		show_items(self, self.loot_items, 0)
		sound_manager.play("coins")
		gui.set_text(lp.hint, i18n.t("ui_doubled"))
		gui.set_color(lp.hint, kit.C.green)
	end)
end

return M
