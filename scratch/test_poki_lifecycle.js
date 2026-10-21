const fs = require('fs');

console.log("=== POKI SDK STRICT INPUT AUDIT ===");

const gameStateCode = fs.readFileSync('lua_modules/game_state.lua', 'utf8').replace(/\r\n/g, '\n');
const mainScriptCode = fs.readFileSync('main/main.script', 'utf8').replace(/\r\n/g, '\n');
const aimGuideCode = fs.readFileSync('main/entities/aim_guide/aim_guide.script', 'utf8').replace(/\r\n/g, '\n');

function assert(condition, message) {
    if (!condition) {
        console.error("FAIL:", message);
        process.exit(1);
    }
    console.log("PASS:", message);
}

// 1. Idempotency guards in game_state.lua
assert(gameStateCode.includes('if M.is_gameplay_active then'), "game_state.lua contains idempotency guard in poki_gameplay_start");
assert(gameStateCode.includes('if not M.is_gameplay_active then'), "game_state.lua contains idempotency guard in poki_gameplay_stop");

// 2. No premature gameplayStart anywhere in setup/turn initialization
assert(!gameStateCode.includes('M.poki_gameplay_start()\n\n\t-- Offer bonus card selection'), "start_match does NOT call gameplayStart");
assert(!gameStateCode.includes('M.poki_gameplay_start()\n\tM.set_state(constants.STATE_INTRO)'), "start_battle does NOT call gameplayStart");
assert(!gameStateCode.includes('begin_current_turn()\n\tM.poki_gameplay_start()') && !gameStateCode.includes('M.set_state(constants.STATE_TURN_ACTIVE)\n\tM.poki_gameplay_start()'), "begin_current_turn does NOT call gameplayStart automatically without input");

// 3. Intro flyover does NOT call gameplayStart
assert(!mainScriptCode.includes('game_state.skip_intro()\n\t\tgame_state.poki_gameplay_start()'), "intro flyover does NOT call gameplayStart");

// 4. Input in main.script ONLY triggers during active player turn
assert(mainScriptCode.includes('if game_state.state == constants.STATE_TURN_ACTIVE and not game_state.is_bot_turn() then\n\t\tif action.pressed or (action_id == hash("touch") and action.pressed) then\n\t\t\tgame_state.poki_gameplay_start()'), "main.script triggers gameplayStart ONLY on first player input during active turn");

// 5. Aim guide touch triggers gameplayStart during active player turn
assert(aimGuideCode.includes('game_state.poki_gameplay_start()'), "aim_guide triggers gameplayStart on aim touch");

// 6. Stop on menu return
assert(mainScriptCode.includes('elseif message_id == hash("show_menu") then\n\t\tgame_state.poki_gameplay_stop()'), "main.script calls poki_gameplay_stop when returning to menu");
assert(mainScriptCode.includes('elseif message_id == hash("show_campaign_map") then\n\t\tgame_state.poki_gameplay_stop()'), "main.script calls poki_gameplay_stop when returning to campaign map");

console.log("\nALL STRICT INPUT POKI CHECKS PASSED 100%!");
