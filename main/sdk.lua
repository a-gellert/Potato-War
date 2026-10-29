-- main/sdk.lua
-- Unified SDK Wrapper: Playgama Bridge SDK (HTML5/Web & Desktop Mock), Poki SDK, & Mobile/AppLovin MAX

local mobile_ads_ok, mobile_ads = pcall(require, "main.applovin_ads")
if not mobile_ads_ok or type(mobile_ads) ~= "table" then
	mobile_ads = {
		init = function() end,
		is_supported = function() return false end,
		show_interstitial = function() return false end,
		show_rewarded = function() return false end,
		show_banner = function() end,
		hide_banner = function() end,
	}
end

local gameanalytics_ok, gameanalytics = pcall(require, "main.gameanalytics")
if not gameanalytics_ok or type(gameanalytics) ~= "table" then
	gameanalytics = {
		init = function() end,
		start_progression = function() end,
		complete_progression = function() end,
		fail_progression = function() end,
		design_event = function() end,
		ad_event = function() end,
	}
end

local adjust_ok, adjust_module = pcall(require, "main.adjust")
if not adjust_ok or type(adjust_module) ~= "table" then
	adjust_module = {
		init = function() end,
		track_event = function() end,
	}
end

local facebook_ok, facebook_module = pcall(require, "main.facebook")
if not facebook_ok or type(facebook_module) ~= "table" then
	facebook_module = {
		init = function() end,
		log_event = function() end,
	}
end

local firebase_ok, firebase_analytics = pcall(require, "main.firebase_analytics")
if not firebase_ok or type(firebase_analytics) ~= "table" then
	firebase_analytics = {
		init = function() end,
		log_ad_impression = function() end,
		log_event = function() end,
	}
end

local M = {}
M.mobile_ads = mobile_ads
M.unityads = mobile_ads -- Backwards compatibility alias
M.admob = mobile_ads -- Backwards compatibility alias
M.gameanalytics = gameanalytics
M.ga = gameanalytics
M.adjust = adjust_module
M.facebook = facebook_module
M.fb = facebook_module
M.firebase = firebase_analytics

----------------------------------------------------------
-- PLATFORM TYPES
----------------------------------------------------------
M.PLATFORM_PLAYGAMA = "playgama"
M.PLATFORM_ANDROID  = "android"
M.PLATFORM_POKI     = "poki"
M.PLATFORM_MOCK     = "mock"

----------------------------------------------------------
-- STATE
----------------------------------------------------------
M.initialized = false
M.game_ready_sent = false
M.ad_showing = false
M.banner_showing = false
M.gameplay_active = false
M.current_round = 1
M.active_platform = M.PLATFORM_MOCK
M.platform_audio_enabled = true
M.platform_paused = false
M.tab_hidden = false
M.last_interstitial_time = os.time()  -- timestamp of last interstitial shown (os.time), initialized on start for grace period
M.has_poki = false
M.has_playgama = false
M.match_count = 0

-- Minimum seconds between interstitial ads (120 seconds)
local AD_COOLDOWN = 120
local resume_gameplay_after_ad = false

-- Bridge reference (Playgama)
local bridge = nil

-- Ad callbacks for Playgama
local current_interstitial_cb = nil
local current_reward_cb = nil
local current_reward_close_cb = nil
local reward_granted = false
local reward_timeout_timer = nil

local function safe_timer_delay(delay_sec, repeating, cb)
	local ok, handle = pcall(timer.delay, delay_sec, repeating, cb)
	if ok then return handle end
	return nil
end

local function safe_timer_cancel(handle)
	if handle then
		pcall(timer.cancel, handle)
	end
end

----------------------------------------------------------
-- LOGGING & PLATFORM DETECTION
----------------------------------------------------------
local function log(...)
	print("[SDK WRAPPER]", ...)
	if html5 and html5.run then
		local parts = {}
		local n = select("#", ...)
		for i = 1, n do
			table.insert(parts, tostring(select(i, ...)))
		end
		local msg = table.concat(parts, " ")
		msg = msg:gsub("\\", "\\\\"):gsub("'", "\\'"):gsub("\n", " "):gsub("\r", "")
		local js = "console.log('%c[SDK WRAPPER]', 'color: #00bcd4; font-weight: bold;', '" .. msg .. "');"
		pcall(html5.run, js)
	end
end

function M.get_platform_id()
	if bridge and bridge.platform and bridge.platform.id then
		local ok, pid = pcall(bridge.platform.id)
		if ok and pid and pid ~= "" then
			return tostring(pid)
		end
	end
	if html5 and html5.run then
		local ok, pid = pcall(html5.run, "(function() { var b = window.bridge || window.playgamaBridge; return (b && b.platform && (typeof b.platform.id === 'function' ? b.platform.id() : b.platform.id)) || ''; })()")
		if ok and pid and pid ~= "" then
			return tostring(pid)
		end
	end
	if M.active_platform == M.PLATFORM_ANDROID then
		return "android"
	elseif M.active_platform == M.PLATFORM_POKI then
		return "poki"
	end
	return "mock"
end

local function parse_state_arg(arg1, arg2)
	if type(arg2) == "string" then return arg2 end
	if type(arg1) == "string" then return arg1 end
	if arg2 ~= nil then return tostring(arg2) end
	if arg1 ~= nil then return tostring(arg1) end
	return ""
end

local function parse_bool_arg(arg1, arg2, default_val)
	if type(arg2) == "boolean" then return arg2 end
	if type(arg1) == "boolean" then return arg1 end
	if arg2 == "true" or arg2 == "1" or arg2 == 1 then return true end
	if arg2 == "false" or arg2 == "0" or arg2 == 0 then return false end
	if arg1 == "true" or arg1 == "1" or arg1 == 1 then return true end
	if arg1 == "false" or arg1 == "0" or arg1 == 0 then return false end
	return default_val
end

----------------------------------------------------------
-- AUDIO / GAMEPLAY PAUSE HELPERS
----------------------------------------------------------
local function pause_audio()
	log("🔇 Pausing/muting game audio")

	-- 1. Defold Sound Groups Gain (master, music, sfx)
	pcall(sound.set_group_gain, hash("master"), 0)
	pcall(sound.set_group_gain, "master", 0)
	pcall(sound.set_group_gain, hash("music"), 0)
	pcall(sound.set_group_gain, "music", 0)
	pcall(sound.set_group_gain, hash("sfx"), 0)
	pcall(sound.set_group_gain, "sfx", 0)

	-- 2. Stop music via sound / sound_manager module if present
	local snd_ok, snd = pcall(require, "main.sound")
	if snd_ok and snd then
		snd.current_sfx_volume = 0
		snd.current_music_volume = 0
		if snd.stop_music then
			pcall(snd.stop_music)
		end
	end
	local sm_ok, sm = pcall(require, "lua_modules.sound_manager")
	if sm_ok and sm and sm.pause_all then
		pcall(sm.pause_all)
	end

	-- 3. Web Audio Context suspend + HTML5 media mute (Web/HTML5)
	if html5 and html5.run then
		pcall(html5.run, [[
			(function() {
				if (window._syncAudio) {
					window._syncAudio(true);
				} else {
					try {
						if (window._dmJSDeviceShared && window._dmJSDeviceShared.audioCtx && window._dmJSDeviceShared.audioCtx.state === 'running') {
							window._dmJSDeviceShared.audioCtx.suspend().catch(function(){});
						}
						if (window._allAudioContexts && window._allAudioContexts.length) {
							for (var i = 0; i < window._allAudioContexts.length; i++) {
								var c = window._allAudioContexts[i];
								if (c && c.state === 'running') c.suspend().catch(function(){});
							}
						}
						var ctx = (window.AL && window.AL.currentContext && window.AL.currentContext.audioCtx)
						       || window.webAudioCtx
						       || (window.AudioContext && window.AudioContext.instance);
						if (ctx && typeof ctx.suspend === 'function' && ctx.state === 'running') {
							ctx.suspend().catch(function(){});
						}
						var media = document.querySelectorAll('audio, video');
						for (var j = 0; j < media.length; j++) {
							if (!media[j].classList.contains('ad-element')) {
								media[j].muted = true;
							}
						}
					} catch(e) {}
				}
			})();
		]])
	end
end

local function resume_audio()
	if M.ad_showing or M.tab_hidden or M.platform_paused or (not M.platform_audio_enabled) then
		return
	end

	log("🔊 Restoring game audio")
	local state_ok, state = pcall(require, "main.state")
	local sfx_vol = (state_ok and state.sfx_volume) or 1.0
	local music_vol = (state_ok and state.music_volume) or 0.8

	-- 1. Defold Sound Groups Gain
	pcall(sound.set_group_gain, hash("master"), 1)
	pcall(sound.set_group_gain, "master", 1)
	pcall(sound.set_group_gain, hash("music"), music_vol)
	pcall(sound.set_group_gain, "music", music_vol)
	pcall(sound.set_group_gain, hash("sfx"), sfx_vol)
	pcall(sound.set_group_gain, "sfx", sfx_vol)

	-- 2. Restore sound module state if present
	local snd_ok, snd = pcall(require, "main.sound")
	if snd_ok and snd then
		snd.current_sfx_volume = sfx_vol
		snd.current_music_volume = music_vol
		if snd.play_music and music_vol > 0.001 then
			pcall(snd.play_music)
		end
	end
	local sm_ok, sm = pcall(require, "lua_modules.sound_manager")
	if sm_ok and sm and sm.resume_all then
		pcall(sm.resume_all)
	end

	-- 3. Web Audio Context resume (Web/HTML5)
	if html5 and html5.run then
		pcall(html5.run, [[
			(function() {
				if (window._syncAudio) {
					window._syncAudio(false);
				} else {
					try {
						if (window._dmJSDeviceShared && window._dmJSDeviceShared.audioCtx && window._dmJSDeviceShared.audioCtx.state === 'suspended') {
							var actx = window._dmJSDeviceShared.audioCtx;
							var resFn = actx._originalResume || actx.resume;
							resFn.call(actx).catch(function(){});
						}
						if (window._allAudioContexts && window._allAudioContexts.length) {
							for (var i = 0; i < window._allAudioContexts.length; i++) {
								var c = window._allAudioContexts[i];
								if (c && c.state === 'suspended') {
									var cRes = c._originalResume || c.resume;
									cRes.call(c).catch(function(){});
								}
							}
						}
						var ctx = (window.AL && window.AL.currentContext && window.AL.currentContext.audioCtx)
						       || window.webAudioCtx
						       || (window.AudioContext && window.AudioContext.instance);
						if (ctx && typeof ctx.resume === 'function' && ctx.state === 'suspended') {
							ctx.resume().catch(function(){});
						}
						var media = document.querySelectorAll('audio, video');
						for (var j = 0; j < media.length; j++) {
							media[j].muted = false;
						}
					} catch(e) {}
				}
			})();
		]])
	end
end

local function pause_gameplay()
	log("⏸️ Pausing gameplay (loop & audio)")
	M.platform_paused = true
	pause_audio()
	if html5 and html5.run then
		pcall(html5.run, [[
			(function() {
				if (window._pauseEngineLoop) {
					window._pauseEngineLoop();
				} else {
					try {
						var mod = (typeof Module !== 'undefined') ? Module : window.Module;
						if (mod) {
							if (typeof mod._dmEngineSetUpdateEnabled === 'function') mod._dmEngineSetUpdateEnabled(0);
							if (typeof mod._dmEngineSetRenderEnabled === 'function') mod._dmEngineSetRenderEnabled(0);
							if (typeof mod.pauseMainLoop === 'function') mod.pauseMainLoop();
						}
					} catch(e) {}
				}
			})();
		]])
	end
end

local function resume_gameplay()
	log("▶️ Resuming gameplay (loop & audio)")
	M.platform_paused = false
	if html5 and html5.run then
		pcall(html5.run, [[
			(function() {
				if (window._resumeEngineLoop) {
					window._resumeEngineLoop();
				} else {
					try {
						var mod = (typeof Module !== 'undefined') ? Module : window.Module;
						if (mod) {
							if (typeof mod._dmEngineSetUpdateEnabled === 'function') mod._dmEngineSetUpdateEnabled(1);
							if (typeof mod._dmEngineSetRenderEnabled === 'function') mod._dmEngineSetRenderEnabled(1);
							if (typeof mod.resumeMainLoop === 'function') mod.resumeMainLoop();
						}
					} catch(e) {}
				}
			})();
		]])
	end
	resume_audio()
end

function M.is_platform_paused()
	return M.platform_paused or M.tab_hidden or M.ad_showing
end

function M.is_platform_audio_enabled()
	return M.platform_audio_enabled
end

