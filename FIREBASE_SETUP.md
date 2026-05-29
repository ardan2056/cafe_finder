Firebase Web + Google Sign-In setup (recommended)

Recommended approach: Use Firebase Authentication for Google Sign-In + OpenStreetMap for maps.

1) Create Firebase project
- Open https://console.firebase.google.com and create a new project (or use existing).

2) Add Web app
- In Project Settings -> General -> Your apps -> Add app (</>)
- Set an app nickname and register app. Copy the Firebase config object.

3) Run `flutterfire configure` (preferred)
- Install FlutterFire CLI if not installed:
  ```bash
  dart pub global activate flutterfire_cli
  ```
- From workspace root run:
  ```bash
  flutterfire configure
  ```
- Select the Firebase project and the platforms (include `web`). This generates `lib/firebase_options.dart`.

4) Enable Google Sign-In provider
- Firebase Console -> Authentication -> Sign-in method -> enable Google
- In Authorized Domains, add `localhost` or `localhost:PORT` used by `flutter run -d chrome`.

5) (Web) Add OAuth client ID for `google_sign_in` plugin
- Firebase will create an OAuth client for the web app; if not, create one in Google Cloud Console -> APIs & Services -> Credentials -> OAuth client ID -> Web application.
- Add authorized origins: e.g. `http://localhost:PORT` and your production domain.
- Copy the Client ID and put it in `web/index.html` meta tag if using `google_sign_in` plugin:
  ```html
  <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
  ```

6) Update app if needed
- Ensure `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` is called before using auth (the project already includes `lib/main.dart` using firebase bootstrap files).

7) Test locally
- Run `flutter run -d chrome`, open the app and test "Masuk dengan Google".
- If error about client id appears, make sure the meta tag contains the Web OAuth client id and `Authorized JavaScript origins` are set.

Notes & alternatives
- If you prefer not to use Firebase, you can still use `google_sign_in` directly via OAuth client ID, but Firebase simplifies backend rules, user records, and storage access.
- For maps in production, prefer a paid tile provider (MapTiler, Mapbox) or self-host tiles instead of using OSM public tile servers.

If you want, I can:
- Fill `lib/firebase_options.dart` if you paste the generated firebase options object (from `flutterfire configure`).
- Add the exact Client ID to `web/index.html` if you paste it here.
- Guide you step-by-step through the Firebase Console screens.
