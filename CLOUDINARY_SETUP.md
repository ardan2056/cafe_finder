# Cloudinary Setup (Gratis)

Dokumen ini untuk mengaktifkan upload gambar cafe tanpa Firebase Storage billing.

## 1. Buat akun Cloudinary

- Daftar di https://cloudinary.com/
- Masuk ke Dashboard
- Catat nilai `Cloud name`

## 2. Buat unsigned upload preset

1. Buka **Settings** -> **Upload**
2. Scroll ke **Upload presets**
3. Klik **Add upload preset**
4. Set:
   - Signing Mode: **Unsigned**
   - Folder mode: optional (boleh default)
5. Simpan, lalu catat nama preset (mis. `cafe_unsigned`)

## 3. Jalankan app dengan dart-define

### Windows (PowerShell)

```powershell
flutter run -d windows `
  --dart-define=CLOUDINARY_CLOUD_NAME=<cloud_name> `
  --dart-define=CLOUDINARY_UPLOAD_PRESET=<unsigned_upload_preset>
```

Contoh:

```powershell
flutter run -d windows `
  --dart-define=CLOUDINARY_CLOUD_NAME=mycafecloud `
  --dart-define=CLOUDINARY_UPLOAD_PRESET=cafe_unsigned
```

Alternatif (tanpa `--dart-define`, khusus native/Windows):

```powershell
$env:CLOUDINARY_CLOUD_NAME = "mycafecloud"
$env:CLOUDINARY_UPLOAD_PRESET = "cafe_unsigned"
flutter run -d windows
```

Atau pakai helper script (lebih aman dari typo):

```powershell
./scripts/run_cloudinary_windows.ps1 -CloudName "mycafecloud" -UploadPreset "cafe_unsigned"
```

## 4. Build release Windows

```powershell
flutter build windows `
  --dart-define=CLOUDINARY_CLOUD_NAME=<cloud_name> `
  --dart-define=CLOUDINARY_UPLOAD_PRESET=<unsigned_upload_preset>
```

## 5. Tes kredensial Cloudinary dulu (opsional tapi direkomendasikan)

```powershell
./scripts/test_cloudinary_upload.ps1 -CloudName "<cloud_name_asli>" -UploadPreset "<upload_preset_asli>"
```

Jika output `Cloudinary OK ✅`, berarti kredensial valid dan upload app seharusnya bisa jalan.

## Catatan

- Upload gambar di app sekarang menggunakan Cloudinary URL publik.
- Jika upload gagal, periksa:
  - cloud name benar
  - upload preset benar
  - preset benar-benar unsigned
  - koneksi internet
