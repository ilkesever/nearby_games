# Security

Before every `git commit` and every `fastlane` release or upload lane, scan
staged/changed files for exposed secrets: API keys, credentials, private keys
(`.json`, `.jks`, `.keystore`, `key.properties`), hardcoded tokens, internal
URLs, or debug flags. Flag anything suspicious and ask before proceeding.

# Playwright UI Testing

Before starting any UI test session, read the Playwright section below first.
After each session, update this file with new findings — do not rediscover
what is already known.

---

# Project Architecture

Mono-repo with two apps and two shared packages:

```
apps/
  chess/       — chess_app v1.1.0+2, bundle: com.nearbygames.chess
  backgammon/  — backgammon_app v1.0.1+2, bundle: com.nearbygames.backgammon
  checkers/    — checkers_app v1.0.0+1, bundle: com.nearbygames.checkers
packages/
  nearby_ble/      — custom BLE plugin (iOS ↔ Android, no internet)
  game_framework/  — shared game abstractions (engine, session, player, state)
```

Both apps: BLE-only multiplayer (no server, no internet), pass-and-play local mode, 12 languages (Arabic, Bengali, Chinese, English, French, German, Hindi, Indonesian, Portuguese, Russian, Spanish, Turkish), Fastlane for App Store + Google Play.

When touching BLE or session lifecycle → `packages/`. When touching game rules, UI, or l10n → `apps/`.

# game_framework Conventions

Core abstractions in `packages/game_framework/lib/src/`:

**`GameEngine<TState, TMove>`** — implement per game
- `gameType` — unique string ID used for BLE service discovery filtering
- `applyMove(state, move) → TState` — pure function, called on both devices to keep state in sync
- `isValidMove / getValidMoves` — used by UI for validation and move highlighting
- `serializeMove / deserializeMove` — JSON for BLE transmission

**`GameSession<TState, TMove>`** — bridges engine ↔ BLE; reuse as-is, no subclassing
- Exposes `stateStream`, `statusStream`, `moveStream`, `errorStream`
- `isMyTurn` checks `state.activePlayerIndex == localPlayer.index`
- `session.makeMove(move)` — validates locally, then sends via BLE

**Key principle:** the framework handles communication; the engine handles rules. Keep game logic out of `GameSession`.

# Fastlane

## Running lanes

Always run from inside the app directory (e.g. `apps/backgammon/`):

```sh
bundle exec fastlane ios release
bundle exec fastlane ios update_metadata
bundle exec fastlane ios upload_screenshots
bundle exec fastlane android release
bundle exec fastlane android update_metadata
bundle exec fastlane update_all_metadata   # both platforms
```

## Known issues / workarounds

- **`skip_app_version_update: true`** in `update_metadata` — workaround for a fastlane bug on new apps (< 2.232) where fetching review details crashes
- **`precheck_include_in_app_purchases: false`** — prevents false-positive precheck failures when the app has no IAP
- **`ignore_language_directory_validation: true`** — required when metadata locales don't exactly match App Store's expected set; safe to keep permanently
- **`force: true`** in metadata/screenshot lanes — skips interactive confirmation prompt
- **New app `update_metadata` crash on Ruby 2.6 / fastlane 2.230** — fastlane 2.232 fixes this but requires Ruby ≥ 2.7. On Ruby 2.6, patch two files in `vendor/bundle`:
  1. `spaceship/lib/spaceship/connect_api/models/app_store_version.rb` — `fetch_app_store_review_detail`: add `rescue RuntimeError => e; return nil if e.message == "No data"; raise`
  2. `deliver/lib/deliver/upload_metadata.rb` — `review_attachment_file`: add `return if app_store_review_detail.nil?` after the fetch call
- **First `ios release` on a new Mac** — no Apple Distribution certificate exists; add `cert(api_key: api_key)` + `sigh(app_identifier: ..., api_key: api_key, force: true)` before `build_app` in the release lane to auto-provision it. These can be removed after the cert is in the keychain.
- **App Store subtitle limit** — 30 characters max. Audit with `for f in fastlane/metadata/ios/*/subtitle.txt; do echo "${#$(cat $f)} $(cat $f)"; done`

## API keys (never commit)

- iOS: `fastlane/app-store-connect-api-key.json` — fields: `key_id`, `issuer_id`, `key`
- Android: `fastlane/google-play-key.json`

## Release checklist

1. Bump `version` in `pubspec.yaml`
2. Update release notes in all locale files (`fastlane/metadata/ios/*/release_notes.txt`, `fastlane/metadata/android/*/changelogs/`)
3. Security scan (see top of this file)
4. `bundle exec fastlane ios release`
5. `bundle exec fastlane android release`
6. `bundle exec fastlane update_all_metadata` (if metadata changed)

# Playwright UI Testing

## Flutter web / accessibility selectors

- Flutter web renders into a canvas-based a11y tree. Always run `browser_snapshot` first before trying to click anything.
- Prefer `role` + `name` selectors over CSS (e.g. `role=button name="Roll Dice"`).
- If a click does nothing, the node likely has no a11y role — confirm via snapshot.

## Backgammon board interaction

- Board points (triangles) render as `role=group` or `role=generic` — not buttons.
- Click a point using its ref or coordinates from the snapshot.
- Opening-roll dice: find by label (`"White"`, `"Black"`) in the snapshot, not by position.
- After every move, call `browser_snapshot` again to verify state before the next action.

## Dev server

- Flutter web runs on `localhost:` (port varies) — check terminal output for the exact port.
- Wait for the a11y tree to populate after `browser_navigate` before interacting.

## Common pitfalls

- Pixel-coordinate clicks are fragile — use `browser_resize` to set a stable viewport first.
- Save debug screenshots to `/tmp/` to avoid cluttering the repo root.