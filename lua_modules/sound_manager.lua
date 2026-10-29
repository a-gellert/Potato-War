-- lua_modules/sound_manager.lua
-- Sound effects and music. Sound components live on /audio (one per sample) and belong to the
-- "sfx" or "music" mixer group, so the volume settings only change group gains.

local player_profile = require("lua_modules.player_profile")

local M = {}

local AUDIO_GO = "/audio#"
local GROUP_SFX = hash("sfx")
local GROUP_MUSIC = hash("music")
local GROUP_MASTER = hash("master")

-- Gain per effect (pre-mixed so all samples sit at a similar loudness)
local SFX = {
	click = 0.7, pop = 0.6, whoosh = 0.5, coin = 0.6, coins = 0.7,
	star1 = 0.8, star2 = 0.8, star3 = 0.9, unlock = 0.9, win = 0.9, lose = 0.8,
	turn_player = 0.6, turn_enemy = 0.5, tick = 0.5, alarm = 0.7,
	shot_rocket = 0.8, shot_shotgun = 0.8, shot_sniper = 0.8, throw = 0.6, radio = 0.6,
	plane = 0.7, whistle = 0.5,
	explode_small = 0.8, explode_big = 1.0, explode_huge = 1.0, holy = 0.9,
	bounce = 0.5, fuse = 0.5, splash = 0.8, sizzle = 0.7,
	hurt = 0.8, death = 0.8, jump = 0.5, land = 0.4, step = 0.25,
	crate = 0.7, pickup = 0.8, heal = 0.7,
}

local MIN_GAP = 0.05 -- seconds between two plays of the same effect
local last_played = {}

local volume = { sfx = 1.0, music = 0.6 }
local ad_muted = false
local focus_muted = false
local current_music = nil
local initialized = false
local game_loaded = false
local pending_music = nil

-- Individual gains per track: battle music is kept quieter than menu music
local MUSIC_GAINS = {
	music_menu = 1.0,
	music_battle = 0.65,
	music_boss = 0.65,
}

local function apply_gains()
	local muted = ad_muted or focus_muted
	pcall(sound.set_group_gain, GROUP_MASTER, muted and 0 or 1)
	pcall(sound.set_group_gain, GROUP_SFX, volume.sfx)
	pcall(sound.set_group_gain, GROUP_MUSIC, volume.music)
end

-- Reads the saved volumes and mutes the game while the browser tab is in the background
function M.init()
	if initialized then
		return
	end
	initialized = true
	volume.sfx = player_profile.get_volume("sfx")
	volume.music = player_profile.get_volume("music")
	apply_gains()
	if window and window.set_listener then
		window.set_listener(function(_, event)
			if event == window.WINDOW_EVENT_FOCUS_LOST then
				focus_muted = true
				apply_gains()
			elseif event == window.WINDOW_EVENT_FOCUS_GAINED then
				focus_muted = false
				apply_gains()
			end
		end)
	end
end

-- kind: "sfx" | "music"; v: 0..1 (saved in the profile)
function M.set_volume(kind, v)
	volume[kind] = math.max(0, math.min(1, v))
	player_profile.set_volume(kind, volume[kind])
	apply_gains()
end

function M.get_volume(kind)
	return volume[kind]
end

-- Poki ads play their own audio: the game stays silent until the break is over
function M.set_ad_mute(muted)
	ad_muted = muted
	apply_gains()
end

-- opts: gain (multiplier), speed (playback rate), vary (random +/- speed spread), pan
function M.play(name, opts)
	local base = SFX[name]
	if not base then
		return
	end
	local now = socket and socket.gettime and socket.gettime() or os.clock()
	local t = last_played[name]
	if t and now - t < MIN_GAP then
		return
	end
	last_played[name] = now
	opts = opts or {}
	local speed = opts.speed or 1
	if opts.vary then
		speed = speed * (1 + (math.random() * 2 - 1) * opts.vary)
	end
	pcall(sound.play, AUDIO_GO .. name, { gain = base * (opts.gain or 1), speed = speed, pan = opts.pan or 0 })
end

-- Switches the looping music track (nil stops the music)
-- If the main game has not finished loading yet, queues the track to play when ready
function M.music(name)
	if not game_loaded then
		pending_music = name
		return
	end
	if name == current_music then
		return
	end
	if current_music then
		pcall(sound.stop, AUDIO_GO .. current_music)
	end
	current_music = name
	if name then
		local track_gain = MUSIC_GAINS[name] or 1.0
		pcall(sound.play, AUDIO_GO .. name, { gain = track_gain })
	end
end

-- Called after the main game has loaded (boot loader finished) to start queued background music
function M.on_game_loaded()
	if game_loaded then
		return
	end
	game_loaded = true
	if pending_music then
		local track = pending_music
		pending_music = nil
		M.music(track)
	end
end

function M.is_game_loaded()
	return game_loaded
end

function M.pause_all()
	if current_music then
		pcall(sound.stop, AUDIO_GO .. current_music)
	end
end

function M.resume_all()
	if game_loaded and current_music then
		local track_gain = MUSIC_GAINS[current_music] or 1.0
		pcall(sound.play, AUDIO_GO .. current_music, { gain = track_gain })
	end
end

-- Explosion sound picked by blast size
function M.play_explosion(radius)
	radius = radius or 36
	if radius >= 70 then
		M.play("explode_huge", { vary = 0.05 })
	elseif radius >= 34 then
		M.play("explode_big", { vary = 0.08 })
	else
		M.play("explode_small", { vary = 0.12 })
	end
end

function M.play_click()
	M.play("click")
end

function M.play_shot()
	M.play("throw", { vary = 0.08 })
end

function M.play_heal()
	M.play("heal")
end

-- Enemy counter-attack alarm
function M.play_siren()
	M.play("alarm")
end

-- Sector flag captured / liberated
function M.play_flag_captured()
	M.play("unlock")
end

function M.play_victory_march()
	M.play("win")
end

function M.play_defeat_accent()
	M.play("lose")
end

-- Fortification / bunker reinforced
function M.play_fortify()
	M.play("crate")
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
