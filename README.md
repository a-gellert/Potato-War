# Great Potato War

A turn-based artillery game (Worms-style) about potato squads built with [Defold](https://defold.com/).
Aim with a slingshot drag or a direct shot, read the wind, carve craters in destructible
terrain and knock the enemy team into the water, lava or a bottomless pit.

- **Engine:** Defold, Lua 5.1, `shared_state = 1`
- **Platforms:** HTML5 (Playgama / Poki), Android, desktop
- **Orientation:** landscape, 960×540 design resolution, 1920×960 battle world
- **Languages:** English, Russian, Portuguese, French, Spanish, Turkish

## Features

- Turn-based artillery with a 25-second turn timer, dynamic wind and one shot per turn.
- Destructible, biome-themed terrain: grass, desert, arctic, volcano and alien.
- 16 carried weapons plus internal shells: grenade, bazooka, shotgun, sniper, knife, molotov,
  pepper, garlic, drill, beetle, dynamite, cluster, homing, holy grenade, airstrike and more.
- Elemental statuses (burning, poison, glue, concussion) and combo reactions.
- 12 potato classes with specialisations and active skills.
- Strategic campaign: 18 sectors across 4 regions, income, fortifications, counter-attacks.
- Meta progression: weapon levels and blueprints, squad XP/ranks/promotions, commander level,
  permanent upgrades (max HP, starting arsenal, round regeneration), hats and supply crates.
- Bot AI with four personalities and four difficulty profiles.
- Readability layer: team-coloured glow/rings, team badges, status icons above every fighter,
  predicted blast rings and a live shot-power/angle meter.
- Juice: impact hit-stop, full-screen hit flashes, turn banners, camera punch/shake, hit sparks,
  lingering crater smoke and a fireworks salute on victory.
- Living parallax backgrounds (sky, distant ridges, drifting clouds, biome mid-ground islands) with
  bird flocks, aircraft silhouettes and wind-blown biome motes; the same backdrop runs behind the menu.
- Map variety: per-seed palette variants (seasons / rock types), time-of-day lighting, a signature
  feature per map and random mirroring, so two battles on the same preset look different.
- Daily reward: a 7-day login cycle (coins, crates, a star) with a rewarded-ad x2.
- Store: free coins for rewarded ads, in-app purchases (starter pack, coins, stars, no ads) through
  Playgama payments and Google Play Billing, soft paywalls. See [`docs/ECONOMY.md`](docs/ECONOMY.md).
- Comic words over explosions ("BOOM!", "БАХ!").
- Local hot-seat PvP, quick battles against bots, and 3×3 bot teams.
- Location-aware SDK layer: Playgama Bridge, Poki, AppLovin MAX (Android/iOS), Firebase Analytics.
- Local saves plus optional Playgama cloud saves with conflict resolution.

## Controls

| Action | Keyboard / mouse | Touch |
| --- | --- | --- |
| Walk | `A` / `D` or `←` / `→` | hold the on-screen arrows |
| Jump | `W`, `↑` or `Space` | jump button |
| Aim / shoot | hold and drag, release | drag and release |
| Select weapon | `1`–`5` (outside PvP) or `Q` inventory | weapon bar / inventory |
| Pause / menu | `Esc` | pause button |

Test builds only (editor or `potato_war.cheats = 1`): `F9` fills the arsenal, `F10` wins the battle.

## Repository layout

```text
game.project                 Defold project, dependencies, SDK/ad settings
main/                        bootstrap collection, main orchestrator, factories, render script
  main.script                match lifecycle, input routing, message bus
  entities/                  potato, projectile, terrain, explosion, weapon rig, pickups
  assets/                    sprites, atlases, fonts, sounds
lua_modules/                 gameplay logic (physics, AI, progression, SDK-agnostic systems)
gui/                         menu, HUD, campaign map, arsenal, squad, game over, loading
input/                       input bindings
res/                         bundled web/android resources
docs/                        architecture and operations documentation
tools/                       asset generators and store/release helpers
scratch/                     ad-hoc development helpers (not bundled)
build/, wasm-web/, pl/, Playgama/, poki/   local export output (not source)
```

## Getting started

1. Install a Defold editor version compatible with the project (the latest build artifacts were
   produced with Defold/bob **1.14.0**).
2. Open `game.project` in the editor.
3. Let the editor resolve dependencies from `game.project` (Playgama Bridge, Druid,
   defold-orthographic, Poki SDK, AppLovin MAX, Firebase).
4. Press **F5** (Build & Run).

The bootstrap chain is `game.project` → `/main/main.collection` → `/main/main.go` →
`/main/main.script`.

## Building and publishing

- **HTML5:** use the Defold HTML5 build. `[html5] htmlfile` points to the Playgama engine template.
  The SDK target is selected in `game.project`:

  ```ini
  [sdk]
  target = playgama   # playgama | poki | mock
  ```

  `mock` is useful for local runs without a platform SDK.
- **Android:** configure your signing keystore **locally** (Defold *Preferences → Android*).
  Never commit keystores, passwords or `google-services.json` to the repository. See
  [`SECURITY.md`](SECURITY.md).
- **Ad units and app IDs** live in the `[max]` section of `game.project`.
- **Feature flags** live in `[potato_war]`: `comic_fx` (comic words over blasts) and `iap` (in-app
  purchases), `1` on / `0` off. The Poki build forces `iap = 0`. Do not add comment lines to
  `game.project`: bob cannot parse them.
- The `Playgama/`, `pl/`, `poki/`, `wasm-web/` and `build/` directories contain local export
  artifacts and are not part of the source.

## Configuration and debugging

- Gameplay constants (turn length, gravity, world size, HP) live in
  `lua_modules/constants.lua`.
- File logging is disabled in release HTML5 builds. It is enabled automatically in editor/debug
  builds and can be forced with:

  ```ini
  [potato_war]
  debug_log = 1
  ```

  The log is written to the platform save directory as `game_debug.log`
  (`sys.get_save_file("potato_war", "game_debug.log")`).
- Save data is stored under the `potato_war` application key. On Playgama the profile is also
  synced through the platform storage API when available.
- Cheats: `F9` (full arsenal) and `F10` (instant win) work in debug builds, or in any build with
  `potato_war.cheats = 1`.
- UI/FX sprites are regenerated with `python tools/gen_juice_assets.py` (Pillow required). The
  script writes the glow/ring/status/parallax PNGs into `main/assets/` and `main/assets/fx/`.

## Architecture

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the module map, match/turn state machines,
terrain and combat pipelines, progression/economy data flow and extension recipes.

## Known limitations

- There is no online multiplayer; the lobby's "human" opponent is local hot-seat play.
- The optional `main/gameanalytics.lua`, `main/adjust.lua` and `main/facebook.lua` wrappers are not
  present; the SDK layer silently falls back to no-op stubs for them.
- Most content is data-driven but the project has no automated test suite. `scratch/` contains
  ad-hoc Lua/JS simulations and asset generators.
- The project does not currently ship a license file. Check the repository owner before reusing
  assets or code.
