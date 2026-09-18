import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createSupabaseAdminMock, createQueryBuilderMock } from './helpers/supabaseMock.js';

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

  it('rechaza (403) proponer una visita en un match del que no se participa', async () => {
    const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
    const req = {
      user: { id: 'usuario-ajeno' },
      params: { matchId: 'm1' },
      body: { proposed_at: futureDate },
    };
    const res = mockRes();

    // matches/getMatchParticipants con el mock por default devuelve null → no participante
    await VisitController.create(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(403);
  });
});

describe('VisitController.updateStatus (cross-tenant)', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rechaza (403) cambiar el estado de una visita de un match ajeno', async () => {
    mockAdmin.from.mockImplementationOnce((table: string) => {
      expect(table).toBe('visit_requests');
      return createQueryBuilderMock({
        data: { id: 'visit-1', match_id: 'match-1', status: 'pending' },
        error: null,
      });
    });
    mockAdmin.from.mockImplementationOnce((table: string) => {
      expect(table).toBe('matches');
      return createQueryBuilderMock({
        data: { adopter_id: 'adopter-1', shelter_id: 'shelter-1' },
        error: null,
      });
    });

    const req = { user: { id: 'usuario-ajeno' }, params: { id: 'visit-1' }, body: { status: 'confirmed' } };
    const res = mockRes();

    await VisitController.updateStatus(req as never, res as never);

    expect(res.status).toHaveBeenCalledWith(403);
  });
});

describe('VisitController.listAll', () => {
  beforeEach(() => vi.clearAllMocks());

  it('incluye limit/offset/hasMore en meta', async () => {
    const req = { user: { id: 'u1' }, query: { limit: '10', offset: '5' } };
    const res = mockRes();

    await VisitController.listAll(req as never, res as never);

    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        meta: expect.objectContaining({ limit: 10, offset: 5 }),
      })
    );
  });
});
