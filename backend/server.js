// ============================================
// Cloud Notes App - Express Server
// ============================================
// Built for the AWS Zero to Hero series
// YouTube: https://youtube.com/@awsandevops

const express = require('express');
const cors = require('cors');
require('dotenv').config();

const {
  pool,
  testConnection,
  initializeDatabase,
  getMaskedEndpoint,
} = require('./db');

const app = express();
const PORT = process.env.PORT || 5000;

// ============================================
// Middleware
// ============================================
app.use(cors());
app.use(express.json());

// Simple request logger
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} | ${req.method} ${req.path}`);
  next();
});

// ============================================
// Routes
// ============================================

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

// Database status endpoint
app.get('/api/db-status', async (req, res) => {
  try {
    const result = await testConnection();
    res.json({
      ...result,
      endpoint: getMaskedEndpoint(),
      database: process.env.DB_NAME || 'not-configured',
      port: process.env.DB_PORT || 3306,
    });
  } catch (error) {
    res.status(500).json({
      connected: false,
      error: error.message,
    });
  }
});

// Get all notes
app.get('/api/notes', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM notes ORDER BY created_at DESC'
    );
    res.json({
      success: true,
      count: rows.length,
      notes: rows,
    });
  } catch (error) {
    console.error('Error fetching notes:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch notes',
      message: error.message,
    });
  }
});

// Create a new note
app.post('/api/notes', async (req, res) => {
  const { title, content } = req.body;

  // Validation
  if (!title || title.trim() === '') {
    return res.status(400).json({
      success: false,
      error: 'Title is required',
    });
  }

  try {
    const [result] = await pool.query(
      'INSERT INTO notes (title, content) VALUES (?, ?)',
      [title.trim(), content ? content.trim() : '']
    );

    const [newNote] = await pool.query('SELECT * FROM notes WHERE id = ?', [
      result.insertId,
    ]);

    res.status(201).json({
      success: true,
      note: newNote[0],
    });
  } catch (error) {
    console.error('Error creating note:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to create note',
      message: error.message,
    });
  }
});

// Delete a note by ID
app.delete('/api/notes/:id', async (req, res) => {
  const { id } = req.params;

  if (!id || isNaN(id)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid note ID',
    });
  }

  try {
    const [result] = await pool.query('DELETE FROM notes WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        error: 'Note not found',
      });
    }

    res.json({
      success: true,
      message: 'Note deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting note:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to delete note',
      message: error.message,
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found',
    path: req.path,
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
  });
});

// ============================================
// Start Server
// ============================================
async function startServer() {
  console.log('\n🚀 Starting Cloud Notes App Backend...\n');

  // Test database connection
  const dbStatus = await testConnection();

  if (dbStatus.connected) {
    console.log('✅ Connected to RDS:', getMaskedEndpoint());
    console.log('✅ Database engine:', dbStatus.engine, dbStatus.version);

    // Initialize tables
    await initializeDatabase();
  } else {
    console.log('⚠️  Server starting WITHOUT database connection');
    console.log('⚠️  Reason:', dbStatus.error);
    console.log('⚠️  Check your .env file and RDS security group rules');
  }

  app.listen(PORT, () => {
    console.log(`\n✅ Server running on http://localhost:${PORT}`);
    console.log(`✅ Health check: http://localhost:${PORT}/health`);
    console.log(`✅ DB Status:    http://localhost:${PORT}/api/db-status\n`);
  });
}

startServer();
