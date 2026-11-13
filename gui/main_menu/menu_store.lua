-- gui/main_menu/menu_store.lua
-- Store window: free coins for a rewarded ad (every platform with rewarded ads, Poki included) and,
-- where in-app purchases are on and supported (main/sdk.lua: [potato_war] iap, Playgama payments,
-- Google Play Billing), the paid products with prices from the platform catalog. Opened from the
-- coin / star counters and as the paywall when the player cannot afford an upgrade, a hat or a class.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local sdk = require("main.sdk")
local player_profile = require("lua_modules.player_profile")
local daily_rewards = require("lua_modules.daily_rewards")
local game_state = require("lua_modules.game_state")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

local SLOTS = 8
local CARD_W, CARD_H = 150, 150
local COL_X = { -243, -81, 81, 243 }
local ROW_Y = { 62, -100 }

-- Card frame and icon of a product
local LOOKS = {
	starter_pack = { frame = "card_legendary", icon = "crate_gold" },
	coins_pack_1000 = { frame = "card_rare", icon = "ic_coin" },
	coins_pack_5000 = { frame = "card_epic", icon = "ic_coin" },
	stars_pack_5 = { frame = "card_rare", icon = "ic_star" },
	stars_pack_20 = { frame = "card_epic", icon = "ic_star" },
	no_ads = { frame = "card_common", icon = "ic_ad" },
}

local function status(self, text, color)
	local note = self.store.note
	gui.cancel_animations(note, "color.w")
	gui.set_color(note, color or kit.C.muted)
	kit.set_text(note, text, 620, 16, "label")
end

-- What the window offers right now: the free card first, then priced products (starter pack on top)
local function offers()
	local list = {}
	-- (debug builds always show it: the local bridge mock reports no rewarded ads but plays them)
	if sdk.is_rewarded_supported() or sys.get_engine_info().is_debug then
		list[1] = { free = true }
	end
	if sdk.is_payments_supported() then
		local paid = {}
		for i, p in ipairs(sdk.DEFAULT_PRODUCTS) do
			local price = sdk.get_price(p.id)
			if price and not (sdk.is_permanent(p.id) and player_profile.owns(p.id)) then
				table.insert(paid, { product = p, price = price, rank = (p.id == "starter_pack") and 0 or i })
			end
		end
		table.sort(paid, function(a, b) return a.rank < b.rank end)
		for _, o in ipairs(paid) do
			table.insert(list, o)
		end
	end
	return list
end

local function on_free(self)
	if daily_rewards.ad_coins_left() <= 0 then
		status(self, i18n.t("ui_daily_next"))
		return
	end
	game_state.poki_rewarded_break(function(success)
		if success and daily_rewards.grant_ad_coins() then
			sound_manager.play("coins")
			status(self, "+" .. daily_rewards.AD_COINS, kit.C.gold)
			if self.on_changed then self.on_changed() end
		end
		M.refresh(self)
	end)
end

local function on_buy(self, offer)
	if self.store.busy then return end
	self.store.busy = true
	status(self, "...")
	sdk.purchase(offer.product.id, function()
		self.store.busy = false
		sound_manager.play("coins")
		sound_manager.play("unlock")
		status(self, i18n.t("ui_store_done"), kit.C.green)
		if self.on_changed then self.on_changed() end
		M.refresh(self)
	end, function(reason)
		self.store.busy = false
		status(self, (reason == "cancelled") and "" or i18n.t("ui_store_failed"), kit.C.red)
	end)
end

function M.build(self, on_close)
	local win = kit.window(self.ui, nil, "store", 680, 420, "", on_close)
	self.store = win
	local p = win.panel
	win.slots = {}
	for i = 1, SLOTS do
		local col = (i - 1) % 4 + 1
		local row = math.floor((i - 1) / 4) + 1
		local s = { node = kit.card(p, COL_X[col], ROW_Y[row], CARD_W, CARD_H, "common") }
		s.icon = kit.icon(s.node, "ic_coin", 0, 30, 56)
		s.name = kit.text(s.node, "", 0, -14, 14, { font = "label", max_w = CARD_W - 12 })
		s.btn = kit.button(self.ui, s.node, "store_buy_" .. i, 0, -50, CARD_W - 20, 40, { style = "green", label = "", px = 16, on_click = function()
			if s.offer and s.offer.free then
				on_free(self)
			elseif s.offer then
				on_buy(self, s.offer)
			end
		end })
		gui.set_enabled(s.node, false)
		win.slots[i] = s
	end
	win.note = kit.text(p, "", 0, -186, 16, { font = "label", color = kit.C.muted, max_w = 620 })
	gui.set_enabled(win.root, false)

	-- A purchase restored or granted at any time (boot restore, store callback) refreshes the menu
	sdk.on_purchase = function()
		if self.on_changed then self.on_changed() end
		if gui.is_enabled(win.root) then M.refresh(self) end
	end
end

function M.refresh(self)
	local win = self.store
	kit.set_text(win.title, i18n.t("ui_store"), 520, 26, "title")
	local list = offers()
	for i, s in ipairs(win.slots) do
		local o = list[i]
		s.offer = o
		gui.set_enabled(s.node, o ~= nil)
		if o and o.free then
			local left = daily_rewards.ad_coins_left()
			kit.set_image(s.node, "card_common")
			kit.set_icon(s.icon, "ic_coin", 56, 56, "ui")
			kit.set_text(s.name, string.format(i18n.t("ui_free_coins_fmt"), daily_rewards.AD_COINS), CARD_W - 12, 14, "label")
			s.btn.set_label(string.format("%d/%d", left, daily_rewards.AD_COINS_PER_DAY))
		elseif o then
			local look = LOOKS[o.product.id] or LOOKS.coins_pack_1000
			kit.set_image(s.node, look.frame)
			kit.set_icon(s.icon, look.icon, 64, 56, "ui")
			kit.set_text(s.name, i18n.field(o.product, "name"), CARD_W - 12, 14, "label")
			s.btn.set_label(o.price)
		end
	end
	if #list == 0 then
		status(self, i18n.t("ui_store_empty"))
	end
end

-- Opened as a paywall: say why (not enough coins / stars)
function M.paywall(self, reason)
	status(self, reason, kit.C.red)
end

function M.show(self, visible)
	gui.set_enabled(self.store.root, visible)
	if visible then
		self.store.busy = false
		status(self, "")
		M.refresh(self)
		kit.pop_in(self.store.panel)
		-- Prices come from the platform catalog; redraw once they arrive
		sdk.refresh_catalog(function()
			if gui.is_enabled(self.store.root) then
				M.refresh(self)
			end
		end)
	end
end

return M
