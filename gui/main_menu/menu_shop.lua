-- gui/main_menu/menu_shop.lua
-- Hat shop: pages of rarity cards; tap a card to equip an owned hat or buy a new one.

local kit = require("lua_modules.ui_kit")
local i18n = require("lua_modules.i18n")
local player_profile = require("lua_modules.player_profile")
local sound_manager = require("lua_modules.sound_manager")

local M = {}

local PER_PAGE = 8
local CARD_W, CARD_H = 172, 168
local COLS = { -285, -95, 95, 285 }
local ROWS = { 78, -102 }

local function page_count()
	return math.ceil(#player_profile.SKINS / PER_PAGE)
end

local function message(self, text, color)
	local note = self.shop.note
	gui.set_text(note, text)
	gui.set_color(note, color or kit.C.red)
	gui.cancel_animations(note, "color.w")
	gui.animate(note, "color.w", 0, gui.EASING_INQUAD, 0.6, 1.6)
end

local function on_card(self, slot)
	local hat = player_profile.SKINS[(self.shop.page - 1) * PER_PAGE + slot]
	if not hat then
		return
	end
	if player_profile.is_skin_unlocked(hat.id) then
		player_profile.equip_skin(hat.id)
		sound_manager.play("pop")
	elseif player_profile.get_points() >= hat.price then
		player_profile.buy_skin(hat.id)
		sound_manager.play("coins")
		sound_manager.play("unlock")
		kit.pop_in(self.shop.cards[slot].btn.node)
	else
		sound_manager.play("tick")
		message(self, i18n.t("ui_need_coins"))
		return
	end
	M.refresh(self)
	if self.on_changed then
		self.on_changed()
	end
end

local function build_card(self, parent, slot, x, y)
	local card = {}
	card.btn = kit.button(self.ui, parent, "shop_card_" .. slot, x, y, CARD_W, CARD_H, { style = "dark", on_click = function()
		on_card(self, slot)
	end })
	card.frame = card.btn.node
	kit.box(card.frame, "glow", 0, 24, 140, 110, vmath.vector4(1, 1, 1, 0.12))
	card.hat = kit.icon(card.frame, "hat_cap", 0, 26, 104, { texture = "game" })
	card.name = kit.text(card.frame, "", 0, -30, 15, { font = "label", max_w = CARD_W - 20 })
	card.coin = kit.icon(card.frame, "ic_coin", -30, -67, 24)
	card.price = kit.text(card.frame, "", 6, -67, 18, { font = "label", align = "left", max_w = 90 })
	card.status = kit.text(card.frame, "", 0, -67, 16, { font = "label", max_w = CARD_W - 24 })
	card.check = kit.icon(card.frame, "ic_check", 64, 62, 30)
	return card
end

function M.build(self, on_close)
	local win = kit.window(self.ui, nil, "shop", 880, 480, "", on_close)
	self.shop = win
	win.page = 1
	local p = win.panel
	win.coins = kit.counter(p, "ic_coin", 330, 168, 140, "0")
	win.cards = {}
	for slot = 1, PER_PAGE do
		local col = (slot - 1) % 4 + 1
		local row = math.floor((slot - 1) / 4) + 1
		win.cards[slot] = build_card(self, p, slot, COLS[col], ROWS[row])
	end
	win.prev = kit.icon_button(self.ui, p, "shop_prev", -432, -12, 54, "ic_left", function()
		win.page = (win.page - 2) % page_count() + 1
		M.refresh(self)
	end, "round_gold")
	win.next = kit.icon_button(self.ui, p, "shop_next", 432, -12, 54, "ic_right", function()
		win.page = win.page % page_count() + 1
		M.refresh(self)
	end, "round_gold")
	win.page_text = kit.text(p, "", 0, -212, 18, { font = "label", color = kit.C.muted })
	win.note = kit.text(p, "", 0, 168, 18, { font = "label", color = kit.C.red })
	gui.set_color(win.note, vmath.vector4(1, 0.36, 0.3, 0))
	gui.set_enabled(win.root, false)
end

function M.refresh(self)
	local win = self.shop
	kit.set_text(win.title, i18n.t("ui_hats"), 600, 26, "title")
	kit.set_text(win.coins.text, kit.num(player_profile.get_points()), 96, 19, "label")
	local equipped = player_profile.get_equipped_skin().id
	local points = player_profile.get_points()
	for slot, card in ipairs(win.cards) do
		local hat = player_profile.SKINS[(win.page - 1) * PER_PAGE + slot]
		gui.set_enabled(card.frame, hat ~= nil)
		if hat then
			kit.set_image(card.frame, "card_" .. (hat.rarity or "common"))
			if hat.hat == "none" then
				kit.set_icon(card.hat, "recruit", 96, 104, "game")
			else
				kit.set_icon(card.hat, hat.hat, 120, 100, "game")
			end
			kit.set_text(card.name, player_profile.get_skin_name(hat, i18n.current_lang), CARD_W - 20, 15, "label")
			local owned = player_profile.is_skin_unlocked(hat.id)
			gui.set_enabled(card.check, hat.id == equipped)
			gui.set_enabled(card.coin, not owned)
			gui.set_enabled(card.price, not owned)
			gui.set_enabled(card.status, owned)
			if owned then
				kit.set_text(card.status, i18n.t(hat.id == equipped and "ui_equipped" or "ui_equip"), CARD_W - 24, 16, "label")
				gui.set_color(card.status, hat.id == equipped and kit.C.green or kit.C.white)
			else
				gui.set_text(card.price, kit.num(hat.price))
				gui.set_color(card.price, points >= hat.price and kit.C.gold or kit.C.disabled)
			end
		end
	end
	gui.set_text(win.page_text, win.page .. " / " .. page_count())
end

function M.show(self, visible)
	gui.set_enabled(self.shop.root, visible)
	if visible then
		M.refresh(self)
		kit.pop_in(self.shop.panel)
	end
end

return M
