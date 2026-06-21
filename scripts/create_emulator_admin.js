// scripts/create_emulator_admin.js
const admin = require('firebase-admin');

process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';

const projectId = 'cafee-finder';
admin.initializeApp({ projectId });

const db = admin.firestore();
const auth = admin.auth();

const email = 'admin@cafefinder.local';
const password = 'Password123!';
const displayName = 'Admin Cafe Finder';

async function createEmulatorAdmin() {
  try {
    // 1. Check if user already exists
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(email);
      console.log(`User already exists in Auth emulator with UID: ${userRecord.uid}`);
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        userRecord = await auth.createUser({
          email,
          password,
          displayName,
          emailVerified: true,
        });
        console.log(`Created user in Auth emulator with UID: ${userRecord.uid}`);
      } else {
        throw e;
      }
    }

    // 2. Create/Update user document in Firestore with 'admin' role
    await db.collection('users').doc(userRecord.uid).set({
      uid: userRecord.uid,
      name: displayName,
      email: email,
      role: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log('\n--- Admin User Ready ---');
    console.log(`Email: ${email}`);
    console.log(`Password: ${password}`);
    console.log(`UID: ${userRecord.uid}`);
    console.log('------------------------');
    process.exit(0);
  } catch (err) {
    console.error('Failed to create emulator admin user:', err);
    process.exit(1);
  }
}

createEmulatorAdmin();