----------------------------------------------------------
-- PLAYGAMA BRIDGE SETUP & AD/PLATFORM LISTENERS
----------------------------------------------------------
local function setup_playgama_listeners()
	-- 1. Defold Lua Bridge Listeners
	if bridge then
		-- Interstitial listener
		if bridge.advertisement and bridge.advertisement.on then
			bridge.advertisement.on("interstitial_state_changed", function(arg1, arg2)
				local state = parse_state_arg(arg1, arg2)
				log("📺 Playgama interstitial_state_changed:", state)
				if state == "opened" or state == "loading" then
					if state == "opened" then
						M.ad_showing = true
						pause_audio()
					end
				elseif state == "closed" or state == "failed" then
					M.ad_showing = false
					resume_audio()
					if resume_gameplay_after_ad then
						resume_gameplay_after_ad = false
						M.gameplay_start()
					end
					if current_interstitial_cb then
						local cb = current_interstitial_cb
						current_interstitial_cb = nil
						cb()
					end
				end
			end)

			-- Rewarded listener
			bridge.advertisement.on("rewarded_state_changed", function(arg1, arg2)
				local state = parse_state_arg(arg1, arg2)
				log("🎁 Playgama rewarded_state_changed:", state)

				if state == "opened" or state == "loading" then
					if state == "opened" then
						M.ad_showing = true
						pause_audio()
						if reward_timeout_timer then
							safe_timer_cancel(reward_timeout_timer)
						end
						reward_timeout_timer = safe_timer_delay(120, false, function()
							reward_timeout_timer = nil
							if M.ad_showing or current_reward_cb or current_reward_close_cb then
								log("⏳ Rewarded ad response timed out while opened — resetting ad state")
								M.ad_showing = false
								resume_audio()
								if resume_gameplay_after_ad then
									resume_gameplay_after_ad = false
									M.gameplay_start()
								end
								local earned = reward_granted
								if html5 and html5.run then
									local ok_eval, res = pcall(html5.run, "(function() { return window._rewardedEarned ? '1' : '0'; })()")
									if ok_eval and res == "1" then earned = true end
								end
								if earned and current_reward_cb then
									local cb = current_reward_cb
									current_reward_cb = nil
									cb()
								end
								if current_reward_close_cb then
									local cb = current_reward_close_cb
									current_reward_close_cb = nil
									cb(earned)
								end
								current_reward_cb = nil
							end
						end)
					end
				elseif state == "rewarded" then
					if reward_timeout_timer then
						safe_timer_cancel(reward_timeout_timer)
						reward_timeout_timer = nil
					end
					reward_granted = true
					log("🎉 Rewarded state reached — granting reward")
					if current_reward_cb then
						local cb = current_reward_cb
						current_reward_cb = nil
						local ok_cb, cb_err = pcall(cb)
						if not ok_cb then
							log("⚠️ Error executing rewarded callback:", cb_err)
						end
					end
				elseif state == "closed" or state == "failed" then
					if reward_timeout_timer then
						safe_timer_cancel(reward_timeout_timer)
						reward_timeout_timer = nil
					end
					M.ad_showing = false
					resume_audio()
					if resume_gameplay_after_ad then
						resume_gameplay_after_ad = false
						M.gameplay_start()
					end

					if state == "failed" then
						local pid = M.get_platform_id()
						if pid == "mock" then
							log("🧪 Mock platform detected on localhost/preview: auto-completing rewarded ad for developer testing!")
							reward_granted = true
							if current_reward_cb then
								local cb = current_reward_cb
								current_reward_cb = nil
								local ok_cb, cb_err = pcall(cb)
								if not ok_cb then
									log("⚠️ Error executing rewarded callback:", cb_err)
								end
							end
							if current_reward_close_cb then
								local cb = current_reward_close_cb
								current_reward_close_cb = nil
								local ok_close, close_err = pcall(cb, true)
								if not ok_close then
									log("⚠️ Error executing rewarded close callback:", close_err)
								end
							end
							current_reward_cb = nil
							return
						else
							log("⚠️ Rewarded ad failed on platform:", pid)
						end
					end

					local earned = reward_granted
					if html5 and html5.run then
						local ok_eval, res = pcall(html5.run, "(function() { return window._rewardedEarned ? '1' : '0'; })()")
						if ok_eval and res == "1" then earned = true end
					end

					if earned and current_reward_cb then
						local cb = current_reward_cb
						current_reward_cb = nil
						local ok_cb, cb_err = pcall(cb)
						if not ok_cb then
							log("⚠️ Error executing rewarded callback:", cb_err)
						end
					end
					if current_reward_close_cb then
						local cb = current_reward_close_cb
						current_reward_close_cb = nil
						local ok_close, close_err = pcall(cb, earned)
						if not ok_close then
							log("⚠️ Error executing rewarded close callback:", close_err)
						end
					end
					current_reward_cb = nil
				end
			end)

			-- Banner listener
			bridge.advertisement.on("banner_state_changed", function(arg1, arg2)
				local state = parse_state_arg(arg1, arg2)
				log("🏷️ Playgama banner_state_changed:", state)
				M.banner_showing = (state == "shown")
			end)

			-- Advanced banners listener
			bridge.advertisement.on("advanced_banners_state_changed", function(arg1, arg2)
				local state = (arg2 ~= nil) and arg2 or arg1
				log("🏷️ Playgama advanced_banners_state_changed:", state)
			end)
		end

		-- 2. Visibility / Focus Listener
		if bridge.game and bridge.game.on then
			bridge.game.on("visibility_state_changed", function(arg1, arg2)
				local state = (arg2 ~= nil) and arg2 or arg1
				log("👁️ Playgama visibility_state_changed:", state)
				M.tab_hidden = (state == "hidden")
				if M.tab_hidden then
					pause_gameplay()
				else
					resume_gameplay()
				end
			end)
		end

		-- 3. Platform Audio & Pause Listeners (Playgama Bridge 2.x standard)
		if bridge.platform and bridge.platform.on then
			bridge.platform.on("audio_state_changed", function(arg1, arg2)
				local is_enabled = parse_bool_arg(arg1, arg2, true)
				log("🔊 Playgama audio_state_changed:", is_enabled)
				M.platform_audio_enabled = (is_enabled ~= false)
				if not M.platform_audio_enabled then
					pause_audio()
				else
					resume_audio()
				end
			end)

			bridge.platform.on("pause_state_changed", function(arg1, arg2)
				local is_paused = parse_bool_arg(arg1, arg2, false)
				log("⏸️ Playgama pause_state_changed:", is_paused)
				M.platform_paused = (is_paused == true)
				if M.platform_paused then
					pause_gameplay()
				else
					resume_gameplay()
				end
			end)
		end
	end

	-- 4. Browser JS Bridge Listeners & State Tracker (HTML5 Web)
	if html5 and html5.run then
		local js_listeners = [[
			(function() {
				var b = window.bridge || window.playgamaBridge;

				window._rewardedState = "idle";
				window._rewardedEarned = false;
				window._interstitialState = "idle";
				window._isAudioEnabled = (window._isAudioEnabled !== undefined ? window._isAudioEnabled : true);
				window._isPlatformPaused = (window._isPlatformPaused !== undefined ? window._isPlatformPaused : false);
				window._gameVisibilityState = (window._gameVisibilityState || (document.hidden ? "hidden" : "visible"));
				window._isEngineLoopPaused = (window._isEngineLoopPaused !== undefined ? window._isEngineLoopPaused : false);
				window._allAudioContexts = window._allAudioContexts || [];

				function shouldAudioBeMuted() {
					return (window._isAudioEnabled === false || window._isPlatformPaused === true || window._gameVisibilityState === "hidden");
				}
				window._shouldAudioBeMuted = shouldAudioBeMuted;

				function hookAudioContext(ctx) {
					if (!ctx || ctx._isHookedBySdk) return;
					ctx._isHookedBySdk = true;
					var origResume = ctx.resume;
					ctx._originalResume = origResume;
					ctx.resume = function() {
						if (shouldAudioBeMuted()) {
							console.log('%c[PLAYGAMA SDK] 🔇 Blocked AudioContext.resume() while muted/paused', 'color: #ff9800; font-weight: bold;');
							return Promise.resolve();
						}
						return origResume.apply(this, arguments);
					};
				}
				window._hookAudioContext = hookAudioContext;

				// Wrap AudioContext constructor
				var OrigAudioContext = window.AudioContext || window.webkitAudioContext;
				if (OrigAudioContext && !OrigAudioContext._isWrappedBySdk) {
					function SdkAudioContext(options) {
						var ctx = options ? new OrigAudioContext(options) : new OrigAudioContext();
						window._allAudioContexts.push(ctx);
						hookAudioContext(ctx);
						if (shouldAudioBeMuted()) {
							try { ctx.suspend().catch(function(){}); } catch(e) {}
						}
						return ctx;
					}
					SdkAudioContext.prototype = OrigAudioContext.prototype;
					for (var k in OrigAudioContext) {
						if (Object.prototype.hasOwnProperty.call(OrigAudioContext, k)) {
							SdkAudioContext[k] = OrigAudioContext[k];
						}
					}
					SdkAudioContext._isWrappedBySdk = true;
					window.AudioContext = SdkAudioContext;
					if (window.webkitAudioContext) window.webkitAudioContext = SdkAudioContext;
				}

				// Intercept window._dmJSDeviceShared for Defold HTML5 Web Audio
				var _sharedHolder = window._dmJSDeviceShared;
				function setupSharedHolder(shared) {
					if (!shared) return;
					var _audioCtx = shared.audioCtx;
					if (_audioCtx) {
						hookAudioContext(_audioCtx);
						if (shouldAudioBeMuted() && _audioCtx.state === 'running') {
							try { _audioCtx.suspend().catch(function(){}); } catch(e) {}
						}
					}
					try {
						Object.defineProperty(shared, 'audioCtx', {
							configurable: true,
							enumerable: true,
							get: function() { return _audioCtx; },
							set: function(newCtx) {
								_audioCtx = newCtx;
								if (newCtx) {
									hookAudioContext(newCtx);
									if (shouldAudioBeMuted() && newCtx.state === 'running') {
										try { newCtx.suspend().catch(function(){}); } catch(e) {}
									}
								}
							}
						});
					} catch(e) {}
				}

				try {
					Object.defineProperty(window, '_dmJSDeviceShared', {
						configurable: true,
						enumerable: true,
						get: function() { return _sharedHolder; },
						set: function(val) {
							_sharedHolder = val;
							setupSharedHolder(val);
						}
					});
				} catch(e) {}
				if (_sharedHolder) setupSharedHolder(_sharedHolder);

				window._syncAudio = function(mute) {
					try {
						if (window._dmJSDeviceShared && window._dmJSDeviceShared.audioCtx) {
							var dCtx = window._dmJSDeviceShared.audioCtx;
							hookAudioContext(dCtx);
							if (mute && dCtx.state === 'running') {
								dCtx.suspend().catch(function(){});
							} else if (!mute && dCtx.state === 'suspended' && !shouldAudioBeMuted()) {
								var resFn = dCtx._originalResume || dCtx.resume;
								resFn.call(dCtx).catch(function(){});
							}
						}

						if (window._allAudioContexts && window._allAudioContexts.length) {
							for (var i = 0; i < window._allAudioContexts.length; i++) {
								var c = window._allAudioContexts[i];
								if (c) {
									hookAudioContext(c);
									if (mute && c.state === 'running') {
										c.suspend().catch(function(){});
									} else if (!mute && c.state === 'suspended' && !shouldAudioBeMuted()) {
										var cRes = c._originalResume || c.resume;
										cRes.call(c).catch(function(){});
									}
								}
							}
						}

						var oalCtx = (window.AL && window.AL.currentContext && window.AL.currentContext.audioCtx) || window.webAudioCtx;
						if (oalCtx) {
							hookAudioContext(oalCtx);
							if (mute && oalCtx.state === 'running') {
								oalCtx.suspend().catch(function(){});
							} else if (!mute && oalCtx.state === 'suspended' && !shouldAudioBeMuted()) {
								var oRes = oalCtx._originalResume || oalCtx.resume;
								oRes.call(oalCtx).catch(function(){});
							}
						}

						var media = document.querySelectorAll('audio, video');
						for (var j = 0; j < media.length; j++) {
							if (!media[j].classList.contains('ad-element')) {
								media[j].muted = !!mute;
							}
						}
					} catch(e) {
						console.warn('[PLAYGAMA SDK] syncAudio error:', e);
					}
				};

				window._pauseEngineLoop = function() {
					if (window._isEngineLoopPaused) return;
					try {
						var mod = (typeof Module !== 'undefined') ? Module : window.Module;
						if (mod) {
							if (typeof mod._dmEngineSetUpdateEnabled === 'function') mod._dmEngineSetUpdateEnabled(0);
							if (typeof mod._dmEngineSetRenderEnabled === 'function') mod._dmEngineSetRenderEnabled(0);
							if (typeof mod.pauseMainLoop === 'function') mod.pauseMainLoop();
							window._isEngineLoopPaused = true;
							console.log('%c[PLAYGAMA SDK] ⏸️ Engine main loop paused', 'color: #ff9800; font-weight: bold;');
						}
					} catch(e) {
						console.warn('[PLAYGAMA SDK] pauseEngineLoop error:', e);
					}
				};

				window._resumeEngineLoop = function() {
					if (!window._isEngineLoopPaused) return;
					try {
						var mod = (typeof Module !== 'undefined') ? Module : window.Module;
						if (mod) {
							if (typeof mod._dmEngineSetUpdateEnabled === 'function') mod._dmEngineSetUpdateEnabled(1);
							if (typeof mod._dmEngineSetRenderEnabled === 'function') mod._dmEngineSetRenderEnabled(1);
							if (typeof mod.resumeMainLoop === 'function') mod.resumeMainLoop();
							window._isEngineLoopPaused = false;
							console.log('%c[PLAYGAMA SDK] ▶️ Engine main loop resumed', 'color: #4caf50; font-weight: bold;');
						}
					} catch(e) {
						console.warn('[PLAYGAMA SDK] resumeEngineLoop error:', e);
					}
				};

				if (!b) return;

				try {
					var initAudio = (typeof b.platform.isAudioEnabled === 'function') ? b.platform.isAudioEnabled() : b.platform.isAudioEnabled;
					if (typeof initAudio === 'boolean') {
						window._isAudioEnabled = initAudio;
						if (!initAudio) {
							console.log('%c[PLAYGAMA SDK] 🔇 Initial platform audio is disabled', 'color: #f44336; font-weight: bold;');
							window._syncAudio(true);
						}
					}
				} catch(e) {}

				try {
					var initPause = (typeof b.platform.isPaused === 'function') ? b.platform.isPaused() : b.platform.isPaused;
					if (typeof initPause === 'boolean' && initPause) {
						window._isPlatformPaused = true;
						console.log('%c[PLAYGAMA SDK] ⏸️ Initial platform is paused', 'color: #ff9800; font-weight: bold;');
						window._pauseEngineLoop();
						window._syncAudio(true);
					}
				} catch(e) {}

				if (b.advertisement && typeof b.advertisement.on === 'function') {
					b.advertisement.on('rewarded_state_changed', function(state) {
						console.log('%c[PLAYGAMA SDK] 🎁 window.bridge rewarded_state_changed: ' + state, 'color: #e91e63; font-weight: bold;');
						window._rewardedState = state;
						if (state === 'rewarded') {
							window._rewardedEarned = true;
						}
					});

					b.advertisement.on('interstitial_state_changed', function(state) {
						console.log('%c[PLAYGAMA SDK] 📺 window.bridge interstitial_state_changed: ' + state, 'color: #9c27b0; font-weight: bold;');
						window._interstitialState = state;
					});
				}

				if (b.platform && typeof b.platform.on === 'function') {
					b.platform.on('audio_state_changed', function(isEnabled) {
						console.log('%c[PLAYGAMA SDK] 🔊 window.bridge audio_state_changed: ' + isEnabled, 'color: #00bcd4; font-weight: bold;');
						window._isAudioEnabled = (isEnabled !== false);
						window._syncAudio(shouldAudioBeMuted());
					});

					b.platform.on('pause_state_changed', function(isPaused) {
						console.log('%c[PLAYGAMA SDK] ⏸️ window.bridge pause_state_changed: ' + isPaused, 'color: #ff9800; font-weight: bold;');
						window._isPlatformPaused = (isPaused === true);
						if (window._isPlatformPaused) {
							window._pauseEngineLoop();
							window._syncAudio(true);
						} else {
							window._resumeEngineLoop();
							window._syncAudio(shouldAudioBeMuted());
						}
					});
				}

				if (b.game && typeof b.game.on === 'function') {
					b.game.on('visibility_state_changed', function(state) {
						console.log('%c[PLAYGAMA SDK] 👁️ window.bridge visibility_state_changed: ' + state, 'color: #8bc34a; font-weight: bold;');
						window._gameVisibilityState = state;
						if (state === 'hidden') {
							window._syncAudio(true);
						} else {
							window._syncAudio(shouldAudioBeMuted());
						}
					});
				}

				document.addEventListener('visibilitychange', function() {
					if (document.hidden) {
						window._gameVisibilityState = 'hidden';
						window._syncAudio(true);
					} else {
						window._gameVisibilityState = 'visible';
						window._syncAudio(shouldAudioBeMuted());
					}
				});
			})();
		]]
		pcall(html5.run, js_listeners)
	end
