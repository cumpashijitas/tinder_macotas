import { describe, it, expect, vi, afterEach } from 'vitest';
import express from 'express';
import request from 'supertest';
import { requestLogger } from '../middlewares/logging.middleware.js';

function buildApp() {
  const app = express();
  app.use(requestLogger);
  app.get('/ok', (_req, res) => res.status(200).json({ ok: true }));
  app.get('/fail', (_req, res) => res.status(500).json({ ok: false }));
  return app;
}

describe('requestLogger', () => {
  afterEach(() => vi.restoreAllMocks());

  it('deja pasar la request sin alterar la respuesta', async () => {
    const app = buildApp();
    const res = await request(app).get('/ok');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true });
  });

  it('loguea con console.log una respuesta exitosa, en formato JSON con method/path/status', async () => {
    const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
    const app = buildApp();

    await request(app).get('/ok');
    // res.on('finish') es asíncrono respecto al envío de la respuesta
    await new Promise((resolve) => setImmediate(resolve));

    expect(logSpy).toHaveBeenCalledTimes(1);
    const entry = JSON.parse(logSpy.mock.calls[0][0] as string);
    expect(entry).toMatchObject({ method: 'GET', path: '/ok', status: 200 });
  });

  it('loguea con console.error una respuesta 500', async () => {
    const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
    const app = buildApp();

    await request(app).get('/fail');
    await new Promise((resolve) => setImmediate(resolve));

    expect(errorSpy).toHaveBeenCalledTimes(1);
    const entry = JSON.parse(errorSpy.mock.calls[0][0] as string);
    expect(entry.status).toBe(500);
  });
});
