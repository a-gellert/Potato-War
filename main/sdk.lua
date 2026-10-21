-- main/sdk.lua
-- Unified SDK Wrapper: Playgama Bridge SDK (HTML5/Web & Desktop Mock) for Potato War

local M = {}

----------------------------------------------------------
-- PLATFORM TYPES
----------------------------------------------------------
M.PLATFORM_PLAYGAMA = "playgama"
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
M.last_interstitial_time = 0 -- timestamp of last interstitial shown (os.time)

-- Minimum seconds between interstitial ads (60 seconds)
local AD_COOLDOWN = 60
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
		local js = "console.log('%c[SDK WRAPPER]', 'color: #8bc34a; font-weight: bold;', '" .. msg .. "');"
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

	-- 1. Defold Sound Groups Gain
	pcall(sound.set_group_gain, hash("master"), 0)
	pcall(sound.set_group_gain, "master", 0)

	-- 2. Web Audio Context suspend + HTML5 media mute (Web/HTML5)
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

	-- 1. Defold Sound Groups Gain
	pcall(sound.set_group_gain, hash("master"), 1)
	pcall(sound.set_group_gain, "master", 1)

	-- 2. Web Audio Context resume (Web/HTML5)
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
								pcall(cb)
							end
							if current_reward_close_cb then
								local cb = current_reward_close_cb
								current_reward_close_cb = nil
								pcall(cb, true)
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
						pcall(cb)
					end
					if current_reward_close_cb then
						local cb = current_reward_close_cb
						current_reward_close_cb = nil
						pcall(cb, earned)
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

		-- 3. Platform Audio & Pause Listeners
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
function M.init()
	if M.initialized then return end
	M.initialized = true
	M.last_interstitial_time = os.time() -- Cooldown starts on init so first ad has cooldown period

	local sys_info = sys.get_sys_info()
	local is_web = (sys_info.system_name == "HTML5") or (html5 ~= nil and html5.run ~= nil)

	-- Resolve Defold Lua bridge binding from multiple sources
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

	-- Web/HTML5 OR Bridge found -> Playgama Bridge Platform
	if is_web or mod ~= nil then
		bridge = mod
		M.active_platform = M.PLATFORM_PLAYGAMA
		local platform_id = M.get_platform_id()
		log("🌐 Playgama Bridge active (Platform: " .. tostring(platform_id) .. ", has_lua_bridge: " .. tostring(bridge ~= nil) .. ")")
		setup_playgama_listeners()

		-- Check initial platform audio state from Defold Lua bridge
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

		-- Check initial platform audio & pause state from browser JS bridge
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

			-- Continuous background synchronization
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
		return
	end

	-- Fallback to Mock on desktop editor without bridge
	M.active_platform = M.PLATFORM_MOCK
	log("💻 Running in Editor / Desktop fallback mock")
end

----------------------------------------------------------
-- DUAL-CHANNEL PLATFORM MESSAGE SENDER (LUA BINDING + HTML5 JS)
----------------------------------------------------------
local function send_platform_message(msg_name, options)
	options = options or {}
	if not M.initialized then M.init() end

	log("📤 send_platform_message: '" .. tostring(msg_name) .. "'")

	-- Channel 1: Defold Lua Bridge extension
	if bridge and bridge.platform then
		local send_fn = bridge.platform.send_message or bridge.platform.sendMessage
		if send_fn then
			pcall(send_fn, msg_name, options, function()
				log("✅ [Defold Bridge] Message delivered:", msg_name)
			end, function(err)
				log("⚠️ [Defold Bridge] Message error callback:", msg_name, tostring(err))
			end)
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
						}
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
end

----------------------------------------------------------
-- LIFECYCLE: IN-GAME LOADING
----------------------------------------------------------
function M.in_game_loading_started()
	send_platform_message("in_game_loading_started")
end

function M.in_game_loading_stopped()
	send_platform_message("in_game_loading_stopped")
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
end

