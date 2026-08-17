const fs = require('fs/promises');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config();

const mode = process.env.DB_MODE || (process.env.DB_HOST ? 'mysql' : 'file');
const dataFile = process.env.DATA_FILE || '/var/lib/cloud-notes/notes.json';
let pool;
let fileWrite = Promise.resolve();

function mysqlPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT || 3306),
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      ssl: process.env.DB_SSL === 'true' ? { minVersion: 'TLSv1.2' } : undefined,
    });
  }
  return pool;
}

async function readFileStore() {
  try {
    return JSON.parse(await fs.readFile(dataFile, 'utf8'));
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    return [];
  }
}

async function writeFileStore(notes) {
  await fs.mkdir(path.dirname(dataFile), { recursive: true });
  const temporary = `${dataFile}.tmp`;
  await fs.writeFile(temporary, JSON.stringify(notes, null, 2), { mode: 0o600 });
  await fs.rename(temporary, dataFile);
}

async function initializeDatabase() {
  if (mode === 'file') {
    const notes = await readFileStore();
    await writeFileStore(notes);
    return true;
  }

  await mysqlPool().query(`
    CREATE TABLE IF NOT EXISTS notes (
      id INT AUTO_INCREMENT PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      content TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  return true;
}

async function testConnection() {
  try {
    if (mode === 'file') {
      await initializeDatabase();
      return { connected: true, version: '1', engine: 'Local encrypted-volume JSON' };
    }
    const connection = await mysqlPool().getConnection();
    const [rows] = await connection.query('SELECT VERSION() AS version');
    connection.release();
    return { connected: true, version: rows[0].version, engine: 'MySQL' };
  } catch (error) {
    return { connected: false, error: error.message };
  }
}

async function listNotes() {
  if (mode === 'file') {
    const notes = await readFileStore();
    return notes.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  }
  const [rows] = await mysqlPool().query('SELECT * FROM notes ORDER BY created_at DESC');
  return rows;
}

async function createNote(title, content) {
  if (mode === 'file') {
    let created;
    fileWrite = fileWrite.then(async () => {
      const notes = await readFileStore();
      created = {
        id: notes.reduce((maximum, note) => Math.max(maximum, note.id), 0) + 1,
        title,
        content,
        created_at: new Date().toISOString(),
      };
      notes.push(created);
      await writeFileStore(notes);
    });
    await fileWrite;
    return created;
  }
  const [result] = await mysqlPool().query(
    'INSERT INTO notes (title, content) VALUES (?, ?)',
    [title, content]
  );
  const [rows] = await mysqlPool().query('SELECT * FROM notes WHERE id = ?', [result.insertId]);
  return rows[0];
}

async function deleteNote(id) {
  if (mode === 'file') {
    let deleted = false;
    fileWrite = fileWrite.then(async () => {
      const notes = await readFileStore();
      const remaining = notes.filter((note) => note.id !== id);
      deleted = remaining.length !== notes.length;
      if (deleted) await writeFileStore(remaining);
    });
    await fileWrite;
    return deleted;
  }
  const [result] = await mysqlPool().query('DELETE FROM notes WHERE id = ?', [id]);
  return result.affectedRows > 0;
}

function getMaskedEndpoint() {
  if (mode === 'file') return 'private EBS volume';
  const parts = (process.env.DB_HOST || 'not-configured').split('.');
  if (parts.length >= 4) parts[1] = '****';
  return parts.join('.');
}

module.exports = {
  mode,
  initializeDatabase,
  testConnection,
  listNotes,
  createNote,
  deleteNote,
  getMaskedEndpoint,
};
