-- gui/main_menu/menu_daily.lua
-- Daily reward window: the 7-day cycle of lua_modules/daily_rewards.lua, today's card highlighted,
-- a claim button, the claimed loot and a rewarded-ad button that doubles it. Opens by itself on
-- the home screen once per day.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local weapons = require("lua_modules.weapons")
local player_profile = require("lua_modules.player_profile")
local daily_rewards = require("lua_modules.daily_rewards")
local game_state = require("lua_modules.game_state")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

local CARD_W, CARD_H, CARD_STEP = 80, 112, 88
local SLOTS = 4

-- Card image of a cycle day: { image, texture, amount text }
local function day_look(def)
	if def.crate then
		return "crate_" .. def.crate, "ui", ""
	elseif def.stars then
		return "ic_star", "ui", "+" .. def.stars
	end
	return "ic_coin", "ui", "+" .. kit.num(def.coins)
end

-- Card image of a claimed loot item (same looks as the results screen)
local function item_look(item)
	if item.type == "coins" then
		return "card_legendary", "ic_coin", "ui"
	elseif item.type == "stars" then
		return "card_epic", "ic_star", "ui"
	elseif item.type == "hat" then
		local h = player_profile.SKINS_BY_ID[item.hat_id]
		return "card_" .. (h and h.rarity or "epic"), h and h.hat or "hat_cap", "game"
	end
	local w = weapons.get(item.weapon_id)
	return "card_" .. (w.rarity or "common"), w.icon, "game"
end

function M.build(self, on_close)
	local win = kit.window(self.ui, nil, "daily", 680, 380, "", on_close)
	self.daily = win
	local p = win.panel
	win.days = {}
	for i = 1, daily_rewards.CYCLE do
		local x = (i - (daily_rewards.CYCLE + 1) / 2) * CARD_STEP
		local d = { node = kit.card(p, x, 56, CARD_W, CARD_H, "common") }
		d.label = kit.text(d.node, "", 0, 38, 13, { font = "label", max_w = CARD_W - 8 })
		d.icon = kit.icon(d.node, "ic_coin", 0, 2, 44)
		d.amount = kit.text(d.node, "", 0, -36, 15, { font = "label", color = kit.C.gold, max_w = CARD_W - 8 })
		d.check = kit.icon(d.node, "ic_check", 22, -22, 30)
		win.days[i] = d
	end
	win.hint = kit.text(p, "", 0, -42, 16, { font = "label", color = kit.C.muted, max_w = 600 })

	win.slots = {}
	for i = 1, SLOTS do
		local s = { node = kit.card(p, (i - (SLOTS + 1) / 2) * 76, -48, 66, 74, "common") }
		s.icon = kit.icon(s.node, "ic_coin", 0, 8, 40)
		s.bp = kit.icon(s.node, "ic_blueprint", 20, 22, 20)
		s.amount = kit.text(s.node, "", 0, -26, 13, { font = "label" })
		gui.set_enabled(s.node, false)
		win.slots[i] = s
	end

	win.claim = kit.button(self.ui, p, "daily_claim", 0, -136, 240, 56, { style = "gold", label = "", px = 22, on_click = function()
		M.claim(self)
	end })
	win.double = kit.button(self.ui, p, "daily_double", -100, -136, 230, 52, { style = "green", icon = "ic_ad", icon_size = 30, label = "", px = 19, on_click = function()
		M.double(self)
	end })
	win.ok = kit.button(self.ui, p, "daily_ok", 120, -136, 150, 52, { style = "steel", label = "OK", px = 22, on_click = on_close })
	gui.set_enabled(win.root, false)
end

local function show_loot(self, items)
	local win = self.daily
	for i, s in ipairs(win.slots) do
		local item = items[i]
		gui.set_enabled(s.node, item ~= nil)
		if item then
			gui.set_position(s.node, vmath.vector3((i - (math.min(#items, SLOTS) + 1) / 2) * 76, -48, 0))
			local frame, image, texture = item_look(item)
			kit.set_image(s.node, frame)
			kit.set_icon(s.icon, image, 44, 40, texture)
			gui.set_enabled(s.bp, item.type == "blueprints")
			gui.set_text(s.amount, item.amount and ("+" .. kit.num(item.amount)) or i18n.t("ui_new_hat"))
			kit.fit_text(s.amount, 60, 13, "label")
			kit.pop_in(s.node, i * 0.1)
		end
	end
end

function M.refresh(self)
	local win = self.daily
	kit.set_text(win.title, i18n.t("ui_daily"), 520, 26, "title")
	local can = daily_rewards.can_claim()
	-- Before the claim the highlight is the day about to be given; after it, the day just taken
	local today = can and daily_rewards.next_cycle_day() or (((daily_rewards.next_cycle_day() - 2) % daily_rewards.CYCLE) + 1)
	for i, d in ipairs(win.days) do
		local image, texture, amount = day_look(daily_rewards.DAYS[i])
		kit.set_image(d.node, (i == today) and "card_legendary" or "card_common")
		kit.set_icon(d.icon, image, 48, 44, texture)
		gui.set_text(d.amount, amount)
		kit.set_text(d.label, string.format(i18n.t("ui_day_fmt"), i), CARD_W - 8, 13, "label")
		local taken = (i < today) or (i == today and not can)
		gui.set_enabled(d.check, taken)
		gui.set_color(d.icon, taken and vmath.vector4(1, 1, 1, 0.45) or vmath.vector4(1, 1, 1, 1))
	end
	win.claim.set_label(i18n.t("ui_claim"))
	win.double.set_label(i18n.t("ui_double"))
	gui.set_enabled(win.claim.node, can)
	gui.set_enabled(win.double.node, not can and self.daily_loot ~= nil and not self.daily_doubled)
	gui.set_enabled(win.ok.node, not can)
	if can then
		kit.set_text(win.hint, i18n.t("ui_daily_hint"), 600, 16, "label")
	elseif not self.daily_loot then
		kit.set_text(win.hint, i18n.t("ui_daily_next"), 600, 16, "label")
	end
end

function M.claim(self)
	local loot = daily_rewards.claim()
	if not loot then
		return
	end
	self.daily_loot = loot
	self.daily_doubled = false
	sound_manager.play("coins")
	gui.set_text(self.daily.hint, "")
	show_loot(self, loot)
	M.refresh(self)
	if self.on_changed then
		self.on_changed()
	end
end

-- Rewarded ad: the same reward once more (hats excluded, see daily_rewards.double)
function M.double(self)
	if not self.daily_loot or self.daily_doubled then
		return
	end
	game_state.poki_rewarded_break(function(success)
		if not success then
			return
		end
		self.daily_doubled = true
		local extra = daily_rewards.double(self.daily_loot)
		local shown = {}
		for _, item in ipairs(self.daily_loot) do
			local copy = { type = item.type, weapon_id = item.weapon_id, hat_id = item.hat_id, amount = item.amount }
			for _, e in ipairs(extra) do
				if e.type == item.type and e.weapon_id == item.weapon_id and e.amount and copy.amount then
					copy.amount = copy.amount + e.amount
					break
				end
			end
			table.insert(shown, copy)
		end
		show_loot(self, shown)
		sound_manager.play("coins")
		kit.set_text(self.daily.hint, i18n.t("ui_doubled"), 600, 16, "label")
		M.refresh(self)
		if self.on_changed then
			self.on_changed()
		end
	end)
end

function M.show(self, visible)
	gui.set_enabled(self.daily.root, visible)
	if visible then
		M.refresh(self)
		kit.pop_in(self.daily.panel)
	end
end

return M
