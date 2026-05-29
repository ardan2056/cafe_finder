// set_admin_role.js
// Usage: node set_admin_role.js /path/to/serviceAccount.json <userUid> <role>
// Example: node set_admin_role.js ./serviceAccount.json abc123 admin

const path = require('path');
const keyPath = process.argv[2];
const uid = process.argv[3];
const role = process.argv[4];

if (!keyPath || !uid || !role) {
  console.error('Usage: node set_admin_role.js /path/to/serviceAccount.json <userUid> <role>');
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

async function setRole() {
  try {
    await db.collection('users').doc(uid).set({ role: role, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    console.log(`Role '${role}' set for user ${uid}`);
    process.exit(0);
  } catch (err) {
    console.error('Failed to set role:', err);
    process.exit(3);
  }
}

setRole();
