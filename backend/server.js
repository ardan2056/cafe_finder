const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const admin = require('firebase-admin');
const { Pool } = require('pg');

// Initialize Firebase Admin SDK
if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  admin.initializeApp();
} else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  // FIREBASE_SERVICE_ACCOUNT_JSON can contain the raw JSON string
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
} else {
  // initializeApp() without creds will attempt to use the environment (Cloud Run default SA)
  try {
    admin.initializeApp();
  } catch (e) {
    console.warn('Firebase Admin not initialized with credentials; set GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_SERVICE_ACCOUNT_JSON');
  }
}

// Postgres pool (Cloud SQL or standard PG connection)
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || process.env.PG_CONNECTION_STRING,
  // If running in Cloud Run and using Cloud SQL Proxy, additional config may be required
});

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Middleware: verify Firebase ID token
async function verifyToken(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  const idToken = auth.split('Bearer ')[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.auth = decoded;
    return next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid ID token', details: err.message });
  }
}

// Check admin role in Firestore or allow ADMIN_SECRET for bootstrap
async function requireAdmin(req, res, next) {
  const bypassSecret = req.headers['x-admin-secret'] || process.env.ADMIN_SECRET;
  if (bypassSecret && req.headers['x-admin-secret'] === bypassSecret) return next();
  if (!req.auth) return res.status(401).json({ error: 'Not authenticated' });
  try {
    const userDoc = await admin.firestore().doc(`users/${req.auth.uid}`).get();
    const role = userDoc.exists ? (userDoc.data().role || '') : '';
    if (role === 'admin') return next();
    return res.status(403).json({ error: 'Admin role required' });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to verify admin role', details: err.message });
  }
}

app.get('/health', (req, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

// Promote a user to a role (admin-only endpoint). Requires caller to be admin or present ADMIN_SECRET.
app.post('/admin/promote', verifyToken, requireAdmin, async (req, res) => {
  const { uid, role } = req.body;
  if (!uid || !role) return res.status(400).json({ error: 'uid and role are required' });
  try {
    await admin.firestore().doc(`users/${uid}`).set({ role }, { merge: true });
    return res.json({ ok: true, uid, role });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to set role', details: err.message });
  }
});

// Endpoint to create a cafe record in Postgres (admin only)
app.post('/cafes', verifyToken, requireAdmin, async (req, res) => {
  const { name, address, lat, lng } = req.body;
  if (!name || !lat || !lng) return res.status(400).json({ error: 'name, lat, lng required' });
  try {
    const result = await pool.query(
      'INSERT INTO cafes (name, address, lat, lng) VALUES ($1, $2, $3, $4) RETURNING id',
      [name, address || null, lat, lng]
    );
    return res.json({ ok: true, id: result.rows[0].id });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to create cafe', details: err.message });
  }
});

// Example: public list of cafes
app.get('/cafes', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, name, address, lat, lng FROM cafes ORDER BY id DESC LIMIT 100');
    return res.json({ ok: true, cafes: result.rows });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch cafes', details: err.message });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`Server listening on port ${PORT}`));
