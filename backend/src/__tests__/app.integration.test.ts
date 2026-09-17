import { describe, it, expect } from 'vitest';
import request from 'supertest';

process.env.NODE_ENV = 'test';
const { default: app } = await import('../app.js');

describe('App HTTP básico', () => {
  it('GET /health responde 200 con estado healthy', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('healthy');
  });

  it('GET /ruta-inexistente responde 404', async () => {
    const res = await request(app).get('/ruta-inexistente');
    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  it('rutas protegidas exigen Bearer token (401 sin token)', async () => {
    const endpoints = [
      ['get', '/api/pets/feed'],
      ['get', '/api/pets/inventory'],
      ['get', '/api/swipes/matches'],
      ['get', '/api/adopter/form'],
      ['get', '/api/stories'],
    ] as const;

    for (const [method, path] of endpoints) {
      const res = await request(app)[method](path);
      expect(res.status, `${method.toUpperCase()} ${path} debería exigir auth`).toBe(401);
    }
  });

  it('POST /api/auth/otp exige un email', async () => {
    const res = await request(app).post('/api/auth/otp').send({});
    expect(res.status).toBe(400);
  });

  it('CORS: refleja el origen para un dominio permitido', async () => {
    const res = await request(app)
      .get('/health')
      .set('Origin', 'https://frontend-six-wheat-83.vercel.app');

    expect(res.headers['access-control-allow-origin']).toBe(
      'https://frontend-six-wheat-83.vercel.app'
    );
  });

  it('CORS: rechaza un origen no permitido', async () => {
    const res = await request(app).get('/health').set('Origin', 'https://sitio-malicioso.com');

    expect(res.headers['access-control-allow-origin']).toBeUndefined();
  });

  it('CORS: sin header Origin (curl, apps móviles) igual responde con éxito', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
  });
});
