-- lua_modules/potato_updater.lua
-- Per-frame potato physics for main.script: integration, landing, air facing,
-- water splash and deep-fryer drowning.

local constants = require("lua_modules.constants")
local terrain_grid = require("lua_modules.terrain_grid")
local physics_sim = require("lua_modules.physics_sim")
local game_state = require("lua_modules.game_state")
local camera_controller = require("lua_modules.camera_controller")
local sound_manager = require("lua_modules.sound_manager")
local i18n = require("lua_modules.i18n")
local achievements = require("lua_modules.achievements")

local M = {}

local function liquid_sound()
	sound_manager.play((game_state.current_biome == "volcano") and "sizzle" or "splash", { vary = 0.1 })
end

local function on_splash(p)
	camera_controller.shake(8, 0.25)
	liquid_sound()
	msg.post("/main#main", "spawn_splash", { x = p.pos.x, size = 1.2 })
	msg.post(p.url, "apply_damage", { damage = 0 }) -- trigger pain flash without double damage
	msg.post("/gui_hud#gui", "show_damage", { x = p.pos.x, y = p.pos.y + 12, amount = 30, status = "water", label = i18n.pick({ ru = "ВОДА!", en = "WATER!", pt = "ÁGUA!", fr = "EAU !", es = "¡AGUA!", tr = "SU!" }) })
end

local function on_drowned(p)
	camera_controller.shake(8, 0.25)
	liquid_sound()
	msg.post("/main#main", "spawn_splash", { x = p.pos.x, size = 1.4 })
	sound_manager.play("death", { vary = 0.08 })
	-- Localized "Бульк" floating message without explosion
	msg.post("/gui_hud#gui", "show_damage", {
		x = p.pos.x,
		y = constants.WATER_LEVEL + 26,
		amount = 0,
		status = "water",
		label = i18n.pick({
			ru = "Бульк!",
			en = "Splash!",
			pt = "Tchibum!",
			fr = "Plouf !",
			es = "¡Chof!",
			tr = "Cumburlop!"
		})
	})
	msg.post(p.url, "drowned")
	p.url = nil

	if p.team == constants.TEAM_RED and game_state.active_team == constants.TEAM_BLUE then
		local ach = achievements.on_drown(p, game_state.active_team)
		if ach then
			msg.post("/gui_hud#gui", "show_achievement_toast", { icon = ach.icon, title = ach.title, points = ach.points })
		end
	end

	-- Conclude the turn upon drowning
	msg.post("/aim_guide#aim_guide", "hide_aim")
	game_state.set_state(constants.STATE_SETTLING)
	game_state.settle_timer = 0
end

-- Landing faster than a plain jump shakes the camera; half of it already kicks up dust
local HARD_LANDING = 340

local function landing_dust(p, impact)
	local k = math.min(1.0, (impact - HARD_LANDING * 0.5) / 300)
	for side = -1, 1, 2 do
		msg.post("/main#main", "spawn_puff", {
			x = p.pos.x + side * 8, y = p.pos.y - constants.POTATO_RADIUS + 2,
			vx = side * (40 + 50 * k), vy = 6 + math.random() * 8,
			life = 0.5 + 0.2 * k, grav = -0.02, size = 0.35 + 0.25 * k, grow = 2.2, drag = 4.0,
			anim = "smoke", tint = vmath.vector4(0.8, 0.72, 0.6, 0.55),
		})
	end
	if impact > HARD_LANDING then
		camera_controller.shake(2 + 4 * k, 0.18)
	end
end

local function on_moved(p, was_grounded, event, impact)
	if not was_grounded and p.is_grounded then
		msg.post(p.url, "on_land")
	end
	if (event == "land" or event == "bounce") and (impact or 0) > HARD_LANDING * 0.5 then
		landing_dust(p, impact)
	end
	-- Face in the direction of horizontal motion while airborne
	if not p.is_grounded and math.abs(p.vel.x) > 15.0 then
		local air_facing = (p.vel.x > 0) and 1 or -1
		if p.facing ~= air_facing then
			p.facing = air_facing
			msg.post(p.url, "set_facing", { facing = air_facing })
		end
	end
	go.set_position(p.pos, p.url)
end

function M.update(dt)
	for _, p in ipairs(game_state.potatoes) do
		if p.is_alive then
			local was_grounded = p.is_grounded
			local result, impact = physics_sim.step_potato(p, dt, terrain_grid, game_state.wind_vector)
			if p.url then
				if result == "tutorial_rescue" then
					go.set_position(p.pos, p.url)
					camera_controller.follow(p.pos.x, p.pos.y, true)
					sound_manager.play("jump")
				elseif result == "water_splash" then
					on_splash(p)
				elseif result == "drowned" then
					on_drowned(p)
				else
					on_moved(p, was_grounded, result, impact)
				end
			end
		end
	end
end

return M
