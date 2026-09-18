import { describe, it, expect, vi, afterEach } from 'vitest';
import express from 'express';
import request from 'supertest';
import { errorHandler } from '../middlewares/error_handler.middleware.js';

function buildThrowingApp() {
  const app = express();
  app.get('/boom', () => {
    throw new Error('algo explotó');
  });
  app.use(errorHandler);
  return app;
}

describe('errorHandler', () => {
  afterEach(() => vi.restoreAllMocks());

  it('convierte una excepción no atrapada en una respuesta JSON 500 (no HTML de Express)', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const app = buildThrowingApp();

    const res = await request(app).get('/boom');

    expect(res.status).toBe(500);
    expect(res.body.success).toBe(false);
    expect(res.headers['content-type']).toMatch(/json/);
  });
});
