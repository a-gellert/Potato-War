-- lua_modules/ui_kit.lua
-- "Military midcore" interface kit: builds GUI nodes in code (panels, labels, icons, buttons,
-- bars, rarity cards) on top of main/assets/ui.atlas and the Rubik fonts.
-- Must be called from a gui_script whose .gui declares the textures "ui" and "game" and the
-- fonts "title", "label" and "body". Positions are relative to the parent node (or the screen).

local ui_manager = require("lua_modules.ui_manager")

local M = {}

M.TEX = "ui"

M.C = {
	white = vmath.vector4(0.95, 0.97, 1.0, 1),
	muted = vmath.vector4(0.62, 0.70, 0.80, 1),
	gold = vmath.vector4(1.0, 0.80, 0.25, 1),
	orange = vmath.vector4(1.0, 0.58, 0.18, 1),
	green = vmath.vector4(0.45, 0.92, 0.35, 1),
	red = vmath.vector4(1.0, 0.36, 0.30, 1),
	blue = vmath.vector4(0.45, 0.72, 1.0, 1),
	xp = vmath.vector4(0.35, 0.68, 1.0, 1),
	hp = vmath.vector4(0.40, 0.88, 0.45, 1),
	outline = vmath.vector4(0.02, 0.04, 0.08, 1),
	shadow = vmath.vector4(0.0, 0.0, 0.0, 0.55),
	clear = vmath.vector4(1, 1, 1, 0),
	disabled = vmath.vector4(0.55, 0.58, 0.62, 1),
}

-- Slice-9 margins (left, top, right, bottom) of the stretchable images
local SLICE = {
	panel = { 18, 18, 18, 18 },
	panel_inset = { 12, 12, 12, 12 },
	header = { 16, 8, 16, 10 },
	pill = { 14, 14, 14, 14 },
	bar_bg = { 10, 10, 10, 10 },
	bar_fill = { 10, 10, 10, 10 },
	card_select = { 16, 16, 16, 16 },
}
for _, style in ipairs({ "gold", "green", "blue", "red", "steel", "dark" }) do
	SLICE["btn_" .. style] = { 16, 12, 16, 16 }
end
for _, r in ipairs({ "common", "rare", "epic", "legendary" }) do
	SLICE["card_" .. r] = { 16, 16, 16, 30 }
end

M.FONT_PX = { title = 56, label = 40, body = 34 }

-- ---------- primitives ----------

-- Box node showing an atlas image, stretched with slice-9 when the image supports it
function M.box(parent, image, x, y, w, h, color, texture)
	local node = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_texture(node, texture or M.TEX)
	if image then
		gui.play_flipbook(node, image)
	end
	local s = image and SLICE[image]
	if s then
		gui.set_slice9(node, vmath.vector4(s[1], s[2], s[3], s[4]))
	end
	if color then
		gui.set_color(node, color)
	end
	if parent then
		gui.set_parent(node, parent, false)
	end
	gui.set_inherit_alpha(node, true)
	return node
end

-- Swaps the image of a box node together with its slice-9 margins
function M.set_image(node, image)
	gui.play_flipbook(node, image)
	local s = SLICE[image] or { 0, 0, 0, 0 }
	gui.set_slice9(node, vmath.vector4(s[1], s[2], s[3], s[4]))
end

-- Invisible container (screen roots, groups): the node itself is not drawn, its children are
function M.group(parent, x, y, w, h)
	local node = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w or 1, h or 1, 0))
	gui.set_visible(node, false)
	if parent then
		gui.set_parent(node, parent, false)
		gui.set_inherit_alpha(node, true)
	end
	return node
end

function M.panel(parent, x, y, w, h)
	return M.box(parent, "panel", x, y, w, h)
end

function M.inset(parent, x, y, w, h)
	return M.box(parent, "panel_inset", x, y, w, h)
end

-- Full-screen darkening behind modal windows (parent: a screen-centred group, or nil)
function M.dim(parent, alpha)
	local x, y = parent and 0 or 480, parent and 0 or 270
	local node = M.box(parent, "dim", x, y, 980, 560, vmath.vector4(1, 1, 1, alpha or 0.72))
	gui.set_inherit_alpha(node, false)
	return node
end

