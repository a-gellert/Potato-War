-- gui/main_menu/menu_shop.lua
-- Hat shop overlay: points display, card layout/state, equip & buy handling.

local player_profile = require("lua_modules.player_profile")
local i18n = require("lua_modules.i18n")

local M = {}

local CARD_POSITIONS = {
	-- Row 1 (4 items)
	vmath.vector3(-330, 85, 0), vmath.vector3(-110, 85, 0), vmath.vector3(110, 85, 0), vmath.vector3(330, 85, 0),
	-- Row 2 (3 items)
	vmath.vector3(-220, -75, 0), vmath.vector3(0, -75, 0), vmath.vector3(220, -75, 0),
}

function M.update_points(self)
	local pts = player_profile.get_points()
	pcall(function()
		gui.set_text(gui.get_node("txt_total_points"), i18n.t("points_lbl") .. tostring(pts))
		gui.set_text(gui.get_node("shop_points"), i18n.t("shop_points_lbl") .. tostring(pts))
	end)
end

local function update_card(i, hat, equipped, points)
	local btn_node = gui.get_node("btn_skin_" .. i)
	local txt_node = gui.get_node("txt_skin_" .. i)
	gui.set_text(gui.get_node("skin_name_" .. i), player_profile.get_skin_name(hat, i18n.current_lang))
	gui.set_text(gui.get_node("skin_desc_" .. i), player_profile.get_skin_desc(hat, i18n.current_lang))

	if hat.id == equipped then
		gui.set_text(txt_node, i18n.t("shop_equipped"))
		gui.set_color(btn_node, vmath.vector4(0.18, 0.80, 0.44, 1.0))
	elseif player_profile.is_skin_unlocked(hat.id) then
		gui.set_text(txt_node, i18n.t("shop_equip"))
		gui.set_color(btn_node, vmath.vector4(0.18, 0.50, 0.82, 1.0))
	elseif points >= hat.price then
		gui.set_text(txt_node, i18n.t("btn_buy", hat.price))
		gui.set_color(btn_node, vmath.vector4(0.85, 0.65, 0.15, 1.0))
	else
		gui.set_text(txt_node, i18n.t("shop_locked_fmt", hat.price))
		gui.set_color(btn_node, vmath.vector4(0.35, 0.38, 0.45, 1.0))
	end
end

function M.update(self)
	M.update_points(self)
	local points = player_profile.get_points()

	pcall(function()
		gui.set_text(gui.get_node("shop_title"), i18n.t("menu_shop"))
		gui.set_text(gui.get_node("txt_shop_back"), i18n.t("menu_back"))
		gui.set_position(gui.get_node("btn_shop_back"), vmath.vector3(0, -215, 0))

		for i = 1, 7 do
			gui.set_position(gui.get_node("skin_bg_" .. i), CARD_POSITIONS[i])
			gui.set_enabled(gui.get_node("skin_bg_" .. i), true)
			gui.set_enabled(gui.get_node("btn_skin_" .. i), true)
		end

		local hats = player_profile.SKINS
		local equipped = player_profile.data.equipped_skin or "classic"
		for i = 1, 7 do
			if hats[i] then
				update_card(i, hats[i], equipped, points)
			end
		end
	end)
end

local function on_card_click(self, idx)
	local skin = player_profile.SKINS[idx]
	if not skin then return end

	if player_profile.is_skin_unlocked(skin.id) then
		player_profile.equip_skin(skin.id)
	elseif not player_profile.buy_skin(skin.id) then
		-- Not enough points: squash-and-bounce the card button
		local btn = gui.get_node("btn_skin_" .. idx)
		pcall(function()
			gui.cancel_animations(btn, "scale")
			gui.set_scale(btn, vmath.vector3(1.10, 0.88, 1.0))
			gui.animate(btn, "scale", vmath.vector3(1.0, 1.0, 1.0), gui.EASING_OUTBOUNCE, 0.25)
		end)
	end
	M.update(self)
end

function M.register(self)
	for i = 1, 7 do
		self.ui:button("btn_skin_" .. i, function() on_card_click(self, i) end)
		self.ui:button("skin_bg_" .. i, function() on_card_click(self, i) end)
	end
end

return M
