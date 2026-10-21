const fs = require('fs');

const path = 'gui/hud/hud.gui_script';
let raw = fs.readFileSync(path, 'utf8');
let isCRLF = raw.includes('\r\n');
let content = raw.replace(/\r\n/g, '\n');

// 1. In init(self), add is_touch_screen detection and badge_timer
const oldInitVars = 'self.tutorial_hand_timer = 0\n\tself.tap_hint_timer = 0';
const newInitVars = `self.tutorial_hand_timer = 0
	self.tap_hint_timer = 0
	self.badge_timer = 0

	-- Detect touch device vs desktop PC (hide screen AWD buttons on PC with mouse cursor)
	local sys_info = sys.get_sys_info()
	local sname = sys_info.system_name
	self.is_touch_screen = (sname == "Android" or sname == "iPhone OS")
	if html5 then
		pcall(function()
			self.is_touch_screen = html5.run("('ontouchstart' in window || navigator.maxTouchPoints > 0) ? '1' : '0'") == "1"
		end)
	end`;

content = content.replace(oldInitVars, newInitVars);

// 2. Tactical button colors for hold buttons
const oldBtnColors = 'local active_btn_color = vmath.vector4(0.18, 0.72, 0.42, 1.0)\n\tlocal normal_btn_color = vmath.vector4(0.22, 0.28, 0.35, 1.0)';
const newBtnColors = `local active_btn_color = vmath.vector4(0.78, 0.58, 0.22, 1.0) -- Warm tactical brass on hold
	local normal_btn_color = vmath.vector4(0.20, 0.23, 0.26, 1.0) -- Graphite steel plate`;

content = content.replace(oldBtnColors, newBtnColors);

// 3. Add update_fighter_badges helper function right before update(self, dt)
const badgeFunction = `local function update_fighter_badges(self, dt)
	self.badge_timer = (self.badge_timer or 0) + dt
	local is_ru = (i18n.current_lang == "ru")

	local p = game_state.active_potato
	local mp = gui.get_node("marker_player_bg")
	local me = gui.get_node("marker_enemy_bg")

	local is_active_game = (game_state.state == constants.STATE_TURN_ACTIVE or game_state.state == constants.STATE_ACTION)

	if not is_active_game or not p or not p.is_alive then
		gui.set_enabled(mp, false)
		gui.set_enabled(me, false)
		return
	end

	local sx, sy = camera_controller.world_to_screen(p.pos.x, p.pos.y)
	if sx < 20 or sx > 940 or sy < 20 or sy > 520 then
		gui.set_enabled(mp, false)
		gui.set_enabled(me, false)
		return
	end

	local bounce_y = math.sin(self.badge_timer * 4.5) * 3.0
	local arrow_pulse = 14 + math.sin(self.badge_timer * 6.0) * 2.5
	local hp = p.hp or 100
	local max_hp = p.max_hp or 100
	local hp_pct = math.max(0.01, math.min(1.0, hp / max_hp))

	if p.team == constants.TEAM_BLUE then
		-- Active Player Fighter: neat plate + name + micro HP + Cyan pulse triangle
		gui.set_enabled(mp, true)
		gui.set_enabled(me, false)
		gui.set_position(mp, vmath.vector3(sx, sy + 34 + bounce_y, 0))

		local name_text = p.name or (is_ru and "ТЫ" or "YOU")
		gui.set_text(gui.get_node("marker_player_text"), name_text)
		gui.set_scale(gui.get_node("marker_player_hp_fill"), vmath.vector3(hp_pct, 1.0, 1.0))
		gui.set_position(gui.get_node("marker_player_arrow"), vmath.vector3(0, arrow_pulse, 0.1))
	else
		-- Active Enemy Fighter: neat plate + name + micro HP + Coral pulse triangle
		gui.set_enabled(me, true)
		gui.set_enabled(mp, false)
		gui.set_position(me, vmath.vector3(sx, sy + 34 + bounce_y, 0))

		local name_text = p.name or (is_ru and "ВРАГ" or "ENEMY")
		gui.set_text(gui.get_node("marker_enemy_text"), name_text)
		gui.set_scale(gui.get_node("marker_enemy_hp_fill"), vmath.vector3(hp_pct, 1.0, 1.0))
		gui.set_position(gui.get_node("marker_enemy_arrow"), vmath.vector3(0, arrow_pulse, 0.1))
	end
end

`;

const updateFuncStart = 'function update(self, dt)\n\tself.ui:update(dt)';
content = content.replace(updateFuncStart, badgeFunction + updateFuncStart);

// 4. In update(self, dt), call update_fighter_badges(self, dt)
content = content.replace(
  'update_squad_widget(self)',
  'update_squad_widget(self)\n\t\tupdate_fighter_badges(self, dt)'
);

// 5. Remove the old tutorial marker logic inside should_show_hand to avoid conflicts
const oldTutorialMarkers = `\t\t\t\t-- Render floating "YOU / ТЫ" marker above player
				pcall(function()
					local mp = gui.get_node("marker_player_bg")
					local mp_txt = gui.get_node("marker_player_text")
					local bounce_y = math.sin(self.tutorial_hand_timer * 4.0) * 4.0
					if sx >= 20 and sx <= 940 and sy >= 20 and sy <= 520 then
						gui.set_enabled(mp, true)
						gui.set_position(mp, vmath.vector3(sx, sy + 38 + bounce_y, 0))
						gui.set_text(mp_txt, is_ru and "ТЫ ⬇" or "YOU ⬇")
					else
						gui.set_enabled(mp, false)
					end
				end)

				-- Render floating "ENEMY / ВРАГ" marker above enemy
				pcall(function()
					local me = gui.get_node("marker_enemy_bg")
					local me_txt = gui.get_node("marker_enemy_text")
					for _, ep in ipairs(game_state.potatoes) do
						if ep.is_alive and ep.team ~= constants.TEAM_BLUE then
							local esx, esy = camera_controller.world_to_screen(ep.pos.x, ep.pos.y)
							local ebounce_y = math.sin(self.tutorial_hand_timer * 4.0 + 1.57) * 4.0
							if esx >= 20 and esx <= 940 and esy >= 20 and esy <= 520 then
								gui.set_enabled(me, true)
								gui.set_position(me, vmath.vector3(esx, esy + 38 + ebounce_y, 0))
								gui.set_text(me_txt, is_ru and "ВРАГ 🎯" or "ENEMY 🎯")
							else
								gui.set_enabled(me, false)
							end
							break
						end
					end
				end)`;

if (content.includes(oldTutorialMarkers)) {
  content = content.replace(oldTutorialMarkers, '-- (Floating fighter badges are handled by update_fighter_badges)');
  console.log('Old tutorial marker logic cleaned up!');
}

// 6. In update(self, dt) tc_node: hide [A W D] buttons on PC, show only on mobile touch
const oldTcEnabled = 'gui.set_enabled(tc_node, is_player_turn)';
const newTcEnabled = 'gui.set_enabled(tc_node, is_player_turn and self.is_touch_screen)';

content = content.replace(oldTcEnabled, newTcEnabled);

// 7. In on_input(self, action_id, action): set is_touch_screen if touch arrived
const oldOnInput = 'function on_input(self, action_id, action)';
const newOnInput = `function on_input(self, action_id, action)
	if action_id == hash("touch_multi") then
		self.is_touch_screen = true
	end`;

content = content.replace(oldOnInput, newOnInput);

if (isCRLF) {
  content = content.replace(/\n/g, '\r\n');
}

fs.writeFileSync(path, content, 'utf8');
console.log('hud.gui_script updated successfully!');
