## GitHub Secrets Template

Add these repository secrets in **Settings → Secrets and variables → Actions**.

- `SENTRY_DSN`
- `MAP_TILE_URL_TEMPLATE`
- `MAP_TILE_API_KEY`
- `MAP_TILE_FALLBACK_URL_TEMPLATE`

### Recommended values

- `SENTRY_DSN`: your Sentry DSN (empty is allowed for staging)
- `MAP_TILE_URL_TEMPLATE`: `https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key={key}`
- `MAP_TILE_API_KEY`: your tile provider API key
- `MAP_TILE_FALLBACK_URL_TEMPLATE`: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`

### Local test command

```bash
flutter run -d chrome \
  --dart-define=SENTRY_DSN="<your_sentry_dsn>" \
  --dart-define=MAP_TILE_URL_TEMPLATE="https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key={key}" \
  --dart-define=MAP_TILE_API_KEY="<your_tile_api_key>" \
  --dart-define=MAP_TILE_FALLBACK_URL_TEMPLATE="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
```