function M.gameplay_stop(world, level)
	if not M.gameplay_active then return end
	M.gameplay_active = false
	log("⏹️ gameplay_stop()", world, level)

	local opts = {}
	if world then opts.world = tostring(world) end
	if level then opts.level = tostring(level) end

	send_platform_message("gameplay_stopped", opts)
end

----------------------------------------------------------
-- ROUND & LEVEL PROGRESSION
----------------------------------------------------------
function M.round_start(round_or_level)
	M.current_round = round_or_level or M.current_round or 1
	log("🚩 round_start:", M.current_round)

	send_platform_message("level_started", { level = M.current_round })
end

function M.round_end(victory, round_or_level)
	local r = round_or_level or M.current_round or 1
	log("🏁 round_end:", victory and "VICTORY" or "DEFEAT", "Round/Level:", r)

	local event_name = victory and "level_completed" or "level_failed"
	send_platform_message(event_name, { level = r })
end

function M.level_paused()
	send_platform_message("level_paused")
end

function M.level_resumed()
	send_platform_message("level_resumed")
end

function M.happy_time(intensity)
	intensity = intensity or 1.0
	log("🎉 happy_time (intensity: " .. tostring(intensity) .. ")")

	if intensity >= 1.0 then
		send_platform_message("player_got_achievement", { type = "victory" })
	end
end

----------------------------------------------------------
-- INTERSTITIAL ADS (COMMERCIAL BREAK)
----------------------------------------------------------
function M.commercial_break(callback, placement)
	if not M.initialized then M.init() end

	if M.ad_showing then
		if callback then callback() end
		return
	end

	local placement_str = tostring(placement or "interstitial")
	pause_audio()

	-- Portal requirement: Stop active gameplay before showing ad
	if M.gameplay_active then
		log("⏸️ Pausing gameplay before interstitial ad")
		resume_gameplay_after_ad = true
		M.gameplay_stop()
	end

	-- 1. Playgama Bridge (Web)
	if M.active_platform == M.PLATFORM_PLAYGAMA then
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

		-- Always poll the JS state transitions in Web/HTML5 for reliable callback
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

	-- 2. Mock Desktop / Editor
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

--- Show interstitial ad only if cooldown (AD_COOLDOWN = 60s) has elapsed since last one.
function M.try_commercial_break(callback, placement)
	local elapsed = os.time() - M.last_interstitial_time
	if elapsed < AD_COOLDOWN then
		log("⏳ Interstitial cooldown active (" .. string.format("%.0f", elapsed) .. "s / " .. AD_COOLDOWN .. "s) — skipping ad")
		if callback then callback() end
		return
	end
	M.commercial_break(callback, placement)
end

function M.is_interstitial_supported()
	if not M.initialized then M.init() end
	if bridge and bridge.advertisement and bridge.advertisement.is_interstitial_supported then
		return bridge.advertisement.is_interstitial_supported()
	end
	return true
end