end

----------------------------------------------------------
-- INITIALIZATION
----------------------------------------------------------
function M.init(custom_config)
	if M.initialized then return end
	M.initialized = true
	M.last_interstitial_time = os.time()

	local sys_info = sys.get_sys_info()
	local is_android = (sys_info.system_name == "Android")
	local is_ios = (sys_info.system_name == "iPhone OS")
	local is_web = (sys_info.system_name == "HTML5") or (html5 ~= nil and html5.run ~= nil)

	-- Check config for target platform SDK switch:
	-- Supports [sdk] target = playgama | poki | mock
	-- Defaults to playgama
	local configured_target = sys.get_config_string("sdk.target", "")
	if configured_target == "" then
		configured_target = sys.get_config_string("project.sdk", "")
	end
	if configured_target == "" then
		configured_target = sys.get_config_string("custom.sdk", "")
	end
	configured_target = string.lower(configured_target or "")
	if configured_target == "" then
		configured_target = "playgama"
	end
	log("⚙️ SDK Target from config:", configured_target)

	-- 1. Mobile Native Build (Android / iOS) -> Unity Ads
	if is_android or is_ios then
		M.active_platform = M.PLATFORM_ANDROID
		log("📱 Mobile build detected (" .. sys_info.system_name .. ") — Initializing AppLovin MAX")
		mobile_ads.init()
		firebase_analytics.init()
		gameanalytics.init()
		adjust_module.init()
		facebook_module.init()
		return
	end

	-- Check Poki availability
	local poki_detected = false
	if _G.poki_sdk ~= nil and type(_G.poki_sdk) == "table" then
		poki_detected = true
	elseif html5 and html5.run then
		local ok_poki, res_poki = pcall(html5.run, "(function() { return (typeof window !== 'undefined' && typeof window.PokiSDK !== 'undefined') ? '1' : '0'; })()")
		if ok_poki and res_poki == "1" then
			poki_detected = true
		end
	end
	M.has_poki = poki_detected

	-- Resolve Playgama Bridge Lua binding
	local mod = nil
	if _G._bridge and type(_G._bridge) == "table" then
		mod = _G._bridge
		log("✅ Resolved native Defold global '_bridge'")
	elseif _G.bridge and type(_G.bridge) == "table" then
		mod = _G.bridge
		log("✅ Resolved global 'bridge'")
	else
		local ok1, res1 = pcall(require, "bridge.bridge")
		if ok1 and res1 and type(res1) == "table" then
			mod = res1
			log("✅ Resolved module 'bridge.bridge'")
		else
			local ok2, res2 = pcall(require, "bridge")
			if ok2 and res2 and type(res2) == "table" then
				mod = res2
				log("✅ Resolved module 'bridge'")
			else
				log("ℹ️ Native Lua bridge require status: " .. tostring(res1))
			end
		end
	end

	local playgama_in_js = false
	if html5 and html5.run then
		local ok_pg, res_pg = pcall(html5.run, "(function() { var b = window.bridge || window.playgamaBridge; return (b && (b.platform || b.advertisement || b.game)) ? '1' : '0'; })()")
		if ok_pg and res_pg == "1" then
			playgama_in_js = true
		end
	end
	M.has_playgama = (mod ~= nil) or playgama_in_js

	-- 2. Forced Poki target in config
	if configured_target == "poki" and (M.has_poki or is_web) then
		M.active_platform = M.PLATFORM_POKI
		log("🌐 Poki SDK active via config (has_poki_sdk: " .. tostring(_G.poki_sdk ~= nil) .. ")")
		gameanalytics.init()
		return
	end

	-- 3. Playgama Target (default or configured_target == "playgama")
	if configured_target == "playgama" and (is_web or mod ~= nil or M.has_playgama) then
		bridge = mod
		M.active_platform = M.PLATFORM_PLAYGAMA
		local platform_id = M.get_platform_id()
		log("🌐 Playgama Bridge active (Platform: " .. tostring(platform_id) .. ", has_lua_bridge: " .. tostring(bridge ~= nil) .. ")")
		setup_playgama_listeners()
		gameanalytics.init()
		adjust_module.init()
		facebook_module.init()

		-- 3a. Check initial platform audio state from Defold Lua bridge
		if bridge and bridge.platform then
			local is_audio_fn = bridge.platform.is_audio_enabled or bridge.platform.isAudioEnabled
			if is_audio_fn then
				local ok_aud, enabled = pcall(is_audio_fn)
				if ok_aud and type(enabled) == "boolean" then
					log("🔊 Initial Lua bridge platform audio enabled:", enabled)
					M.platform_audio_enabled = enabled
					if not enabled then
						pause_audio()
					end
				end
			end
		end

		-- 3b. Check initial platform audio & pause state from browser JS bridge
		if html5 and html5.run then
			local ok_js, res_js = pcall(html5.run, [[
				(function() {
					var b = window.bridge || window.playgamaBridge;
					var audio = true;
					var paused = false;
					if (b && b.platform) {
						try {
							var a = (typeof b.platform.isAudioEnabled === 'function') ? b.platform.isAudioEnabled() : b.platform.isAudioEnabled;
							if (typeof a === 'boolean') audio = a;
						} catch(e) {}
						try {
							var p = (typeof b.platform.isPaused === 'function') ? b.platform.isPaused() : b.platform.isPaused;
							if (typeof p === 'boolean') paused = p;
						} catch(e) {}
					}
					if (window._isAudioEnabled !== undefined) audio = window._isAudioEnabled;
					if (window._isPlatformPaused !== undefined) paused = window._isPlatformPaused;
					return (audio ? "1" : "0") + "|" + (paused ? "1" : "0");
				})()
			]])
			if ok_js and res_js and res_js ~= "" then
				local a_flag, p_flag = res_js:match("([^|]+)|([^|]+)")
				if a_flag == "0" then
					log("🔇 Initial browser bridge audio disabled — muting")
					M.platform_audio_enabled = false
					pause_audio()
				end
				if p_flag == "1" then
					log("⏸️ Initial browser bridge platform paused — pausing gameplay")
					M.platform_paused = true
					pause_gameplay()
				end
			end
		end

		if html5 and html5.run then
			local test_helpers_js = [[
				(function() {
					window.testRewardedAd = function(placement) {
						placement = placement || 'test_rewarded';
						console.log('%c[TEST AD] 🎬 Testing rewarded ad: "' + placement + '"', 'color: #ff5722; font-weight: bold;');
						var b = window.bridge || window.playgamaBridge;
						if (b && b.advertisement) {
							console.log('[TEST AD] isRewardedSupported:', b.advertisement.isRewardedSupported);
							console.log('[TEST AD] rewardedState:', b.advertisement.rewardedState);
							if (typeof b.advertisement.showRewarded === 'function') {
								b.advertisement.showRewarded(placement);
							} else if (typeof b.advertisement.show_rewarded === 'function') {
								b.advertisement.show_rewarded(placement);
							}
						} else {
							console.warn('[TEST AD] window.bridge not available');
						}
					};

					window.testInterstitialAd = function(placement) {
						placement = placement || 'test_interstitial';
						console.log('%c[TEST AD] 📺 Testing interstitial ad: "' + placement + '"', 'color: #9c27b0; font-weight: bold;');
						var b = window.bridge || window.playgamaBridge;
						if (b && b.advertisement) {
							console.log('[TEST AD] isInterstitialSupported:', b.advertisement.isInterstitialSupported);
							console.log('[TEST AD] interstitialState:', b.advertisement.interstitialState);
							if (typeof b.advertisement.showInterstitial === 'function') {
								b.advertisement.showInterstitial(placement);
							} else if (typeof b.advertisement.show_interstitial === 'function') {
								b.advertisement.show_interstitial(placement);
							}
						} else {
							console.warn('[TEST AD] window.bridge not available');
						}
					};

					window.getBridgeStatus = function() {
						var b = window.bridge || window.playgamaBridge;
						var cg = window.CrazyGames && window.CrazyGames.SDK;
						var status = {
							hasBridge: !!b,
							platformId: (b && b.platform && (typeof b.platform.id === 'function' ? b.platform.id() : b.platform.id)) || 'unknown',
							isInitialized: (b && b.isInitialized),
							isRewardedSupported: (b && b.advertisement && b.advertisement.isRewardedSupported),
							rewardedState: (b && b.advertisement && b.advertisement.rewardedState),
							isInterstitialSupported: (b && b.advertisement && b.advertisement.isInterstitialSupported),
							interstitialState: (b && b.advertisement && b.advertisement.interstitialState),
							hasCrazyGamesSDK: !!cg
						};
						console.table ? console.table(status) : console.log('[BRIDGE STATUS]', status);
						return status;
					};

					console.log('%c[PLAYGAMA SDK] 🛠️ Debug helpers ready: window.testRewardedAd(), window.testInterstitialAd(), window.getBridgeStatus()', 'color: #00e676; font-weight: bold;');
				})();
			]]
			pcall(html5.run, test_helpers_js)

			-- Continuous background synchronization for Platform Audio, Pause, and Visibility
			safe_timer_delay(0.05, true, function()
				local ok, res = pcall(html5.run, "(function() { return (window._isAudioEnabled === false ? '0' : '1') + '|' + (window._isPlatformPaused === true ? '1' : '0') + '|' + (window._gameVisibilityState === 'hidden' ? '1' : '0'); })()")
				if ok and res and res ~= "" then
					local audio_flag, pause_flag, vis_flag = res:match("([^|]+)|([^|]+)|([^|]+)")
					local audio_enabled = (audio_flag ~= "0")
					local is_paused = (pause_flag == "1")
					local is_hidden = (vis_flag == "1")

					local audio_changed = (M.platform_audio_enabled ~= audio_enabled)
					local pause_changed = (M.platform_paused ~= is_paused)
					local vis_changed = (M.tab_hidden ~= is_hidden)

					if audio_changed then
						M.platform_audio_enabled = audio_enabled
						if not M.platform_audio_enabled then
							pause_audio()
						else
							resume_audio()
						end
					end

					if pause_changed or vis_changed then
						M.platform_paused = is_paused
						M.tab_hidden = is_hidden
						if M.platform_paused or M.tab_hidden then
							pause_gameplay()
						else
							resume_gameplay()
						end
					end
				end
			end)
		end

		safe_timer_delay(1.0, false, function()
			M.check_pending_purchases()
		end)
		return
	end

	-- 4. Fallback Mock Desktop / Editor
	M.active_platform = M.PLATFORM_MOCK
	log("💻 Running in Editor / Desktop fallback mock")
	mobile_ads.init()
	gameanalytics.init()
	adjust_module.init()
	facebook_module.init()
	safe_timer_delay(1.0, false, function()
		M.check_pending_purchases()
	end)
