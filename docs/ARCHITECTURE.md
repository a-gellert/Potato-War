# Architecture

This document describes how Great Potato War is assembled: the boot chain, the match lifecycle,
the main gameplay systems, the GUI layer, progression/economy and the platform SDK abstraction.

## 1. Boot chain

```text
game.project
  └─ [bootstrap] main_collection = /main/main.collection
       └─ /main/main.go
            └─ /main/main.script      ← game orchestrator
                 ├─ /terrain          (destructible terrain + background)
                 ├─ /aim_guide        (slingshot / target aiming)
                 ├─ /gui_menu         (main menu)
                 ├─ /gui_hud          (battle HUD)
                 ├─ /gui_game_over    (results)
                 ├─ /gui_campaign_map (strategic map)
                 ├─ /gui_arsenal      (weapon upgrades)
                 ├─ /gui_squad        (squad/ranks)
                 ├─ /gui_loading      (boot + transitions)
                 └─ /audio            (one sound component per sample)
```

`main/main.script` is the only global orchestrator. It owns factories, routes gameplay messages and
runs the per-frame update order:

```text
world_events → camera_controller → player_control → potato_updater
→ tutorial → weapon_fire (projectiles/bursts) → bot_turn → battle_camera
→ game_state.update (turn timer, settling, win check)
```

## 2. Match lifecycle

```text
MODE select
  ├─ tutorial        → flat training ground, unlimited bazooka, scripted hints
  ├─ campaign        → level_config.LEVELS (18 levels) or a war-map sector battle
  ├─ quick_bot       → quick battle vs. bot
  ├─ quick_pvp       → local hot-seat duel
  └─ pvp_bots        → 3×3 bot battle

start_game_match (main.script)
  ├─ match_spawner.clear
  ├─ game_state.start_match / start_battle
  ├─ terrain_grid.generate + terrain.generate_terrain
  ├─ match_spawner.spawn_battle / spawn_tutorial
  ├─ match_spawner.validate_surface_spawns
  ├─ camera intro flyover (or tutorial camera)
  ├─ show HUD, music, SDK round_start
  └─ loading screen finished
```

The game-state machine lives in `lua_modules/game_state.lua`:

```text
menu → intro → card_select → turn_active → action → settling → game_over
                    │              └───────────────┘
                    └─ campaign levels > 1 offer two bonus cards
```

Turn rules:

- `TURN_DURATION = 25 s` (`constants.lua`).
- On each turn change, wind is re-rolled (`wind_vector.x` 0–30, `.y` -3..3, zero in tutorial).
- One shot per turn; after impact/explosion the state settles, then `next_turn()` selects the next
  living unit of the other team.
- A team loses when all of its units are dead or drowned. Drowning is instant.

## 3. Module map

### Core / orchestration

| Module | Responsibility |
| --- | --- |
| `main/main.script` | Match start/leave, message bus, per-frame update, cheats |
| `lua_modules/game_state.lua` | Turn manager, state machine, ammo/loadout facade, win check, cards |
| `lua_modules/match_spawner.lua` | Spawns/removes potatoes, pickups, barrels, crates; safe-ground search |
| `lua_modules/constants.lua` | World/turn/physics constants and logging |
| `lua_modules/camera_controller.lua` | Camera position, zoom, screenshake, view matrix |
| `lua_modules/battle_camera.lua` | Cinematic director: flyover, damage focus, projectile chase, victory |
| `lua_modules/world_events.lua` | Timed airship raids and parachute supply crates |

### Combat

| Module | Responsibility |
| --- | --- |
| `lua_modules/weapons.lua` | Weapon database, status types, combo reactions, rarity/pickup helpers |
| `lua_modules/physics_sim.lua` | Potato movement/collision and projectile ballistics, wind, status modifiers |
| `lua_modules/weapon_fire.lua` | Firing, burst queue, projectile bookkeeping, napalm/beetles/cluster/airstrike |
| `main/entities/projectile` | Per-shell flight, bounce, fuse, detonation, damage application |
| `main/entities/potato` | Potato visuals, HP bar, weapon rig, emotions, statuses, damage/heal |
| `main/entities/explosion` | Explosion visuals, camera shake, SFX |
| `main/entities/weapon_rig` | Held weapon sprite and gloves |
| `main/entities/barrel`, `crate` | Destructible TNT barrels and supply crates |

