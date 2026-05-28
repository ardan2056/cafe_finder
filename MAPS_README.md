Panduan singkat konfigurasi peta (flutter_map)

Project ini memakai `flutter_map` dan tile source yang dikonfigurasi via `--dart-define`.

Default dev:
- `MAP_TILE_URL_TEMPLATE=https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- `MAP_TILE_FALLBACK_URL_TEMPLATE=https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- tanpa API key

Untuk production, pakai provider tile resmi (contoh MapTiler) agar sesuai kebijakan pemakaian tile.

1) Contoh jalankan dengan tile provider production (MapTiler):

```bash
flutter run -d chrome \
  --dart-define=MAP_TILE_URL_TEMPLATE=https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key={key} \
  --dart-define=MAP_TILE_API_KEY=YOUR_MAPTILER_KEY
```

2) Opsional set user-agent package:

```bash
flutter run -d chrome --dart-define=MAP_TILE_USER_AGENT_PACKAGE=com.cafefinder.app
```

3) Opsional fallback URL (dipakai jika primary URL kosong):

```bash
flutter run -d chrome \
  --dart-define=MAP_TILE_URL_TEMPLATE= \
  --dart-define=MAP_TILE_FALLBACK_URL_TEMPLATE=https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

4) Jangan commit API key ke repository.
   Simpan key di secret manager atau CI variables.

5) Referensi kebijakan OSM tile server publik:
   - https://operations.osmfoundation.org/policies/tiles
