-- gui/campaign_map/camp_view.lua
-- Map rendering: top bar, connection lines, sector nodes, alert banner, per-frame pulses.

local territory_map = require("lua_modules.territory_map")
local strategic_campaign = require("lua_modules.strategic_campaign")
local sound_manager = require("lua_modules.sound_manager")
local i18n = require("lua_modules.i18n")
local camp_data = require("gui.campaign_map.camp_data")
local camp_inspector = require("gui.campaign_map.camp_inspector")
local camp_barracks = require("gui.campaign_map.camp_barracks")

local M = {}

-- Builds one box node per sector connection under "lines_container".
function M.build_lines(self)
	self.lines = {}
	local edges = territory_map.get_connections()
	local container = gui.get_node("lines_container")

	for _, e in ipairs(edges) do
		local a = e.sector_a
		local b = e.sector_b
		if a and b then
			local mx = (a.x + b.x) * 0.5
			local my = (a.y + b.y) * 0.5
			local dx = b.x - a.x
			local dy = b.y - a.y
			local len = math.sqrt(dx * dx + dy * dy)
			local angle_rad = math.atan2(dy, dx)

			local line_node = gui.new_box_node(vmath.vector3(mx, my, 0), vmath.vector3(len, 2.5, 0))
			gui.set_parent(line_node, container)
			gui.set_rotation(line_node, vmath.quat_rotation_z(angle_rad))
			gui.set_color(line_node, vmath.vector4(0.3, 0.38, 0.48, 0.5))

			table.insert(self.lines, {
				node = line_node,
				from = a.id,
				to = b.id,
				len = len,
				is_frontline = e.is_frontline,
			})
		end
	end
end

local function update_top_bar(stats, supplies, turn)
	pcall(function()
		gui.set_text(gui.get_node("txt_top_title"), i18n.t("camp_title"))
		gui.set_text(gui.get_node("txt_top_sectors"), string.format(i18n.t("camp_sectors_fmt"), stats.blue_count, stats.total_count, stats.progress_pct))
		gui.set_text(gui.get_node("txt_top_supplies"), string.format(i18n.t("camp_supplies_fmt"), supplies))
		gui.set_text(gui.get_node("txt_top_turn"), string.format(i18n.t("camp_turn_fmt"), turn))
		gui.set_text(gui.get_node("txt_top_barracks"), i18n.t("camp_btn_barracks"))
		gui.set_text(gui.get_node("txt_top_menu"), i18n.t("camp_btn_back"))
		gui.set_text(gui.get_node("txt_bot_hint"), i18n.t("camp_hint_bottom"))
	end)
end

local function update_lines(self, secs)
	for _, l in ipairs(self.lines or {}) do
		local sa = secs[l.from]
		local sb = secs[l.to]
		if sa and sb then
			local is_frontline = (sa.owner ~= sb.owner)
			l.is_frontline = is_frontline
			if is_frontline then
				-- Frontline: gold / orange pulsating line
				gui.set_color(l.node, vmath.vector4(0.96, 0.72, 0.16, 0.95))
				gui.set_size(l.node, vmath.vector3(l.len, 4.5, 0))
			elseif sa.owner == "blue" then
				-- Friendly route: calm blue
				gui.set_color(l.node, vmath.vector4(0.18, 0.45, 0.75, 0.55))
				gui.set_size(l.node, vmath.vector3(l.len, 2.5, 0))
			else
				-- Enemy route: dark burgundy
				gui.set_color(l.node, vmath.vector4(0.48, 0.18, 0.22, 0.45))
				gui.set_size(l.node, vmath.vector3(l.len, 2.0, 0))
			end
		end
	end
end

