import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock, lastBuilderFor } from './helpers/supabaseMock.js';

const mockAdmin = createSupabaseAdminMock({
  profiles: { data: { id: 'user-1', full_name: 'Ana Torres', role: 'adopter' }, error: null },
});

vi.mock('../config/supabase.js', () => ({
  supabaseAdmin: mockAdmin,
  supabaseAnon: mockAdmin,
}));

const { AuthController } = await import('../controllers/auth.controller.js');

function mockRes() {
  const res: Record<string, unknown> = {};
  res.status = vi.fn(() => res);
  res.json = vi.fn(() => res);
  return res as { status: ReturnType<typeof vi.fn>; json: ReturnType<typeof vi.fn> };
}

describe('AuthController.upsertProfile', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza sin nombre completo', async () => {
    const req = { user: { id: 'user-1' }, body: { role: 'adopter' } };
    const res = mockRes();

    await AuthController.upsertProfile(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('rechaza un rol inválido', async () => {
    const req = { user: { id: 'user-1' }, body: { full_name: 'Ana Torres', role: 'superadmin' } };
    const res = mockRes();

    await AuthController.upsertProfile(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('no incluye latitude/longitude en el upsert si no vienen ambas (no pisa la ubicación guardada)', async () => {
    const req = {
      user: { id: 'user-1' },
      body: { full_name: 'Ana Torres', role: 'adopter', latitude: -34.6 }, // falta longitude
    };
    const res = mockRes();

    await AuthController.upsertProfile(req as never, res as never);

    const builder = lastBuilderFor(mockAdmin, 'profiles');
    const payload = builder.upsert.mock.calls[0][0];
    expect(payload.latitude).toBeUndefined();
    expect(payload.longitude).toBeUndefined();
  });

  it('incluye latitude/longitude en el upsert cuando vienen ambas como número', async () => {
    const req = {
      user: { id: 'user-1' },
      body: { full_name: 'Ana Torres', role: 'adopter', latitude: -34.6, longitude: -58.4 },
    };
    const res = mockRes();

    await AuthController.upsertProfile(req as never, res as never);

    const builder = lastBuilderFor(mockAdmin, 'profiles');
    const payload = builder.upsert.mock.calls[0][0];
    expect(payload.latitude).toBe(-34.6);
    expect(payload.longitude).toBe(-58.4);
  });
});