### Terrain and presentation

| Module | Responsibility |
| --- | --- |
| `lua_modules/terrain_grid.lua` | 960×480 destructible grid (2 px/cell), generation, craters, ground queries |
| `lua_modules/terrain_painter.lua` | Paints biome shading, outlines, props and charred crater rims into the texture |
| `main/entities/terrain` | Uploads the grid to a dynamic texture, biome palettes, layered background, victory salute |
| `lua_modules/bg_battle.lua` | Low-cost ambient background warfare (pixel soldiers, aircraft, searchlights) |
| `lua_modules/debris_fx.lua` | Small particle/debris effects |
| `main/game.render_script` | Orthographic world pass + fixed GUI pass, aspect handling, buffer clears |
| `tools/gen_juice_assets.py` | Generates glow/ring/status/parallax sprites (Pillow) |

Background layers (all disabled in the main menu, enabled in battle):

```text
dynamic sky (bg_sky_<biome>)          z = -0.45
  → distant ridge (bg_distant)        z = -0.35   parallax 0.55
  → drifting clouds (bg_clouds)       z = -0.32   parallax 0.40 + sine drift
  → mid-ground biome islands          z = -0.25   parallax 0.28
  → destructible terrain              z = -0.10
```

Each biome supplies `distant_tint` and `cloud_tint` in `BIOME_THEMES`; the mid-ground islands use
`bg_islands_<biome>` from `terrain.atlas`.

Terrain pipeline:

```text
terrain_grid.generate(preset, level, is_defense)
  → flat Lua array of solid/air cells (960 × 480)
  → terrain_painter.paint(...) writes RGBA into a buffer stream
  → terrain.script updates a dynamic texture each time a crater is carved
```

### AI

| Module | Responsibility |
| --- | --- |
| `lua_modules/bot_ai.lua` | Perception, positioning, ballistic candidate search, personality, aim error |
| `lua_modules/bot_turn.lua` | Bot turn state machine: survey → move → settle → think → aim → retreat |

Difficulty profiles (`easy`, `normal`, `hard`, `pvp`) control angle/power error, zero-in speed,
wind awareness, weapon candidates, target count, walking range and drowning attempts.

### Progression / economy

| Module | Responsibility |
| --- | --- |
| `lua_modules/player_profile.lua` | Local save (`sys.save`) + Playgama cloud storage, hats, points, stars, squad, settings |
| `lua_modules/progression.lua` | Weapon levels (1–5), blueprints, squad XP/ranks, commander level, crates |
| `lua_modules/meta_progression.lua` | Permanent upgrades: max HP, starting arsenal, round regeneration |
| `lua_modules/classes.lua` | 12 classes, stats, base arsenals, active skills, specialisation tree |
| `lua_modules/inventory_manager.lua` | Per-potato inventories, ammo, 5-slot loadout, class skills |
| `lua_modules/cards.lua` | Two-card bonus choice between campaign levels |
| `lua_modules/achievements.lua` | Micro-achievements and toast payloads |
| `lua_modules/strategic_campaign.lua` | War-map phases, income, attacks, AI counter-attacks, battle resolution |
| `lua_modules/territory_map.lua` | 18 sectors, 4 regions, ownership graph, income, victory/defeat |
| `lua_modules/level_config.lua` | 18 campaign level definitions, quick-match presets, biome/terrain mapping |
| `lua_modules/match_results.lua` | End-of-match rewards, stars, onboarding payload |

Progression data flow:

