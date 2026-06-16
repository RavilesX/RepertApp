# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

RepertApp is a Flutter mobile app (Android/iOS) for tracking a personal song catalog: each song stores artist, title, musical key, capo position, and an optional photo (e.g. a chart/lyrics sheet). The app is offline-only — there is no backend; all data lives on-device. UI strings are in Spanish.

## Commands

```bash
flutter pub get                 # install deps
flutter run                     # run on connected device/emulator
flutter analyze                 # lint (flutter_lints, see analysis_options.yaml)
flutter test                    # run all tests
flutter test test/foo_test.dart # run a single test file
flutter build apk               # release Android build
flutter pub run flutter_launcher_icons   # regenerate app icons from assets/images/logo.png
```

Note: `test/` is currently empty (no tests yet).

## Architecture

Layered by directory under `lib/`, no state-management package — plain `StatefulWidget` + `setState`. Services are singletons accessed via `.instance`.

- **`models/song.dart`** — the `Song` model. Persisted as JSON via `toMap`/`fromMap`. `fromMap` runs an inline migration (`_noteMigration`) that rewrites old Spanish note names (Do/Re/Mi…) to international notation (C/D/E…) on load — keep this when changing the model so existing saved data still parses. `keyLabel` formats note + accidental + mode for display.

- **`storage/song_storage.dart`** — the entire song list is serialized as a `List<String>` of JSON under the single SharedPreferences key `songs_v1`. `saveAll` overwrites the whole list; there is no per-song persistence. Bumping the storage schema means a new key + migration here.

- **`services/`** — singletons:
  - `image_service.dart` — picks from gallery/camera, compresses (WebP on Android, JPEG elsewhere), and writes a full image + a thumbnail into `<app documents>/song_images/`. Songs store absolute file paths (`imagePath`/`thumbPath`), not bytes.
  - `backup_service.dart` — export/import. Export bundles `songs.json` (a manifest with `version` + songs, image paths rewritten to **basenames**) plus the referenced image files into a `.zip`, then shares it via `share_plus`. Import picks a zip, extracts images back into `song_images/`, rewrites basenames to **absolute paths**, and merges by `Song.id` (existing ids are replaced). The basename↔absolute-path conversion is the crux — paths are device-specific, so they must never be stored absolute in the backup.
  - `sound_service.dart` — plays UI feedback sounds (`assets/sounds/button.mp3`, `ok.mp3`).

- **`screens/`** — `song_list.dart` is the home screen and the bulk of the app (sorting via `SortColumn`, three layouts via `ViewMode` {card, compact, list} persisted under `view_mode`, search, backup actions). `song_form.dart` is add/edit. `image_viewer.dart` is fullscreen image view.

- **`theme/app_colors.dart`** + **`widgets/music_background.dart`** — the dark neon "glass" visual style (gradient background, translucent cards). `AppColors` is the single source of palette truth; `main.dart` seeds the Material 3 dark theme from `AppColors.neonPurple` and applies Google Fonts Poppins.

### Key conventions

- Song `id` is the merge/identity key everywhere (storage, backup import dedup).
- When adding/removing image fields on `Song`, update three places in lockstep: the model map, `BackupService` (basename rewrite on both export and import), and `ImageService` cleanup (`deleteIfExists`).
- Backup manifest carries a `version` field — bump it and branch in import if the format changes.
