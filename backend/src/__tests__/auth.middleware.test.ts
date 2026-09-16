import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock } from './helpers/supabaseMock.js';

function mockRes() {
  const res: Record<string, unknown> = {};
  res.status = vi.fn(() => res);
  res.json = vi.fn(() => res);
  return res as { status: ReturnType<typeof vi.fn>; json: ReturnType<typeof vi.fn> };
}

describe('authMiddleware', () => {
  beforeEach(() => vi.resetModules());

  it('devuelve 401 si no hay header Authorization', async () => {
    const mockAdmin = createSupabaseAdminMock();
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { authMiddleware } = await import('../middlewares/auth.middleware.js');

    const req = { headers: {} };
    const res = mockRes();
    const next = vi.fn();

    await authMiddleware(req as never, res as never, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('devuelve 401 si el token es inválido o expiró', async () => {
    const mockAdmin = createSupabaseAdminMock();
    mockAdmin.auth.getUser.mockResolvedValue({ data: { user: null }, error: { message: 'invalid token' } });
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { authMiddleware } = await import('../middlewares/auth.middleware.js');

    const req = { headers: { authorization: 'Bearer bad-token' } };
    const res = mockRes();
    const next = vi.fn();

    await authMiddleware(req as never, res as never, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('adjunta req.user con el rol del perfil y llama a next() con token válido', async () => {
    const mockAdmin = createSupabaseAdminMock({
      profiles: { data: { role: 'shelter' }, error: null },
    });
    mockAdmin.auth.getUser.mockResolvedValue({
      data: { user: { id: 'user-1', email: 'a@b.com' } },
      error: null,
    });
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { authMiddleware } = await import('../middlewares/auth.middleware.js');

    const req: { headers: Record<string, string>; user?: unknown } = { headers: { authorization: 'Bearer good-token' } };
    const res = mockRes();
    const next = vi.fn();

    await authMiddleware(req as never, res as never, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(req.user).toEqual({ id: 'user-1', email: 'a@b.com', role: 'shelter' });
  });

  it('usa el rol "adopter" por defecto si el perfil aún no existe', async () => {
    const mockAdmin = createSupabaseAdminMock({
      profiles: { data: null, error: null },
    });
    mockAdmin.auth.getUser.mockResolvedValue({
      data: { user: { id: 'user-2', email: 'new@user.com' } },
      error: null,
    });
    vi.doMock('../config/supabase.js', () => ({ supabaseAdmin: mockAdmin, supabaseAnon: mockAdmin }));
    const { authMiddleware } = await import('../middlewares/auth.middleware.js');

    const req: { headers: Record<string, string>; user?: { role?: string } } = {
      headers: { authorization: 'Bearer good-token' },
    };
    const res = mockRes();
    const next = vi.fn();

    await authMiddleware(req as never, res as never, next);

    expect(req.user?.role).toBe('adopter');
  });
});
