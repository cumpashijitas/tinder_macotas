import { describe, it, expect, vi } from 'vitest';
import request from 'supertest';

const mockAdmin = {
  from: vi.fn(() => ({
    select: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    maybeSingle: vi.fn(() => Promise.resolve({ data: null, error: null })),
  })),
  auth: {
    getUser: vi.fn(),
    signInWithOtp: vi.fn(() => Promise.resolve({ error: null })),
  },
};

vi.mock('../config/supabase.js', () => ({
  supabaseAdmin: mockAdmin,
  supabaseAnon: mockAdmin,
}));

process.env.NODE_ENV = 'test';
const { default: app } = await import('../app.js');

describe('Rate limiting de /api/auth/otp', () => {
  it('permite hasta 5 pedidos de OTP y bloquea (429) el sexto dentro de la misma ventana', async () => {
    for (let i = 0; i < 5; i++) {
      const res = await request(app).post('/api/auth/otp').send({ email: 'test@example.com' });
      expect(res.status).toBe(200);
    }

    const blocked = await request(app).post('/api/auth/otp').send({ email: 'test@example.com' });
    expect(blocked.status).toBe(429);
    expect(blocked.body.success).toBe(false);
  });
});

describe('Headers de seguridad (Helmet)', () => {
  it('incluye X-Content-Type-Options: nosniff en la respuesta', async () => {
    const res = await request(app).get('/health');
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });
});