-- Text label. opts: font ("title"|"label"|"body"), color, align ("center"|"left"|"right"),
-- width (wraps lines inside this width), max_w (shrinks to fit), outline, shadow
function M.text(parent, str, x, y, px, opts)
	opts = opts or {}
	local font = opts.font or "body"
	local node = gui.new_text_node(vmath.vector3(x, y, 0), str or "")
	gui.set_font(node, font)
	local k = (px or 18) / M.FONT_PX[font]
	gui.set_scale(node, vmath.vector3(k, k, 1))
	gui.set_color(node, opts.color or M.C.white)
	gui.set_outline(node, opts.outline or M.C.outline)
	gui.set_shadow(node, opts.shadow or M.C.shadow)
	local align = opts.align or "center"
	gui.set_pivot(node, (align == "left" and gui.PIVOT_W) or (align == "right" and gui.PIVOT_E) or gui.PIVOT_CENTER)
	if opts.width then
		gui.set_line_break(node, true)
		gui.set_size(node, vmath.vector3(opts.width / k, 400, 0))
	end
	if parent then
		gui.set_parent(node, parent, false)
	end
	gui.set_inherit_alpha(node, true)
	if opts.max_w then
		M.fit_text(node, opts.max_w, px, font)
	end
	return node
end

-- Sets text and shrinks the label so it stays within max_w pixels
function M.fit_text(node, max_w, px, font)
	local k = (px or 18) / M.FONT_PX[font or "body"]
	local metrics = resource.get_text_metrics(gui.get_font_resource(gui.get_font(node)), gui.get_text(node))
	local w = metrics.width * k
	if max_w and w > max_w and w > 0 then
		k = k * max_w / w
	end
	gui.set_scale(node, vmath.vector3(k, k, 1))
end

function M.set_text(node, str, max_w, px, font)
	gui.set_text(node, str or "")
	if max_w then
		M.fit_text(node, max_w, px, font)
	end
end

-- Icon fitted into a size x size square. opts: texture ("ui"|"game"), color
function M.icon(parent, image, x, y, size, opts)
	opts = opts or {}
	local node = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(size, size, 0))
	gui.set_texture(node, opts.texture or M.TEX)
	if parent then
		gui.set_parent(node, parent, false)
	end
	gui.set_inherit_alpha(node, true)
	if opts.color then
		gui.set_color(node, opts.color)
	end
	M.set_icon(node, image, size, size)
	return node
end

-- Swaps the image of an icon node, keeping it fitted to max_w x max_h
function M.set_icon(node, image, max_w, max_h, texture)
	if texture then
		gui.set_texture(node, texture)
	end
	gui.set_size_mode(node, gui.SIZE_MODE_AUTO)
	gui.play_flipbook(node, image)
	local size = gui.get_size(node)
	local k = math.min(max_w / math.max(1, size.x), max_h / math.max(1, size.y))
	gui.set_scale(node, vmath.vector3(k, k, 1))
end

-- Pill-shaped counter: icon on the left, value text. Returns { node, text, icon }
function M.counter(parent, image, x, y, w, value)
	local node = M.box(parent, "pill", x, y, w, 34)
	local ic = M.icon(node, image, -w / 2 + 16, 1, 34)
	local txt = M.text(node, value or "0", 10, 0, 19, { font = "label", max_w = w - 44 })
	return { node = node, text = txt, icon = ic }
end

-- Notification dot, hidden by default
function M.badge(parent, x, y)
	local node = M.box(parent, "badge", x, y, 22, 22)
	gui.set_enabled(node, false)
	return node
end

-- ---------- buttons ----------

local STYLE_TEXT = {
	gold = M.C.white, green = M.C.white, blue = M.C.white, red = M.C.white, steel = M.C.white, dark = M.C.white,
}

