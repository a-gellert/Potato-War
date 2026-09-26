-- lua_modules/ui_manager.lua
-- Mobile-first UI input manager with continuous hold support, multi-touch handling, and generous touch tolerance

local M = {}

local sound_manager = require("lua_modules.sound_manager")

local function is_node_effectively_enabled(node)
	if not node then return false end
	local ok, enabled = pcall(gui.is_enabled, node, true)
	if ok then return enabled end
	local ok2, enabled2 = pcall(gui.is_enabled, node)
	return ok2 and enabled2 or false
end

local function pick_node_with_slop(node, x, y, slop)
	if not is_node_effectively_enabled(node) then
		return false
	end
	if gui.pick_node(node, x, y) then
		return true
	end
	if slop and slop > 0 then
		local offsets = {
			{ -slop, 0 }, { slop, 0 }, { 0, -slop }, { 0, slop },
			{ -slop, -slop }, { slop, -slop }, { -slop, slop }, { slop, slop }
		}
		for i = 1, #offsets do
			if gui.pick_node(node, x + offsets[i][1], y + offsets[i][2]) then
				return true
			end
		end
	end
	return false
end

local function animate_button_press(node, pressed)
	pcall(function()
		local s = pressed and 0.92 or 1.0
		gui.animate(node, "scale", vmath.vector3(s, s, 1.0), gui.EASING_OUTQUAD, 0.08)
	end)
end

local function animate_button_click(node)
	pcall(function()
		gui.set_scale(node, vmath.vector3(1.0, 1.0, 1.0))
		gui.animate(node, "scale", vmath.vector3(1.08, 1.08, 1.0), gui.EASING_OUTQUAD, 0.10, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
	end)
end

function M.create(script_instance)
	local ui = {
		buttons = {},
		hold_buttons = {},
		active_btn = nil,
		captured_touch = false,
		pointer_down = false,
		pointer_x = 0,
		pointer_y = 0,
		multi_touches = {},
		last_multitouch_frame = -1,
		frame_counter = 0,
	}

	function ui:button(node_id, callback, opts)
		local node = gui.get_node(node_id)
		opts = opts or {}
		local entry
		local wrapped_callback = function(...)
			if entry and (self.frame_counter - (entry.last_fire_frame or -10)) <= 2 then
				return
			end
			if entry then
				entry.last_fire_frame = self.frame_counter
			end
			sound_manager.play_click()
			if callback then callback(...) end
		end
		entry = {
			id = node_id,
			node = node,
			callback = wrapped_callback,
			instant = opts.instant or false,
			slop = opts.slop or 8,
			last_fire_frame = -10,
		}
		table.insert(self.buttons, entry)
		return entry
	end

	function ui:hold_button(node_id, callbacks)
		local node = gui.get_node(node_id)
		local entry = {
			id = node_id,
			node = node,
			on_press = callbacks and callbacks.on_press or nil,
			on_release = callbacks and callbacks.on_release or nil,
			on_hold = callbacks and callbacks.on_hold or nil,
			is_held = false,
			slop = (callbacks and callbacks.slop) or 12,
		}
		table.insert(self.hold_buttons, entry)
		return entry
	end

	local function evaluate_hold_buttons(self)
		local has_multitouch = (self.frame_counter - self.last_multitouch_frame) <= 2
		for _, hb in ipairs(self.hold_buttons) do
			local now_held = false
			if is_node_effectively_enabled(hb.node) then
				if has_multitouch then
					for _, pt in pairs(self.multi_touches) do
						if pick_node_with_slop(hb.node, pt.x, pt.y, hb.slop) then
							now_held = true
							break
						end
					end
				elseif self.pointer_down then
					if pick_node_with_slop(hb.node, self.pointer_x, self.pointer_y, hb.slop) then
						now_held = true
					end
				end
			end

			if now_held and not hb.is_held then
				hb.is_held = true
				sound_manager.play_click()
				animate_button_press(hb.node, true)
				if hb.on_press then hb.on_press() end
			elseif not now_held and hb.is_held then
				hb.is_held = false
				animate_button_press(hb.node, false)
				if hb.on_release then hb.on_release() end
			end
		end
	end

	function ui:on_input(action_id, action)
		-- 1. Handle multi-touch (mobile fingers)
		if action_id == hash("touch_multi") and action.touch then
			self.last_multitouch_frame = self.frame_counter
			local any_on_ui = false
			local new_touches = {}

			for _, t in ipairs(action.touch) do
				if not t.released then
					new_touches[t.id] = { x = t.x, y = t.y, pressed = t.pressed }
				end

				for _, hb in ipairs(self.hold_buttons) do
					if pick_node_with_slop(hb.node, t.x, t.y, hb.slop) then
						any_on_ui = true
					end
				end
				for _, btn in ipairs(self.buttons) do
					if pick_node_with_slop(btn.node, t.x, t.y, btn.slop) then
						any_on_ui = true
						if (t.pressed and btn.instant) or (t.released and not btn.instant) then
							animate_button_click(btn.node)
							btn.callback()
						end
					end
				end
			end

			self.multi_touches = new_touches
			evaluate_hold_buttons(self)

			if any_on_ui then
				return true
			end
		end

		-- 2. Handle single touch / mouse click
		if action_id == hash("touch") then
			if action.pressed then
				self.pointer_down = true
				self.pointer_x = action.x
				self.pointer_y = action.y
				self.active_btn = nil
				self.captured_touch = false

				-- Check hold buttons first
				for _, hb in ipairs(self.hold_buttons) do
					if pick_node_with_slop(hb.node, action.x, action.y, hb.slop) then
						self.captured_touch = true
					end
				end

				evaluate_hold_buttons(self)
				if self.captured_touch then
					return true
				end

				-- Check regular buttons
				for _, btn in ipairs(self.buttons) do
					if pick_node_with_slop(btn.node, action.x, action.y, btn.slop) then
						self.active_btn = btn
						self.captured_touch = true
						if btn.instant then
							animate_button_click(btn.node)
							btn.callback()
							self.active_btn = nil
						else
							animate_button_press(btn.node, true)
						end
						return true
					end
				end

			elseif action.released then
				self.pointer_down = false
				self.pointer_x = action.x
				self.pointer_y = action.y
				evaluate_hold_buttons(self)

				local was_captured = self.captured_touch
				local btn = self.active_btn
				self.active_btn = nil
				self.captured_touch = false

				if btn then
					animate_button_press(btn.node, false)
					-- Generous release slop (24px) so slight thumb roll on mobile still triggers the button
					if pick_node_with_slop(btn.node, action.x, action.y, 24) then
						animate_button_click(btn.node)
						btn.callback()
					end
					return true
				end

				if was_captured then
					return true
				end

			else
				-- Pointer held / moved
				if self.pointer_down then
					self.pointer_x = action.x
					self.pointer_y = action.y
					evaluate_hold_buttons(self)
					if self.captured_touch then
						return true
					end
				end
			end
		end

		return false
	end

	function ui:update(dt)
		self.frame_counter = self.frame_counter + 1
		for _, hb in ipairs(self.hold_buttons) do
			if hb.is_held and hb.on_hold then
				hb.on_hold(dt)
			end
		end
	end

	return ui
end

return M

