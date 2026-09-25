-- lua_modules/sound_manager.lua
-- Central sound manager for Potato War audio effects

local M = {}

function M.play_click()
	pcall(function()
		sound.play("/main#sound_click")
	end)
end

function M.play_shot()
	pcall(function()
		sound.play("/main#sound_shot")
	end)
end

function M.play_explosion()
	pcall(function()
		sound.play("/main#sound_explosion")
	end)
end

function M.play_heal()
	pcall(function()
		sound.play("/main#sound_heal")
	end)
end

return M
