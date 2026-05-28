# Cafe Finder v1.0.0

Tanggal rilis: 2026-05-29

## Highlights

- Migrasi peta ke OpenStreetMap via `flutter_map`.
- Marker clustering + daftar cafe terdekat pada halaman map.
- CI otomatis untuk analyze, test, format check, dan web build.
- Konfigurasi production map tiles via GitHub Secrets / `--dart-define`.

## What’s Changed

### Added
- Integrasi `flutter_map`, `latlong2`, dan `flutter_map_marker_cluster`.
- Dokumentasi release dan secrets (`RELEASE_CHECKLIST.md`, `.github/SECRETS_TEMPLATE.md`).
- Test unit dan widget untuk alur model serta map screen.

### Changed
- Upgrade dependency ke versi stabil yang kompatibel.
- Penyelarasan service web/native untuk alur cafe, favorite, dan profile.

### Fixed
- Perbaikan inkompatibilitas API pasca migrasi map package.
- Perbaikan file picker dan gap API profile/favorites.
- Pembersihan error sintaks/runtime yang ditemukan saat hardening.

## Verification

- `flutter analyze` ✅
- `flutter test` ✅
- CI workflow `CI` dan `Format Check` siap dijalankan di GitHub Actions.

## Setup Required (GitHub Secrets)

- `SENTRY_DSN`
- `MAP_TILE_URL_TEMPLATE`
- `MAP_TILE_API_KEY`
- `MAP_TILE_FALLBACK_URL_TEMPLATE`

## Notes

- Jika masih memakai tile publik OSM, pastikan patuh kebijakan penggunaan tile server.
