Demo migration E2E (emulator) — scaffold

This file describes how to run an end-to-end flow against the Firebase Emulators to validate demo→register migration.

Prerequisites:
- Install firebase-tools and start emulators (see `scripts/emulator/README.md`).
- Ensure `firebase.json` contains emulator config for auth and firestore (optional).

High-level flow:
1. Start emulators: `.\scripts\start_firebase_emulator.ps1 -ProjectId auto`
2. In another terminal, set `USE_FIREBASE_EMULATOR=1` and run the app: `$env:USE_FIREBASE_EMULATOR='1'; flutter run -d windows`
3. In app: click "Masuk sebagai Tamu" (Guest). App should create an anonymous user in the Auth emulator.
4. Use Profile → Buat Akun to register. App should migrate demo SharedPreferences into Firestore; verify in the emulator UI or via `firebase emulators:exec` or `firebase firestore:documents`.

Automating the test:
- You can automate steps 3–4 with a Flutter integration_test that controls the UI, but make sure the emulator is started and `USE_FIREBASE_EMULATOR` is set in the test environment before launching the app.

If you'd like, I can:
- Add a Flutter `integration_test` that runs the guest→register flow (requires adding `integration_test` bindings), or
- Add a Node.js script using the Firebase Admin SDK to inspect emulator data after the flow completes.

Which automation option do you prefer? (1) Flutter integration_test, (2) Node admin verification script, (3) Manual verification steps only.
