Panduan singkat konfigurasi Google Maps

1) Buat API key di Google Cloud Console
   - Aktifkan Maps SDK for Android, Maps SDK for iOS, Maps JavaScript API
   - Hubungkan billing
   - (Opsional) Batasi key sesuai platform

2) Gunakan helper script untuk memasukkan key (Windows PowerShell):

```powershell
cd c:\Users\ASUS\cafe_finder
.\scripts\insert_map_keys.ps1 -webKey "YOUR_WEB_KEY" -androidKey "YOUR_ANDROID_KEY" -iosKey "YOUR_IOS_KEY"
```

3) Alternatif: jalankan dengan `--dart-define` untuk runtime config (terutama untuk web builds):

```bash
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=YOUR_WEB_KEY
```

4) Jangan commit API keys ke git. Simpan di secret manager atau environment variables.
