-- main/applovin_ads.lua
-- AppLovin MAX (extension-applovin) for Android / iOS builds.
-- The `applovin` global exists only in mobile builds; on Web / Desktop every call is a no-op.
-- SDK key and ad unit IDs live in the [max] section of game.project.

local M = {}

-- Delays before reloading after a failed load (seconds), capped at the last value
local RETRY_DELAYS = { 2, 4, 8, 16, 32, 64 }
-- A reward event may arrive slightly after the "hidden" event on some networks
local REWARD_GRACE_SEC = 0.5

local initialized = false
local ad_units = { rewarded = "", interstitial = "", banner = "" }
local loading = {}
local load_failures = {}
local banner_created = false

local interstitial_done_cb = nil
local rewarded_done_cb = nil
local reward_earned = false

local function log(...)
	print("[AppLovin]", ...)
end

local function load_ad(ad_unit_id)
	if not initialized or ad_unit_id == "" or loading[ad_unit_id] then return end
	loading[ad_unit_id] = true
	if ad_unit_id == ad_units.rewarded then
		applovin.load_rewarded_ad(ad_unit_id)
	else
		applovin.load_interstitial(ad_unit_id)
	end
end

local function on_load_failed(ad_unit_id)
	loading[ad_unit_id] = nil
	local failures = (load_failures[ad_unit_id] or 0) + 1
	load_failures[ad_unit_id] = failures
	local delay = RETRY_DELAYS[math.min(failures, #RETRY_DELAYS)]
	timer.delay(delay, false, function()
		load_ad(ad_unit_id)
	end)
end

local function finish_interstitial()
	local cb = interstitial_done_cb
	interstitial_done_cb = nil
	if cb then pcall(cb) end
end

local function finish_rewarded()
	local cb = rewarded_done_cb
	local earned = reward_earned
	rewarded_done_cb = nil
	reward_earned = false
	if cb then pcall(cb, earned) end
end

local function on_max_event(self, name, params)
	params = params or {}
	local ad_unit_id = params.adUnitIdentifier

	if name == "OnSdkInitializedEvent" then
		log("Initialized, country:", tostring(params.countryCode))
		initialized = true
		load_ad(ad_units.interstitial)
		load_ad(ad_units.rewarded)

	elseif name == "OnInterstitialAdLoadedEvent" or name == "OnRewardedAdLoadedEvent" then
		loading[ad_unit_id] = nil
		load_failures[ad_unit_id] = 0
	elseif name == "OnInterstitialAdLoadFailedEvent" or name == "OnRewardedAdLoadFailedEvent" then
		log("Load failed:", tostring(ad_unit_id), tostring(params.code), tostring(params.message))
		on_load_failed(ad_unit_id)

	elseif name == "OnInterstitialAdHiddenEvent" or name == "OnInterstitialAdDisplayFailedEvent" then
		if name == "OnInterstitialAdDisplayFailedEvent" then
			log("Interstitial display failed:", tostring(params.code), tostring(params.message))
		end
		finish_interstitial()
		load_ad(ad_unit_id)

	elseif name == "OnRewardedAdReceivedRewardEvent" then
		reward_earned = true
	elseif name == "OnRewardedAdHiddenEvent" then
		if reward_earned then
			finish_rewarded()
		else
			timer.delay(REWARD_GRACE_SEC, false, finish_rewarded)
		end
		load_ad(ad_unit_id)
	elseif name == "OnRewardedAdDisplayFailedEvent" then
		log("Rewarded display failed:", tostring(params.code), tostring(params.message))
		reward_earned = false
		finish_rewarded()
		load_ad(ad_unit_id)
	end
end

function M.is_supported()
	return applovin ~= nil
end

function M.init()
	if not M.is_supported() then return end

	local is_ios = (sys.get_sys_info().system_name == "iPhone OS")
	local prefix = is_ios and "max.ios_" or "max.android_"
	ad_units.rewarded = sys.get_config_string(prefix .. "rewarded_ad_unit_id", "")
	ad_units.interstitial = sys.get_config_string(prefix .. "interstitial_ad_unit_id", "")
	ad_units.banner = sys.get_config_string(prefix .. "banner_ad_unit_id", "")

	local sdk_key = sys.get_config_string("max.sdk_key", "")
	if sdk_key == "" then
		log("max.sdk_key is empty in game.project — ads disabled")
		return
	end

	applovin.set_callback(on_max_event)
	applovin.set_verbose_logging_enabled(sys.get_config_int("max.debug_mode", 0) == 1)

	-- MAX consent flow (GDPR / UMP, iOS ATT) needs a public privacy policy URL
	local privacy_url = sys.get_config_string("max.privacy_policy_url", "")
	if privacy_url ~= "" then
		applovin.set_terms_and_privacy_policy_flow_enabled(true)
		applovin.set_privacy_policy_url(privacy_url)
		local terms_url = sys.get_config_string("max.terms_of_service_url", "")
		if terms_url ~= "" then
			applovin.set_terms_of_service_url(terms_url)
		end
	end

	applovin.initialize(sdk_key)
end

--- Shows an interstitial if one is loaded. `on_done()` runs when it closes or fails to display.
--- Returns false (and does not call `on_done`) when nothing is ready.
function M.show_interstitial(on_done, placement)
	if not initialized or ad_units.interstitial == "" or not applovin.is_interstitial_ready(ad_units.interstitial) then
		load_ad(ad_units.interstitial)
		return false
	end
	interstitial_done_cb = on_done
	applovin.show_interstitial(ad_units.interstitial, placement or "interstitial")
	return true
end

--- Shows a rewarded ad if one is loaded. `on_done(earned)` runs once the ad closes or fails to display.
--- Returns false (and does not call `on_done`) when nothing is ready.
function M.show_rewarded(on_done, placement)
	if not initialized or ad_units.rewarded == "" or not applovin.is_rewarded_ad_ready(ad_units.rewarded) then
		load_ad(ad_units.rewarded)
		return false
	end
	rewarded_done_cb = on_done
	reward_earned = false
	applovin.show_rewarded_ad(ad_units.rewarded, placement or "rewarded")
	return true
end

function M.show_banner()
	if not initialized or ad_units.banner == "" then return end
	if not banner_created then
		applovin.create_banner(ad_units.banner, "bottom_center")
		banner_created = true
	end
	applovin.show_banner(ad_units.banner)
end

function M.hide_banner()
	if banner_created then
		applovin.hide_banner(ad_units.banner)
	end
end

--- Mediation Debugger: shows the state of every network adapter (use on a test device)
function M.show_mediation_debugger()
	if initialized then
		applovin.show_mediation_debugger()
	end
end

return M