end

----------------------------------------------------------
-- DUAL-CHANNEL PLATFORM MESSAGE SENDER (LUA BINDING + HTML5 JS)
----------------------------------------------------------
local function send_platform_message(msg_name, options)
	options = options or {}
	if not M.initialized then M.init() end

	log("📤 send_platform_message: '" .. tostring(msg_name) .. "'")

	-- Channel 1: Defold Lua / C++ Bridge extension
	if bridge and bridge.platform then
		local send_fn = bridge.platform.send_message or bridge.platform.sendMessage
		if send_fn then
			pcall(send_fn, msg_name, options, function()
				log("✅ [Defold Bridge] Message delivered:", msg_name)
			end, function(err)
				log("⚠️ [Defold Bridge] Message error callback:", msg_name, tostring(err))
			end)
		else
			log("⚠️ bridge.platform.send_message function not found")
		end
	end

	-- Channel 2: Direct browser JavaScript call via html5.run (Web/HTML5 only)
	if html5 and html5.run then
		local opts_json = "{}"
		if options and next(options) then
			local parts = {}
			for k, v in pairs(options) do
				local val_str = type(v) == "number" and tostring(v) or string.format("%q", tostring(v))
				table.insert(parts, string.format("%q:%s", tostring(k), val_str))
			end
			opts_json = "{" .. table.concat(parts, ",") .. "}"
		end

		local js = string.format([[
			(function() {
				var msg = %q;
				var opts = %s;
				try {
					var b = window.bridge || window.playgamaBridge;
					if (b) {
						if (b.platform && typeof b.platform.sendMessage === 'function') {
							b.platform.sendMessage(msg, opts)
								.then(function() { console.log('[PLAYGAMA SDK] ✅ window.bridge.platform.sendMessage("' + msg + '") OK'); })
								.catch(function(e) { console.warn('[PLAYGAMA SDK] ⚠️ sendMessage error (' + msg + '):', e); });
						} else if (typeof b.sendMessage === 'function') {
							b.sendMessage(msg, opts);
							console.log('[PLAYGAMA SDK] ✅ window.bridge.sendMessage("' + msg + '") called');
						}
						if (msg === 'game_ready' || msg === 'in_game_loading_stopped') {
							var el = document.getElementById('loading-overlay');
							if (el) el.remove();
						}
					} else {
						console.warn('[PLAYGAMA SDK] window.bridge not defined yet for message:', msg);
					}

					// Direct CrazyGames SDK support (v2/v3)
					try {
						var cg = (window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.game) || (window.crazygames && window.crazygames.game);
						if (cg) {
							if (msg === 'in_game_loading_started') {
								if (typeof cg.loadingStart === 'function') cg.loadingStart();
								console.log('[CrazyGames SDK] ⏳ loadingStart() called');
							} else if (msg === 'in_game_loading_stopped' || msg === 'game_ready') {
								if (typeof cg.loadingStop === 'function') cg.loadingStop();
								console.log('[CrazyGames SDK] ⌛ loadingStop() called');
							} else if (msg === 'gameplay_started' || msg === 'level_started' || msg === 'level_resumed') {
								if (typeof cg.gameplayStart === 'function') cg.gameplayStart();
								console.log('[CrazyGames SDK] ▶️ gameplayStart() called (' + msg + ')');
							} else if (msg === 'gameplay_stopped' || msg === 'level_completed' || msg === 'level_failed' || msg === 'level_paused') {
								if (typeof cg.gameplayStop === 'function') cg.gameplayStop();
								console.log('[CrazyGames SDK] ⏹️ gameplayStop() called (' + msg + ')');
							} else if (msg === 'happy_time' || msg === 'player_got_achievement') {
								if (typeof cg.happytime === 'function') cg.happytime();
								console.log('[CrazyGames SDK] 🎉 happytime() called');
							}
						}
					} catch(cgErr) {
						console.warn('[CrazyGames SDK Direct] Error:', cgErr);
					}
				} catch(err) {
					console.error('[PLAYGAMA SDK] ❌ Exception in sendMessage (' + msg + '):', err);
				}
			})();
		]], msg_name, opts_json)

		pcall(html5.run, js)
	end
end

----------------------------------------------------------
-- LIFECYCLE: GAME READY
----------------------------------------------------------
--- Call when game assets and main menu are fully loaded & ready for player input
function M.send_game_ready()
	if M.game_ready_sent then
		log("ℹ️ send_game_ready() already dispatched previously, ignoring duplicate call")
		return
	end
	M.game_ready_sent = true

	log("📤 send_game_ready() triggered — dispatching game_ready and in_game_loading_stopped events")
	send_platform_message("game_ready")
	send_platform_message("in_game_loading_stopped")

	-- Poki SDK gameLoadingFinished
	pcall(function()
		if _G.poki_sdk and _G.poki_sdk.game_loading_finished then
			_G.poki_sdk.game_loading_finished()
		end
	end)
	if html5 and html5.run then
		pcall(html5.run, "(function() { try { if (typeof PokiSDK !== 'undefined' && typeof PokiSDK.gameLoadingFinished === 'function') PokiSDK.gameLoadingFinished(); } catch(e){} })();")
	end
end

----------------------------------------------------------
-- LIFECYCLE: IN-GAME LOADING
----------------------------------------------------------
function M.in_game_loading_started()
	send_platform_message("in_game_loading_started")
	pcall(function()
		if _G.poki_sdk and _G.poki_sdk.game_loading_start then
			_G.poki_sdk.game_loading_start()
		end
	end)
end

function M.in_game_loading_stopped()
	send_platform_message("in_game_loading_stopped")
	pcall(function()
		if _G.poki_sdk and _G.poki_sdk.game_loading_finished then
			_G.poki_sdk.game_loading_finished()
		end
	end)
end

----------------------------------------------------------
-- LIFECYCLE: GAMEPLAY START / STOP
----------------------------------------------------------
function M.gameplay_start(world, level)
	if M.gameplay_active then return end
	M.gameplay_active = true
	log("▶️ gameplay_start()", world, level)

	local opts = {}
	if world then opts.world = tostring(world) end
	if level then opts.level = tostring(level) end

	send_platform_message("gameplay_started", opts)

	-- Poki SDK
	pcall(function()
		if _G.poki_sdk and _G.poki_sdk.gameplay_start then
			_G.poki_sdk.gameplay_start()
		end
	end)
	if html5 and html5.run then
		pcall(html5.run, "(function() { try { if (typeof PokiSDK !== 'undefined' && typeof PokiSDK.gameplayStart === 'function') PokiSDK.gameplayStart(); } catch(e){} })();")
	end
end

function M.gameplay_stop(world, level)
	if not M.gameplay_active then return end
	M.gameplay_active = false
	log("⏹️ gameplay_stop()", world, level)

	local opts = {}
	if world then opts.world = tostring(world) end
	if level then opts.level = tostring(level) end

	send_platform_message("gameplay_stopped", opts)

	-- Poki SDK
	pcall(function()
		if _G.poki_sdk and _G.poki_sdk.gameplay_stop then
			_G.poki_sdk.gameplay_stop()
		end
	end)
	if html5 and html5.run then
		pcall(html5.run, "(function() { try { if (typeof PokiSDK !== 'undefined' && typeof PokiSDK.gameplayStop === 'function') PokiSDK.gameplayStop(); } catch(e){} })();")
	end
end

----------------------------------------------------------
-- ROUND & LEVEL PROGRESSION
----------------------------------------------------------
function M.round_start(round_or_level)
	M.current_round = round_or_level or M.current_round or 1
	log("🚩 round_start:", M.current_round)

	send_platform_message("level_started", { level = M.current_round })
	gameanalytics.start_progression("world", tostring(M.current_round))
end

function M.round_end(victory, round_or_level)
	local r = round_or_level or M.current_round or 1
	log("🏁 round_end:", victory and "VICTORY" or "DEFEAT", "Round/Level:", r)

	local event_name = victory and "level_completed" or "level_failed"
	send_platform_message(event_name, { level = r })
	if victory then
		gameanalytics.complete_progression("world", tostring(r))
	else
		gameanalytics.fail_progression("world", tostring(r))
	end
end

function M.level_paused()
	send_platform_message("level_paused")
end

function M.level_resumed()
	send_platform_message("level_resumed")
end

----------------------------------------------------------
-- ACHIEVEMENTS / CELEBRATION / HAPPY TIME
----------------------------------------------------------
function M.happy_time(intensity)
	intensity = intensity or 1.0
	log("🎉 happy_time (intensity: " .. tostring(intensity) .. ")")

	if intensity >= 1.0 then
		send_platform_message("player_got_achievement", { type = "victory" })
	end
end

function M.tutorial_started()
	log("📖 tutorial_started")
	send_platform_message("level_started", { level = "tutorial" })
	gameanalytics.start_progression("tutorial")
end

function M.tutorial_completed()
	log("🎓 tutorial_completed")
	send_platform_message("level_completed", { level = "tutorial" })
	gameanalytics.complete_progression("tutorial")
end

function M.chest_opened(chest_id, chest_name)
	local name = tostring(chest_name or chest_id or "chest")
	log("📦 chest_opened:", name)
	send_platform_message("player_got_achievement", { type = "chest_opened", name = name })
	gameanalytics.design_event("chest:opened:" .. tostring(chest_id or name))
end

function M.hero_upgraded(hero_id, new_level)
	local tag = tostring(hero_id) .. "_lvl" .. tostring(new_level)
	log("⭐ hero_upgraded:", tag)
	send_platform_message("player_got_achievement", { type = "hero_upgraded", id = tostring(hero_id), level = tonumber(new_level) or 1 })
	gameanalytics.design_event("hero:upgraded:" .. tostring(hero_id), new_level)
end

function M.measure(category, what, action)
	log("📊 measure:", category, what, action)
	if not M.initialized then M.init() end

	if bridge and bridge.platform and bridge.platform.send_custom_message then
		bridge.platform.send_custom_message(tostring(category), { what = tostring(what), action = tostring(action) })
	end
end

M.matches_since_ad = 0
M.total_matches = 0
M.first_interstitial_shown = false

--- Handles interstitial ad triggers for level closing and match completions.
--- Follows the rules:
--- 1. Interstitial after 3rd battle, then after every 2nd battle.
--- 2. Interstitial also on level close.
--- 3. Strict minimum cooldown of 120 seconds between any interstitial ads.
---
--- @param callback function|nil Callback to invoke when ad closes or is skipped
--- @param is_level_exit boolean|nil Whether the level is being closed/exited (default true)
--- @param is_match_finish boolean|nil Whether this occurred upon a completed match (default false)
function M.on_level_closed(callback, is_level_exit, is_match_finish)
	if not M.initialized then M.init() end

	if is_level_exit == nil then is_level_exit = true end
	if is_match_finish == nil then is_match_finish = false end

	if is_match_finish then
		M.total_matches = (M.total_matches or 0) + 1
		M.matches_since_ad = (M.matches_since_ad or 0) + 1
	end

	local threshold = M.first_interstitial_shown and 2 or 3
	local elapsed = os.time() - (M.last_interstitial_time or 0)

	log("🚪 on_level_closed - is_exit:", tostring(is_level_exit), "is_match_finish:", tostring(is_match_finish),
		"matches_since_ad:", (M.matches_since_ad or 0) .. "/" .. threshold,
		"elapsed:", string.format("%.0f", elapsed) .. "s / " .. AD_COOLDOWN .. "s")

	-- 1. HARD CONSTRAINT: Minimum interval of 120 seconds between ads
	if elapsed < AD_COOLDOWN then
		log("⏳ Interstitial cooldown active (" .. string.format("%.0f", elapsed) .. "s / " .. AD_COOLDOWN .. "s) — skipping ad")
		if callback then callback() end
		return
	end

	-- 2. Cooldown elapsed (>= 120s). Check if trigger conditions are met:
	-- - Condition A: Level closed / exited (is_level_exit == true)
	-- - Condition B: Match threshold reached (matches_since_ad >= threshold)
	local should_show = false
	local placement = "interstitial"

	if is_level_exit then
		should_show = true
		placement = "level_closed"
	elseif is_match_finish and (M.matches_since_ad or 0) >= threshold then
		should_show = true
		placement = "match_end_" .. (threshold == 3 and "first_3" or "every_2")
	end

	if should_show then
		log("📺 Interstitial trigger satisfied (" .. placement .. "). Showing ad...")
		M.commercial_break(callback, placement, true)
	else
		log("⏳ Matches until next interstitial:", (threshold - (M.matches_since_ad or 0)))
		if callback then callback() end
	end