-- Button registered with ui_manager. opts: style ("gold"|"green"|"blue"|"red"|"steel"|"dark"|"round"),
-- label, px (label size), icon, icon_size, icon_texture, on_click, slop
-- Returns { node, label, icon, enabled, set_label(s), set_enabled(b), set_style(s) }
function M.button(ui, parent, id, x, y, w, h, opts)
	opts = opts or {}
	local style = opts.style or "gold"
	local image = (style == "round") and "round" or (style == "round_gold") and "round_gold" or ("btn_" .. style)
	local node = M.box(parent, image, x, y, w, h)
	gui.set_id(node, id)

	local btn = { node = node, enabled = true, style = style }
	local label_x = 0
	if opts.icon then
		local isz = opts.icon_size or math.min(h - 16, 34)
		local ix = opts.label and (-w / 2 + 14 + isz / 2) or 0
		btn.icon = M.icon(node, opts.icon, ix, 3, isz, { texture = opts.icon_texture })
		if opts.label then
			label_x = isz / 2 + 6
		end
	end
	if opts.label then
		local px = opts.px or math.min(22, h * 0.42)
		local max_w = w - 24 - (opts.icon and (opts.icon_size or 34) + 6 or 0)
		btn.label = M.text(node, opts.label, label_x, 3, px, { font = "label", color = STYLE_TEXT[style] or M.C.white, max_w = max_w })
		btn.px = px
		btn.max_w = max_w
	end

	function btn.set_label(s)
		if btn.label then
			M.set_text(btn.label, s, btn.max_w, btn.px, "label")
		end
	end
	function btn.set_style(s)
		btn.style = s
		M.set_image(node, (s == "round" or s == "round_gold") and s or ("btn_" .. s))
	end
	function btn.set_enabled(on)
		btn.enabled = on
		gui.set_color(node, on and vmath.vector4(1, 1, 1, 1) or vmath.vector4(0.55, 0.58, 0.64, 1))
		if btn.label then
			gui.set_color(btn.label, on and (STYLE_TEXT[btn.style] or M.C.white) or M.C.disabled)
		end
	end

	if ui then
		ui:button(id, function()
			if btn.enabled and opts.on_click then
				opts.on_click(btn)
			end
		end, { slop = opts.slop or 6 })
	end
	return btn
end

-- Square round icon button (close, settings, arrows)
function M.icon_button(ui, parent, id, x, y, size, icon, on_click, style)
	return M.button(ui, parent, id, x, y, size, size, {
		style = style or "round", icon = icon, icon_size = size * 0.52, on_click = on_click,
	})
end

-- ---------- bars ----------

-- Progress bar. Returns { node, fill, set(pct) }
function M.bar(parent, x, y, w, h, color)
	local bg = M.box(parent, "bar_bg", x, y, w, h)
	local fill = M.box(bg, "bar_fill", -w / 2, 0, w, h, color or M.C.xp)
	gui.set_pivot(fill, gui.PIVOT_W)
	local bar = { node = bg, fill = fill, w = w, h = h }
	function bar.set(pct, duration)
		pct = math.max(0, math.min(1, pct or 0))
		-- slice-9 needs a minimum width for its rounded ends
		local fw = (pct <= 0) and 0 or math.max(h, w * pct)
		gui.set_enabled(fill, pct > 0)
		if duration and duration > 0 then
			gui.animate(fill, "size.x", fw, gui.EASING_OUTCUBIC, duration)
		else
			gui.set_size(fill, vmath.vector3(fw, h, 0))
		end
	end
	function bar.set_color(c)
		gui.set_color(fill, c)
	end
	bar.set(0)
	return bar
end

-- ---------- cards ----------

-- Rarity-framed card (weapons, hats). Returns the frame node.
function M.card(parent, x, y, w, h, rarity)
	return M.box(parent, "card_" .. (rarity or "common"), x, y, w, h)
end

-- ---------- screen helpers ----------

-- Window with a title strip and a close button. Returns { root, panel, title, close }
function M.window(ui, parent, id, w, h, title, on_close)
	local root = M.group(parent, 480, 270, 960, 540)
	M.dim(root, 0.72)
	local panel = M.panel(root, 0, -8, w, h)
	local header = M.box(panel, "header", 0, h / 2 - 22, w - 8, 44)
	local title_node = M.text(header, title, 0, 2, 26, { font = "title", color = M.C.gold, max_w = w - 140 })
	local close = M.icon_button(ui, panel, id .. "_close", w / 2 - 6, h / 2 - 6, 50, "ic_close", on_close, "round")
	return { root = root, panel = panel, header = header, title = title_node, close = close }
end

-- Pops a node in (scale from small with an overshoot). Text and icons carry their size in the
-- scale, so the pop runs relative to the resting scale, kept while a pop is in flight.
local popping = setmetatable({}, { __mode = "k" })
function M.pop_in(node, delay)
	local s = popping[node] or gui.get_scale(node)
	popping[node] = s
	gui.cancel_animations(node, "scale")
	gui.set_scale(node, s * 0.6)
	gui.animate(node, "scale", s, gui.EASING_OUTBACK, 0.28, delay or 0, function()
		popping[node] = nil
	end)
end

-- Number formatting: 12500 -> "12 500"
function M.num(n)
	local s = tostring(math.floor(n or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
	return (out:gsub("^%s+", ""))
end

-- Re-export so screens only need the kit
M.fit_icon = ui_manager.fit_icon

return M
