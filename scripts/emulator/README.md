Local Firebase Emulator (Auth + Firestore)

This project supports running the Firebase Auth and Firestore emulators locally for end-to-end testing and development without touching your production Firebase project.

Quick steps (Windows PowerShell):

1. Install firebase-tools if you don't have it:

```powershell
npm install -g firebase-tools
```

2. Start the emulators (from project root):

```powershell
# optional: provide a project id (default: auto)
.
./scripts/start_firebase_emulator.ps1 -ProjectId auto
```

The script sets `USE_FIREBASE_EMULATOR=1` in the spawned shell, and runs the emulators for Auth and Firestore.

3. In another PowerShell window (project root), run the app with the same env var so the app will connect to the emulators:

```powershell
$env:USE_FIREBASE_EMULATOR = '1'
flutter run -d windows
```

Notes:
- The native bootstrap (`lib/bootstrap/firebase_bootstrap_native.dart`) will detect `USE_FIREBASE_EMULATOR=1` and call the appropriate `useFirestoreEmulator` and `useAuthEmulator` APIs.
- The emulator UI runs on http://localhost:4000 by default; check the emulator output for the port and web UI link.
- For Flutter web you may need to call the emulator config APIs in `lib/bootstrap/firebase_bootstrap_web.dart` if you want web support.

Running tests against emulators:
- Start the emulators first (see step 2).
- Then run the app or integration tests while `USE_FIREBASE_EMULATOR` is set in the environment.

Security: Always ensure you are not pointing an emulator to production credentials. Emulators are local-only and safe for development.

Inspecting emulator data from Node.js

You can use a small Node script to inspect the `users` collection in the Firestore emulator. Example script added at `scripts/inspect_emulator_users.js`.

Run the script while the emulators are running (make sure `FIRESTORE_EMULATOR_HOST` is set by the emulator process):

```powershell
# From project root, with emulators started in another terminal
node scripts/inspect_emulator_users.js                 # list up to 50 user docs
node scripts/inspect_emulator_users.js <uid>           # show a single user doc
```

Notes:
- The script initializes `firebase-admin` with only `projectId` so it connects to the emulator when `FIRESTORE_EMULATOR_HOST` is set.
- If you run into permission errors, ensure you started the emulators with the same `--project` id and that the `FIRESTORE_EMULATOR_HOST` environment variable is present in the shell you're using to run the script.
