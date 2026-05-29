Admin account creation — secure instructions

Options to create an admin user for cafe_finder

Option A — Run the included Node script locally (recommended, secure)

1. Obtain a Firebase service account JSON for your project:
   - Console → Project settings → Service accounts → Generate new private key
   - Save the file somewhere safe (e.g. C:\Users\YOU\Downloads\serviceAccount.json)

2. From the repo root run:

```powershell
node create_admin_user.js C:\path\to\serviceAccount.json admin@cafefinder.local "S3cureP@ssw0rd" "Admin User"
```

3. Script output shows the created UID. Verify in Firebase Console → Authentication and Firestore → users/{uid}.

4. For security, delete the local `serviceAccount.json` after use.

Option B — Run the script on your machine but keep the key out of the repo

- Same as Option A but explicitly avoid committing or uploading the key. If you need to re-run, store the key outside of the project folder.

Option C — Manual creation via Firebase Console

1. Console → Authentication → Users → Add user
   - Email: admin@cafefinder.local
   - Password: choose a secure password
   - Email verified: optional

2. Console → Firestore → Create document
   - Collection: `users`
   - Document ID: the UID from the created auth user (found in Authentication list)
   - Fields (JSON):

```json
{
  "uid": "<the-uid>",
  "name": "Admin User",
  "email": "admin@cafefinder.local",
  "role": "admin",
  "createdAt": "<server timestamp>",
  "updatedAt": "<server timestamp>"
}
```

3. Save document. The app checks `users/{uid}.role === 'admin'` to enable admin features.

Verification snippets

- Using Firebase Console: check Authentication and Firestore documents.
- Using Node (quick read):

```js
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.cert(require('./serviceAccount.json')) });
const db = admin.firestore();
(async () => {
  const userDoc = await db.collection('users').doc('<uid>').get();
  console.log(userDoc.data());
})();
```

Notes & security

- Never commit `serviceAccount.json` to source control.
- Prefer running the script locally and deleting the key immediately after.
- If you prefer, create the user manually via Console (Option C).

If you want, I can run the script here if you upload the `serviceAccount.json` to the workspace (NOT recommended for public repos). Otherwise, run it locally and paste the UID output if you want me to verify role and Firestore doc creation.