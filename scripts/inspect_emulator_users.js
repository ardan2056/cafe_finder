// scripts/inspect_emulator_users.js
// Usage:
//   node scripts/inspect_emulator_users.js            -> lists up to 50 users in emulator
//   node scripts/inspect_emulator_users.js <UID>     -> prints user doc for UID

const admin = require('firebase-admin');

async function main() {
  const uid = process.argv[2];
  const projectId = process.env.FIREBASE_PROJECT_ID || 'demo';

  // When connecting to the emulator, set FIRESTORE_EMULATOR_HOST=localhost:8080
  // and set FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 if needed.
  admin.initializeApp({ projectId });
  const db = admin.firestore();

  if (uid) {
    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) {
      console.log(`No user document found for uid=${uid}`);
      process.exit(2);
    }
    console.log(`User ${uid} doc:`);
    console.log(JSON.stringify(doc.data(), null, 2));
    process.exit(0);
  }

  const snap = await db.collection('users').limit(50).get();
  console.log(`Found ${snap.size} user docs (showing up to 50):`);
  snap.forEach(d => {
    console.log(`- ${d.id}: ${JSON.stringify(d.data())}`);
  });
}

main().catch(err => {
  console.error('Error inspecting emulator users:', err);
  process.exit(1);
});
