const express = require('express');
require('dotenv').config();

const store = require('./db');

function inspectVerifiedAccessContext(value) {
  if (!value) return { context_present: false };
  if (value.length > 16384) return { context_present: true, error: 'context_too_large' };

  try {
    const parts = value.split('.');
    if (parts.length !== 3) throw new Error('not_jwt');
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    const safeClaims = {};
    for (const key of ['sub', 'email', 'preferred_username', 'iss', 'aud', 'iat', 'exp']) {
      if (payload[key] !== undefined) safeClaims[key] = payload[key];
    }
    return {
      context_present: true,
      signature_validated: false,
      claims: safeClaims,
      notice: 'Claims are informational until the JWT signature is validated against the Verified Access public key.',
    };
  } catch (_) {
    return { context_present: true, signature_validated: false, error: 'invalid_context_format' };
  }
}

function createApp() {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '32kb' }));

  app.use((req, res, next) => {
    res.set('Cache-Control', 'no-store');
    console.log(`${new Date().toISOString()} | ${req.method} ${req.path}`);
    next();
  });

  app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'healthy' });
  });

  app.get('/identity', (req, res) => {
    res.json(inspectVerifiedAccessContext(req.get('x-amzn-ava-user-context')));
  });

  app.get('/api/db-status', async (_req, res) => {
    const result = await store.testConnection();
    res.status(result.connected ? 200 : 503).json({
      ...result,
      endpoint: store.getMaskedEndpoint(),
      database: store.mode === 'file' ? 'cloud-notes' : process.env.DB_NAME || 'not-configured',
      port: store.mode === 'file' ? 'local' : process.env.DB_PORT || 3306,
    });
  });

  app.get('/api/notes', async (_req, res, next) => {
    try {
      const notes = await store.listNotes();
      res.json({ success: true, count: notes.length, notes });
    } catch (error) { next(error); }
  });

  app.post('/api/notes', async (req, res, next) => {
    const title = typeof req.body.title === 'string' ? req.body.title.trim() : '';
    const content = typeof req.body.content === 'string' ? req.body.content.trim() : '';
    if (!title) return res.status(400).json({ success: false, error: 'Title is required' });
    if (title.length > 255) return res.status(400).json({ success: false, error: 'Title is too long' });
    try {
      const note = await store.createNote(title, content);
      return res.status(201).json({ success: true, note });
    } catch (error) { return next(error); }
  });

  app.delete('/api/notes/:id', async (req, res, next) => {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id < 1) return res.status(400).json({ success: false, error: 'Invalid note ID' });
    try {
      const deleted = await store.deleteNote(id);
      if (!deleted) return res.status(404).json({ success: false, error: 'Note not found' });
      return res.json({ success: true, message: 'Note deleted successfully' });
    } catch (error) { return next(error); }
  });

  app.use((req, res) => res.status(404).json({ success: false, error: 'Route not found', path: req.path }));
  app.use((error, _req, res, _next) => {
    console.error('Unhandled request error:', error.message);
    res.status(500).json({ success: false, error: 'Internal server error' });
  });
  return app;
}

async function startServer() {
  await store.initializeDatabase();
  const port = Number(process.env.PORT || 5000);
  return createApp().listen(port, '0.0.0.0', () => console.log(`Cloud Notes listening on port ${port}`));
}

if (require.main === module) {
  startServer().catch((error) => {
    console.error('Application startup failed:', error.message);
    process.exit(1);
  });
}

module.exports = { createApp, inspectVerifiedAccessContext, startServer };
