# Economy and monetization

How Great Potato War earns and spends its currencies, where it asks for money, and how in-app
purchases (IAP) are wired on each platform. Code: `main/sdk.lua` (payments), `gui/main_menu/menu_store.lua`
(store window), `lua_modules/player_profile.lua` (grants), `lua_modules/daily_rewards.lua` (daily cycle and
rewarded coins).

## 1. Currencies

| Currency | Earned from | Spent on |
| --- | --- | --- |
| Coins | Battle: 40 quick win, 60 + 10 × level sector win, 15 defeat. Crates. Daily reward days 1/3/6 (60/120/200). Store: 75 per rewarded ad, 5 a day. IAP packs. | Meta upgrades (250 … 13 000 per level, about 66 000 for all), weapon upgrades (with blueprints), hats. |
| Stars | Campaign stars (1–3 per battle), daily reward day 5, IAP packs. | Squad slots (3 and 7 stars), class promotions (2–4 stars). |
| Blueprints | Supply crates (battle wins, daily days 2/4/7, commander level-ups). | Weapon levels 1–5. |

Design intent: a free player affords the first meta level and a third squad member within the first
session, then progress slows to roughly one meaningful purchase per 3–5 battles. That gap is what the
store and the rewarded placements fill.

## 2. Monetization layers

1. **Rewarded ads (all platforms, Poki included)**
   - x2 battle loot (`gui/game_over/go_loot.lua`)
   - revive after a defeat
   - x2 daily reward (`gui/main_menu/menu_daily.lua`)
   - free coins in the store: +75, 5 views a day (`daily_rewards.grant_ad_coins`)
2. **Interstitials**: between battles, at most one per 120 s (`sdk.commercial_break`). Removed by
   `no_ads` or `starter_pack`. Rewarded ads always stay.
3. **In-app purchases**: catalog below, only where the platform supports them and the `iap` flag is on.

## 3. IAP catalog

The ids must match `res/web/playgama-bridge-config.json` (`payments`), every portal dashboard and the
Google Play Console. Prices are never hard-coded: the store shows the platform catalog price and hides
products the store has not priced. The USD prices in `sdk.DEFAULT_PRODUCTS` are shown only in debug
builds.

| id | Type | Grants | Suggested price |
| --- | --- | --- | --- |
| `starter_pack` | permanent, once | 2500 coins + 8 stars + no ads | 2.99 USD |
| `coins_pack_1000` | consumable | 1000 coins | 0.99 USD |
| `coins_pack_5000` | consumable | 5000 coins (≈ +25 % per dollar) | 3.99 USD |
| `stars_pack_5` | consumable | 5 stars | 1.49 USD |
| `stars_pack_20` | consumable | 20 stars | 4.99 USD |
| `no_ads` | permanent | no interstitials | 1.99 USD |

Grant rules:
- **Consumables** are granted only after the store confirms the consume: Bridge `consume_purchase`,
  Google Play `iap.finish`. An interrupted purchase stays pending and is granted on the next launch.
- **Permanent products** are restored on every launch. Bridge: `get_purchases`. Google Play: pending,
  acknowledged transactions are re-delivered to the listener.
- **The starter pack** records `profile.owned.starter_pack`, so its currency is granted only once. Its
  no-ads part is restored every time.

## 4. Paywalls (soft)

The store opens with the reason in red ("Not enough coins" / "Not enough stars") when the player taps:
- an upgrade they cannot afford (`menu_upgrades`)
- a hat they cannot afford (`menu_shop`)
- hiring or promoting in the squad without enough stars. This only fires when the squad screen was
  opened from the menu.

The "+" buttons next to the coin and star counters open the store at any time. Closing the store returns
to the window it covered.

## 5. Platforms

| Platform | IAP | How |
| --- | --- | --- |
| Google Play (Android) | yes | `extension-iap` 8.4.1, Google Play Billing; `[iap] auto_finish_transactions = 0` |
| Playgama, Yandex Games, MSN, Microsoft Store, CrazyGames, Facebook, Discord, Huawei, Reddit, Portal | yes | Playgama Bridge `payments` (portal reports `is_supported`) |
| Poki | **forbidden** by Poki, `iap = 0` in `tools/poki.settings` | rewarded ads only |
| VK, OK, GameDistribution, Y8, Lagged, Telegram, YouTube, Xiaomi, GameSnacks, TikTok, Samsung, … | no (Bridge reports unsupported) | store shows only the free rewarded coins |

Source: the Playgama Bridge payments page, fetched 2026-11-13. One Playgama guide also lists Samsung as
supported; the API page does not. The code follows `bridge.payments.is_supported()` at runtime, so
either case is handled.

## 6. Flags

`game.project`, section `[potato_war]`:

| Key | Default | Effect |
| --- | --- | --- |
| `comic_fx` | 1 | Comic words over explosions ("БАХ!", "BOOM!"). Set 0 to turn them off. |
| `iap` | 1 | In-app purchases and the paid part of the store. Set 0 to keep only rewarded coins. |

`tools/poki.settings` overrides `iap = 0`. Do not put comment lines into `game.project`: bob fails with
"Could not parse".

## 7. Setup checklists

**Playgama submission**: tick "in-app purchases" and enter every `product_id`, its USD price and its type
(consumable / permanent).

**Yandex Games and other portals**: create the products in the portal console with the same ids. For
a different id, use a per-platform override in the config:
`{ "id": "no_ads", "yandex": { "id": "yandex_no_ads" } }`.

**Google Play Console**:
1. Create in-app products with the same ids. All of them are one-time products; the game decides
   which ones it consumes.
2. Add license testers.
3. Upload a signed build to the internal testing track. Billing does not work in a sideloaded debug
   APK that Play has never seen.
4. Test with the reserved id `android.test.purchased` if needed.

**Playgama rules 2.4.x**, as implemented:

| Rule | Implementation |
| --- | --- |
| Payments only through the Bridge | Yes |
| Platform-currency prices | From the catalog |
| Grant only after success | Yes |
| Consume right after granting | Yes; the grant waits for the consume |
| Check pending purchases at start | `sdk.check_pending_purchases` |
| Permanent purchases restored and not buyable twice | Owned products are hidden |
| Store hidden when unsupported | Only the free card shows |

## 8. Known limits

- No server-side receipt verification. Playgama's `POST /api/bridge/v1/verify` supports only
  playgama, msn and microsoft_store. Google receipts (`transaction.receipt` / `signature`) are not
  checked.
- iOS is not configured (no App Store products, no `ios_*` settings).