local function update_sector_node(self, i, s)
	local is_blue = (s.owner == "blue")
	local is_selected = (self.selected_sector_id == i)
	local can_atk = territory_map.can_attack(i)

	pcall(function()
		local btn = gui.get_node("sec_btn_" .. i)
		local glow = gui.get_node("sec_glow_" .. i)
		local potato = gui.get_node("sec_potato_" .. i)
		local stars = gui.get_node("sec_stars_" .. i)
		local alert = gui.get_node("sec_alert_" .. i)
		local lbl = gui.get_node("sec_lbl_" .. i)

		-- Faction color & potato avatar
		gui.play_flipbook(potato, hash("recruit"))
		if is_blue then
			gui.set_color(btn, vmath.vector4(0.16, 0.44, 0.82, 1.0))
			gui.set_color(potato, vmath.vector4(0.85, 0.95, 1.0, 1.0))
		else
			gui.set_color(btn, vmath.vector4(0.74, 0.18, 0.20, 1.0))
			gui.set_color(potato, vmath.vector4(1.0, 0.85, 0.85, 1.0))
		end

		gui.set_text(stars, camp_data.DEF_STARS[s.defense_level or 1] or "★☆☆")
		gui.set_text(lbl, i18n.field(s, "name"))
		gui.set_enabled(alert, s.under_attack == true)

		-- Glow ring
		if is_selected then
			gui.set_enabled(glow, true)
			gui.set_color(glow, vmath.vector4(0.98, 0.88, 0.25, 0.90))
			gui.set_size(glow, vmath.vector3(64, 64, 0))
		elseif s.under_attack then
			gui.set_enabled(glow, true)
			gui.set_color(glow, vmath.vector4(0.95, 0.20, 0.20, 0.85))
			gui.set_size(glow, vmath.vector3(62, 62, 0))
		elseif can_atk then
			-- Available target indicator: subtle golden ring
			gui.set_enabled(glow, true)
			gui.set_color(glow, vmath.vector4(0.95, 0.75, 0.20, 0.50))
			gui.set_size(glow, vmath.vector3(58, 58, 0))
		else
			gui.set_enabled(glow, false)
		end
	end)
end

local function update_alert_banner(attacked_sector)
	pcall(function()
		local banner = gui.get_node("alert_banner")
		if attacked_sector then
			gui.set_enabled(banner, true)
			gui.set_text(gui.get_node("txt_alert_banner"), string.format(i18n.t("camp_alert_siren"), attacked_sector.id))
		else
			gui.set_enabled(banner, false)
		end
	end)
end

function M.update_visuals(self)
	local secs = territory_map.get_sectors()

	update_top_bar(territory_map.get_stats(), strategic_campaign.get_supplies(), strategic_campaign.get_turn())
	camp_barracks.update(self)
	update_lines(self, secs)

	local attacked_sector = nil
	for i = 1, 18 do
		local s = secs[i]
		if s then
			if s.under_attack then
				attacked_sector = s
			end
			update_sector_node(self, i, s)
		end
	end

	update_alert_banner(attacked_sector)
	camp_inspector.update(self)
end

-- Selects a sector with a bounce on its node and refreshes the map.
function M.select_sector(self, sector_id)
	sound_manager.play_click()
	self.selected_sector_id = sector_id
	M.bounce_sector(sector_id, 1.15, 0.25)
	M.update_visuals(self)
end

function M.bounce_sector(sector_id, from_scale, duration)
	pcall(function()
		local btn = gui.get_node("sec_btn_" .. sector_id)
		gui.cancel_animations(btn, "scale")
		gui.set_scale(btn, vmath.vector3(from_scale, from_scale, 1.0))
		gui.animate(btn, "scale", vmath.vector3(1.0, 1.0, 1.0), gui.EASING_OUTBOUNCE, duration)
	end)
end

-- Pulsing frontline lines and alert banner.
function M.pulse(self, dt)
	self.pulse_timer = (self.pulse_timer or 0) + dt

	local alpha_wave = 0.70 + 0.30 * math.sin(self.pulse_timer * 4.0)
	local gold_pulse = vmath.vector4(0.98, 0.72 + 0.10 * math.sin(self.pulse_timer * 3.0), 0.15, alpha_wave)

	for _, l in ipairs(self.lines or {}) do
		if l.is_frontline then
			pcall(gui.set_color, l.node, gold_pulse)
		end
	end

	pcall(function()
		local banner = gui.get_node("alert_banner")
		if gui.is_enabled(banner) then
			local b_alpha = 0.80 + 0.20 * math.sin(self.pulse_timer * 6.0)
			gui.set_color(banner, vmath.vector4(0.85, 0.12, 0.12, b_alpha))
		end
	end)
end

return M
