// ============================================
// Database Connection Module
// ============================================
// Handles MySQL/RDS connection pool and table setup

const mysql = require('mysql2/promise');
require('dotenv').config();

// Create a connection pool (better than single connections for production)
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // Enable this if your RDS requires SSL
  // ssl: { rejectUnauthorized: false }
});

/**
 * Test database connection
 * Returns connection info if successful
 */
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query('SELECT VERSION() as version');
    connection.release();
    return {
      connected: true,
      version: rows[0].version,
      engine: 'MySQL',
    };
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    return {
      connected: false,
      error: error.message,
    };
  }
}

/**
 * Create notes table if it doesn't exist
 * This runs automatically on server start
 */
async function initializeDatabase() {
  const createTableSQL = `
    CREATE TABLE IF NOT EXISTS notes (
      id INT AUTO_INCREMENT PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      content TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `;

  try {
    await pool.query(createTableSQL);
    console.log('✅ Notes table ready');
    return true;
  } catch (error) {
    console.error('❌ Failed to create table:', error.message);
    return false;
  }
}

/**
 * Mask sensitive parts of the RDS endpoint
 * Example: mydb.abc123.ap-south-1.rds.amazonaws.com -> mydb.****.ap-south-1.rds.amazonaws.com
 */
function getMaskedEndpoint() {
  const host = process.env.DB_HOST || 'not-configured';
  const parts = host.split('.');

  if (parts.length >= 4) {
    // Mask the account-specific identifier (second part)
    parts[1] = '****';
    return parts.join('.');
  }

  return host;
}

module.exports = {
  pool,
  testConnection,
  initializeDatabase,
  getMaskedEndpoint,
};
