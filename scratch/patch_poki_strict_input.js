const fs = require('fs');
const path = require('path');

function patchFile(relPath, transforms) {
    const fullPath = path.resolve(__dirname, '..', relPath);
    let content = fs.readFileSync(fullPath, 'utf8');
    const isCrlf = content.includes('\r\n');
    let normalized = content.replace(/\r\n/g, '\n');

    for (const [target, replacement] of transforms) {
        const normTarget = target.replace(/\r\n/g, '\n');
        const normReplacement = replacement.replace(/\r\n/g, '\n');
        if (!normalized.includes(normTarget)) {
            console.error(`Target not found in ${relPath}:\n${normTarget.slice(0, 100)}...`);
            process.exit(1);
        }
        normalized = normalized.replace(normTarget, normReplacement);
    }

    if (isCrlf) {
        normalized = normalized.replace(/\n/g, '\r\n');
    }

    fs.writeFileSync(fullPath, normalized, 'utf8');
    console.log(`Successfully patched ${relPath}`);
}

// 1. lua_modules/game_state.lua - Remove poki_gameplay_start from begin_current_turn
patchFile('lua_modules/game_state.lua', [
    [
`	M.set_state(constants.STATE_TURN_ACTIVE)
	M.poki_gameplay_start()
end`,
`	M.set_state(constants.STATE_TURN_ACTIVE)
end`
    ]
]);

// 2. main/main.script - Ensure poki_gameplay_start ONLY triggers on active player input
patchFile('main/main.script', [
    [
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
	end`,
`	-- Skip flyover on any press
	if self.intro_flyover and (action.pressed or (action_id == hash("touch") and action.pressed)) then
		self.intro_flyover = false
		if game_state.active_potato and game_state.active_potato.is_alive then
			camera_controller.follow(game_state.active_potato.pos.x, game_state.active_potato.pos.y, true)
		end
		camera_controller.set_zoom(1.0)
		game_state.skip_intro()
	end

	-- Trigger poki gameplay_start ONLY on player's first active gameplay input
	if game_state.state == constants.STATE_TURN_ACTIVE and not game_state.is_bot_turn() then
		if action.pressed or (action_id == hash("touch") and action.pressed) then
			game_state.poki_gameplay_start()
		end
	end`
    ],
    [
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
`	elseif message_id == hash("player_move_state") then
		if game_state.state == constants.STATE_TURN_ACTIVE and not game_state.is_bot_turn() then
			game_state.poki_gameplay_start()
		end
		self.touch_move_dir = message.dir or 0
		self.touch_move_timer = (self.touch_move_dir ~= 0) and 0.25 or 0

	elseif message_id == hash("player_move") then
		if game_state.state == constants.STATE_TURN_ACTIVE and not game_state.is_bot_turn() then
			game_state.poki_gameplay_start()
		end
		self.touch_move_dir = message.dir or 0
		self.touch_move_timer = (self.touch_move_dir ~= 0) and 0.25 or 0

	elseif message_id == hash("player_jump") then
		if game_state.state == constants.STATE_TURN_ACTIVE and not game_state.is_bot_turn() then
			game_state.poki_gameplay_start()
		end`
    ]
]);