end

--- Convenience / backwards-compatible wrapper for match end
function M.on_match_finished(callback, is_level_exit)
	return M.on_level_closed(callback, is_level_exit ~= false, true)
end

function M.commercial_break(callback, placement, force)
	if not M.initialized then M.init() end

	if M.has_no_ads() then
		log("🚫 No-Ads active — skipping commercial_break")
		if callback then callback() end
		return
	end

	if M.ad_showing then
		if callback then callback() end
		return
	end

	local elapsed = os.time() - (M.last_interstitial_time or 0)
	if not force and M.last_interstitial_time > 0 and elapsed < AD_COOLDOWN then
		log("⏳ Interstitial cooldown active (" .. string.format("%.0f", elapsed) .. "s / " .. AD_COOLDOWN .. "s) — skipping commercial_break")
		if callback then callback() end
		return
	end

	-- Ad initiated: mark timestamp and reset match count
	M.last_interstitial_time = os.time()
	M.matches_since_ad = 0
	M.first_interstitial_shown = true

	local placement_str = tostring(placement or "interstitial")
	pause_audio()

	-- Log detailed diagnostics to browser JS DevTools console
	if html5 and html5.run then
		local js_diag = string.format([[
			(function() {
				var p = %q;
				var b = window.bridge || window.playgamaBridge;
				var cg = window.CrazyGames && window.CrazyGames.SDK;
				console.log('%%c[PLAYGAMA SDK] 📺 commercial_break initiated (placement: "' + p + '")', 'color: #9c27b0; font-weight: bold;', {
					hasBridge: !!b,
					platformId: (b && b.platform && (typeof b.platform.id === 'function' ? b.platform.id() : b.platform.id)) || 'unknown',
					isInterstitialSupported: (b && b.advertisement && b.advertisement.isInterstitialSupported),
					interstitialState: (b && b.advertisement && b.advertisement.interstitialState),
					hasCrazyGamesSDK: !!cg
				});
			})();
		]], placement_str)
		pcall(html5.run, js_diag)
	end

	-- Portal requirement: Stop active gameplay before showing ad
	if M.gameplay_active then
		log("⏸️ Pausing gameplay before interstitial ad")
		resume_gameplay_after_ad = true
		M.gameplay_stop()
	end

	-- 1. Poki Platform
	if M.active_platform == M.PLATFORM_POKI then
		log("📺 Showing Poki commercialBreak...")
		M.ad_showing = true
		M.last_interstitial_time = os.time()
		local called = false
		local function on_poki_done()
			if called then return end
			called = true
			M.ad_showing = false
			resume_audio()
			if resume_gameplay_after_ad then
				resume_gameplay_after_ad = false
				M.gameplay_start()
			end
			if callback then callback() end
		end

		local dispatched = false
		if _G.poki_sdk and _G.poki_sdk.commercial_break then
			local ok = pcall(function()
				_G.poki_sdk.commercial_break(on_poki_done)
			end)
			if ok then dispatched = true end
		end
		if not dispatched and html5 and html5.run then
			local ok_js = pcall(function()
				html5.run("(function() { try { if (typeof PokiSDK !== 'undefined' && typeof PokiSDK.commercialBreak === 'function') { PokiSDK.commercialBreak().then(function(){}).catch(function(){}); } } catch(e){} })();")
			end)
			if ok_js then
				safe_timer_delay(0.5, false, on_poki_done)
				dispatched = true
			end
		end
		if not dispatched then
			on_poki_done()
		end

	-- 2. Playgama Bridge (Web)
	elseif M.active_platform == M.PLATFORM_PLAYGAMA then
		log("📺 Showing Playgama interstitial ad (placement: " .. placement_str .. ")...")
		M.last_interstitial_time = os.time()
		current_interstitial_cb = callback

		if html5 and html5.run then
			pcall(html5.run, [[
				(function() {
					window._interstitialState = "loading";
				})();
			]])
		end

		local call_success = false
		if bridge and bridge.advertisement and bridge.advertisement.show_interstitial then
			local ok, err = pcall(function()
				bridge.advertisement.show_interstitial(placement_str)
			end)
			if ok then
				call_success = true
				log("✅ bridge.advertisement.show_interstitial dispatched successfully")
			else
				log("❌ Playgama show_interstitial Lua error:", err)
			end
		end

		if not call_success and html5 and html5.run then
			log("🌐 Fallback: Calling window.bridge.advertisement.showInterstitial directly via JS")
			local js = string.format([[
				(function() {
					window._interstitialState = "loading";
					try {
						var b = window.bridge || window.playgamaBridge;
						if (b && b.advertisement && typeof b.advertisement.showInterstitial === 'function') {
							b.advertisement.showInterstitial(%q);
							return "1";
						}
					} catch(e) {}
					return "0";
				})();
			]], placement_str)
			local ok_call, res = pcall(html5.run, js)
			if ok_call and res == "1" then call_success = true end
		end

		if html5 and html5.run then
			local poll_timer = nil
			poll_timer = safe_timer_delay(0.05, true, function(_, handle)
				local ok_eval, res = pcall(html5.run, "window._interstitialState || ''")
				if ok_eval and res and res ~= "" then
					if res == "opened" then
						M.ad_showing = true
						pause_audio()
					elseif res == "closed" or res == "failed" then
						safe_timer_cancel(handle)
						M.ad_showing = false
						resume_audio()
						if resume_gameplay_after_ad then
							resume_gameplay_after_ad = false
							M.gameplay_start()
						end
						if current_interstitial_cb then
							local cb = current_interstitial_cb
							current_interstitial_cb = nil
							cb()
						end
					end
				end
			end)
		elseif not call_success then
			M.ad_showing = false
			resume_audio()
			if resume_gameplay_after_ad then
				resume_gameplay_after_ad = false
				M.gameplay_start()
			end
			if callback then callback() end
		end

	-- 3. Android / iOS (AppLovin MAX)
	elseif (M.active_platform == M.PLATFORM_ANDROID or mobile_ads.is_supported()) then
		log("📺 Showing AppLovin MAX interstitial ad...")
		M.last_interstitial_time = os.time()
		M.ad_showing = true
		local function on_max_done()
			M.ad_showing = false
			resume_audio()
			if resume_gameplay_after_ad then
				resume_gameplay_after_ad = false
				M.gameplay_start()
			end
			if callback then callback() end
		end
		if not mobile_ads.show_interstitial(on_max_done, placement_str) then
			log("⚠️ MAX interstitial not ready — skipping")
			on_max_done()
		end

	-- 4. Mock
	else
		log("💻 Mock commercial_break")
		M.last_interstitial_time = os.time()
		if resume_gameplay_after_ad then
			resume_gameplay_after_ad = false
			M.gameplay_start()
		end
		if callback then callback() end
	end
end

M.show_interstitial = M.commercial_break

--- Show interstitial ad only if cooldown (AD_COOLDOWN = 120s) has elapsed since last one.
function M.try_commercial_break(callback, placement)
	local elapsed = os.time() - (M.last_interstitial_time or 0)
	if elapsed < AD_COOLDOWN then
		log("⏳ Interstitial cooldown active (" .. string.format("%.0f", elapsed) .. "s / " .. AD_COOLDOWN .. "s) — skipping ad")
		if callback then callback() end
		return
	end
	M.commercial_break(callback, placement, true)
end

function M.is_interstitial_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.advertisement and bridge.advertisement.is_interstitial_supported then
		return bridge.advertisement.is_interstitial_supported()
	elseif M.active_platform == M.PLATFORM_ANDROID then
		return true
	end
	return true
end

