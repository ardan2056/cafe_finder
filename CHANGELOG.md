# Changelog

All notable changes to this project are documented in this file.

## [1.0.0] - 2026-05-29

### Added
- OpenStreetMap migration using `flutter_map` with marker clustering.
- Nearest cafes UX on map screen with list and marker interactions.
- CI workflows for analyze, tests, format checks, and web build.
- Production map tile configuration via `--dart-define` and GitHub Secrets.
- Sentry integration hook and release documentation (`RELEASE_CHECKLIST.md`).
- Unit and widget tests for map and model behavior.

### Changed
- Updated dependencies to compatible stable versions.
- Improved native and web service parity for cafe/favorite/user flows.

### Fixed
- Resolved map package API incompatibilities after migration.
- Fixed file picker usage and profile/favorite API gaps.
- Cleaned syntax and test/runtime issues found during hardening.
