-- gui/main_menu/menu_home.lua
-- Home screen: commander bar, coins and stars, the squad leader in his hat, navigation to the
-- arsenal / squad / hats, the campaign card and the two battle buttons.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local player_profile = require("lua_modules.player_profile")
local progression = require("lua_modules.progression")
local classes = require("lua_modules.classes")
local territory_map = require("lua_modules.territory_map")
local strategic_campaign = require("lua_modules.strategic_campaign")

local M = {}

local HERO_H = 170 -- potato body height on screen
local NAV = {
	{ id = "nav_arsenal", icon = "ic_arsenal", key = "ui_arsenal", y = 92 },
	{ id = "nav_squad", icon = "ic_squad", key = "ui_squad", y = -10 },
	{ id = "nav_hats", icon = "ic_hat", key = "ui_hats", y = -112 },
}

-- Tall menu button: icon above the label, notification badge in the corner
local function nav_button(self, root, def, on_click)
	local btn = kit.button(self.ui, root, def.id, -372, def.y, 132, 94, { style = "dark", on_click = on_click })
	kit.icon(btn.node, def.icon, 0, 14, 46)
	local label = kit.text(btn.node, "", 0, -28, 16, { font = "label", max_w = 118 })
	local badge = kit.badge(btn.node, 56, 38)
	return { btn = btn, label = label, badge = badge, key = def.key }
end

