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
function M.music(name)
	if name == current_music then
		return
	end
	if current_music then
		pcall(sound.stop, AUDIO_GO .. current_music)
	end
	current_music = name
	if name then
		pcall(sound.play, AUDIO_GO .. name, { gain = 1.0 })
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

return M
