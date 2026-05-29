const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

async function run() {
  const sqlPath = path.join(__dirname, 'migrations.sql');
  if (!fs.existsSync(sqlPath)) {
    console.error('migrations.sql not found');
    process.exit(1);
  }
  const sql = fs.readFileSync(sqlPath, 'utf8');
  const pool = new Pool({ connectionString: process.env.DATABASE_URL || process.env.PG_CONNECTION_STRING });
  try {
    console.log('Running migrations...');
    await pool.query(sql);
    console.log('Migrations complete');
    await pool.end();
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err.message || err);
    process.exit(2);
  }
}

run();
