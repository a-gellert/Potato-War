-- lua_modules/ui_manager.lua
-- Wrapper for Druid UI with automatic graceful fallback

local M = {}

local sound_manager = require("lua_modules.sound_manager")
local has_druid, druid = pcall(require, "druid.druid")

function M.create(script_instance)
	local ui = {
		is_druid = has_druid,
		buttons = {},
	}

	if has_druid and druid then
		ui.druid_instance = druid.new(script_instance)
	end

	function ui:button(node_id, callback)
		local node = gui.get_node(node_id)
		local wrapped_callback = function(...)
			sound_manager.play_click()
			if callback then callback(...) end
		end
		if self.is_druid and self.druid_instance then
			return self.druid_instance:new_button(node, wrapped_callback)
		else
			table.insert(self.buttons, {
				node = node,
				callback = wrapped_callback,
			})
		end
	end

	function ui:on_input(action_id, action)
		if self.is_druid and self.druid_instance then
			return self.druid_instance:on_input(action_id, action)
		end

		if action_id == hash("touch") and action.released then
			for _, btn in ipairs(self.buttons) do
				if gui.is_enabled(btn.node) and gui.pick_node(btn.node, action.x, action.y) then
					-- Button click animation (node, property, to, easing, duration, delay, complete, playback)
					pcall(function()
						gui.animate(btn.node, "scale", vmath.vector3(1.08, 1.08, 1.0), gui.EASING_OUTQUAD, 0.12, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
					end)
					btn.callback()
					return true
				end
			end
		end
		return false
	end

	function ui:update(dt)
		if self.is_druid and self.druid_instance then
			self.druid_instance:update(dt)
		end
	end

	return ui
end

return M