```text
battle ends
  → game_state.next_turn detects 0 living units on a team
  → match_results.build(...) collects stars/rewards and calls progression.finish_battle(...)
  → progression grants squad XP, commander XP, coins, blueprints and a supply crate
  → player_profile.save() → local file + delayed Playgama cloud save
  → /gui_game_over renders the report/loot screens
```

The meta upgrades are consumed in gameplay:

- Max HP: `match_spawner.spawn_battle` adds `meta_progression.get_max_hp_bonus()` to the player's
  units; `meta_progression.get_player_max_hp()` is used for campaign card heals.
- Starting arsenal: `match_spawner.spawn_battle` merges `meta_progression.get_starting_weapons()`
  on top of each class's `base_arsenal`.
- Regeneration: `game_state.begin_current_turn` applies
  `meta_progression.apply_round_regen` to the active blue fighter in campaign battles.
- UI: `gui/main_menu/menu_upgrades.lua` buys upgrades with coins.

### SDK / platform abstraction

`main/sdk.lua` is the single platform facade. It detects the runtime and picks one of:

| Platform | Implementation |
| --- | --- |
| Android / iOS | AppLovin MAX (`main/applovin_ads.lua`) + Firebase Analytics |
| HTML5 Playgama | Playgama Bridge (Lua binding and/or `window.bridge`) |
| HTML5 Poki | Poki SDK (configured with `[sdk] target = poki`) |
| Desktop / tests | Mock platform with no-ops |

Responsibilities:

- lifecycle: `send_game_ready`, `in_game_loading_started/stopped`, `gameplay_start/stop`,
  `round_start/end`, `happy_time`;
- ads: interstitial with a 120 s cooldown, rewarded with callbacks, banners;
- audio/pause: mute/resume on platform pause, tab hidden or ad display (including Web Audio resume);
- storage: `storage_get/storage_set` for cloud profiles;
- language and player identity helpers.

Optional analytics/attribution wrappers (`main/gameanalytics.lua`, `main/adjust.lua`,
`main/facebook.lua`) are loaded through `pcall` and silently replaced by no-op tables when absent.

### GUI

GUI scripts are thin controllers; most nodes are built in code with `lua_modules/ui_kit.lua`
(panels, buttons, icons, bars, rarity cards, windows) on top of `main/assets/ui.atlas` and the
Rubik fonts.

| Screen | Controller | Widgets |
| --- | --- | --- |
| Main menu | `gui/main_menu/main_menu.gui_script` | `menu_home`, `menu_settings`, `menu_shop`, `menu_lobby`, `menu_upgrades` |
| Battle HUD | `gui/hud/hud.gui_script` | `hud_timer`, `hud_weapons`, `hud_indicators`, `hud_tutorial`, `hud_popups`, `hud_pause`, `hud_aim`, `hud_banner`, `hud_fx` |
| Campaign map | `gui/campaign_map/campaign_map.gui_script` | `camp_view`, `camp_inspector`, `camp_data` |
| Arsenal | `gui/arsenal/arsenal.gui_script` | weapon cards, upgrade detail panel |
| Squad | `gui/squad/squad.gui_script` | slots, ranks, promotions |
| Game over | `gui/game_over/game_over.gui_script` | `go_report`, `go_loot`, `go_actions`, `go_seamless` |
| Loading | `gui/loading/loading.gui_script` | boot progress, level briefing, tips |

`lua_modules/ui_manager.lua` handles multi-touch, hold buttons, slop and press animation. It is
mobile-first: every registered button can be pressed with a generous touch tolerance.

### Readability and juice

- Every potato carries `unit_glow`, `team_ring` and `team_badge` sprites (blue/red shapes differ,
  not only colours), plus four `status_*` icons above the HP bar.
- `aim_guide.script` draws a glowing dotted trajectory, colours it by shot power and highlights the
  predicted blast radius with `impact_ring`. It streams `aim_meter` messages to `hud_aim`, which
  shows power %, angle and danger/on-target state.
