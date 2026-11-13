-- gui/main_menu/menu_upgrades.lua
-- Meta-progression window: three permanent upgrades (max HP, starting arsenal, HP regen).
-- Spends coins through lua_modules/meta_progression and is refreshed from the home screen.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local player_profile = require("lua_modules.player_profile")
local sound_manager = require("lua_modules.sound_manager")
local meta_progression = require("lua_modules.meta_progression")

local M = {}

local ORDER = {
	meta_progression.UPGRADE_MAX_HP,
	meta_progression.UPGRADE_STARTING_WEAPON,
	meta_progression.UPGRADE_HP_REGEN,
}
local ROW_Y = { 96, -8, -112 }
local ROW_W, ROW_H = 740, 88

local function message(self, text, color)
	local note = self.upgrades.note
	gui.set_text(note, text)
	gui.set_color(note, color or kit.C.red)
	gui.cancel_animations(note, "color.w")
	gui.animate(note, "color.w", 0, gui.EASING_INQUAD, 0.6, 1.6)
end

local function build_row(self, parent, id, y)
	local row = { id = id }
	local upg = meta_progression.UPGRADES[id]

	row.bg = kit.inset(parent, 0, y, ROW_W, ROW_H)
	row.icon = kit.icon(parent, upg.icon, -332, y, 52)
	row.name = kit.text(parent, "", -294, y + 22, 20, { font = "label", align = "left", max_w = 330 })
	row.desc = kit.text(parent, "", -294, y - 8, 14, { font = "label", align = "left", max_w = 430, color = kit.C.muted })
	row.level = kit.text(parent, "", 128, y + 24, 16, { font = "label", align = "right", max_w = 120 })
	row.bar = kit.bar(parent, 120, y + 3, 140, 12, kit.C.gold)
	row.cost_icon = kit.icon(parent, "ic_coin", 78, y - 30, 22)
	row.cost = kit.text(parent, "", 100, y - 30, 17, { font = "label", align = "left", max_w = 110 })
	row.buy = kit.button(self.ui, parent, "meta_buy_" .. id, 290, y, 150, 54, {
		style = "gold",
		label = "",
		px = 17,
		on_click = function()
			local ok = meta_progression.buy_upgrade(id)
			if ok then
				sound_manager.play("coins")
				sound_manager.play("unlock")
				kit.pop_in(row.buy.node)
				if self.on_changed then
					self.on_changed()
				end
			else
				sound_manager.play("tick")
				message(self, i18n.t("ui_need_coins"))
				if self.open_store then self.open_store(i18n.t("ui_need_coins")) end
			end
			M.refresh(self)
		end,
	})
	return row
end

function M.build(self, on_close)
	local win = kit.window(self.ui, nil, "upgrades", 780, 460, "", on_close)
	self.upgrades = win
	local p = win.panel
	win.coins = kit.counter(p, "ic_coin", 270, 208, 140, "0")
	win.hint = kit.text(p, "", 0, 158, 14, { font = "label", color = kit.C.muted, max_w = 700 })
	win.rows = {}
	for i, id in ipairs(ORDER) do
		win.rows[i] = build_row(self, p, id, ROW_Y[i])
	end
	win.note = kit.text(p, "", 0, -182, 17, { font = "label", color = kit.C.red })
	gui.set_color(win.note, vmath.vector4(1, 0.36, 0.3, 0))
	gui.set_enabled(win.root, false)
end

function M.refresh(self)
	local win = self.upgrades
	kit.set_text(win.title, i18n.t("ui_upgrades"), 600, 26, "title")
	kit.set_text(win.hint, i18n.t("ui_upgrades_hint"), 700, 14, "label")
	kit.set_text(win.coins.text, kit.num(player_profile.get_points()), 100, 19, "label")

	for _, row in ipairs(win.rows) do
		local upg = meta_progression.UPGRADES[row.id]
		local level = meta_progression.get_level(row.id)
		local max_level = upg.max_level
		kit.set_text(row.name, i18n.field(upg, "name"), 330, 20, "label")
		kit.set_text(row.desc, meta_progression.get_level_description(row.id), 430, 14, "label")
		kit.set_text(row.level, string.format(i18n.t("ui_level_fmt"), level) .. " / " .. max_level, 120, 16, "label")
		row.bar.set(level / max_level)

		local cost = meta_progression.get_upgrade_cost(row.id)
		if cost < 0 then
			gui.set_enabled(row.cost_icon, false)
			kit.set_text(row.cost, i18n.t("ui_max"), 110, 17, "label")
			gui.set_color(row.cost, kit.C.green)
			row.buy.set_label(i18n.t("ui_max"))
			row.buy.set_enabled(false)
		else
			gui.set_enabled(row.cost_icon, true)
			kit.set_text(row.cost, kit.num(cost), 110, 17, "label")
			gui.set_color(row.cost, meta_progression.can_afford(row.id) and kit.C.gold or kit.C.disabled)
			row.buy.set_label(i18n.t("ui_upgrade"))
			row.buy.set_enabled(meta_progression.can_afford(row.id))
			row.buy.enabled = true -- a tap on a disabled-looking button opens the store (paywall)
		end
	end
end

function M.show(self, visible)
	gui.set_enabled(self.upgrades.root, visible)
	if visible then
		M.refresh(self)
		kit.pop_in(self.upgrades.panel)
	end
end

return M
