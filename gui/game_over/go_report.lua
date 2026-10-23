-- gui/game_over/go_report.lua
-- Results, left panel: experience of every squad member (rank bars that fill up, promotions)
-- and the commander level bar.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local classes = require("lua_modules.classes")
local progression = require("lua_modules.progression")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

local ROWS = 4
local ROW_Y = { 82, 34, -14, -62 }
local FILL_TIME = 0.7

local function build_row(parent, y)
	local r = { node = kit.group(parent, 0, y) }
	r.body = kit.icon(r.node, "recruit", -186, 0, 40, { texture = "game" })
	r.rank = kit.icon(r.node, "rank_1", -152, 0, 34)
	r.name = kit.text(r.node, "", -130, 9, 14, { font = "label", align = "left", max_w = 130 })
	r.bar = kit.bar(r.node, -50, -9, 160, 12, kit.C.xp)
	r.gain = kit.text(r.node, "", 112, 0, 18, { font = "label", color = kit.C.gold, align = "left" })
	r.promo = kit.text(r.node, "", 56, 10, 13, { font = "label", color = kit.C.green })
	return r
end

function M.build(self, root)
	local panel = kit.panel(root, -232, 20, 440, 300)
	local header = kit.box(panel, "header", 0, 128, 432, 40)
	self.report = { panel = panel }
	local rp = self.report
	rp.title = kit.text(header, "", 0, 2, 18, { font = "title", color = kit.C.gold, max_w = 400 })
	rp.rows = {}
	for i = 1, ROWS do
		rp.rows[i] = build_row(panel, ROW_Y[i])
	end
	rp.note = kit.text(panel, "", 0, -92, 12, { font = "label", color = kit.C.muted, max_w = 410 })
	kit.box(panel, "white", 0, -104, 400, 2, vmath.vector4(0.95, 0.72, 0.2, 0.35))
	kit.icon(panel, "ic_level", -176, -126, 40)
	rp.level = kit.text(panel, "1", -176, -126, 18, { font = "title" })
	rp.cmd_label = kit.text(panel, "", -148, -116, 13, { font = "label", align = "left", color = kit.C.muted, max_w = 150 })
	rp.cmd_bar = kit.bar(panel, -40, -134, 216, 14, kit.C.gold)
	rp.cmd_gain = kit.text(panel, "", 112, -126, 18, { font = "label", color = kit.C.gold, align = "left" })
	rp.levelup = kit.text(panel, "", 0, -152, 14, { font = "label", color = kit.C.green })
end

-- Fills a bar from the old to the new value; a rank-up runs it to the end, then from zero
local function animate_bar(bar, from_pct, to_pct, ranked_up, delay, on_rank_up)
	bar.set(from_pct)
	timer.delay(delay, false, function()
		if ranked_up then
			bar.set(1, FILL_TIME * 0.6)
			timer.delay(FILL_TIME * 0.6 + 0.05, false, function()
				if on_rank_up then
					on_rank_up()
				end
				bar.set(0)
				bar.set(to_pct, FILL_TIME * 0.6)
			end)
		else
			bar.set(to_pct, FILL_TIME)
		end
	end)
end

local function pct(into, need)
	return need and (into / need) or 1
end

function M.show(self, progress)
	local rp = self.report
	gui.set_enabled(rp.panel, progress ~= nil)
	if not progress then
		return
	end
	kit.set_text(rp.title, i18n.t("ui_squad_xp"), 400, 18, "title")
	local members = progress.members or {}
	for i, r in ipairs(rp.rows) do
		local m = members[i]
		gui.set_enabled(r.node, m ~= nil)
		if m then
			local c = classes.get(m.class_id)
			kit.set_icon(r.body, classes.sprite_of(m.class_id), 40, 40, "game")
			gui.play_flipbook(r.rank, "rank_" .. m.rank_before)
			kit.set_text(r.name, i18n.field(c, "name"), 130, 14, "label")
			gui.set_text(r.gain, "+" .. m.gained)
			gui.set_text(r.promo, "")
			local _, into_before, need_before = progression.rank_of(m.xp - m.gained)
			local _, into_after, need_after = progression.rank_of(m.xp)
			local ranked_up = m.rank_after > m.rank_before
			animate_bar(r.bar, pct(into_before, need_before), pct(into_after, need_after), ranked_up, 0.35 + i * 0.12, function()
				gui.play_flipbook(r.rank, "rank_" .. m.rank_after)
				gui.set_text(r.promo, i18n.t("ui_rank_up"))
				kit.pop_in(r.rank)
				kit.pop_in(r.promo)
				sound_manager.play("unlock")
			end)
		end
	end
	gui.set_text(rp.note, (progress.members and #progress.members > 0 and not progress.uses_squad) and i18n.t("ui_training_xp") or "")

	local cmd = progress.commander
	gui.set_enabled(rp.cmd_bar.node, cmd ~= nil)
	gui.set_text(rp.levelup, "")
	if cmd then
		kit.set_text(rp.cmd_label, i18n.t("ui_commander"), 150, 13, "label")
		gui.set_text(rp.level, tostring(cmd.level_before))
		gui.set_text(rp.cmd_gain, "+" .. cmd.gained)
		local leveled = cmd.level > cmd.level_before
		local before_into = cmd.into - cmd.gained
		local before_pct = leveled and 0.6 or math.max(0, before_into) / cmd.need
		animate_bar(rp.cmd_bar, before_pct, cmd.into / cmd.need, leveled, 0.9, function()
			gui.set_text(rp.level, tostring(cmd.level))
			gui.set_text(rp.levelup, string.format(i18n.t("ui_level_up_fmt"), cmd.level))
			kit.pop_in(rp.levelup)
			sound_manager.play("star3")
		end)
	end
end

return M
