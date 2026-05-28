# Cafe Finder v1.0.0

Rilis awal stabil Cafe Finder dengan migrasi map ke OpenStreetMap, peningkatan kualitas rilis, dan hardening alur utama aplikasi.

## 🚀 Highlights

- Migrasi peta ke OpenStreetMap menggunakan `flutter_map`.
- Marker clustering dan daftar cafe terdekat di halaman map.
- Pipeline CI untuk analyze, test, format check, dan web build.
- Konfigurasi map tiles production via GitHub Secrets / `--dart-define`.

## ✨ Added

- Integrasi `flutter_map`, `latlong2`, dan `flutter_map_marker_cluster`.
- Dokumentasi operasional rilis (`RELEASE_CHECKLIST.md`) dan setup secrets (`.github/SECRETS_TEMPLATE.md`).
- Unit test dan widget test untuk model + map screen.

## 🔧 Changed

- Upgrade dependencies ke versi stabil yang kompatibel.
- Penyelarasan service web/native untuk flow cafe, favorite, dan profile.

## 🐛 Fixed

- Inkompatibilitas API map package pasca migrasi.
- Gap API profile/favorites dan penggunaan file picker.
- Error sintaks/runtime yang ditemukan selama hardening.

## ✅ Verification

- `flutter analyze` passed.
- `flutter test` passed.

## 🔐 Required Secrets

- `SENTRY_DSN`
- `MAP_TILE_URL_TEMPLATE`
- `MAP_TILE_API_KEY`
- `MAP_TILE_FALLBACK_URL_TEMPLATE`

## 📌 Notes

- Jika memakai tile publik OSM, pastikan patuh kebijakan penggunaan tile server:
  https://operations.osmfoundation.org/policies/tiles
