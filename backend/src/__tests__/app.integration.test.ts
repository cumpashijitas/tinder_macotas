import { describe, it, expect, vi } from 'vitest';
import request from 'supertest';
import { createSupabaseAdminMock } from './helpers/supabaseMock.js';

const mockAdmin = createSupabaseAdminMock({
  profiles: { data: [{ id: 'profile-1' }], error: null },
});

vi.mock('../config/supabase.js', () => ({
  supabaseAdmin: mockAdmin,
  supabaseAnon: mockAdmin,
}));

process.env.NODE_ENV = 'test';
const { default: app } = await import('../app.js');

describe('App HTTP básico', () => {
  it('GET /health responde 200 con estado healthy cuando la base responde', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('healthy');
    expect(res.body.data.database).toBe('up');
  });

  it('GET /health responde 503 y "degraded" si Supabase falla', async () => {
    mockAdmin.from.mockImplementationOnce(() => ({
      select: vi.fn().mockReturnThis(),
      limit: vi.fn(() => Promise.resolve({ data: null, error: { message: 'connection refused' } })),
    }));

    const res = await request(app).get('/health');
    expect(res.status).toBe(503);
    expect(res.body.success).toBe(false);
    expect(res.body.errors.status).toBe('degraded');
    expect(res.body.errors.database).toBe('down');
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
