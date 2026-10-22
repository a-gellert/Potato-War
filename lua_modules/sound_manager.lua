-- lua_modules/sound_manager.lua
-- Central sound manager for Potato War audio effects
-- Includes tactical audio cues: Siren alarm, Flag captured, Victory march, Defeat accent, Fortify

local M = {}

function M.play_click()
	pcall(function()
		sound.play("/main#sound_click", { gain = 0.8, speed = 1.0 })
	end)
end

function M.play_shot()
	pcall(function()
		sound.play("/main#sound_shot", { gain = 0.9, speed = 1.0 })
	end)
end

function M.play_explosion()
	pcall(function()
		sound.play("/main#sound_explosion", { gain = 1.0, speed = 1.0 })
	end)
end

function M.play_heal()
	pcall(function()
		sound.play("/main#sound_heal", { gain = 0.85, speed = 1.0 })
	end)
end

-- Sound effect: Enemy counter-attack alarm siren
function M.play_siren()
	pcall(function()
		-- Pulse alarm using multi-tone alert
		sound.play("/main#sound_shot", { gain = 0.7, speed = 0.6 })
		timer.delay(0.18, false, function()
			sound.play("/main#sound_heal", { gain = 0.8, speed = 0.5 })
		end)
		timer.delay(0.36, false, function()
			sound.play("/main#sound_shot", { gain = 0.7, speed = 0.65 })
		end)
	end)
end

-- Sound effect: Sector flag captured / liberated
function M.play_flag_captured()
	pcall(function()
		sound.play("/main#sound_heal", { gain = 1.0, speed = 1.25 })
		timer.delay(0.15, false, function()
			sound.play("/main#sound_heal", { gain = 0.9, speed = 1.6 })
		end)
	end)
end

-- Sound effect: Victory march accent
function M.play_victory_march()
	pcall(function()
		sound.play("/main#sound_heal", { gain = 1.0, speed = 1.2 })
		timer.delay(0.16, false, function()
			sound.play("/main#sound_heal", { gain = 1.0, speed = 1.5 })
		end)
		timer.delay(0.32, false, function()
			sound.play("/main#sound_heal", { gain = 1.1, speed = 1.8 })
		end)
	end)
end

-- Sound effect: Defeat accent
function M.play_defeat_accent()
	pcall(function()
		sound.play("/main#sound_explosion", { gain = 0.85, speed = 0.45 })
		timer.delay(0.25, false, function()
			sound.play("/main#sound_shot", { gain = 0.6, speed = 0.35 })
		end)
	end)
end

-- Sound effect: Fortification / bunker reinforced
function M.play_fortify()
	pcall(function()
		sound.play("/main#sound_click", { gain = 1.0, speed = 0.8 })
		timer.delay(0.08, false, function()
			sound.play("/main#sound_click", { gain = 1.0, speed = 1.1 })
		end)
	end)
end

-- Sound effect: Rubber spud bounce & squash "плюх" / "боинг"
function M.play_plop(gain_mult)
	pcall(function()
		local g = (gain_mult or 1.0) * 0.95
		local spd = 1.6 + (math.random() - 0.5) * 0.3
		sound.play("/main#sound_heal", { gain = g, speed = spd })
		timer.delay(0.04, false, function()
			sound.play("/main#sound_click", { gain = g * 0.7, speed = spd * 1.3 })
		end)
	end)
end

-- Sound effect: Descending whistle tone for airdrop parachute crate
function M.play_whistle_fall()
	pcall(function()
		sound.play("/main#sound_heal", { gain = 0.85, speed = 2.2 })
		timer.delay(0.12, false, function()
			sound.play("/main#sound_heal", { gain = 0.85, speed = 1.7 })
		end)
		timer.delay(0.24, false, function()
			sound.play("/main#sound_heal", { gain = 0.80, speed = 1.25 })
		end)
	end)
end

-- Sound effect: Loud sizzling oil in deep fryer
function M.play_fry_sizzle()
	pcall(function()
		sound.play("/main#sound_explosion", { gain = 0.75, speed = 2.4 })
		sound.play("/main#sound_shot", { gain = 0.85, speed = 2.6 })
		for i = 1, 4 do
			timer.delay(i * 0.05, false, function()
				local spd = 2.0 + math.random() * 0.8
				sound.play("/main#sound_click", { gain = 0.9, speed = spd })
			end)
		end
	end)
end

-- Sound effect: Whistle & deep fryer sizzle when falling into the fryer oil
function M.play_fry_whistle()
	M.play_fry_sizzle()
	pcall(function()
		-- Ascending cartoon whistle tone
		sound.play("/main#sound_heal", { gain = 0.9, speed = 1.4 })
		timer.delay(0.12, false, function()
			sound.play("/main#sound_heal", { gain = 1.0, speed = 2.0 })
		end)
		timer.delay(0.24, false, function()
			sound.play("/main#sound_shot", { gain = 0.8, speed = 2.4 })
			sound.play("/main#sound_explosion", { gain = 0.7, speed = 2.2 })
		end)
	end)
end

-- Sound effect: Falling airdrop parachute whistle
function M.play_airdrop_whistle()
	pcall(function()
		-- Descending airdrop falling whistle tone
		sound.play("/main#sound_heal", { gain = 0.85, speed = 1.9 })
		timer.delay(0.09, false, function()
			sound.play("/main#sound_heal", { gain = 0.9, speed = 1.6 })
		end)
		timer.delay(0.18, false, function()
			sound.play("/main#sound_heal", { gain = 0.95, speed = 1.3 })
		end)
		timer.delay(0.27, false, function()
			sound.play("/main#sound_heal", { gain = 0.9, speed = 1.0 })
		end)
	end)
end

return M