----------------------------------------------------------
-- REWARDED ADS (REWARDED BREAK)
----------------------------------------------------------
function M.rewarded_break(on_reward, on_close, placement_or_size)
	if not M.initialized then M.init() end

	local placement = (placement_or_size and placement_or_size ~= "") and tostring(placement_or_size) or "rewarded"
	log("🎁 rewarded_break() requested — placement: '" .. placement .. "', active_platform: " .. tostring(M.active_platform) .. ", platform_id: " .. tostring(M.get_platform_id()))

	if M.ad_showing then
		log("⚠️ Ad already showing, ignoring duplicate rewarded_break call")
		if on_close then on_close(false) end
		return
	end

	pause_audio()

	-- Log detailed diagnostics to browser JS DevTools console
	if html5 and html5.run then
		local js_diag = string.format([[
			(function() {
				var p = %q;
				var b = window.bridge || window.playgamaBridge;
				var cg = window.CrazyGames && window.CrazyGames.SDK;
				console.log('%%c[PLAYGAMA SDK] 🎁 rewarded_break initiated (placement: "' + p + '")', 'color: #e91e63; font-weight: bold;', {
					hasBridge: !!b,
					platformId: (b && b.platform && (typeof b.platform.id === 'function' ? b.platform.id() : b.platform.id)) || 'unknown',
					isRewardedSupported: (b && b.advertisement && b.advertisement.isRewardedSupported),
					rewardedState: (b && b.advertisement && b.advertisement.rewardedState),
					hasCrazyGamesSDK: !!cg
				});
			})();
		]], placement)
		pcall(html5.run, js_diag)
	end

	-- Portal requirement: Stop active gameplay before showing ad
	if M.gameplay_active then
		log("⏸️ Pausing gameplay before rewarded ad")
		resume_gameplay_after_ad = true
		M.gameplay_stop()
	end

	if reward_timeout_timer then
		safe_timer_cancel(reward_timeout_timer)
		reward_timeout_timer = nil
	end

	-- 1. Poki Platform
	if M.active_platform == M.PLATFORM_POKI then
		log("🎁 Showing Poki rewardedBreak...")
		M.ad_showing = true
		local called = false
		local function finish_reward(success)
			if called then return end
			called = true
			M.ad_showing = false
			resume_audio()
			if resume_gameplay_after_ad then
				resume_gameplay_after_ad = false
				M.gameplay_start()
			end
			if success and on_reward then
				pcall(on_reward)
			end
			if on_close then
				pcall(on_close, success == true)
			end
		end

		local dispatched = false
		if _G.poki_sdk and _G.poki_sdk.rewarded_break then
			local ok = pcall(function()
				_G.poki_sdk.rewarded_break(function(self, success)
					finish_reward(success == true)
				end)
			end)
			if ok then dispatched = true end
		end

		if not dispatched and html5 and html5.run then
			local ok_js = pcall(function()
				html5.run([[(function() {
					try {
						if (typeof PokiSDK !== 'undefined' && typeof PokiSDK.rewardedBreak === 'function') {
							PokiSDK.rewardedBreak().then(function(success) {
								window._pokiRewardedResult = success ? '1' : '0';
							}).catch(function() {
								window._pokiRewardedResult = '0';
							});
						}
					} catch(e){}
				})();]])
			end)
			if ok_js then
				dispatched = true
				local poll_timer = nil
				poll_timer = safe_timer_delay(0.05, true, function(_, handle)
					local ok_ev, res = pcall(html5.run, "window._pokiRewardedResult || ''")
					if ok_ev and res and res ~= "" then
						safe_timer_cancel(handle)
						pcall(html5.run, "window._pokiRewardedResult = '';")
						finish_reward(res == "1")
					end
				end)
			end
		end

		if not dispatched then
			finish_reward(true)
		end

	-- 2. Playgama Bridge & Web Platform
	elseif M.active_platform == M.PLATFORM_PLAYGAMA then
		log("🎁 Showing Playgama / Web rewarded ad (placement: " .. tostring(placement) .. ")...")
		current_reward_cb = on_reward
		current_reward_close_cb = on_close
		reward_granted = false

		if html5 and html5.run then
			pcall(html5.run, [[
				(function() {
					window._rewardedState = "loading";
					window._rewardedEarned = false;
				})();
			]])
		end

		local call_success = false
		if bridge and bridge.advertisement and bridge.advertisement.show_rewarded then
			local ok, err = pcall(function()
				bridge.advertisement.show_rewarded(placement)
			end)
			if ok then
				call_success = true
				log("✅ bridge.advertisement.show_rewarded dispatched successfully")
			else
				log("⚠️ bridge.advertisement.show_rewarded Lua error:", err)
			end
		end

		if not call_success and html5 and html5.run then
			log("🌐 Fallback: Calling window.bridge.advertisement.showRewarded directly via JS")
			local js = string.format([[
				(function() {
					var p = %q;
					window._rewardedState = "loading";
					window._rewardedEarned = false;
					try {
						var b = window.bridge || window.playgamaBridge;
						if (b && b.advertisement) {
							if (typeof b.advertisement.showRewarded === 'function') {
								b.advertisement.showRewarded(p);
								return "1";
							} else if (typeof b.advertisement.show_rewarded === 'function') {
								b.advertisement.show_rewarded(p);
								return "1";
							}
						}
						var cg = window.CrazyGames && window.CrazyGames.SDK;
						if (cg && cg.ad && typeof cg.ad.requestAd === 'function') {
							cg.ad.requestAd('rewarded');
							return "1";
						}
					} catch(e) {
						console.error('[SDK WRAPPER] JS showRewarded error:', e);
					}
					return "0";
				})();
			]], placement)
			local ok_js, res = pcall(html5.run, js)
			if ok_js and res == "1" then call_success = true end
		end

		if html5 and html5.run then
			local poll_timer = nil
			poll_timer = safe_timer_delay(0.05, true, function(_, handle)
				local ok_eval, res = pcall(html5.run, "(function() { return (window._rewardedState || '') + '|' + (window._rewardedEarned ? '1' : '0'); })()")
				if ok_eval and res and res ~= "" then
					local st, earned_flag = res:match("([^|]+)|([^|]+)")
					if st == "opened" then
						M.ad_showing = true
						pause_audio()
					elseif st == "rewarded" or earned_flag == "1" then
						if reward_timeout_timer then
							safe_timer_cancel(reward_timeout_timer)
							reward_timeout_timer = nil
						end
						if not reward_granted then
							reward_granted = true
							log("🎉 Rewarded earned in Web/JS — executing reward callback")
							if current_reward_cb then
								local cb = current_reward_cb
								current_reward_cb = nil
								local ok_cb, cb_err = pcall(cb)
								if not ok_cb then
									log("⚠️ Error executing rewarded callback:", cb_err)
								end
							end
						end
					end

					if st == "closed" or st == "failed" then
						safe_timer_cancel(handle)
						M.ad_showing = false
						resume_audio()
						if resume_gameplay_after_ad then
							resume_gameplay_after_ad = false
							M.gameplay_start()
						end
						if reward_timeout_timer then
							safe_timer_cancel(reward_timeout_timer)
							reward_timeout_timer = nil
						end
						local earned = (earned_flag == "1") or reward_granted
						local pid = M.get_platform_id()
						if st == "failed" and (pid == "mock" or pid == "qa_tool") then
							log("🧪 Test platform: auto-completing reward for developer testing")
							earned = true
						end
						if earned and current_reward_cb then
							local cb = current_reward_cb
							current_reward_cb = nil
							local ok_cb, cb_err = pcall(cb)
							if not ok_cb then
								log("⚠️ Error executing rewarded callback:", cb_err)
							end
						end
						if current_reward_close_cb then
							local cb = current_reward_close_cb
							current_reward_close_cb = nil
							local ok_close, close_err = pcall(cb, earned)
							if not ok_close then
								log("⚠️ Error executing rewarded close callback:", close_err)
							end
						end
						current_reward_cb = nil
					end
				end
			end)
		end

		reward_timeout_timer = safe_timer_delay(120, false, function()
			reward_timeout_timer = nil
			if M.ad_showing or current_reward_cb or current_reward_close_cb then
				log("⏳ Rewarded ad response timed out — resetting ad state")
				M.ad_showing = false
				resume_audio()
				if resume_gameplay_after_ad then
					resume_gameplay_after_ad = false
					M.gameplay_start()
				end

				local earned = reward_granted
				if html5 and html5.run then
					local ok_eval, res = pcall(html5.run, "(function() { return window._rewardedEarned ? '1' : '0'; })()")
					if ok_eval and res == "1" then earned = true end
				end

				if earned and current_reward_cb then
					local cb = current_reward_cb
					current_reward_cb = nil
					cb()
				end

				if current_reward_close_cb then
					local cb = current_reward_close_cb
					current_reward_close_cb = nil
					cb(earned)
				end
				current_reward_cb = nil
			end
		end)

	-- 3. Android / iOS (AppLovin MAX)
	elseif (M.active_platform == M.PLATFORM_ANDROID or mobile_ads.is_supported()) then
		log("🎁 Showing AppLovin MAX rewarded ad...")
		M.ad_showing = true
		local function finish_reward(earned)
			M.ad_showing = false
			resume_audio()
			if resume_gameplay_after_ad then
				resume_gameplay_after_ad = false
				M.gameplay_start()
			end
			if earned and on_reward then
				pcall(on_reward)
			end
			if on_close then
				pcall(on_close, earned == true)
			end
		end
		if not mobile_ads.show_rewarded(finish_reward, placement) then
			log("⚠️ MAX rewarded ad not ready — no reward")
			finish_reward(false)
		end

	-- 4. Mock
	else
		log("💻 Mock rewarded_break (granting reward)")
		if resume_gameplay_after_ad then
			resume_gameplay_after_ad = false
			M.gameplay_start()
		end
		if on_reward then on_reward() end
		if on_close then on_close(true) end
	end
end

M.show_rewarded = M.rewarded_break

function M.is_rewarded_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.advertisement and bridge.advertisement.is_rewarded_supported then
		return bridge.advertisement.is_rewarded_supported()
	elseif M.active_platform == M.PLATFORM_ANDROID then
		return true
	end
	return true
end

----------------------------------------------------------
-- BANNER ADS
----------------------------------------------------------
function M.show_banner(position, placement)
	position = position or "bottom"
	log("🏷️ show_banner() requested (position: " .. tostring(position) .. ")")
	if not M.initialized then M.init() end

	if bridge and bridge.advertisement and bridge.advertisement.show_banner then
		pcall(function()
			bridge.advertisement.show_banner(position, placement)
		end)
	elseif (M.active_platform == M.PLATFORM_ANDROID or mobile_ads.is_supported()) then
		mobile_ads.show_banner()
	else
		log("💻 Mock show_banner")
	end
end

function M.hide_banner()
	log("🏷️ hide_banner() requested")
	if not M.initialized then M.init() end

	if bridge and bridge.advertisement and bridge.advertisement.hide_banner then
		pcall(function()
			bridge.advertisement.hide_banner()
		end)
	elseif (M.active_platform == M.PLATFORM_ANDROID or mobile_ads.is_supported()) then
		mobile_ads.hide_banner()
	else
		log("💻 Mock hide_banner")
	end
end

function M.is_banner_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.advertisement and bridge.advertisement.is_banner_supported then
		return bridge.advertisement.is_banner_supported()
	end
	return false
end

----------------------------------------------------------
-- LEADERBOARDS
----------------------------------------------------------
function M.set_leaderboard_score(id_or_score, score_or_cb, on_success_or_failure, on_failure)
	local board_id = "leaderboard"
	local score = 0
	local success_cb = nil
	local failure_cb = nil

	if type(id_or_score) == "number" then
		score = id_or_score
		success_cb = score_or_cb
		failure_cb = on_success_or_failure
	else
		board_id = tostring(id_or_score or "leaderboard")
		score = tonumber(score_or_cb) or 0
		success_cb = on_success_or_failure
		failure_cb = on_failure
	end

	log("🏆 set_leaderboard_score:", board_id, score)
	if not M.initialized then M.init() end

	if bridge and bridge.leaderboards and bridge.leaderboards.set_score then
		bridge.leaderboards.set_score(board_id, score, success_cb, failure_cb)
		return
	end

	if success_cb then success_cb() end
end

function M.get_leaderboard_entries(id, on_success, on_failure)
	local board_id = tostring(id or "leaderboard")
	log("🏆 get_leaderboard_entries:", board_id)
	if not M.initialized then M.init() end

	if bridge and bridge.leaderboards and bridge.leaderboards.get_entries then
		bridge.leaderboards.get_entries(board_id, on_success, on_failure)
		return
	end

	if on_failure then on_failure("Leaderboards not supported") end
end

function M.show_leaderboard_popup(id, on_success, on_failure)
	local board_id = tostring(id or "leaderboard")
	log("🏆 show_leaderboard_popup:", board_id)
	if not M.initialized then M.init() end

	if bridge and bridge.leaderboards and bridge.leaderboards.show_native_popup then
		bridge.leaderboards.show_native_popup(board_id, on_success, on_failure)
		return
	end

	if on_failure then on_failure("Native leaderboard popup not supported") end
end

function M.is_leaderboard_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.leaderboards and bridge.leaderboards.type then
		return bridge.leaderboards.type() ~= "not_available"
	end
	return false
end

----------------------------------------------------------
-- CLOUD STORAGE (PLAYGAMA STORAGE WITH LOCAL & CRAZYGAMES FALLBACK)
----------------------------------------------------------
function M.storage_get(keys, on_success, on_failure)
	if not M.initialized then M.init() end

	local keys_list = keys
	if type(keys) == "string" then
		keys_list = { keys }
	end

	log("📦 storage_get requested for keys:", table.concat(keys_list, ", "))

	local responded = false
	local function finish_success(data)
		if responded then return end
		responded = true
		log("📦 storage_get finished successfully, has data:", (data and next(data) ~= nil) == true)
		if on_success then
			on_success(nil, data)
		end
	end

	local function finish_failure(err)
		if responded then return end
		responded = true
		log("⚠️ storage_get failed:", tostring(err))
		if on_failure then
			on_failure(err)
		elseif on_success then
			on_success(err, nil)
		end
	end

	local key = (keys_list and keys_list[1]) or "player_profile"
	local sys_info = sys.get_sys_info()
	local is_web = (sys_info.system_name == "HTML5") or (html5 ~= nil and html5.run ~= nil)

	-- Desktop editor / mock fallback
	if not is_web then
		local app_title = sys.get_config_string("project.title", "potato_war")
		local path = sys.get_save_file(app_title, "bridge_storage_data")
		local loaded = (path and sys and sys.load) and sys.load(path) or {}
		local result = {}
		for _, k in ipairs(keys_list) do
			if loaded[k] ~= nil then
				result[k] = loaded[k]
			end
		end
		log("📦 Desktop storage_get loaded keys:", next(result) ~= nil)
		if next(result) ~= nil then
			finish_success(result)
			return
		end
	end

	-- Safety timeout: if storage doesn't respond in 3 seconds, proceed gracefully
	local timeout_handle = safe_timer_delay(3.0, false, function()
		if not responded then
			log("⏳ storage_get timed out — continuing with local profile")
			finish_success(nil)
		end
	end)

	local function run_web_js_fallback()
		if not (html5 and html5.run) then
			safe_timer_cancel(timeout_handle)
			finish_success(nil)
			return
		end

		log("🌐 Running Web JS storage_get fallback for key:", key)
		local js = string.format([[
			(function() {
				window._storageGetResult = "";
				window._storageGetStatus = "pending";
				var k = %q;
				var b = window.bridge || window.playgamaBridge;
				var cg = (window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.data) || (window.crazygames && window.crazygames.data);

				function tryCrazyGames() {
					try {
						if (cg && typeof cg.getItem === 'function') {
							var item = cg.getItem(k);
							if (item !== null && item !== undefined && item !== "") {
								return typeof item === 'object' ? JSON.stringify(item) : String(item);
							}
						}
					} catch(e) {}
					return null;
				}

				function tryLocalStorage() {
					try {
						if (typeof window !== 'undefined' && window.localStorage) {
							var item = window.localStorage.getItem(k);
							if (item !== null && item !== undefined && item !== "") {
								return item;
							}
						}
					} catch(e) {}
					return null;
				}

				function tryBridge() {
					if (!b) return Promise.reject("no bridge");
					var initPromise = b.isInitialized ? Promise.resolve() : (b.initialize ? b.initialize() : Promise.resolve());
					return initPromise.then(function() {
						if (b.storage && typeof b.storage.get === 'function') {
							return b.storage.get([k], true).then(function(res) {
								var val = Array.isArray(res) ? res[0] : (res && res[k] !== undefined ? res[k] : res);
								if (val !== null && val !== undefined && val !== "") {
									return typeof val === 'object' ? JSON.stringify(val) : String(val);
								}
								throw new Error("empty");
							});
						}
						throw new Error("no storage");
					});
				}

				tryBridge().then(function(str) {
					window._storageGetResult = str;
					window._storageGetStatus = "done";
				}).catch(function() {
					var cgVal = tryCrazyGames();
					if (cgVal) {
						window._storageGetResult = cgVal;
						window._storageGetStatus = "done";
						return;
					}
					var lsVal = tryLocalStorage();
					if (lsVal) {
						window._storageGetResult = lsVal;
						window._storageGetStatus = "done";
						return;
					}
					window._storageGetResult = "";
					window._storageGetStatus = "done";
				});
			})();
		]], key)
		pcall(html5.run, js)

		local poll_timer
		poll_timer = safe_timer_delay(0.05, true, function(_, handle)
			local ok_st, st = pcall(html5.run, "window._storageGetStatus || ''")
			if ok_st and (st == "done" or st == "error") then
				safe_timer_cancel(handle)
				safe_timer_cancel(timeout_handle)
				if st == "done" then
					local ok_val, val = pcall(html5.run, "window._storageGetResult || ''")
					if ok_val and val and val ~= "" and val ~= "null" and val ~= "undefined" then
						local json_ok, decoded = pcall(json.decode, val)
						local payload = {}
						payload[key] = (json_ok and decoded) and decoded or val
						log("📦 Web JS fallback successfully retrieved key:", key)
						finish_success(payload)
					else
						finish_success(nil)
					end
				else
					finish_success(nil)
				end
			end
		end)
	end

	-- Channel 1: Bridge Lua extension (Web WASM / Native)
	local channel1_attempted = false
	if bridge and bridge.storage and bridge.storage.get then
		channel1_attempted = true
		local ok, err = pcall(function()
			bridge.storage.get(keys_list, function(arg1, arg2)
				local raw_data = nil
				if type(arg1) == "table" and arg1.player_profile ~= nil then
					raw_data = arg1
				elseif type(arg2) == "table" and arg2.player_profile ~= nil then
					raw_data = arg2
				elseif type(arg2) == "table" or type(arg2) == "string" then
					raw_data = arg2
				elseif type(arg1) == "table" or type(arg1) == "string" then
					raw_data = arg1
				end

				if type(raw_data) == "string" and raw_data ~= "" then
					local json_ok, decoded = pcall(json.decode, raw_data)
					if json_ok and type(decoded) == "table" then
						raw_data = decoded
					end
				end

				if raw_data and (type(raw_data) == "table" and next(raw_data) ~= nil) then
					safe_timer_cancel(timeout_handle)
					finish_success(raw_data)
				else
					run_web_js_fallback()
				end
			end, function(arg1, arg2)
				local err_msg = arg2 or arg1
				log("⚠️ bridge.storage.get returned error, attempting JS fallback:", tostring(err_msg))
				run_web_js_fallback()
			end)
		end)
		if not ok then
			log("⚠️ bridge.storage.get exception:", err)
			run_web_js_fallback()
		end
	end

	if not channel1_attempted then
		run_web_js_fallback()
	end
