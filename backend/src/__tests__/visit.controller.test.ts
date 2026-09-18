import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock } from './helpers/supabaseMock.js';

const mockAdmin = createSupabaseAdminMock();

vi.mock('../config/supabase.js', () => ({
  supabaseAdmin: mockAdmin,
  supabaseAnon: mockAdmin,
}));

const { VisitController } = await import('../controllers/visit.controller.js');

function mockRes() {
  const res: Record<string, unknown> = {};
  res.status = vi.fn(() => res);
  res.json = vi.fn(() => res);
  return res as { status: ReturnType<typeof vi.fn>; json: ReturnType<typeof vi.fn> };
}

describe('VisitController.create', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza una fecha inválida', async () => {
    const req = {
      user: { id: 'u1' },
      params: { matchId: 'm1' },
      body: { proposed_at: 'no-es-una-fecha' },
    };
    const res = mockRes();

    await VisitController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('rechaza (422) una fecha propuesta en el pasado', async () => {
    const pastDate = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const req = {
      user: { id: 'u1' },
      params: { matchId: 'm1' },
      body: { proposed_at: pastDate },
    };
    const res = mockRes();

    await VisitController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });

  it('rechaza (422) notas que superan los 500 caracteres', async () => {
    const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
    const req = {
      user: { id: 'u1' },
      params: { matchId: 'm1' },
      body: { proposed_at: futureDate, notes: 'x'.repeat(501) },
    };
    const res = mockRes();

    await VisitController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(422);
  });
});
