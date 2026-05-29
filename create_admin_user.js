// create_admin_user.js
// Usage: node create_admin_user.js /path/to/serviceAccount.json email password [displayName]
// Example: node create_admin_user.js ./serviceAccount.json admin@example.com S3cretP@ss "Admin User"

const path = require('path');
const keyPath = process.argv[2];
const email = process.argv[3];
const password = process.argv[4];
const displayName = process.argv[5] || 'Admin';

if (!keyPath || !email || !password) {
  console.error('Usage: node create_admin_user.js /path/to/serviceAccount.json email password [displayName]');
  process.exit(1);
}

const admin = require('firebase-admin');

try {
  const fullPath = path.resolve(keyPath);
  admin.initializeApp({ credential: admin.credential.cert(require(fullPath)) });
} catch (err) {
  console.error('Failed to initialize Firebase Admin SDK:', err.message || err);
  process.exit(2);
}

const db = admin.firestore();

async function createAdmin() {
  try {
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: displayName,
      emailVerified: true,
    });

    const uid = userRecord.uid;
    await db.collection('users').doc(uid).set({
      uid: uid,
      name: displayName,
      email: email,
      role: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log(`Admin user created: ${email} (uid: ${uid})`);
    process.exit(0);
  } catch (err) {
    console.error('Failed to create admin user:', err);
    process.exit(3);
  }
}

createAdmin();
