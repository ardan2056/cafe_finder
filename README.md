# Cafe Finder

Project Flutter untuk aplikasi Cafe Finder.

## Alur aplikasi

Splash Screen -> Onboarding -> Login/Register -> Home -> Detail Cafe -> Search -> Maps -> Favorite -> Review

## Setup sesuai langkah Anda

1. Buat project Flutter: `flutter create cafe_finder`
2. Masuk folder project: `cd cafe_finder`
3. Buka VS Code: `code .`
4. Jalankan project pertama: `flutter run`
5. Buat Firebase project dengan nama `Cafe Finder`
6. Install Firebase CLI:
	- Install NodeJS
	- `npm install -g firebase-tools`
	- Cek: `firebase --version`
7. Login Firebase: `firebase login`
8. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
9. Hubungkan Firebase ke Flutter: `flutterfire configure`
10. Tambahkan package Firebase di `pubspec.yaml`
11. Jalankan: `flutter pub get`
12. Test Firebase dengan `main.dart`

## Struktur folder

- `lib/core`
- `lib/features`
- `lib/models`
- `lib/services`
- `lib/providers`

## Catatan

- File `lib/firebase_options.dart` di project ini masih placeholder sampai Anda menjalankan `flutterfire configure`.
- `firebase_storage` sudah ditambahkan untuk kebutuhan upload file/foto cafe di tahap berikutnya.

## Quick helpers for web development

- Free ports in the common dev range (8080–8090):

```powershell
# Lists processes listening on ports 8080..8090 and prompts to kill them
./scripts/free_port.ps1
```

- Run Flutter for web on a free port (lets Flutter pick a free web port):

```powershell
# Runs on Chrome using a free web port
./scripts/run_web.ps1 -Device chrome -Port 0
```

Use these when you see SocketException Errno 10048 (address already in use) on Windows.

## Setting the admin passcode (web)

The app reads an admin passcode from Cloud Firestore at `config/app.admin_secret` for web demo admin login.

1) Recommended (Firebase Console)

- Open https://console.firebase.google.com/ and select your project.
- Go to **Firestore Database** → **Data**.
- Create collection `config` (if missing) and add document `app`.
- Add field `admin_secret` (type: string) and set its value to the passcode you want (e.g. `ardan2056`).

2) Using Firebase CLI (if you have `firebase-tools` configured)

You can use the REST admin endpoint via `firebase deploy` / scripts, or use a small Node script with a service account (example below).

3) Node script template (requires Firebase service account JSON)

Create `scripts/set_admin_secret.js` and run with `node` (example below). This is useful for automation.

```js
// scripts/set_admin_secret.js
// Usage: node set_admin_secret.js /path/to/serviceAccount.json ardan2056
const admin = require('firebase-admin');
const [,, keyPath, secret] = process.argv;
if (!keyPath || !secret) {
	console.error('Usage: node set_admin_secret.js <serviceAccount.json> <secret>');
	process.exit(1);
}
admin.initializeApp({ credential: admin.credential.cert(require(keyPath)) });
const db = admin.firestore();
db.collection('config').doc('app').set({ admin_secret: secret })
	.then(() => { console.log('admin_secret set'); process.exit(0); })
	.catch(err => { console.error(err); process.exit(2); });
```

After setting the secret, open the web app and use the `Kode Admin (Web)` field on the login screen to sign in as admin.

Security note: this passcode flow is intended for development/demo only. For production, use authenticated admin accounts stored in `users/{uid}.role = 'admin'` and secure Firestore rules so only authorized parties can modify `config/app`.

## Avatar Upload & Guest Upgrade

How avatar uploads and guest upgrades work in this project:

- When a user picks an image (mobile), the app automatically crops the image to a centered square and resizes it to a maximum of 1600×1600, then compresses to JPEG (quality 85) or PNG when the source file is PNG.
- Temporary processed files are written to the system temp directory and uploaded to Firebase Storage under `users/{uid}/` (filename is a timestamped `.jpg`/`.png`). After successful upload the temporary files are cleaned up automatically.
- Guest (anonymous) users can use the app; when they upgrade (register), the app links the anonymous account to the new credential and migrates demo/local preferences into Firestore under `users/{uid}`.

Testing the flow locally:

1. Run the app on a device/emulator.
2. Sign in anonymously from the login screen and try the app (create favorites, etc.).
3. Go to Profile → Upgrade to register an email/password account; after linking, verify Firestore `users/{uid}` contains the demo data and `photoUrl` if you uploaded an avatar.

If you want an explicit interactive crop UI, consider adding `image_cropper` package and a small cropping step before upload (not included by default to avoid broad dependency upgrades). If you'd like, I can add this next.

## Profile: Simple Mode Toggle & Guest Login

- The app supports a "Simple Profile" mode that hides advanced profile features (preferences, admin panel, etc.) to keep the UI minimal for demos or guest users.
- You can toggle the mode at runtime from the Profile screen using the `Mode Sederhana` switch — the choice is stored in `SharedPreferences` under the key `simple_profile_mode_override` so you don't need to rebuild the app.
- Anonymous (guest) login is enabled by default. Use the `Masuk sebagai Tamu` button on the login screen to sign in anonymously. Guest data is stored locally (web) or in Firestore (native) and can be upgraded to a permanent account via the Upgrade flow in Profile.

## Creating an Admin User

For step-by-step secure instructions to create an admin user (script or manual via Console) see [ADMIN_CREATE.md](ADMIN_CREATE.md).

## Demo guest fallback & migration

When Anonymous sign-in is disabled for the Firebase project, the app now provides a safe local "demo guest" fallback so users can still explore the app without remote auth.

- How it works:
	- When `signInAnonymously()` fails with a restriction, the app stores demo data in `SharedPreferences` and sets `demo_mode = true`.
	- Keys used (in `SharedPreferences`): `demo_mode`, `demo_name`, `demo_email`, `demo_phone`, `demo_role`, `demo_photo`, `demo_preferences`.
	- The Profile screen detects `demo_mode` and shows a local demo profile built from those keys. Logout clears the demo keys.

- Migration to a real account:
	- If a demo user later registers using the app's `Buat Akun` flow, the app will automatically migrate demo data into Firestore under `users/{uid}` for the newly created Firebase user (merge).
	- After successful migration the app clears the local demo keys.

- How to test locally:
	1. Run the app and click `Masuk sebagai Tamu` (if Anonymous sign-in disabled, the app enters demo mode automatically).
 2. Go to Profile and verify demo name/role shown.
 3. Use `Buat Akun` to register; after registration check Firestore `users/{uid}` for migrated fields (name, preferences, role).

- Notes:
	- Demo mode stores data locally only; it is intended for development and demos. For production, prefer enabling Anonymous sign-in in Firebase and using real Firestore documents.
	- The migration attempts to copy name, phone, photo URL, and preferences into the Firestore document for the new user and marks role as `user`.