- `hud_banner` shows short `YOUR TURN` / `ENEMY TURN` / `FIGHT!` banners.
- `hud_fx` flashes the screen on damage/heal/status events; `main.script` adds a 20–55 ms
  hit-stop on explosions and damage while the camera keeps moving.
- Sprites are generated by `tools/gen_juice_assets.py`; regenerate them after changing the style.
  A static mock of the fighter readability + aiming feedback is kept in
  `scratch/juice_preview.jpg` (not part of the build).

### Save data

`player_profile.lua` stores a single Lua table:

```lua
{
  language, points, stars, squad, unlocked_skins, equipped_skin,
  tutorial_completed, onboarding_stage, campaign_hp, campaign_max_hp,
  meta_upgrades = { max_hp, starting_weapon, hp_regen },
  campaign_map, campaign_turn, campaign_stats,
  settings = { sfx, music },
  weapon_levels, blueprints, commander_xp, stats
}
```

- Local: `sys.save(sys.get_save_file("potato_war", "profile_save"), data)`.
- Cloud: Playgama `storage_set({ player_profile = data })` with a delayed/debounced write.
  On boot, `load_cloud` compares a progress score and applies the newer save; if cloud takes longer
  than 2 seconds, the game proceeds with local data.
- Migrations: `apply_profile_data` fills missing fields with defaults and keeps unknown keys.

## 4. Extension recipes

### Add a weapon

1. Add an entry to `DEFS` in `lua_modules/weapons.lua` (id, names, icon, rarity, category,
   `fire_mode`, ballistics, blast/damage, status, SFX, projectile sprite).
2. Add the id to `ORDER` so it appears in HUD/arsenal lists.
3. Add the icon/projectile sprite to `main/assets/game.atlas`.
4. Optionally add a card in `lua_modules/cards.lua`, a class arsenal entry in `classes.lua`, and
   loot weight handling in `progression.lua`.

### Add a class

1. Add a class entry in `lua_modules/classes.lua` (branch, tier, `star_cost`, stats, base arsenal,
   active skill).
2. Export the sprite and add it to `game.atlas` (`classes.sprite_of` uses the class id).
3. Add localised name/description fields (`name_ru`, `name_en`, ...).

### Add a campaign level

Add an entry to `M.LEVELS` in `lua_modules/level_config.lua` with `level`, names, `enemy_hp`,
`enemy_count`, `terrain_type`, `biome`, `enemy_skill` and optional `enemy_classes`/`is_boss`.
War-map sectors live separately in `lua_modules/territory_map.lua` (`DEFAULT_SECTORS`).

### Add a meta upgrade

Add a definition to `M.UPGRADES` in `lua_modules/meta_progression.lua` (`id`, `max_level`, localized
name/desc, atlas icon, `costs`, effect table) and append the id to `ORDER` in
`gui/main_menu/menu_upgrades.lua`. Consume the effect in `match_spawner.lua` or `game_state.lua`.

## 5. Technical notes and known debt

- `constants.log` writes to `sys.get_save_file("potato_war", "game_debug.log")` only in debug
  builds or with `potato_war.debug_log = 1`; HTML5 uses `console.log` only.
- Signing material is not tracked anymore (see `SECURITY.md`); old commits still contain it, so
  keys should be rotated.
- `main/sdk.lua` is large because it carries defensive shims for several bridge/SDK shapes. Keep
  platform-specific code there rather than in gameplay modules.
- `gameanalytics`/`adjust`/`facebook` wrapper files are absent by design in this snapshot; add
  them if attribution is required on mobile.
- No automated tests. `scratch/` contains one-off balance/physics simulations and asset generators;
  do not ship it.
- The render script uses a single custom pass with `tile`, `particle`, `model`, `gui` and
  `debug_text` predicates. Any new renderable must use one of these materials.
- The battle world is wider and taller than the screen (1920×960 vs. 960×540); camera clamping and
  `world_to_screen` conversions are central to HUD placement.