function M.build(self, handlers)
	local root = kit.group(nil, 480, 270, 960, 540)
	self.home = { root = root }
	local h = self.home

	kit.box(root, "vignette", 0, 0, 980, 560)

	-- Top bar: commander level, coins, stars, settings
	kit.box(root, "dim", 0, 246, 980, 56, vmath.vector4(1, 1, 1, 0.6))
	kit.box(root, "white", 0, 217, 980, 2, vmath.vector4(0.95, 0.72, 0.2, 0.55))
	kit.icon(root, "ic_level", -440, 246, 50)
	h.level = kit.text(root, "1", -440, 246, 22, { font = "title" })
	h.commander = kit.text(root, "", -408, 257, 13, { font = "label", align = "left", color = kit.C.muted })
	h.xp_bar = kit.bar(root, -333, 236, 150, 14, kit.C.xp)
	h.xp_text = kit.text(root, "", -333, 236, 11, { font = "label" })
	h.coins = kit.counter(root, "ic_coin", 200, 246, 136, "0")
	h.stars = kit.counter(root, "ic_star", 334, 246, 104, "0")
	kit.icon_button(self.ui, root, "home_settings", 438, 246, 46, "ic_gear", handlers.settings)

	-- Title
	h.title = kit.text(root, "POTATO WAR", 0, 168, 58, { font = "title", color = kit.C.gold })
	h.subtitle = kit.text(root, "", 0, 128, 16, { font = "label", color = kit.C.muted })

	-- Squad leader on a pedestal
	kit.box(root, "glow", 0, -92, 230, 46, vmath.vector4(0.02, 0.04, 0.08, 0.7))
	h.hero = kit.group(root, 0, -2)
	h.hero_body = kit.icon(h.hero, "recruit", 0, 0, HERO_H, { texture = "game" })
	h.hero_hat = kit.icon(h.hero, "hat_cap", 0, HERO_H * 0.51, HERO_H * 0.62, { texture = "game" })
	gui.animate(h.hero, "scale.y", 1.03, gui.EASING_INOUTSINE, 1.4, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	h.squad_size = kit.text(root, "", 0, -122, 14, { font = "label", color = kit.C.muted })

	-- Left navigation
	h.nav = {
		nav_button(self, root, NAV[1], handlers.arsenal),
		nav_button(self, root, NAV[2], handlers.squad),
		nav_button(self, root, NAV[3], handlers.hats),
	}

	-- Campaign card
	local card = kit.panel(root, 360, 30, 210, 170)
	local header = kit.box(card, "header", 0, 63, 202, 40)
	h.camp_title = kit.text(header, "", 0, 2, 18, { font = "title", color = kit.C.gold, max_w = 180 })
	kit.icon(card, "ic_flag", -70, 12, 40)
	h.camp_sectors = kit.text(card, "", 18, 20, 17, { font = "label", max_w = 120 })
	h.camp_bar = kit.bar(card, 18, -2, 120, 12, kit.C.blue)
	h.camp_turn = kit.text(card, "", 0, -40, 15, { font = "label", color = kit.C.muted })
	h.camp_income = kit.text(card, "", 0, -62, 14, { font = "label", color = kit.C.gold })

	-- Battle buttons
	h.quick = kit.button(self.ui, root, "home_quick", 30, -207, 236, 72, { style = "steel", icon = "ic_battle", icon_size = 40, label = "", px = 20, on_click = handlers.quick })
	h.campaign = kit.button(self.ui, root, "home_campaign", 318, -207, 300, 86, { style = "gold", icon = "ic_map", icon_size = 48, label = "", px = 26, on_click = handlers.campaign })
	gui.animate(h.campaign.node, "scale", vmath.vector3(1.04, 1.04, 1), gui.EASING_INOUTSINE, 0.9, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
end

function M.refresh(self)
	local h = self.home
	local level, into, need = progression.commander_level()
	gui.set_text(h.level, tostring(level))
	gui.set_text(h.commander, i18n.t("ui_commander"))
	h.xp_bar.set(into / need)
	gui.set_text(h.xp_text, into .. " / " .. need)
	kit.set_text(h.coins.text, kit.num(player_profile.get_points()), 92, 19, "label")
	kit.set_text(h.stars.text, kit.num(player_profile.get_stars()), 60, 19, "label")
	kit.set_text(h.subtitle, i18n.t("ui_subtitle"), 420, 16, "label")

	-- Hero: the first squad member in the equipped hat
	local squad = player_profile.get_squad()
	local leader = squad[1]
	kit.set_icon(h.hero_body, classes.sprite_of(leader and leader.class_id), HERO_H, HERO_H)
	local hat = player_profile.get_equipped_hat()
	local has_hat = hat and hat.hat and hat.hat ~= "none"
	gui.set_enabled(h.hero_hat, has_hat)
	if has_hat then
		kit.set_icon(h.hero_hat, hat.hat, HERO_H * 0.66, HERO_H * 0.62)
	end
	kit.set_text(h.squad_size, string.format(i18n.t("ui_fighters_fmt"), #squad), 300, 14, "label")

	for _, n in ipairs(h.nav) do
		kit.set_text(n.label, i18n.t(n.key), 118, 16, "label")
	end
	-- Anything left to spend in the arsenal or the barracks lights a badge
	gui.set_enabled(h.nav[1].badge, progression.any_weapon_upgrade())
	gui.set_enabled(h.nav[2].badge, progression.squad_can_improve())

	local stats = territory_map.get_stats()
	kit.set_text(h.camp_title, i18n.t("ui_campaign_card"), 180, 18, "title")
	kit.set_text(h.camp_sectors, string.format(i18n.t("ui_sectors_fmt"), stats.blue_count, stats.total_count), 120, 17, "label")
	h.camp_bar.set(stats.blue_count / math.max(1, stats.total_count))
	kit.set_text(h.camp_turn, string.format(i18n.t("ui_turn_fmt"), strategic_campaign.get_turn()), 180, 15, "label")
	kit.set_text(h.camp_income, string.format(i18n.t("ui_income_fmt"), territory_map.get_income("blue")), 180, 14, "label")

	h.quick.set_label(i18n.t("ui_quick"))
	h.campaign.set_label(i18n.t("ui_campaign"))
end

function M.set_enabled(self, enabled)
	gui.set_enabled(self.home.root, enabled)
end

return M
