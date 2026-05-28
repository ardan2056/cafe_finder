# Cafe Finder

This repository is a Flutter app that helps users find nearby cafes.

CI workflows

- `CI` (`.github/workflows/ci.yml`): dependency resolution, analyze, test, web build
- `Format Check` (`.github/workflows/format.yml`): fails PR if Dart formatting is not clean

Quick start

```bash
flutter pub get
flutter run -d chrome
```

Production checklist

- Upgrade dependencies (`flutter pub outdated`)
- Run `flutter analyze` and fix issues
- Add Sentry/Crashlytics DSN via `--dart-define` or CI secrets
- Prepare platform signing (Android keystore, iOS provisioning)
- Build and distribute

Development notes

- CI runs analyze and tests on push/PR.
- Format is enforced by `.github/workflows/format.yml`.
- Localization ARB files are under `lib/l10n/`.

Release checklist (practical)

- Confirm `flutter analyze` and `flutter test` are green locally and in CI
- Set GitHub secrets for web build:
	- `SENTRY_DSN`
	- `MAP_TILE_URL_TEMPLATE`
	- `MAP_TILE_API_KEY`
	- `MAP_TILE_FALLBACK_URL_TEMPLATE`
- Build web release and smoke test map, auth, and detail flows
- Tag release and update changelog

Detailed release SOP is available in `RELEASE_CHECKLIST.md`.
Secrets setup template is available in `.github/SECRETS_TEMPLATE.md`.
Release notes are tracked in `CHANGELOG.md`.
GitHub release template is available in `.github/RELEASE_TEMPLATE_v1.0.0.md`.

Release scripts
---------------

Simple helpers are provided in `scripts/release.sh` (bash) and `scripts/release.ps1` (PowerShell).
They commit, tag `v1.0.0`, push, and will create a GitHub Release if the `gh` CLI is installed.

Usage examples:

```bash
./scripts/release.sh "chore: release v1.0.0"
```

```powershell
.\scripts\release.ps1 -Message "chore: release v1.0.0"
```

If you don't have `gh` installed, the scripts will still tag and push; create the release manually and paste the release body from `.github/RELEASE_BODY_v1.0.0.md`.

