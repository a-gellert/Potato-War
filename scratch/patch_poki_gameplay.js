const fs = require('fs');
const path = require('path');

function patchFile(relPath, transforms) {
    const fullPath = path.resolve(__dirname, '..', relPath);
    let content = fs.readFileSync(fullPath, 'utf8');
    const originalLineEnding = content.includes('\r\n') ? '\r\n' : '\n';
    
    // Normalize to \n for matching, but maintain structure
    let normalized = content.replace(/\r\n/g, '\n');
    
    for (const [target, replacement] of transforms) {
        const normTarget = target.replace(/\r\n/g, '\n');
        const normReplacement = replacement.replace(/\r\n/g, '\n');
        if (!normalized.includes(normTarget)) {
            console.error(`Target not found in ${relPath}:\n${normTarget.slice(0, 80)}...`);
            process.exit(1);
        }
        normalized = normalized.replace(normTarget, normReplacement);
    }
    
    if (originalLineEnding === '\r\n') {
        normalized = normalized.replace(/\n/g, '\r\n');
    }
    
    fs.writeFileSync(fullPath, normalized, 'utf8');
    console.log(`Successfully patched ${relPath}`);
}

// 2. main/main.script
patchFile('main/main.script', [
    [
`	local is_tutorial = (mode == constants.MODE_TUTORIAL) or (game_state.mode == constants.MODE_TUTORIAL)
	if is_tutorial then
		game_state.gameplay_started = false
	end`,
`	local is_tutorial = (mode == constants.MODE_TUTORIAL) or (game_state.mode == constants.MODE_TUTORIAL)`
    ],
    [
`	if self.intro_flyover and (action.pressed or (action_id == hash("touch") and action.pressed)) then
		self.intro_flyover = false
		if game_state.active_potato and game_state.active_potato.is_alive then
			camera_controller.follow(game_state.active_potato.pos.x, game_state.active_potato.pos.y, true)
		end
		camera_controller.set_zoom(1.0)
	end

	if game_state.mode == constants.MODE_TUTORIAL and not game_state.gameplay_started then
		if action.pressed or (action_id == hash("touch") and action.pressed) then
			game_state.gameplay_started = true
			game_state.poki_gameplay_start()
		end
	end`,
`	-- Skip flyover on any press
	if self.intro_flyover and (action.pressed or (action_id == hash("touch") and action.pressed)) then
		self.intro_flyover = false
		if game_state.active_potato and game_state.active_potato.is_alive then
			camera_controller.follow(game_state.active_potato.pos.x, game_state.active_potato.pos.y, true)
		end
		camera_controller.set_zoom(1.0)
		game_state.skip_intro()
		game_state.poki_gameplay_start()
	end

	-- Universal first interaction trigger for Poki SDK across all modes (campaign, PvP, bot, tutorial)
	if game_state.state ~= constants.STATE_MENU and game_state.state ~= constants.STATE_CARD_SELECT and game_state.state ~= constants.STATE_GAME_OVER then
		if action.pressed or (action_id == hash("touch") and action.pressed) then
			game_state.poki_gameplay_start()
		end
	end`
    ],
    [
`	elseif message_id == hash("show_menu") then
		self.victory_celebration = false`,
`	elseif message_id == hash("show_menu") then
		game_state.poki_gameplay_stop()
		self.victory_celebration = false`
    ],
    [
`	elseif message_id == hash("show_campaign_map") then
		self.victory_celebration = false`,
`	elseif message_id == hash("show_campaign_map") then
		game_state.poki_gameplay_stop()
		self.victory_celebration = false`
    ],
    [
`	elseif message_id == hash("player_move_state") then
		if game_state.mode == constants.MODE_TUTORIAL and not game_state.gameplay_started then
			game_state.gameplay_started = true
			game_state.poki_gameplay_start()
		end
		self.touch_move_dir = message.dir or 0
		self.touch_move_timer = (self.touch_move_dir ~= 0) and 0.25 or 0

	elseif message_id == hash("player_move") then
		if game_state.mode == constants.MODE_TUTORIAL and not game_state.gameplay_started then
			game_state.gameplay_started = true
			game_state.poki_gameplay_start()
		end
		self.touch_move_dir = message.dir or 0
		self.touch_move_timer = (self.touch_move_dir ~= 0) and 0.25 or 0

	elseif message_id == hash("player_jump") then
		if game_state.mode == constants.MODE_TUTORIAL and not game_state.gameplay_started then
			game_state.gameplay_started = true
			game_state.poki_gameplay_start()
		end`,
`	elseif message_id == hash("player_move_state") then
		game_state.poki_gameplay_start()
		self.touch_move_dir = message.dir or 0
		self.touch_move_timer = (self.touch_move_dir ~= 0) and 0.25 or 0

	elseif message_id == hash("player_move") then
		game_state.poki_gameplay_start()
		self.touch_move_dir = message.dir or 0
		self.touch_move_timer = (self.touch_move_dir ~= 0) and 0.25 or 0

	elseif message_id == hash("player_jump") then
		game_state.poki_gameplay_start()`,
    ]
]);

// 3. main/entities/aim_guide/aim_guide.script
patchFile('main/entities/aim_guide/aim_guide.script', [
    [
`			if game_state.mode == constants.MODE_TUTORIAL and not game_state.gameplay_started then
				game_state.gameplay_started = true
				game_state.poki_gameplay_start()
			end`,
`			game_state.poki_gameplay_start()`
    ]
]);
