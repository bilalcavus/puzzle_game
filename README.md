# Puzzle Arcade

Flutter application that bundles two different puzzle experiences: a classic 4x4 Sliding Puzzle and a feature-rich Wooden Block Puzzle with endless/classic and Adventure modes. The same codebase targets phones, tablets, desktop, and web.

## Highlights
- Sliding Puzzle: solvable shuffling, timer/move tracking, Riverpod-powered levels, victory dialog with next-level flow.
- Wooden Block Puzzle: 8x8 & 10x10 classic boards, combo/perfect bonuses, adventure path with special targets, animated feedback.
- Local leaderboards: sliding puzzle tracks moves/time, block puzzle tracks score (top 10) via SharedPreferences.
- Dynamic audio: background loop + movement/success/failure effects with runtime toggles.
- Persistent progress: best scores, unlocked adventure levels, seeds, and settings survive restarts.
- Responsive UI & theming: custom `AppTheme`, reusable widgets, Lottie animations, media-query aware layouts.

## Game Modes
### Sliding Puzzle
- `PuzzleNotifier` (Riverpod) builds solvable sequences through `core/utils/puzzle_shuffle.dart`.
- `PuzzleTimerHelper` feeds live timers, and `VictoryDialog` presents restart/next-level actions.
- Completing a puzzle inserts a `LeaderboardEntry` with duration + moves and stores it locally.

### Wooden Block Puzzle
- `BlockPuzzleModeView` lets players pick Adventure (level ladder) or Classic (endless scoring).
- Adventure mode uses `LevelPathView` to render a multi-row map of 100+ levels and enforces unlock order.
- Classic mode runs on `BlockPuzzleNotifier`, generating random pieces, combo streaks, perfect bonuses, and particle/haptic cues.
- Leaderboard is limited to top 10 scores; blocked cells, combo count, and targets are persisted.

## Architecture & Tech
- **State management:** `flutter_riverpod` for all gameplay and settings state machines.
- **Feature folders:** `features/<feature>/{domain,application,presentation}` encourages clean separation.
- **Core utilities:** puzzle shuffler, timer helper, block piece factory, extensions live in `lib/core`.
- **Shared widgets:** boards, counters, buttons, dialogs located under `lib/widgets`.
- **Packages:** Riverpod, Audioplayers, Shared Preferences, Kartal, Iconsax, Hugeicons, Lottie, flutter_launcher_icons.

## Project Layout
- `lib/app`: MaterialApp bootstrapping + theme definitions.
- `lib/views`: screen-level widgets (splash, home, mode selectors, gameplay screens).
- `lib/features`: domain-specific logic for block and sliding puzzles.
- `lib/providers`: Riverpod state notifiers (puzzle state, block puzzle state, sound settings, leaderboards).
- `lib/core`: utilities and extensions shared across the app.
- `assets`: audio, images, icons, lottie files, and Baloo2 font family (referenced in `pubspec.yaml`).

## Getting Started
1. Install [Flutter 3.22+](https://docs.flutter.dev/get-started/install) and set up device/emulator targets.
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run on a connected device/simulator:
   ```bash
   flutter run -d <device_id>
   ```
4. Execute tests:
   ```bash
   flutter test
   ```

## Useful Commands
- `flutter analyze` – static analysis & lint checks.
- `flutter pub run flutter_launcher_icons` – regenerate launcher icons (configured in `pubspec.yaml`).
- `flutter build apk` / `flutter build ios` / `flutter build web` – production builds.
- `dart format .` – keep formatting consistent before committing.

## Contribution Notes
- When adding new audio/images, place them under the appropriate `assets/` subfolder and ensure they are listed in `pubspec.yaml`.
- Adventure progress is stored with the key `kBlockLevelProgressKey`; clearing app data resets the map.
- Before opening a PR, confirm formatting and all tests pass.

Happy puzzling! 🎮
