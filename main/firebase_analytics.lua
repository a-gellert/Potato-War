-- main/firebase_analytics.lua
-- Firebase Analytics wrapper for Defold (extension-firebase + extension-firebase-analytics).
-- Used for MMP (Mobile Measurement Partner) revenue tracking and custom events.

local M = {}

local initialized = false
local initializing = false
local pending_events = {}

local function log(...)
	print("[Firebase]", ...)
end

function M.is_supported()
	return _G.firebase ~= nil
end

local function flush_pending()
	if not initialized or not _G.firebase or not _G.firebase.analytics then return end
	if #pending_events == 0 then return end

	log("Flushing", #pending_events, "queued events...")
	for _, item in ipairs(pending_events) do
		M.log_event(item.name, item.params)
	end
	pending_events = {}
end

local function on_analytics_callback(self, message_id, message)
	if not _G.firebase or not _G.firebase.analytics then return end
	if message_id == _G.firebase.analytics.MSG_ERROR then
		log("Analytics error:", message and message.error)
	elseif message_id == _G.firebase.analytics.MSG_INSTANCE_ID then
		log("Analytics instance_id:", message and message.instance_id)
	end
end

local function on_core_callback(self, message_id, message)
	if not _G.firebase then return end

	if message_id == _G.firebase.MSG_INITIALIZED then
		log("Core Firebase initialized successfully")
		if _G.firebase.analytics then
			if _G.firebase.analytics.set_callback then
				pcall(_G.firebase.analytics.set_callback, on_analytics_callback)
			end
			local ok, err = pcall(_G.firebase.analytics.initialize)
			if ok then
				initialized = true
				initializing = false
				log("Firebase Analytics initialized successfully")
				flush_pending()
			else
				log("Firebase Analytics initialize error:", err)
			end
		else
			log("extension-firebase-analytics not detected in runtime")
		end
	elseif message_id == _G.firebase.MSG_ERROR then
		log("Core Firebase error:", message and message.error)
		initializing = false
	end
end

function M.init()
	if initialized or initializing then return end
	if not M.is_supported() then
		log("Firebase not supported on this platform/build (desktop/web mock)")
		return
	end

	initializing = true
	log("Initializing Firebase Core...")
	local ok, err = pcall(function()
		_G.firebase.set_callback(on_core_callback)
		_G.firebase.initialize()
	end)

	if not ok then
		log("Failed to start Firebase initialization:", err)
		initializing = false
	end
end

--- Log a general analytics event with table parameters
function M.log_event(name, params)
	if not name or name == "" then return end

	if not initialized then
		if M.is_supported() then
			table.insert(pending_events, { name = name, params = params })
			if not initializing then M.init() end
		end
		return
	end

	if not _G.firebase or not _G.firebase.analytics then return end

	local fa = _G.firebase.analytics
	if params and type(params) == "table" then
		if fa.log_table then
			local ok, err = pcall(fa.log_table, name, params)
			if ok then return end
			log("log_table failed, falling back to individual log calls:", err)
		end
		-- Fallback if log_table is unavailable
		for k, v in pairs(params) do
			if type(v) == "number" then
				if fa.log_number then pcall(fa.log_number, name, tostring(k), v)
				elseif fa.log_float then pcall(fa.log_float, name, tostring(k), v) end
			elseif type(v) == "string" then
				if fa.log_string then pcall(fa.log_string, name, tostring(k), v) end
			end
		end
	else
		if fa.log then pcall(fa.log, name) end
	end
end

--- Tracks MMP ad revenue impression required by the AppLovin + Firebase MMP guide:
--- Event: "ad_impression"
--- Parameters:
---   ad_platform: "AppLovin"
---   ad_source: networkName
---   ad_unit_name: adUnitIdentifier
---   ad_format: format
---   value: revenue (double/number)
---   currency: "USD"
function M.log_ad_impression(ad_info)
	ad_info = ad_info or {}
	local revenue = tonumber(ad_info.revenue) or 0.0

	local params = {
		ad_platform = "AppLovin",
		ad_source = tostring(ad_info.networkName or "unknown"),
		ad_unit_name = tostring(ad_info.adUnitIdentifier or ""),
		ad_format = tostring(ad_info.format or ""),
		value = revenue,
		currency = "USD",
	}

	log("Ad impression tracked:", params.ad_unit_name, "Source:", params.ad_source, "Revenue:", revenue, "USD")
	M.log_event("ad_impression", params)
end

return M
