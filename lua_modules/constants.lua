-- lua_modules/constants.lua
-- Global game configuration and constants for Potato War

local M = {}

-- Screen & World configuration (Landscape 960x540 viewport)
M.SCREEN_WIDTH = 960
M.SCREEN_HEIGHT = 540
M.WORLD_WIDTH = 1920 -- Expanded 1920 world width for full camera tracking
M.PVP_WORLD_WIDTH = 1920
M.WORLD_HEIGHT = 960 -- Expanded 960 world height for true Worms Armageddon vertical gameplay!
M.WATER_LEVEL = 28

-- Terrain Grid Configuration
M.TERRAIN_WIDTH = 960 -- Expanded grid width (960 * 2.0 = 1920 world width)
M.PVP_TERRAIN_WIDTH = 960
M.TERRAIN_HEIGHT = 480 -- Expanded grid height (480 * 2.0 = 960 world height)
M.TERRAIN_SCALE = 2.0 -- 1 terrain cell = 2x2 world pixels

function M.get_world_width(mode)
	return 1920
end

function M.get_terrain_width(mode)
	return 960
end

-- Turn & Match rules
M.TURN_DURATION = 20.0 -- 20 seconds per turn
M.SETTLE_TIMEOUT = 3.5 -- Physics settle timeout (balanced for Poki playtime)

-- Physics
M.GRAVITY = 460.0
M.POTATO_RADIUS = 12.0
M.POTATO_WALK_SPEED = 75.0
M.POTATO_JUMP_IMPULSE = 190.0
M.MAX_FALL_SPEED = 600.0
M.PLAYER_HP = 100

-- Teams
M.TEAM_BLUE = 1
M.TEAM_RED = 2

M.TEAM_NAMES = {
	[M.TEAM_BLUE] = "Картошка (Синие)",
	[M.TEAM_RED] = "Картошка (Красные)",
}

M.TEAM_COLORS = {
	[M.TEAM_BLUE] = vmath.vector4(0.18, 0.55, 0.90, 1.0),
	[M.TEAM_RED] = vmath.vector4(0.95, 0.25, 0.20, 1.0),
}

-- Game Modes
M.MODE_CAMPAIGN = "campaign"
M.MODE_QUICK_BOT = "quick_bot"
M.MODE_QUICK_PVP = "quick_pvp"
M.MODE_PVP_BOTS = "pvp_bots"

-- Game States
M.STATE_MENU = "menu"
M.STATE_INTRO = "intro"
M.STATE_CARD_SELECT = "card_select"
M.STATE_TURN_ACTIVE = "turn_active"
M.STATE_ACTION = "action"
M.STATE_SETTLING = "settling"
M.STATE_GAME_OVER = "game_over"

function M.log(...)
	local parts = { ... }
	for i = 1, #parts do
		parts[i] = tostring(parts[i])
	end
	local str = table.concat(parts, " ")
	print(str)
	local f = io.open("C:/Users/gellert.alexandr/Desktop/D_Projects/Potato War/game_debug.log", "a")
	if f then
		f:write(str .. "\n")
		f:close()
	end
end

return M