end

function M.storage_set(data_or_key, value_or_cb, on_success_or_failure, on_failure)
	if not M.initialized then M.init() end

	local data = {}
	local success_cb = nil
	local failure_cb = nil

	if type(data_or_key) == "table" and type(value_or_cb) == "table" then
		for i, k in ipairs(data_or_key) do
			data[k] = value_or_cb[i]
		end
		success_cb = on_success_or_failure
		failure_cb = on_failure
	elseif type(data_or_key) == "table" then
		data = data_or_key
		success_cb = value_or_cb
		failure_cb = on_success_or_failure
	elseif type(data_or_key) == "string" then
		data[data_or_key] = value_or_cb
		success_cb = on_success_or_failure
		failure_cb = on_failure
	end

	log("📦 storage_set saving data...")

	local sys_info = sys.get_sys_info()
	local is_web = (sys_info.system_name == "HTML5") or (html5 ~= nil and html5.run ~= nil)

	-- Desktop editor / mock fallback
	if not is_web then
		local app_title = sys.get_config_string("project.title", "potato_war")
		local path = sys.get_save_file(app_title, "bridge_storage_data")
		local loaded = (path and sys and sys.load) and sys.load(path) or {}
		for k, v in pairs(data) do
			loaded[k] = v
		end
		if path and sys and sys.save then
			sys.save(path, loaded)
		end
		log("📦 Desktop storage_set saved successfully")
		if success_cb then success_cb() end
		return
	end

	-- Channel 1: Bridge Defold (C++ / WASM extension)
	if bridge and bridge.storage and bridge.storage.set then
		pcall(function()
			bridge.storage.set(data, function(arg1, arg2)
				log("✅ Playgama storage_set success via Lua bridge")
				if success_cb then success_cb() end
			end, function(arg1, arg2)
				local err = arg2 or arg1
				log("⚠️ Playgama storage_set failure via Lua bridge:", tostring(err))
				if failure_cb then failure_cb(err) end
			end)
		end)
	end

	-- Channel 2: Direct Web JS (window.bridge, CrazyGames SDK & localStorage)
	if html5 and html5.run then
		for k, v in pairs(data) do
			local val_json = ""
			if type(v) == "table" then
				local ok_enc, enc = pcall(json.encode, v)
				val_json = (ok_enc and enc) and enc or "{}"
			else
				val_json = string.format("%q", tostring(v))
			end

			local js = string.format([[
				(function() {
					try {
						var k = %q;
						var v = %s;
						var vStr = (typeof v === 'object') ? JSON.stringify(v) : String(v);

						// 1. window.localStorage (guaranteed persistent local mirror)
						try {
							if (typeof window !== 'undefined' && window.localStorage) {
								window.localStorage.setItem(k, vStr);
							}
						} catch(lsErr) {}

						// 2. Playgama Bridge
						var b = window.bridge || window.playgamaBridge;
						if (b) {
							var initP = b.isInitialized ? Promise.resolve() : (b.initialize ? b.initialize() : Promise.resolve());
							initP.then(function() {
								if (b.storage && typeof b.storage.set === 'function') {
									b.storage.set([k], [v]).catch(function(e) {
										console.warn('[SDK WRAPPER] JS bridge.storage.set error:', e);
									});
								}
							}).catch(function(){});
						}

						// 3. CrazyGames SDK Data
						var cg = (window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.data) || (window.crazygames && window.crazygames.data);
						if (cg && typeof cg.setItem === 'function') {
							cg.setItem(k, vStr);
						}
					} catch(e) {
						console.warn('[SDK WRAPPER] storage_set JS exception:', e);
					}
				})();
			]], tostring(k), val_json)
			pcall(html5.run, js)
		end
	end

	if not (bridge and bridge.storage and bridge.storage.set) and is_web then
		if success_cb then success_cb() end
	end
end

function M.storage_delete(keys, on_success, on_failure)
	if not M.initialized then M.init() end

	local keys_list = keys
	if type(keys) == "string" then
		keys_list = { keys }
	end

	if bridge and bridge.storage and bridge.storage.delete then
		pcall(function()
			bridge.storage.delete(keys_list, function(arg1, arg2)
				log("🗑️ Playgama storage_delete success")
				if on_success then on_success() end
			end, function(arg1, arg2)
				local err = arg2 or arg1
				log("⚠️ Playgama storage_delete failure:", tostring(err))
				if on_failure then on_failure(err) end
			end)
		end)
		return
	end

	if on_success then on_success() end
end

function M.is_storage_supported(storage_type)
	if not M.initialized then M.init() end
	if bridge and bridge.storage and bridge.storage.is_supported then
		return bridge.storage.is_supported(storage_type or "platform_internal")
	end
	return true
end

----------------------------------------------------------
-- PLAYER PROFILE & AUTHORIZATION
----------------------------------------------------------
function M.get_player_id()
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.id then
		return bridge.player.id()
	end
	return nil
end

function M.get_player_name()
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.name then
		return bridge.player.name()
	end
	return nil
end

function M.get_player_photos()
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.photos then
		return bridge.player.photos()
	end
	return {}
end

function M.is_player_authorized()
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.is_authorized then
		return bridge.player.is_authorized()
	end
	return false
end

function M.is_player_authorization_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.is_authorization_supported then
		return bridge.player.is_authorization_supported()
	end
	return false
end

