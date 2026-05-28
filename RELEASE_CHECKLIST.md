# Release Checklist

Panduan ringkas untuk rilis aplikasi Cafe Finder.

## 1) Pre-release (wajib)

- Pastikan dependency sinkron:
  - `flutter pub get`
- Pastikan kualitas kode:
  - `flutter analyze`
  - `flutter test`
- Verifikasi CI `CI` dan `Format Check` berstatus hijau.
- Pastikan secret GitHub Actions sudah diisi:
  - `SENTRY_DSN`
  - `MAP_TILE_URL_TEMPLATE`
  - `MAP_TILE_API_KEY`
  - `MAP_TILE_FALLBACK_URL_TEMPLATE`

## 2) Web release

- Build release:
  - `flutter build web --release`
- Smoke test minimal:
  - Auth (login/register)
  - Home/search/detail
  - Maps (tile load, marker, list nearest cafe)
  - Favorite/profile
- Validasi error monitoring aktif (Sentry event masuk).

## 3) Android release

- Konfigurasi keystore signing.
- Build:
  - `flutter build apk --release`
  - atau `flutter build appbundle --release`
- Uji instalasi APK/AAB pada device nyata.

## 4) iOS release

- Konfigurasi provisioning profile dan signing di Xcode.
- Build:
  - `flutter build ios --release`
- Upload dSYM/symbol jika pakai crash reporting.

## 5) Post-release

- Update changelog.
- Tag release git.
- Gunakan template release notes: `.github/RELEASE_TEMPLATE_v1.0.0.md`.
- Monitor crash/error rate 24 jam pertama.
- Cek metrik utama (login success rate, halaman map, favorite flow).