----------------------------------------------------------
-- REWARDED ADS (REWARDED BREAK)
----------------------------------------------------------
function M.rewarded_break(on_reward, on_close, placement_or_size)
	if not M.initialized then M.init() end

	local placement = (placement_or_size and placement_or_size ~= "") and tostring(placement_or_size) or "rewarded"
	log("🎁 rewarded_break() requested — placement: '" .. placement .. "'")

	if M.ad_showing then
		log("⚠️ Ad already showing, ignoring duplicate rewarded_break call")
		if on_close then on_close(false) end
		return
	end

	pause_audio()

	-- Stop active gameplay before showing ad
	if M.gameplay_active then
		log("⏸️ Pausing gameplay before rewarded ad")
		resume_gameplay_after_ad = true
		M.gameplay_stop()
	end

	if reward_timeout_timer then
		safe_timer_cancel(reward_timeout_timer)
		reward_timeout_timer = nil
	end

	-- 1. Playgama Bridge
	if M.active_platform == M.PLATFORM_PLAYGAMA then
		log("🎁 Showing Playgama rewarded ad (placement: " .. tostring(placement) .. ")...")
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
					} catch(e) {}
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
								pcall(cb)
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
							pcall(cb)
						end
						if current_reward_close_cb then
							local cb = current_reward_close_cb
							current_reward_close_cb = nil
							pcall(cb, earned)
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

	-- 2. Mock
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
-- CLOUD STORAGE (PLAYGAMA BRIDGE STORAGE)
----------------------------------------------------------
function M.storage_get(keys, on_success, on_failure)
	if not M.initialized then M.init() end

	local keys_list = keys
	if type(keys) == "string" then
		keys_list = { keys }
	end

	local responded = false

	-- Channel 1: Bridge Lua extension
	if bridge and bridge.storage and bridge.storage.get then
		pcall(function()
			bridge.storage.get(keys_list, function(arg1, arg2)
				if responded then return end
				responded = true
				local data = (type(arg2) == "table") and arg2 or ((type(arg1) == "table") and arg1 or nil)
				log("📦 Playgama storage_get success, keys loaded:", data and next(data) ~= nil)
				if on_success then on_success(nil, data) end
			end, function(arg1, arg2)
				local err = arg2 or arg1
				log("⚠️ Playgama storage_get failure:", tostring(err))
				if not responded then
					responded = true
					if on_failure then on_failure(err) end
				end
			end)
		end)
	end

	-- Channel 2: Direct browser JS fallback
	if html5 and html5.run and not responded then
		local key = (keys_list and keys_list[1]) or "player_profile"
		local js = string.format([[
			(function() {
				var k = %q;
				try {
					var b = window.bridge || window.playgamaBridge;
					if (b && b.storage && typeof b.storage.get === 'function') {
						b.storage.get([k]).then(function(res) {
							window._lastStorageGet = res ? JSON.stringify(res) : "";
						}).catch(function(e) { window._lastStorageGet = ""; });
					}
				} catch(e) {}
			})();
		]], key)
		pcall(html5.run, js)
	end

	if not responded and on_success then
		on_success(nil, nil)
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

	-- Channel 1: Bridge Defold
	if bridge and bridge.storage and bridge.storage.set then
		pcall(function()
			bridge.storage.set(data, function(arg1, arg2)
				log("✅ Playgama storage_set success")
				if success_cb then success_cb() end
			end, function(arg1, arg2)
				local err = arg2 or arg1
				log("⚠️ Playgama storage_set failure:", tostring(err))
				if failure_cb then failure_cb(err) end
			end)
		end)
	end

	-- Channel 2: Direct Web JS
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
						var b = window.bridge || window.playgamaBridge;
						if (b && b.storage && typeof b.storage.set === 'function') {
							b.storage.set([k], [v]).catch(function(e) {});
						}
					} catch(e) {}
				})();
			]], tostring(k), val_json)
			pcall(html5.run, js)
		end
	end

	if not (bridge and bridge.storage and bridge.storage.set) then
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
			bridge.storage.delete(keys_list, function()
				log("🗑️ Playgama storage_delete success")
				if on_success then on_success() end
			end, function(err)
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
	end
	return "mock"
end

function M.get_language()
	if not M.initialized then M.init() end

	-- 1. Playgama Bridge Lua binding
	if bridge and bridge.platform and bridge.platform.language then
		local ok, lang = pcall(bridge.platform.language)
		if ok and lang and lang ~= "" then
			log("🌐 Language from bridge.platform.language():", lang)
			return lang
		end
	end

	-- 2. JS-level bridge (HTML5)
	if html5 and html5.run then
		local ok, lang = pcall(html5.run, [[(function() {
			try {
				var b = window.bridge || window.playgamaBridge;
				if (b && b.platform && typeof b.platform.language === 'function') {
					return b.platform.language() || '';
				}
				if (b && b.platform && typeof b.platform.language === 'string') {
					return b.platform.language || '';
				}
			} catch(e) {}
			return navigator.language || navigator.userLanguage || '';
		})()]])
		if ok and lang and lang ~= "" then
			log("🌐 Language from JS bridge/navigator:", lang)
			return lang
		end
	end

	-- 3. Defold sys_info fallback
	local sys_info = sys.get_sys_info()
	return sys_info.device_language or "en"
end

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

return M