function M.authorize_player(options, on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.player and bridge.player.authorize then
		bridge.player.authorize(options, on_success, on_failure)
		return
	end
	if on_failure then on_failure("Authorization not supported") end
end

----------------------------------------------------------
-- SOCIAL & SHARE & RATING
----------------------------------------------------------
function M.share(options, on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.share then
		bridge.social.share(options, on_success, on_failure)
		return
	end
	if on_success then on_success() end
end

function M.is_share_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.is_share_supported then
		return bridge.social.is_share_supported()
	end
	return false
end

function M.rate(on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.rate then
		bridge.social.rate(on_success, on_failure)
		return
	end
	if on_success then on_success() end
end

function M.is_rate_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.is_rate_supported then
		return bridge.social.is_rate_supported()
	end
	return false
end

function M.add_to_favorites(on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.add_to_favorites then
		bridge.social.add_to_favorites(on_success, on_failure)
		return
	end
	if on_success then on_success() end
end

function M.is_add_to_favorites_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.is_add_to_favorites_supported then
		return bridge.social.is_add_to_favorites_supported()
	end
	return false
end

function M.add_to_home_screen(on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.add_to_home_screen then
		bridge.social.add_to_home_screen(on_success, on_failure)
		return
	end
	if on_success then on_success() end
end

function M.is_add_to_home_screen_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.social and bridge.social.is_add_to_home_screen_supported then
		return bridge.social.is_add_to_home_screen_supported()
	end
	return false
end

function M.get_server_time(on_success, on_failure)
	if not M.initialized then M.init() end
	if bridge and bridge.platform and bridge.platform.get_server_time then
		bridge.platform.get_server_time(on_success, on_failure)
		return
	end
	if on_success then on_success(nil, os.time()) end
end

----------------------------------------------------------
-- DEVICE & PLATFORM INFO
----------------------------------------------------------
function M.get_device_info()
	if not M.initialized then M.init() end

	if bridge and bridge.device and bridge.device.type then
		local dev_type = bridge.device.type()
		return {
			is_mobile = (dev_type == "mobile"),
			is_tablet = (dev_type == "tablet"),
			is_desktop = (dev_type == "desktop" or dev_type == nil),
			type = dev_type or "desktop"
		}
	elseif M.active_platform == M.PLATFORM_ANDROID then
		return {
			is_mobile = true,
			is_tablet = false,
			is_desktop = false,
			type = "mobile"
		}
	else
		local sys_info = sys.get_sys_info()
		local is_mob = (sys_info.system_name == "Android" or sys_info.system_name == "iPhone OS")
		return {
			is_mobile = is_mob,
			is_tablet = false,
			is_desktop = not is_mob,
			type = is_mob and "mobile" or "desktop"
		}
	end
end

function M.get_platform()
	if not M.initialized then M.init() end

	if bridge and bridge.platform and bridge.platform.id then
		return bridge.platform.id()
	elseif M.active_platform == M.PLATFORM_ANDROID then
		return "android"
	elseif M.active_platform == M.PLATFORM_POKI then
		return "poki"
	end
	return "mock"
end

function M.get_language()
	if not M.initialized then M.init() end

	-- 1. Poki SDK (Lua / Web) if in Poki mode
	if M.active_platform == M.PLATFORM_POKI and _G.poki_sdk then
		local ok, lang = pcall(function()
			if _G.poki_sdk.get_language then
				local pl = _G.poki_sdk.get_language()
				if pl and type(pl) == "string" and pl ~= "" then return pl end
			end
			if _G.poki_sdk.get_url_param then
				local up = _G.poki_sdk.get_url_param("lang") or _G.poki_sdk.get_url_param("locale") or _G.poki_sdk.get_url_param("language")
				if up and type(up) == "string" and up ~= "" then return up end
			end
			return nil
		end)
		if ok and lang and lang ~= "" then
			log("🌐 Language from poki_sdk:", lang)
			return lang
		end
	end

	-- 2. Playgama Bridge Lua binding (native WASM bridge)
	if bridge and bridge.platform and bridge.platform.language then
		local ok, lang = pcall(bridge.platform.language)
		if ok and lang and lang ~= "" then
			log("🌐 Language from bridge.platform.language():", lang)
			return lang
		end
	end

	-- 3. JS-level bridge (HTML5 only: Playgama / Poki / Navigator)
	if html5 and html5.run then
		local ok, lang = pcall(html5.run, [[(function() {
			try {
				if (typeof PokiSDK !== 'undefined') {
					if (typeof PokiSDK.getLanguage === 'function') {
						var pl = PokiSDK.getLanguage();
						if (pl && typeof pl === 'string' && pl.length >= 2) return pl;
					}
					if (typeof PokiSDK.getURLParam === 'function') {
						var up = PokiSDK.getURLParam('lang') || PokiSDK.getURLParam('locale') || PokiSDK.getURLParam('language');
						if (up && typeof up === 'string' && up.length >= 2) return up;
					}
				}
				var b = window.bridge || window.playgamaBridge;
				if (b && b.platform && typeof b.platform.language === 'function') {
					return b.platform.language() || '';
				}
				if (b && b.platform && typeof b.platform.language === 'string') {
					return b.platform.language || '';
				}
				if (window.location && window.location.search) {
					var sp = new URLSearchParams(window.location.search);
					var ql = sp.get('lang') || sp.get('locale') || sp.get('language') || sp.get('poki_lang');
					if (ql && typeof ql === 'string' && ql.length >= 2) return ql;
				}
			} catch(e) {}
			return navigator.language || navigator.userLanguage || '';
		})()]])
		if ok and lang and lang ~= "" then
			log("🌐 Language from JS bridge/navigator:", lang)
			return lang
		end
	end

	-- 4. Defold sys_info fallback (mobile / desktop)
	local sys_info = sys.get_sys_info()
	return sys_info.device_language or "en"
end

--- Returns normalized 2-letter language code ('ru', 'tr', 'es', 'pt', 'fr', 'en')
function M.get_language_code()
	local raw = M.get_language()
	if raw then
		local lower = string.lower(tostring(raw))
		if lower:find("^ru") or lower:find("^be") or lower:find("^uk") or lower:find("^kk") then
			return "ru"
		elseif lower:find("^tr") then
			return "tr"
		elseif lower:find("^es") then
			return "es"
		elseif lower:find("^pt") then
			return "pt"
		elseif lower:find("^fr") then
			return "fr"
		end
	end
	return "en"
end

function M.is_adblock_detected(callback)
	if not M.initialized then M.init() end

	if bridge and bridge.advertisement and bridge.advertisement.check_ad_block then
		bridge.advertisement.check_ad_block(function(self, is_blocked)
			if callback then callback(is_blocked) end
		end)
		return
	end
	if callback then callback(false) end
end

----------------------------------------------------------
-- PAYMENTS & IN-APP PURCHASES (PLAYGAMA BRIDGE)
----------------------------------------------------------
M.DEFAULT_PRODUCTS = {
	{
		id = "coins_pack_1000",
		name_ru = "1,000 Очков",
		name_en = "1,000 Points",
		name_tr = "1.000 Puan",
		name_es = "1.000 Puntos",
		name_pt = "1.000 Pontos",
		name_fr = "1 000 Points",
		desc_ru = "Запас очков на покупку шапок",
		desc_en = "Points pack for hats and items",
		desc_tr = "Şapka ve eşya almak için puan paketi",
		desc_es = "Paquete de puntos para sombreros y objetos",
		desc_pt = "Pacote de pontos para chapéus e itens",
		desc_fr = "Pack de points pour chapeaux et objets",
		price = "0.99 USD",
		price_value = 0.99,
		type = "consumable",
		amount = 1000,
	},
	{
		id = "coins_pack_5000",
		name_ru = "5,000 Очков",
		name_en = "5,000 Points",
		name_tr = "5.000 Puan",
		name_es = "5.000 Puntos",
		name_pt = "5.000 Pontos",
		name_fr = "5 000 Points",
		desc_ru = "Огромный мешок картофельных очков",
		desc_en = "Huge bag of potato points",
		desc_tr = "Büyük patates puanı torbası",
		desc_es = "Gran saco de puntos de papa",
		desc_pt = "Grande saco de pontos de batata",
		desc_fr = "Gros sac de points patate",
		price = "2.99 USD",
		price_value = 2.99,
		type = "consumable",
		amount = 5000,
	},
	{
		id = "stars_pack_5",
		name_ru = "5 Звёзд",
		name_en = "5 Stars",
		name_tr = "5 Yıldız",
		name_es = "5 Estrellas",
		name_pt = "5 Estrelas",
		name_fr = "5 Étoiles",
		desc_ru = "Звёзды для прокачки классов казармы",
		desc_en = "Stars to upgrade squad classes",
		desc_tr = "Kışla sınıflarını yükseltmek için yıldızlar",
		desc_es = "Estrellas para mejorar clases del cuartel",
		desc_pt = "Estrelas para melhorar classes do quartel",
		desc_fr = "Étoiles pour améliorer les classes de la caserne",
		price = "1.49 USD",
		price_value = 1.49,
		type = "consumable",
		amount = 5,
	},
	{
		id = "stars_pack_20",
		name_ru = "20 Звёзд",
		name_en = "20 Stars",
		name_tr = "20 Yıldız",
		name_es = "20 Estrellas",
		name_pt = "20 Estrelas",
		name_fr = "20 Étoiles",
		desc_ru = "Открой все классы и слоты отряда!",
		desc_en = "Unlock all squad classes and slots!",
		desc_tr = "Tüm sınıf ve takım yuvalarını aç!",
		desc_es = "¡Desbloquea todas las clases y ranuras!",
		desc_pt = "Desbloqueie todas as classes e vagas!",
		desc_fr = "Débloquez toutes les classes et escouades !",
		price = "4.99 USD",
		price_value = 4.99,
		type = "consumable",
		amount = 20,
	},
	{
		id = "no_ads",
		name_ru = "Отключить Рекламу",
		name_en = "No Ads",
		name_tr = "Reklamsız",
		name_es = "Sin Anuncios",
		name_pt = "Sem Anúncios",
		name_fr = "Sans Publicité",
		desc_ru = "Навсегда убирает межраундовую рекламу",
		desc_en = "Permanently removes all interstitial ads",
		desc_tr = "Tüm ara reklamları kalıcı olarak kaldırır",
		desc_es = "Elimina para siempre los anuncios entre rondas",
		desc_pt = "Remove permanentemente os anúncios entre rodadas",
		desc_fr = "Supprime définitivement les pubs interstitielles",
		price = "1.99 USD",
		price_value = 1.99,
		type = "permanent",
		amount = 1,
	},
}

function M.has_no_ads()
	local profile_ok, profile = pcall(require, "lua_modules.player_profile")
	if profile_ok and profile and profile.data and profile.data.no_ads then
		return true
	end
	return false
end

function M.is_payments_supported()
	if not M.initialized then M.init() end

	if bridge and bridge.payments and bridge.payments.is_supported then
		local ok, supp = pcall(bridge.payments.is_supported)
		if ok and supp ~= nil then return supp end
	end

	if html5 and html5.run then
		local ok_eval, res = pcall(html5.run, [[
			(function() {
				var b = window.bridge || window.playgamaBridge;
				if (b && b.payments) {
					var s = b.payments.isSupported;
					return (typeof s === 'function' ? s() : s) ? '1' : '0';
				}
				return '0';
			})()
		]])
		if ok_eval and res == "1" then return true end
	end

	-- In mock platform or desktop editor, enable for testing
	if M.active_platform == M.PLATFORM_MOCK then
		return true
	end

	return false
end

function M.get_catalog(on_success, on_failure)
	if not M.initialized then M.init() end
	log("🛒 Fetching in-app products catalog...")

	-- 1. Bridge Lua
	if bridge and bridge.payments and bridge.payments.get_catalog then
		local ok = pcall(function()
			bridge.payments.get_catalog(function(catalog)
				log("🛒 Catalog loaded via Lua bridge, items:", catalog and #catalog or 0)
				if on_success then on_success(catalog or M.DEFAULT_PRODUCTS) end
			end, function(err)
				log("⚠️ Bridge get_catalog failed, using default catalog:", tostring(err))
				if on_success then on_success(M.DEFAULT_PRODUCTS) end
			end)
		end)
		if ok then return end
	end

	-- 2. HTML5 JS Bridge
	if html5 and html5.run then
		local js = [[
			(function() {
				try {
					var b = window.bridge || window.playgamaBridge;
					if (b && b.payments && typeof b.payments.getCatalog === 'function') {
						b.payments.getCatalog().then(function(catalog) {
							window._lastCatalog = JSON.stringify(catalog);
						}).catch(function(e) { window._lastCatalog = ""; });
					}
				} catch(e) {}
			})();
		]]
		pcall(html5.run, js)
	end

	if on_success then
		on_success(M.DEFAULT_PRODUCTS)
	end
end

function M.get_purchases(on_success, on_failure)
	if not M.initialized then M.init() end
	log("🛍️ Fetching player purchases...")

	if bridge and bridge.payments and bridge.payments.get_purchases then
		local ok = pcall(function()
			bridge.payments.get_purchases(function(purchases)
				log("🛍️ Purchases loaded via Lua bridge, count:", purchases and #purchases or 0)
				if on_success then on_success(purchases) end
			end, function(err)
				log("⚠️ get_purchases failure:", tostring(err))
				if on_failure then on_failure(err) end
			end)
		end)
		if ok then return end
	end

	if on_success then on_success({}) end
end

function M.consume_purchase(purchase_id_or_token, on_success, on_failure)
	if not M.initialized then M.init() end
	local id = tostring(purchase_id_or_token or "")
	log("🔄 Consuming purchase:", id)

	if bridge and bridge.payments and bridge.payments.consume_purchase then
		local ok = pcall(function()
			bridge.payments.consume_purchase(id, function()
				log("✅ Purchase consumed via Lua bridge:", id)
				if on_success then on_success() end
			end, function(err)
				log("⚠️ Consume purchase failed via Lua bridge:", tostring(err))
				if on_failure then on_failure(err) end
			end)
		end)
		if ok then return end
	end

	if html5 and html5.run then
		local js = string.format([[
			(function() {
				try {
					var b = window.bridge || window.playgamaBridge;
					if (b && b.payments && typeof b.payments.consumePurchase === 'function') {
						b.payments.consumePurchase(%q).then(function() {
							console.log('[PLAYGAMA SDK] Consumed purchase:', %q);
						}).catch(function(e){ console.warn('[PLAYGAMA SDK] Consume error:', e); });
					}
				} catch(e) {}
			})();
		]], id, id)
		pcall(html5.run, js)
	end

	if on_success then on_success() end
end

function M.purchase(id, options, on_success, on_failure)
	if not M.initialized then M.init() end

	if type(options) == "function" then
		on_failure = on_success
		on_success = options
		options = {}
	end
	options = options or {}
	local product_id = tostring(id or "")
	log("💳 Initiating purchase for:", product_id)

	local function handle_purchase_granted(item_id, purchase_data)
		log("🎉 Purchase successful for item:", item_id)
		-- Automatically grant rewards in player_profile
		local profile_ok, profile = pcall(require, "lua_modules.player_profile")
		if profile_ok and profile and profile.apply_purchase then
			profile.apply_purchase(item_id)
		end

		-- If consumable, auto-consume per Playgama guidelines
		if item_id ~= "no_ads" then
			M.consume_purchase(item_id)
		else
			if profile_ok and profile and profile.set_no_ads then
				profile.set_no_ads(true)
			end
		end

		if on_success then
			on_success(purchase_data or { id = item_id })
		end
	end

	-- 1. Defold Lua Bridge
	if bridge and bridge.payments and bridge.payments.purchase then
		local ok = pcall(function()
			bridge.payments.purchase(product_id, options, function(res)
				handle_purchase_granted(product_id, res)
			end, function(err)
				log("❌ Purchase failed or cancelled via Lua bridge:", tostring(err))
				if on_failure then on_failure(err) end
			end)
		end)
		if ok then return end
	end

	-- 2. HTML5 Web JS Bridge
	if html5 and html5.run then
		local js = string.format([[
			(function() {
				window._purchaseStatus = "pending";
				try {
					var b = window.bridge || window.playgamaBridge;
					if (b && b.payments && typeof b.payments.purchase === 'function') {
						b.payments.purchase({ id: %q }).then(function(res) {
							window._purchaseStatus = "success";
							window._lastPurchaseRes = res ? JSON.stringify(res) : "";
						}).catch(function(err) {
							window._purchaseStatus = "failed";
							window._lastPurchaseErr = String(err);
						});
						return "1";
					}
				} catch(e) {}
				return "0";
			})();
		]], product_id)
		local ok_eval, res = pcall(html5.run, js)
		if ok_eval and res == "1" then
			local poll_timer
			local elapsed = 0
			poll_timer = safe_timer_delay(0.2, true, function()
				elapsed = elapsed + 0.2
				if not html5 or not html5.run or elapsed > 180 then
					safe_timer_cancel(poll_timer)
					if on_failure then on_failure("Purchase timeout") end
					return
				end
				local ok_status, status = pcall(html5.run, "(function() { return window._purchaseStatus || ''; })()")
				if ok_status and status == "success" then
					safe_timer_cancel(poll_timer)
					handle_purchase_granted(product_id, { id = product_id })
				elseif ok_status and status == "failed" then
					safe_timer_cancel(poll_timer)
					if on_failure then on_failure("Purchase failed or cancelled") end
				end
			end)
			return
		end
	end

	-- 3. Mock platform fallback (Desktop / Local testing)
	log("🧪 Mock platform: Auto-approving purchase for testing:", product_id)
	handle_purchase_granted(product_id, { id = product_id })
end

function M.check_pending_purchases()
	if not M.is_payments_supported() then return end
	M.get_purchases(function(purchases)
		if type(purchases) == "table" then
			local profile_ok, profile = pcall(require, "lua_modules.player_profile")
			for _, item in ipairs(purchases) do
				local pid = item.id or item.productID or item
				if pid == "no_ads" then
					log("💎 Restoring permanent purchase: no_ads")
					if profile_ok and profile and profile.set_no_ads then
						profile.set_no_ads(true)
					end
				elseif type(pid) == "string" and (pid:match("^coins_") or pid:match("^stars_")) then
					log("📦 Found unconsumed purchase:", pid)
					if profile_ok and profile and profile.apply_purchase then
						profile.apply_purchase(pid)
					end
					M.consume_purchase(item.token or pid)
				end
			end
		end
	end)
end

return M
