# Development & Maintenance

Quick guide for keeping the project healthy and preparing releases.

1. Audit dependencies

```bash
flutter pub outdated
flutter pub upgrade --major-versions
flutter pub get
```

2. Static analysis, tests, and formatting

```bash
flutter analyze
flutter test
flutter format .
```

3. CI

- A GitHub Actions workflow is added at `.github/workflows/ci.yml` that runs `flutter analyze` and `flutter test` on push/PR.

4. Building and releasing

- For web: `flutter build web`
- For Android: configure keystore and run `flutter build apk --release`
- For iOS: configure signing and run `flutter build ios --release`

5. Map & tiles

- We use OpenStreetMap tiles by default. Consider using MapTiler or another commercial tile provider for production and add API keys via secure environment variables.

6. Monitoring

- Add Sentry or Firebase Crashlytics for crash reporting. Keep keys out of repository and load via CI secrets or platform env.

7. CI secrets mapping (recommended)

- `SENTRY_DSN`: used by app runtime via `--dart-define=SENTRY_DSN=...`
- `MAP_TILE_URL_TEMPLATE`: production tile URL template
- `MAP_TILE_API_KEY`: tile provider key (if URL uses `{key}`)
- `MAP_TILE_FALLBACK_URL_TEMPLATE`: fallback tile URL if primary is empty

Example GitHub Actions build step:

```yaml
- name: Build web with env
	run: |
		flutter build web \
			--dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }} \
			--dart-define=MAP_TILE_URL_TEMPLATE=${{ secrets.MAP_TILE_URL_TEMPLATE }} \
			--dart-define=MAP_TILE_API_KEY=${{ secrets.MAP_TILE_API_KEY }} \
			--dart-define=MAP_TILE_FALLBACK_URL_TEMPLATE=${{ secrets.MAP_TILE_FALLBACK_URL_TEMPLATE }}
```
