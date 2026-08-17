process.env.DB_MODE = 'file';
process.env.DATA_FILE = `${__dirname}/test-notes-${process.pid}.json`;

const fs = require('fs/promises');
const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { createApp } = require('../server');

const app = createApp();

test.after(async () => {
  await fs.rm(process.env.DATA_FILE, { force: true });
});

test('health endpoint returns the contract', async () => {
  const response = await request(app).get('/health').expect(200);
  assert.deepEqual(response.body, { status: 'healthy' });
});

test('identity endpoint does not return the raw token', async () => {
  const payload = Buffer.from(JSON.stringify({ email: 'user@magnitglobal.com', secret: 'never-return' })).toString('base64url');
  const token = `header.${payload}.signature`;
  const response = await request(app).get('/identity').set('x-amzn-ava-user-context', token).expect(200);
  assert.equal(response.body.claims.email, 'user@magnitglobal.com');
  assert.equal(response.body.claims.secret, undefined);
  assert.equal(JSON.stringify(response.body).includes(token), false);
  assert.equal(response.body.signature_validated, false);
});

test('notes can be created, listed, and deleted', async () => {
  const created = await request(app).post('/api/notes').send({ title: 'Zero Trust', content: 'Verified Access' }).expect(201);
  const id = created.body.note.id;
  const listed = await request(app).get('/api/notes').expect(200);
  assert.equal(listed.body.notes.some((note) => note.id === id), true);
  await request(app).delete(`/api/notes/${id}`).expect(200);
});

test('invalid note input is rejected', async () => {
  await request(app).post('/api/notes').send({ title: ' ' }).expect(400);
  await request(app).delete('/api/notes/not-a-number').expect(400);
});
